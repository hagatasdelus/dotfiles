return {
    dir = "~/dev/ghq/github.com/hagatasdelus/tdf.nvim",
    event = "VeryLazy",
    enabled = false,
    config = function()
        require("tdf").setup()
    end,
}
