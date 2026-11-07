local M = {}

local modules = {
    skkelua = "plugins.goda.skkelua",
    nvim_lsp = "plugins.goda.nvim_lsp",
    nvim_lua = "plugins.goda.nvim_lua",
    luasnip = "plugins.goda.luasnip",
}

local function module(name)
    local path = modules[name]
    if not path then
        return nil
    end
    local ok, loaded = pcall(require, path)
    if not ok then
        return nil
    end
    return loaded
end

local function empty(start)
    return { start = start or 0, items = {}, incomplete = false }
end

function M.gather(opts)
    local source = module(opts.name)
    if not source or type(source.gather) ~= "function" then
        return empty(#((opts.context or {}).input or ""))
    end
    local ok, gathered = pcall(source.gather, opts)
    if not ok or type(gathered) ~= "table" then
        return empty(#((opts.context or {}).input or ""))
    end
    return gathered
end

function M.position(opts)
    local source = module(opts.name)
    if not source or type(source.position) ~= "function" then
        return -1
    end
    local ok, position = pcall(source.position, opts)
    if not ok or type(position) ~= "number" then
        return -1
    end
    return position
end

function M.complete(opts)
    local source = module(opts.name)
    if not source or type(source.complete) ~= "function" then
        return
    end
    pcall(source.complete, opts)
end

function M.resolve(opts)
    local source = module(opts.name)
    if not source or type(source.resolve) ~= "function" then
        return nil
    end
    local ok, resolved = pcall(source.resolve, opts)
    if not ok or type(resolved) ~= "table" then
        return nil
    end
    return resolved
end

return M
