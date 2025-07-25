local M = {}

function M.on_attach(client, buf)
    if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = buf,
            callback = function()
                vim.lsp.buf.format({
                    filter = function(c)
                        return c.name == client.name
                    end,
                    bufnr = buf,
                })
            end,
        })
    end
end

return M
