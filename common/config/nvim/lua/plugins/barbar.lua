return {
    "romgrk/barbar.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    init = function()
        vim.g.barbar_auto_setup = false
    end,
    config = function()
        require("barbar").setup({
            animation = true,
            tabpages = true,
            clickable = true,
        })
    end,
    version = "^1.0.0",
}
