local M = {}

local function kind_name(kind)
    local name = vim.lsp.protocol.CompletionItemKind[kind]
    return type(name) == "string" and name or "Text"
end

local function documentation_text(documentation)
    if type(documentation) == "string" then
        return documentation
    end
    if type(documentation) == "table" and type(documentation.value) == "string" then
        return documentation.value
    end
    return ""
end

local function info_text(item)
    local parts = {}
    if item.detail and item.detail ~= "" then
        parts[#parts + 1] = item.detail
    end
    local documentation = documentation_text(item.documentation)
    if documentation ~= "" then
        parts[#parts + 1] = documentation
    end
    return table.concat(parts, "\n\n")
end

local function snippet_plain(text)
    text = text:gsub("%${(%d+):([^}]*)}", "%2")
    text = text:gsub("%$%d+", "")
    text = text:gsub("%$([%a_][%w_]*)", "%1")
    text = text:gsub("\\%$", "$")
    text = text:gsub("\\}", "}")
    text = text:gsub("\\\\", "\\")
    return text
end

local function first_line(text)
    return text:match("^[^\n]*") or ""
end

local function character(text, encoding)
    if encoding == "utf-8" then
        return #text
    end
    local utf32, utf16 = vim.str_utfindex(text, #text)
    return encoding == "utf-16" and utf16 or utf32
end

M._character = character

local function byte_offset(text, position, encoding)
    if encoding == "utf-8" then
        return math.min(position, #text)
    end
    local ok, offset = pcall(vim.str_byteindex, text, position, encoding == "utf-16")
    if not ok then
        return #text
    end
    return offset
end

local function text_edit(item)
    local edit = item.textEdit
    if type(edit) ~= "table" or type(edit.newText) ~= "string" then
        return nil
    end
    return edit
end

local function item_word(item)
    local edit = text_edit(item)
    local text = item.insertText or (edit and edit.newText) or item.label or ""
    if item.insertTextFormat == 2 then
        return first_line(snippet_plain(text))
    end
    return text
end

local function item_start(item, line, encoding, default)
    local edit = text_edit(item)
    if edit and type(edit.range) == "table" and edit.range.start then
        return byte_offset(line, edit.range.start.character or 0, encoding)
    end
    return default
end

function M._convert_item(item, line, encoding, options)
    options = options or {}
    local word = item_word(item)
    local start = item_start(item, line or "", encoding or "utf-16", options.start or 0)
    local data = {
        nvim_lsp = true,
        completion_item = item,
        word = word,
        start = start,
        client_id = options.client_id,
        encoding = encoding or "utf-16",
    }
    if item.insertTextFormat == 2 then
        local edit = text_edit(item)
        data.snippet = edit and edit.newText or item.insertText
    end
    return {
        word = word,
        abbr = item.label or word,
        kind = kind_name(item.kind),
        info = info_text(item),
        filter_text = item.filterText or "",
        sort_text = item.sortText or "",
        data = data,
        start = start,
    }
end

local function request_clients(bufnr)
    if vim.lsp.get_clients then
        return vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/completion" })
    end
    return vim.lsp.get_active_clients({ bufnr = bufnr, method = "textDocument/completion" })
end

local function completion_results(client, params, bufnr)
    local ok, result, err = pcall(client.request_sync, client, "textDocument/completion", params, 500, bufnr)
    if not ok or err ~= nil or result == nil then
        return nil
    end
    return result.result
end

local function collect_items(result)
    if type(result) ~= "table" then
        return {}
    end
    local items = result.items or result
    local defaults = result.itemDefaults
    if type(defaults) ~= "table" then
        return items
    end
    for _, item in ipairs(items) do
        if defaults.insertTextFormat ~= nil and item.insertTextFormat == nil then
            item.insertTextFormat = defaults.insertTextFormat
        end
        if defaults.data ~= nil and item.data == nil then
            item.data = defaults.data
        end
        if defaults.editRange ~= nil and item.textEdit == nil then
            item.textEdit = {
                range = defaults.editRange,
                newText = item.textEditText or item.insertText or item.label,
            }
        end
    end
    return items
end

local function incomplete(result)
    return type(result) == "table" and result.isIncomplete == true
end

function M.gather(opts)
    local context = opts.context or {}
    local input = context.input or ""
    local default_start = #(input:match("[%w_]*$") or "")
    default_start = #input - default_start
    if context.mode ~= "i" then
        return { start = default_start, items = {}, incomplete = false }
    end

    local bufnr = context.bufnr or 0
    local items = {}
    local is_incomplete = false
    local starts = {}

    for _, client in ipairs(request_clients(bufnr)) do
        local encoding = client.offset_encoding or "utf-16"
        local params = {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            position = {
                line = (context.lnum or 1) - 1,
                character = character(input, encoding),
            },
            context = { triggerKind = 1 },
        }
        local result = completion_results(client, params, bufnr)
        local raw_items = collect_items(result)
        is_incomplete = is_incomplete or incomplete(result)
        for _, item in ipairs(raw_items) do
            local converted = M._convert_item(item, input, encoding, {
                client_id = client.id,
                start = default_start,
            })
            items[#items + 1] = converted
            starts[converted.start] = true
        end
    end

    local start = default_start
    local keys = vim.tbl_keys(starts)
    if #keys == 1 then
        start = keys[1]
    end
    return { start = start, items = items, incomplete = is_incomplete }
end

function M.complete(opts)
    local data = opts.data or {}
    local item = data.completion_item
    if type(item) ~= "table" then
        return
    end

    if type(item.additionalTextEdits) == "table" and #item.additionalTextEdits > 0 then
        local bufnr = vim.api.nvim_get_current_buf()
        pcall(vim.lsp.util.apply_text_edits, item.additionalTextEdits, bufnr, data.encoding)
    end

    if data.snippet and vim.snippet then
        local word = data.word or ""
        local cursor = vim.api.nvim_win_get_cursor(0)
        local row = cursor[1] - 1
        local col = cursor[2]
        if col >= #word then
            pcall(vim.api.nvim_buf_set_text, 0, row, col - #word, row, col, {})
        end
        pcall(vim.snippet.expand, data.snippet)
    end

    if type(item.command) == "table" then
        pcall(vim.lsp.buf.execute_command, item.command)
    end
end

function M.resolve(opts)
    local data = opts.data or {}
    local item = data.completion_item
    local client = data.client_id and vim.lsp.get_client_by_id(data.client_id) or nil
    if type(item) ~= "table" or not client then
        return nil
    end
    local resolved = client:request_sync("completionItem/resolve", item, 500, 0)
    if type(resolved) ~= "table" or type(resolved.result) ~= "table" then
        return nil
    end
    local converted = M._convert_item(resolved.result, "", data.encoding, {
        client_id = data.client_id,
        start = data.start,
    })
    converted.data.snippet = converted.data.snippet or data.snippet
    converted.data.word = data.word
    converted.data.start = data.start
    return converted
end

return M
