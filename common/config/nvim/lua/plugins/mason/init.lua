local ensure_installed = {
    "efm",

    "yamlls",
    "jsonls",
    "taplo",
    "denols",
    "vtsls",

    "html",

    "lua_ls",

    "pyright",
    "ruff",
}

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
                ensure_installed = ensure_installed,
                automatic_installation = true,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "b0o/schemastore.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },

        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.config('*', { capabilities = capabilities })
            vim.lsp.enable(ensure_installed)
        end,
    }
}
