-- Command abbreviations
vim.cmd('cnoreabbrev tn tabnew')
vim.cmd('cnoreabbrev vs vsplit')

vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    callback = function()
        vim.cmd.startinsert()
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        vim.api.nvim_exec('silent! normal! g`"zv', false)
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})
