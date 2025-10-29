return {
    "https://github.com/kazhala/close-buffers.nvim",
    cond = not is_on_vscode(),
    event = { "BufAdd", "TabEnter" },
    keys = {
        { "<A-c>", "<Cmd>BufferClose<CR>", desc = "Close Current Buffer" },
        { "<A-w>", "<Cmd>BufferWipeout<CR>", desc = "Wipeout Current Buffer" },
        { "<A-a>", "<Cmd>BufferCloseAllButCurrent<CR>", desc = "Close All Buffers Except Current" },
    },
}
