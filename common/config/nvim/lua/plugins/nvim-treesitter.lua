return {
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
}
