local M = {}

local modules = {
    skkelua = "plugins.goda.skkelua",
    nvim_lsp = "plugins.goda.nvim_lsp",
    nvim_lua = "plugins.goda.nvim_lua",
}

-- gather runs on every keystroke, so report each failure only once.
local reported = {}

local function report(name, method, err)
    local message = string.format("goda-cmp: %s.%s failed: %s", name, method, tostring(err))
    if reported[message] then
        return
    end
    reported[message] = true
    vim.schedule(function()
        vim.notify(message, vim.log.levels.ERROR)
    end)
end

local function module(name)
    local path = modules[name]
    if not path then
        return nil
    end
    local ok, loaded = pcall(require, path)
    if not ok then
        report(name, "require", loaded)
        return nil
    end
    return loaded
end

local function input_length(opts)
    return #((opts.context or {}).input or "")
end

local function empty(start)
    return { start = start or 0, items = {}, incomplete = false }
end

local function is_table(value)
    return type(value) == "table"
end

local function is_number(value)
    return type(value) == "number"
end

local function call(opts, method, fallback, valid)
    local source = module(opts.name)
    if not source or type(source[method]) ~= "function" then
        return fallback
    end
    local ok, result = pcall(source[method], opts)
    if not ok then
        report(opts.name, method, result)
        return fallback
    end
    if valid and not valid(result) then
        report(opts.name, method, "returned " .. type(result))
        return fallback
    end
    return result
end

function M.gather(opts)
    return call(opts, "gather", empty(input_length(opts)), is_table)
end

function M.position(opts)
    return call(opts, "position", -1, is_number)
end

function M.complete(opts)
    call(opts, "complete", nil, nil)
end

function M.resolve(opts)
    return call(opts, "resolve", nil, is_table)
end

return M
