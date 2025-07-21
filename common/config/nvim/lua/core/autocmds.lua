-- Command abbreviations
vim.cmd('cnoreabbrev tn tabnew')
vim.cmd('cnoreabbrev vs vsplit')

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function()
        vim.lsp.buf.format() { sync = false, timeout_ms = 20000 }
    end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    callback = function()
        vim.cmd.startinsert()
    end,
})
