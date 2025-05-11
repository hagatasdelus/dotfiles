return {
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        cmd = "Mason",
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                -- lsp_servers table Install
                ensure_installed = {
                    "bashls",
                    "efm",
                    "lua_ls",
                    "yamlls",
                    "jsonls",
                    "taplo",
                    "ts_ls",
                    "html",
                    "cssls",
                },
                automatic_installation = true,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- "windwp/nvim-autopairs",
            "hrsh7th/cmp-nvim-lsp",
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lsp_config = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            lsp_config.bashls.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.cssls.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.efm.setup({
                capabilities = capabilities,
                init_options = {
                    documentFormatting = true,
                    documentRangeFormatting = true,
                    hover = true,
                    documentSymbol = true,
                    codeAction = true,
                    completion = true,
                },
                filetypes = {
                    "lua",
                    "python",
                    "html",
                    "javascript",
                    "javascriptreact",
                    "javascript.jsx",
                    "typescript",
                    "typescriptreact",
                    "typescript.tsx",
                    "svelte",
                    "vue",
                    "markdown",
                    "markdown.mdx",
                    "css",
                    "scss",
                    "json",
                    "jsonc",
                    "yaml",
                },
            })
            lsp_config.html.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.jsonls.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.lua_ls.setup({
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { "vim" },
                        },
                        workspace = {
                            -- library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = "Disable",
                        },
                    },
                },
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.taplo.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.ts_ls.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
            lsp_config.yamlls.setup({
                capabilities = capabilities,
                root_dir = function(fname)
                    return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                end,
            })
        end,
    }
}
