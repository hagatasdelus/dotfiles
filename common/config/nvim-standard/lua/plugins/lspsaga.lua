return {
    "https://github.com/nvimdev/lspsaga.nvim",
    config = function()
        require("lspsaga").setup({
            symbol_in_winbar = {
                separator = "  ",
            },
        })
    end,
    dependencies = {
        "https://github.com/nvim-tree/nvim-web-devicons",
    },
    event = { "BufRead", "BufNewFile" },
}
