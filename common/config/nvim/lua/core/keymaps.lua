local vim = vim

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

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
