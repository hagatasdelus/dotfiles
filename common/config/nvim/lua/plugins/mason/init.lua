local ensure_installed = {
    "efm",

    "yamlls",
    "jsonls",
    "taplo",
    "denols",
    "vtsls",

    "html",

    "lua_ls",
    "stylua",

    "pyright",
    "ruff",

    "tinymist",
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
        init = function()
            local auon_attach = require("core.utils").on_attach
            auon_attach(function(client, bufnr)
                if vim.tbl_contains({ "oil" }, vim.bo.filetype) then
                    return
                end

                local on_attach = require("plugins.mason.on_attach")
                on_attach(client, bufnr)

                vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
            end)

            vim.api.nvim_create_user_command("LspDiagnosticReset", function()
                vim.diagnostic.reset()
            end, {})
        end,
    }
}
