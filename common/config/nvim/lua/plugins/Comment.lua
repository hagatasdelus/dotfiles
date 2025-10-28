return {
    "https://github.com/numToStr/Comment.nvim",
    keys = {
        { "gcc", mode = "n" },
        { "gc", mode = { "n", "x" } },
        { "gb", mode = { "n", "x" } },
    },
    config = function()
        require("Comment").setup({
            pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
        })
    end,
}
