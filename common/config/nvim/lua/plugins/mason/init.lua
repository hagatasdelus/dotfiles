return {
    {
        "https://github.com/mason-org/mason.nvim",
        dependencies = {
            "https://github.com/mason-org/mason-lspconfig.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        cmd = "Mason",
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = require("hagata.lsp.servers"),
                automatic_installation = true,
            })
        end,
    },
    {
        "https://github.com/neovim/nvim-lspconfig",
        dependencies = {
            "https://github.com/b0o/schemastore.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("hagata.lsp").setup()
        end,
    },
}
