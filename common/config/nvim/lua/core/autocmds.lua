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

-- FileType specific settings
local set_file_type_settings = function(ft, settings)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        callback = function()
            for option, value in pairs(settings) do
                vim.opt_local[option] = value
            end
        end
    })
end

-- -- Define settings for each filetype
set_file_type_settings('cpp', {
    tabstop = 2,
    shiftwidth = 2,
    expandtab = true
})

set_file_type_settings('c', {
    tabstop = 2,
    expandtab = true
})

set_file_type_settings('markdown', {
    expandtab = true
})

set_file_type_settings('javascript', {
    tabstop = 2,
    shiftwidth = 2,
    expandtab = true
})

set_file_type_settings('typescript', {
    tabstop = 2,
    shiftwidth = 2,
    expandtab = true
})

set_file_type_settings('json', {
    tabstop = 2,
    shiftwidth = 2,
    expandtab = true
})

set_file_type_settings('html', {
    tabstop = 2,
    shiftwidth = 2,
    expandtab = true,
    autoindent = false,
    cindent = false,
    smartindent = false
})
