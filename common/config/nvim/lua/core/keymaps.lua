local vim = vim

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function extend_opts(desc, buffer)
    local final_opts = vim.tbl_extend("force", opts, {})
    if desc then
        final_opts.desc = desc
    end
    if buffer then
        final_opts.buffer = buffer
    end
    return final_opts
end

-- Key mappings
map("n", "<CR><CR>", "<C-w><C-w>")
map("i", "jj", "<ESC>")
map("", "ss", "^")
map("", ";;", "$")
map("n", "<Tab>", "<Cmd>tabnext<CR>", opts)
map("n", "<S-Tab>", "<Cmd>tabprevious<CR>", opts)
map("n", "th", "<Cmd>tabfirst<CR>", opts)
map("n", "tj", "<Cmd>tabprevious<CR>", opts)
map("n", "tk", "<Cmd>tabnext<CR>", opts)
map("n", "tl", "<Cmd>tablast<CR>", opts)
map("n", "tt", "<Cmd>tabe .<CR>", opts)
map("n", "tq", "<Cmd>tabclose<CR>", opts)
map("n", "tm", "<Cmd>tab term<CR>", opts)
map({ "n", "v" }, "x", '"_x')  -- Delete without yanking
map({ "n", "v" }, "X", '"_d$') -- Delete to end of line without yanking
-- terminal mode
map("t", [[<ESC><ESC>]], [[<C-\><C-n>]], opts)
map("t", [[<C-[><C-[>]], [[<C-\><C-n>]], opts)

-- LSP-related key mapping and configuration
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        -- Buffer local LSP configuration
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        -- Buffer-local key mapping
        map("n", "gD", vim.lsp.buf.declaration, extend_opts("Go to declaration", ev.buf))
        map("n", "gd", vim.lsp.buf.definition, extend_opts("Go to definition", ev.buf))
        map("n", "K", vim.lsp.buf.hover, extend_opts("Hover", ev.buf))
        map("n", "gi", vim.lsp.buf.implementation, extend_opts("Go to implementation", ev.buf))
        map("n", "<C-k>", vim.lsp.buf.signature_help, extend_opts("Signature help", ev.buf))
        map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, extend_opts("Add workspace folder", ev.buf))
        map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, extend_opts("Remove workspace folder", ev.buf))
        map("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, extend_opts("List workspace folders", ev.buf))
        map("n", "<leader>D", vim.lsp.buf.type_definition, extend_opts("Go to type definition", ev.buf))
        map("n", "<leader>rn", vim.lsp.buf.rename, extend_opts("Rename", ev.buf))
        map({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, extend_opts("Code action", ev.buf))
        map("n", "gr", vim.lsp.buf.references, extend_opts("References", ev.buf))
        map("n", "<leader><space>", function()
            vim.lsp.buf.format({ async = true })
        end, extend_opts("Format", ev.buf))

        -- Diagnostic mappings
        map("n", "<leader>e", vim.diagnostic.open_float, extend_opts("Open diagnostic float", ev.buf))
        map("n", "[d", vim.diagnostic.goto_prev, extend_opts("Go to previous diagnostic", ev.buf))
        map("n", "]d", vim.diagnostic.goto_next, extend_opts("Go to next diagnostic", ev.buf))
        map("n", "<leader>q", vim.diagnostic.setloclist, extend_opts("Set diagnostic loclist", ev.buf))

        -- Lspsaga key mappings
        map("n", "<leader>lf", "<Cmd>Lspsaga finder<cr>", extend_opts("Lspsaga Finder show references", ev.buf))
        map("n", "<leader>lh", "<Cmd>Lspsaga hover_doc<cr>", extend_opts("Lspsaga Hover Doc", ev.buf))
        map("n", "<leader>lo", "<Cmd>Lspsaga outline<cr>", extend_opts("Lspsaga Outline", ev.buf))
        map("n", "<leader>lr", "<Cmd>Lspsaga rename<cr>", extend_opts("Lspsaga Rename", ev.buf))
        map("n", "<leader>la", "<Cmd>Lspsaga code_action<cr>", extend_opts("Lspsaga Code Action", ev.buf))
    end,
})
