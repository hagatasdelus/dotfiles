local M = {}

function M.on_attach(client, bufnr)
    if client.supports_method("textDocument/publishDiagnostics") then
        vim.api.nvim_set_option_value("vim.diagnostic.config", {
            virtual_text = {
                spacing = 4,
                prefix = "●",
            },
            signs = true,
            underline = true,
            update_in_insert = false,
        }, { buf = bufnr })
    end
end

return M
