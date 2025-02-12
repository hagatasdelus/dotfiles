-- Key mappings setup
local vim = vim

-- local map = vim.api.nvim_set_keymap
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function extend_opts(desc, buffer)
    -- return vim.tbl_extend('force', opts, { desc = desc })
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
map("n", "<CR><CR>", "<C-w><C-w>", extend_opts(""))
map("i", "jj", "<ESC>", opts)
map("", "ss", "^", opts)
map("", ";;", "$", opts)
map("n", "<leader>nn", "<Cmd>Neotree toggle<CR>", extend_opts("Neotree Toggle"))
map(
    "n",
    "<leader>no",
    "<Cmd>Neotree reveal<CR><Cmd>Neotree ~/dotfiles/common/config/nvim/<CR>",
    extend_opts("Neotree reveal")
)

-- Move to previous/next
map("n", "<leader>,", "<Cmd>BufferPrevious<CR>", opts)
map("n", "<leader>.", "<Cmd>BufferNext<CR>", opts)

-- Re-order to previous/next
map("n", "<leader>>", ":BufferMovePrevious<CR>", opts)
map("n", "<leader><", "<Cmd>BufferMoveNext<CR>", opts)

-- Goto buffer in position...
map("n", "<leader>1", "<Cmd>BufferGoto 1<CR>", opts)
map("n", "<leader>2", "<Cmd>BufferGoto 2<CR>", opts)
map("n", "<leader>3", "<Cmd>BufferGoto 3<CR>", opts)
map("n", "<leader>4", "<Cmd>BufferGoto 4<CR>", opts)
map("n", "<leader>5", "<Cmd>BufferGoto 5<CR>", opts)
map("n", "<leader>6", "<Cmd>BufferGoto 6<CR>", opts)
map("n", "<leader>7", "<Cmd>BufferGoto 7<CR>", opts)
map("n", "<leader>8", "<Cmd>BufferGoto 8<CR>", opts)
map("n", "<leader>9", "<Cmd>BufferGoto 9<CR>", opts)
map("n", "<leader>0", "<Cmd>BufferLast<CR>", opts)

map("n", "<leader>hd", "<Cmd>DiffviewOpen HEAD~1<CR>", opts)
map("n", "<leader>hf", "<Cmd>DiffviewFileHistory %<CR>", opts)

map("n", "<leader>gg", "<Cmd>LazyGit<CR>", extend_opts("LazyGit"))

-- map('n', 'un', ':<C-u>Unite buffer<CR>', opt )
-- map('n', 'fgr', ':<cmd>Telescope live_grep<CR>', opts)
-- map('n', 'term', ':ToggleTerm', opts)
-- map('n', '<space>jj', '<C-\\><C-n>', opts)
-- map('n', 'gx', '<Plug>(openbrowser-smart-search)', opts)

-- LSP関連のキーマッピングと設定
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        -- バッファローカルでのLSP設定
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        -- バッファローカルなキーマッピング
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

        -- Lspsaga キーマッピング
        map("n", "<leader>lf", "<Cmd>Lspsaga finder<cr>", extend_opts("Lspsaga Finder show references", ev.buf))
        map("n", "<leader>lh", "<Cmd>Lspsaga hover_doc<cr>", extend_opts("Lspsaga Hover Doc", ev.buf))
        map("n", "<leader>lo", "<Cmd>Lspsaga outline<cr>", extend_opts("Lspsaga Outline", ev.buf))
        map("n", "<leader>lr", "<Cmd>Lspsaga rename<cr>", extend_opts("Lspsaga Rename", ev.buf))
        map("n", "<leader>la", "<Cmd>Lspsaga code_action<cr>", extend_opts("Lspsaga Code Action", ev.buf))
    end,
})
