return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    enabled = false,
    version = false,
    opts = {
        provider = "copilot",
    },
    build = "make",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim", -- for input provider dressing"
        "ManifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
        "zbirenbaum/copilot.lua", -- for providers = { "copilot" },
        {
            -- Make sure to set this up properly if you have lazy=true
            "MeanderingProgrammer/render-markdown.nvim",
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
