return {
    "https://github.com/chomosuke/term-edit.nvim",
    event = "TermEnter",
    config = function()
        require("term-edit").setup({
            prompt_end = "[❯#$] ",
            mapping = {
                n = {
                    s = false,
                },
            },
        })
    end,
}
