local on_attach = function(client, bufnr)
    require("plugins.mason.on_attach.keymaps").on_attach(client, bufnr)
    -- require("plugins.mason.on_attach.diagnostic").on_attach(client, bufnr)
    require("plugins.mason.on_attach.format").on_attach(client, bufnr)
end

return on_attach
