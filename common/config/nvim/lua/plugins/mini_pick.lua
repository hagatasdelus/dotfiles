return {
    "https://github.com/echasnovski/mini.pick",
    version = false,
    event = "VeryLazy",
    opts = {
        -- window = { config = { border = 'double' } }
    },
    config = function(_, opts)
        local pick = require("mini.pick")
        pick.setup(opts)

        vim.keymap.set("n", "<Leader>nf", function()
            pick.builtin.files()
        end, { desc = "MiniPick: Files" })

        vim.keymap.set("n", "<Leader>ng", function()
            pick.builtin.grep_live()
        end, { desc = "MiniPick: Grep Live" })

        vim.keymap.set("n", "<Leader>nr", function()
            pick.builtin.grep()
        end, { desc = "MiniPick: Grep" })
    end,
}
