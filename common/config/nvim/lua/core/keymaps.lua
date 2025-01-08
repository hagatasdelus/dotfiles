-- Key mappings setup
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

local function extend_opts(desc)
    return vim.tbl_extend('force', opts, { desc = desc })
end

-- Key mappings
map('n', '<CR><CR>', '<C-w><C-w>', opts)
map('i', 'jj', '<ESC>', opts)
map('', 'ss', '^', opts)
map('', ';;', '$', opts)
map('n', '<leader>nn', '<Cmd>Neotree toggle<CR>', extend_opts('Neotree Toggle'))

-- Move to previous/next
map('n', '<C-,>', '<Cmd>BufferPrevious<CR>', opts)
map('n', '<C-.>', '<Cmd>BufferNext<CR>', opts)

-- Re-order to previous/next
map('n', '<C-<>', '<Cmd>BufferMovePrevious<CR>', opts)
map('n', '<C->>', '<Cmd>BufferMoveNext<CR>', opts)

-- Goto buffer in position...
map('n', '<C-1>', '<Cmd>BufferGoto 1<CR>', opts)
map('n', '<C-2>', '<Cmd>BufferGoto 2<CR>', opts)
map('n', '<C-3>', '<Cmd>BufferGoto 3<CR>', opts)
map('n', '<C-4>', '<Cmd>BufferGoto 4<CR>', opts)
map('n', '<C-5>', '<Cmd>BufferGoto 5<CR>', opts)
map('n', '<C-6>', '<Cmd>BufferGoto 6<CR>', opts)
map('n', '<C-7>', '<Cmd>BufferGoto 7<CR>', opts)
map('n', '<C-8>', '<Cmd>BufferGoto 8<CR>', opts)
map('n', '<C-9>', '<Cmd>BufferGoto 9<CR>', opts)
map('n', '<C-0>', '<Cmd>BufferLast<CR>', opts)


-- map('n', 'un', ':<C-u>Unite buffer<CR>', opt )
-- map('n', 'fgr', ':<cmd>Telescope live_grep<CR>', opts)
-- map('n', 'term', ':ToggleTerm', opts)
-- map('n', '<space>jj', '<C-\\><C-n>', opts)
-- map('n', 'gx', '<Plug>(openbrowser-smart-search)', opts)
