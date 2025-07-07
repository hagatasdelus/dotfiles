return {
    "kazhala/close-buffers.nvim",
    cond = not is_on_vscode(),
    event = { "BufAdd", "TabEnter" },
}
