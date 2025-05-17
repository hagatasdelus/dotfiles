-- local ensure_installed = {
--     "efm",
--     "lua_ls",
--     "yamlls",
--     "jsonls",
--     "taplo",
--     "ts_ls",
--     "html",
-- }

return {
    {
        "mason-org/mason.nvim",
        dependencies = {
            "mason-org/mason-lspconfig.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        cmd = "Mason",
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "efm",
                    "lua_ls",
                    "yamlls",
                    "jsonls",
                    "ts_ls",
                    "html",
                },
                automatic_installation = true,
            })
    end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        event = { "BufReadPre", "BufNewFile" },

        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.config('*', { capabilities = capabilities })
            vim.lsp.enable({
                "efm",
            })
        end,
    }
}
