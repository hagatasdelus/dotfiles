return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost" },
    cmds = { "Gitsigns" },
    keys = {
        { "]g",         "<Cmd>Gitsigns next_hunk<CR>",       desc = "Next Git Hunk" },
        { "[g",         "<Cmd>Gitsigns prev_hunk<CR>",       desc = "Previous Git Hunk" },
        { "<C-g><C-a>", "<Cmd>Gitsigns stage_hunk<CR>",      desc = "Stage Git Hunk" },
        { "<C-g><C-d>", "<Cmd>Gitsigns diffthis ~<CR>",      desc = "Diff Current File" },
        { "<C-g><C-p>", "<Cmd>Gitsigns diffthis ~<CR>",      desc = "Preview Git Hunk" },
        { "<C-g><C-q>", "<Cmd>Gitsigns setqflist<CR>",       desc = "Set Quickfix List" },
        { "<C-g><C-r>", "<Cmd>Gitsigns undo_stage_hunk<CR>", desc = "Undo Stage Hunk" },
        { "<C-g>a",     "<Cmd>Gitsigns stage_buffer<CR>",    desc = "Stage Buffer" },
        { "<C-g><C-a>", ":'<,'>Gitsigns stage_hunk<CR>",     mode = "x",                desc = "Stage Selected Hunk" },
        { "<C-g><C-v>", "<Cmd>Gitsigns blame_line<CR>",      mode = { "n", "x" },       desc = "Blame Line" },
    },
    opts = function()
        return {
            signcolumn = true,
            numhl = true,
            attach_to_untracked = true,
        }
    end,
    config = function(_, opts)
        local gitsigns = require("gitsigns")
        gitsigns.setup(opts)
    end,
}
