---@type vim.lsp.Config
return {
    -- cmd = { "lua-language-server" },
    -- filetypes = { "lua" },
    -- root_markers = { ".git", ".luarc.json", ".luarc.jsonc", ".luacheckrc", "stylua.toml", "selene.toml", "selene.yml" },
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
        },
    },
}
