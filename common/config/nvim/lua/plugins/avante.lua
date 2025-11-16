return {
    "https://github.com/yetone/avante.nvim",
    event = "VeryLazy",
    enabled = false,
    version = false,
    opts = {
        provider = "copilot",
    },
    build = "make",
    dependencies = {
        "https://github.com/nvim-lua/plenary.nvim",
        "https://github.com/nvim-treesitter/nvim-treesitter",
        "https://github.com/stevearc/dressing.nvim", -- for input provider dressing"
        "https://github.com/ManifTanjim/nui.nvim",
        "https://github.com/nvim-tree/nvim-web-devicons",
        "https://github.com/zbirenbaum/copilot.lua", -- for providers = { "copilot" },
        {
            -- Make sure to set this up properly if you have lazy=true
            "https://github.com/MeanderingProgrammer/render-markdown.nvim",
            opts = {
                file_types = {
                    -- "markdown",
                    "Avante",
                },
            },
            ft = {
                -- "markdown",
                "Avante",
            },
        },
    },
}
