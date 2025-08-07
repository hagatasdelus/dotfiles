local M = {}

local map = vim.keymap.set

local function extend_opts(desc, buffer)
    local opts = vim.tbl_extend("force", { silent = true }, {})
    if desc then
        opts.desc = desc
    end
    if buffer then
        opts.buffer = buffer
    end
    return opts
end

M.on_attach = function(client, bufnr)
    map("n", "gD", vim.lsp.buf.declaration, extend_opts("Go to declaration", bufnr))
    map("n", "gd", vim.lsp.buf.definition, extend_opts("Go to definition", bufnr))
    map("n", "K", vim.lsp.buf.hover, extend_opts("Hover", bufnr))
    map("n", "gi", vim.lsp.buf.implementation, extend_opts("Go to implementation", bufnr))
    map("i", "<C-k>", vim.lsp.buf.signature_help, extend_opts("Signature help", bufnr))
    map("n", "gk", vim.lsp.buf.signature_help, extend_opts("Signature help", bufnr))
    map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, extend_opts("Add workspace folder", bufnr))
    map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, extend_opts("Remove workspace folder", bufnr))
    map("n", "<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, extend_opts("List workspace folders", bufnr))
    map("n", "<leader>D", vim.lsp.buf.type_definition, extend_opts("Go to type definition", bufnr))
    map("n", "<leader>rn", vim.lsp.buf.rename, extend_opts("Rename", bufnr))
    map({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, extend_opts("Code action", bufnr))
    map("n", "gr", vim.lsp.buf.references, extend_opts("References", bufnr))
    map("n", "<leader><space>", function()
        vim.lsp.buf.format({ async = true })
    end, extend_opts("Format", bufnr))
    -- Diagnostic mappings
    map("n", "<leader>e", vim.diagnostic.open_float, extend_opts("Open diagnostic float", bufnr))
    map("n", "[d", vim.diagnostic.goto_prev, extend_opts("Go to previous diagnostic", bufnr))
    map("n", "]d", vim.diagnostic.goto_next, extend_opts("Go to next diagnostic", bufnr))
    map("n", "<leader>q", vim.diagnostic.setloclist, extend_opts("Set diagnostic loclist", bufnr))
    -- Lspsaga key mappings
    map("n", "<leader>lf", "<Cmd>Lspsaga finder<cr>", extend_opts("Lspsaga Finder show references", bufnr))
    map("n", "<leader>lh", "<Cmd>Lspsaga hover_doc<cr>", extend_opts("Lspsaga Hover Doc", bufnr))
    map("n", "<leader>lo", "<Cmd>Lspsaga outline<cr>", extend_opts("Lspsaga Outline", bufnr))
    map("n", "<leader>lr", "<Cmd>Lspsaga rename<cr>", extend_opts("Lspsaga Rename", bufnr))
    map("n", "<leader>la", "<Cmd>Lspsaga code_action<cr>", extend_opts("Lspsaga Code Action", bufnr))
end

return M
