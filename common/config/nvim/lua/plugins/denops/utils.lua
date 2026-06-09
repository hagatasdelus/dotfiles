local M = {}

local deno = require("plugins.denops.deno")

function M.get_or_install(version)
    version = version or "2.8.2"
    local nvim_cache = vim.fn.stdpath("cache") --[[@as string]]
    local cache_denops = vim.fs.joinpath(nvim_cache, "denops", "deno", version)
    local deno_paths = {
        bin = vim.fs.joinpath(cache_denops, "bin", "deno"),
        cache = vim.fs.joinpath(cache_denops, "cache"),
    }
    if not vim.uv.fs_stat(deno_paths.bin) then
        local obj = deno.install(version, { env = { DENO_INSTALL = cache_denops } }):wait()
        if obj.code ~= 0 then
            error(obj.stderr) -- requires unzip
        end
    end
    -- return bin, vim.fs.joinpath(base, "cache")
    return deno_paths
end

---Deno cache for denops plugins
---@param x string | table | nil i.e. Lazyspec
---@param reload boolean | nil
function M.cache_plugin(x, reload)
    local dir = type(x) == "table" and require("atusy.lazy").dir(x) or x or require("lazy.core.config").root
    if type(dir) ~= "string" then
        return
    end
    deno.cache_dir(dir, vim.g["denops#deno"], vim.g["denops#deno_dir"], reload)
end

return M
