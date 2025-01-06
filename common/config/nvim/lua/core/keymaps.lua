-- Key mappings setup
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Key mappings
map('n', '<CR><CR>', '<C-w><C-w>', opts)
map('i', 'jj', '<ESC>', opts)
map('n', '<C-t>', ':NERDTreeToggle<CR>', opts)
map('', 'ss', '^', opts)
map('', ';;', '$', opts)
-- map('n', 'un', ':<C-u>Unite buffer<CR>', opts)
-- map('n', 'fgr', ':<cmd>Telescope live_grep<CR>', opts)
-- map('n', 'term', ':ToggleTerm', opts)
-- map('n', '<space>jj', '<C-\\><C-n>', opts)
-- map('n', 'gx', '<Plug>(openbrowser-smart-search)', opts)
