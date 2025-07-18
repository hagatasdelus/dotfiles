return {
    "romgrk/barbar.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    cond = not is_on_vscode(),
    event = { "BufAdd", "TabEnter" },
    init = function()
        vim.g.barbar_auto_setup = false
    end,
    config = function()
        require("barbar").setup({
            animation = false,

            -- icons = {
            --     separator = {left = '▎', right = ''},
            --     separator_at_end = true,
            -- },

            -- auto_hide = true,
            tabpages = true,
            clickable = true,

            -- highlight_visible = true,
            -- highlight_alternate = false,
        })
    end,
    version = "^1.0.0",
}
