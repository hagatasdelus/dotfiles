-- @base https://zenn.dev/uga_rosa/articles/afe384341fc2e1

local function get_plugin_paths(names)
    local plugins = require("lazy.core.config").plugins
    return vim.iter(names)
        :filter(function(name)
            local exists = plugins[name] ~= nil
            if not exists then
                vim.notify(string.format("Plugin '%s' not found in lazy config", name), vim.log.levels.WARN)
            end
            return exists
        end)
        :map(function(name)
            return plugins[name].dir .. "/lua"
        end)
        :totable()
end

local function library(plugins)
    local plugin_paths = get_plugin_paths(plugins)

    local base_paths = {
        -- vim.fn.stdpath("config") .. "/lua",
        vim.env.VIMRUNTIME .. "/lua",
        "${3rd}/luv/library",
        "${3rd}/busted/library",
        "${3rd}/luassert/library",
    }

    return vim.iter({ base_paths, plugin_paths }):flatten():totable()
end

---@type vim.lsp.Config
return {
    on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
                pathStrict = true,
                path = {
                    "?.lua",
                    "?/init.lua",
                },
            },
            diagnostics = {
                globals = { "vim" },
                unusedLocalExclude = { "_*" },
            },
            workspace = {
                library = library({
                    "lazy.nvim",
                    "plenary.nvim",
                    "noice.nvim",
                    "nvim-cmp",
                    "nvim-lspconfig",
                    "snacks.nvim",
                    "oil.nvim",
                }),
                checkThirdParty = "Disable",
            },
            format = {
                enable = false,
            },
            hint = {
                enable = true,
            },
            semantic = {
                enable = false,
            },
        },
    },
}
