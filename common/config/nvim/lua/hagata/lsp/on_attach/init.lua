local on_attach = function(client, bufnr)
    require("hagata.lsp.on_attach.keymaps").on_attach(client, bufnr)
    -- require("hagata.lsp.on_attach.diagnostic").on_attach(client, bufnr)
    require("hagata.lsp.on_attach.format").on_attach(client, bufnr)
    require("hagata.lsp.on_attach.fold").on_attach(client, bufnr)
end

return on_attach
