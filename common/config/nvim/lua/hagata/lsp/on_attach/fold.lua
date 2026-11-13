local M = {}

function M.on_attach(client, _)
    if client:supports_method("textDocument/foldingRange") then
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_option_value("foldmethod", "expr", { win = win })
        vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.lsp.foldexpr()", { win = win })
        vim.opt_local.foldlevel = 99
        vim.opt_local.foldlevelstart = 99
        vim.opt_local.foldenable = true
    end
end

return M
