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
}
