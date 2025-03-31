local lsp_servers = {
    "pyright",
    "ruff",
    "bashls",
    "lua_ls",
    "yamlls",
    "jsonls",
    "taplo",
    "ts_ls",
    "html",
    "cssls",
}

local formatters = {
    "stylua",
    "shfmt",
    "prettier",
}

local diagnostics = {
    "yamllint",
    "selene",
}

return {
    -- mason / mason-lspconfig / lspconfig
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig",
            "jay-babu/mason-null-ls.nvim",
            "nvimtools/none-ls.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        cmd = "Mason",
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                -- lsp_servers table Install
                ensure_installed = lsp_servers,
            })

            local lsp_config = require("lspconfig")
            -- lsp_servers table setup
            for _, lsp_server in ipairs(lsp_servers) do
                if lsp_server == "lua_ls" then
                    -- Should be corrected in future
                    lsp_config[lsp_server].setup({
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
                else
                    lsp_config[lsp_server].setup({
                        root_dir = function(fname)
                            return lsp_config.util.find_git_ancestor(fname) or vim.fn.getcwd()
                        end,
                    })
                end
            end
        end,
    },

    -- mason-null-ls
    {
        "jay-babu/mason-null-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        cmd = "Mason",
        dependencies = {
            "williamboman/mason.nvim",
            "nvimtools/none-ls.nvim",
        },
        config = function()
            require("mason-null-ls").setup({
                automatic_setup = true,
                -- formatters table and diagnostics table Install
                ensure_installed = vim.tbl_flatten({ formatters, diagnostics }),
                handlers = {},
            })
        end,
    },

    -- none-ls
    {
        "nvimtools/none-ls.nvim",
        requires = "nvim-lua/plenary.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local null_ls = require("null-ls")

            -- formatters table
            local formatting_sources = {}
            for _, tool in ipairs(formatters) do
                table.insert(formatting_sources, null_ls.builtins.formatting[tool])
            end

            -- diagnostics table
            local diagnostics_sources = {}
            for _, tool in ipairs(diagnostics) do
                table.insert(diagnostics_sources, null_ls.builtins.diagnostics[tool])
            end

            -- none-ls setup
            null_ls.setup({
                diagnostics_format = "[#{m}] #{s} (#{c})",
                sources = vim.tbl_flatten({ formatting_sources, diagnostics_sources }),
            })
        end,
    },
}
