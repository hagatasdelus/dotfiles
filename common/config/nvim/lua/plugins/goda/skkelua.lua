local M = {}

local active_phases = {
    ["input:okurinasi"] = true,
    ["input:okuriari"] = true,
    henkan = true,
}

local function skk()
    return package.loaded["skkelua"]
end

local function pum_item()
    local ok, visible = pcall(vim.fn["pum#visible"])
    if not ok or not (visible == true or visible == 1) then
        return nil
    end
    local item_ok, item = pcall(vim.fn["pum#current_item"])
    if not item_ok or type(item) ~= "table" then
        return nil
    end
    return item
end

local function shown_sources()
    if vim.fn.exists("*goda_cmp#_shown") ~= 1 then
        return {}
    end
    local ok, shown = pcall(vim.fn["goda_cmp#_shown"])
    if not ok or type(shown) ~= "table" then
        return {}
    end
    return type(shown.sources) == "table" and shown.sources or {}
end

local function showing_skkelua()
    return vim.tbl_contains(shown_sources(), "skkelua")
end

local function is_register_item(item)
    if type(item) ~= "table" then
        return false
    end
    local data = vim.tbl_get(item, "user_data", "nvim", "lsp", "completion_item", "data")
    if type(data) == "table" and data.register == true then
        return true
    end
    return item.abbr == "[辞書登録]" or item.word == "[辞書登録]"
end

local function register_item()
    return {
        user_data = {
            nvim = { lsp = { completion_item = { data = { skkelua = true, register = true } } } },
        },
    }
end

local function kind_name(kind)
    local name = vim.lsp.protocol.CompletionItemKind[kind]
    return type(name) == "string" and name or "Text"
end

local function unescape_snippet(text)
    return (text:gsub("\\%$", "$"):gsub("\\\\", "\\"))
end

local function item_word(item)
    local data = item.data or {}
    if type(data.text) == "string" and data.text ~= "" then
        return data.text
    end
    local edit = item.textEdit
    if type(edit) == "table" and type(edit.newText) == "string" then
        return unescape_snippet(edit.newText)
    end
    return item.label or ""
end

local function to_item(item)
    local data = vim.deepcopy(item.data or {})
    data.skkelua = true
    local word = item_word(item)
    return {
        word = word,
        abbr = data.display or item.label or word,
        kind = kind_name(item.kind),
        sort_text = item.sortText or "",
        data = data,
    }
end

local function empty(start)
    return { start = start, items = {}, incomplete = true }
end

function M.active()
    local module = skk()
    if not module or not module.is_enabled() then
        return false
    end
    return active_phases[module.phase()] == true
end

function M.position(opts)
    local module = skk()
    if not module or not module.is_enabled() then
        return -1
    end
    local input = (opts.context or {}).input or ""
    local pre_edit = module.get_pre_edit()
    if pre_edit == "" or not vim.endswith(input, pre_edit) then
        return -1
    end
    return #input - #pre_edit
end

function M.gather(opts)
    local context = opts.context or {}
    local start = M.position(opts)
    if start < 0 then
        return empty(#(context.input or ""))
    end

    local completeopt = vim.bo.completeopt
    local ok, list = pcall(require("skkelua.lsp")._make_completion_list)
    pcall(function()
        vim.bo.completeopt = completeopt
    end)
    if not ok or type(list) ~= "table" then
        return empty(start)
    end

    local items = {}
    for _, item in ipairs(list.items or {}) do
        item.detail = nil
        items[#items + 1] = to_item(item)
    end
    return { start = start, items = items, incomplete = list.isIncomplete == true }
end

function M.complete(opts)
    local data = opts.data or {}
    local module = skk()
    if not module then
        return
    end

    if data.register then
        vim.schedule(function()
            module.handle("handleKey", { ["function"] = "registerWord" })
        end)
        return
    end

    if data.raw then
        return
    end

    if data.midasi and data.word and data.type then
        module.complete_callback(data.midasi, data.word, data.type)
    end
end

function M.setup()
    local module = skk()
    if not module or module._goda_cmp_vim_status then
        return
    end
    module._goda_cmp_vim_status = true

    local original = module.vim_status
    module.vim_status = function()
        local status = original()
        if type(status) ~= "table" or status.completeType ~= "pum.vim" then
            return status
        end
        if not is_register_item(pum_item()) then
            return status
        end
        status.completeInfo = status.completeInfo or {}
        status.completeInfo.selected = 0
        status.completeInfo.items = { register_item() }
        return status
    end

    vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("config.goda_cmp.skkelua", { clear = true }),
        pattern = "skkelua-handled",
        callback = function()
            vim.schedule(function()
                if M.active() then
                    if vim.fn.exists("*goda_cmp#complete") == 1 then
                        vim.fn["goda_cmp#complete"]({ sources = { "skkelua" } })
                    end
                    return
                end
                if vim.fn.exists("*goda_cmp#hide") == 1 and showing_skkelua() then
                    vim.fn["goda_cmp#hide"]()
                end
            end)
        end,
    })
end

return M
