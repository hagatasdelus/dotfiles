local M = {}

local cache = {}

local function snippet_filetypes()
    local ok, util = pcall(require, "luasnip.util.util")
    if not ok then
        return {}
    end
    return util.get_snippet_filetypes()
end

local function filetype_items(filetype)
    if cache[filetype] then
        return cache[filetype]
    end
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        return {}
    end
    local items = {}
    for _, snip in pairs(luasnip.get_snippets(filetype, { type = "snippets" })) do
        if not snip.hidden then
            items[#items + 1] = {
                word = snip.trigger,
                abbr = snip.trigger,
                kind = "Snippet",
                data = {
                    luasnip = true,
                    filetype = filetype,
                    snip_id = snip.id,
                    priority = snip.effective_priority or 1000,
                },
            }
        end
    end
    table.sort(items, function(a, b)
        return a.data.priority > b.data.priority
    end)
    cache[filetype] = items
    return items
end

local function keyword_start(input)
    return #input - #(input:match("[%w_]*$") or "")
end

local function shown(snip_id, input)
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        return false
    end
    local snip = luasnip.get_id_snippet(snip_id)
    if not snip then
        return false
    end
    return snip.show_condition == nil or snip.show_condition(input)
end

function M.gather(opts)
    local context = opts.context or {}
    local input = context.input or ""
    local ok, _ = pcall(require, "luasnip")
    if not ok then
        return { start = keyword_start(input), items = {}, incomplete = false }
    end

    local items = {}
    for _, filetype in ipairs(snippet_filetypes()) do
        for _, candidate in ipairs(filetype_items(filetype)) do
            if shown(candidate.data.snip_id, input) then
                items[#items + 1] = vim.deepcopy(candidate)
            end
        end
    end
    return { start = keyword_start(input), items = items, incomplete = false }
end

function M.resolve(opts)
    local data = opts.data or {}
    local ok, luasnip = pcall(require, "luasnip")
    if not ok or not data.snip_id then
        return nil
    end
    local snip = luasnip.get_id_snippet(data.snip_id)
    if not snip then
        return nil
    end
    local documentation = table.concat({
        (snip.name or "") .. " _ `[" .. (data.filetype or "") .. "]`",
        "",
        "```" .. (data.filetype or ""),
        snip:get_docstring(),
        "```",
        "",
        snip.dscr or "",
    }, "\n")
    return { info = documentation, data = data }
end

function M.complete(opts)
    local data = opts.data or {}
    local ok, luasnip = pcall(require, "luasnip")
    if not ok or not data.snip_id then
        return
    end
    local snip = luasnip.get_id_snippet(data.snip_id)
    if not snip then
        return
    end
    if snip.regTrig then
        snip = snip:get_pattern_expand_helper()
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    cursor[1] = cursor[1] - 1
    local line = require("luasnip.util.util").get_current_line_to_cursor()
    local expand_params = snip:matches(line)
    local word = data.word or snip.trigger
    local clear_region = {
        from = { cursor[1], cursor[2] - #word },
        to = cursor,
    }
    if expand_params ~= nil then
        if expand_params.clear_region ~= nil then
            clear_region = expand_params.clear_region
        elseif expand_params.trigger ~= nil then
            clear_region = {
                from = { cursor[1], cursor[2] - #expand_params.trigger },
                to = cursor,
            }
        end
    end
    luasnip.snip_expand(snip, { clear_region = clear_region, expand_params = expand_params })
end

return M
