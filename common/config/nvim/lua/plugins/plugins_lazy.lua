return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        opts = {
            window = {
                position = "left",
            },
            event_handlers = {
                {
                    event = "file_open_requested",
                    handler = function()
                        require("neo-tree.command").execute({ action = "close" })
                    end,
                },
            },
        },
        cmd = "Neotree",
    },
    {
        "echasnovski/mini.indentscope",
        config = function()
            require("mini.indentscope").setup({
                symbol = "▏",
            })
        end,
        event = "BufRead",
    },
    {
        "nvim-treesitter/nvim-treesitter",
        event = {
            "BufRead",
            "BufNewFile",
            "InsertEnter",
        },
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")
            configs.setup({
                ensure_installed = {
                    "awk",
                    "bash",
                    "c",
                    "cpp",
                    "csv",
                    "diff",
                    "go",
                    "html",
                    "htmldjango",
                    "java",
                    "javascript",
                    "json",
                    "lua",
                    "markdown",
                    "python",
                    "rust",
                    "scss",
                    "sql",
                    "ssh_config",
                    "typescript",
                    "toml",
                    "vim",
                    "xml",
                    "regex",
                    "vimdoc",
                },
                sync_install = false,
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },
    {
        "romgrk/barbar.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        init = function()
            vim.g.barbar_auto_setup = false
        end,
        opts = {
            animation = true,
            tabpages = true,
            clickable = true,
        },
        version = "^1.0.0",
    },
    {
        "kazhala/close-buffers.nvim",
    },
    {
        "folke/which-key.nvim",
        lazy = true,
        event = "VeryLazy",
        cmd = {
            "WhichKey",
        },
        opts = {},
    },
    {
        "numToStr/Comment.nvim",
        opts = true,
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        opts = {
            lsp = {
                overrice = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
        },
        presets = {
            bottom_search = true,
            command_palette = true,
            long_message_to_split = true,
            inc_rename = false,
            lsp_doc_border = false,
        },
    },
    -- Editorial Enhancement
    {
        "RRethy/nvim-treesitter-textsubjects",
        config = function()
            require("nvim-treesitter.configs").setup({
                textsubjects = {
                    enable = true,
                    prev_selection = ",", -- (Optional) keymap to select the previous selection
                    keymaps = {
                        ["."] = "textsubjects-smart",
                        [";"] = "textsubjects-container-outer",
                        ["i;"] = {
                            "textsubjects-container-inner",
                            desc = "Select inside containers (classes, functions, etc,)",
                        },
                    },
                },
            })
        end,
    },
}
