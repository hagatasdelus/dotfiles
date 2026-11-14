local M = {}

local kind_by_type = {
    ["function"] = "Function",
    table = "Struct",
    string = "Value",
    boolean = "Value",
    number = "Value",
}

local function item(key, value)
    local value_type = type(value)
    return {
        word = key,
        abbr = key,
        kind = kind_by_type[value_type] or "Field",
        info = value_type,
        data = { nvim_lua = true },
    }
end

local function target(path)
    local node = _G
    for _, name in ipairs(vim.split(path, ".", { plain = true })) do
        if name ~= "" then
            if type(node) ~= "table" then
                return nil
            end
            node = node[name]
        end
    end
    return node
end

function M._items(_, path)
    local node = target(path or "")
    if type(node) ~= "table" then
        return {}
    end

    local keys = vim.tbl_keys(node)
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    local items = {}
    for _, key in ipairs(keys) do
        if type(key) == "string" then
            items[#items + 1] = item(key, node[key])
        end
    end
    return items
end

function M.gather(opts)
    local context = opts.context or {}
    local input = context.input or ""
    local filetype = context.filetype or vim.bo.filetype
    if filetype ~= "lua" and filetype ~= "vim" then
        return { start = #input, items = {}, incomplete = false }
    end

    local head, tail = input:match("^(.*)%.([%w_]*)$")
    if head == nil then
        return { start = #input, items = {}, incomplete = false }
    end

    local items = M._items(nil, head)
    local filtered = {}
    for _, candidate in ipairs(items) do
        if vim.startswith(candidate.word, tail) then
            filtered[#filtered + 1] = candidate
        end
    end
    return { start = #input - #tail, items = filtered, incomplete = false }
end

return M
