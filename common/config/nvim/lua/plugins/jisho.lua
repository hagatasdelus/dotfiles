return {
    "https://github.com/Imngzx/jisho.nvim",
    cmd = "Jisho",
    keys = {
        {
            "<Leader>tj",
            function()
                require("jisho").search()
            end,
            mode = "n",
        },
        {
            "<Leader>tj",
            function()
                local start_pos = vim.fn.getpos("v")
                local end_pos = vim.fn.getpos(".")
                local lines = vim.fn.getregion(start_pos, end_pos)
                vim.api.nvim_feedkeys(
                    vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
                    require("jisho").search(table.concat(lines, " "))
                )
            end,
            mode = "v",
        },
    },
    opts = {},
}
