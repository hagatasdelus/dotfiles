return {
    "kazhala/close-buffers.nvim",
    cond = not use_in_vscode(),
    event = { "BufAdd", "TabEnter" },
}
