-- Keymaps for mo.nvim (buffer local)
vim.keymap.set("n", "<Leader>mo", "<Plug>(mo-preview)", { buffer = true, desc = "Markdown preview" })
vim.keymap.set(
    "n",
    "<Leader>mc",
    "<Plug>(mo-preview-cmux)",
    { buffer = true, desc = "Markdown preview in cmux browser" }
)
vim.keymap.set("n", "<Leader>mC", "<Plug>(mo-close)", { buffer = true, desc = "Close cmux preview browser" })
