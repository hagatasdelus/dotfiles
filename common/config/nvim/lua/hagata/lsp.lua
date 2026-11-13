local M = {}

function M.setup()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    vim.lsp.config("*", { capabilities = capabilities })

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
            local bufnr = args.buf
            if vim.tbl_contains({ "oil" }, vim.bo[bufnr].filetype) then
                return
            end

            require("hagata.lsp.on_attach")(client, bufnr)
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
        end,
    })

    vim.api.nvim_create_user_command("LspDiagnosticReset", function()
        vim.diagnostic.reset()
    end, {})

    vim.lsp.enable(require("hagata.lsp.servers"))
end

return M
