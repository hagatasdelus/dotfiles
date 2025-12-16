---@type vim.lsp.Config
return {
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
                -- library = vim.api.nvim_get_runtime_file("", true),
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
