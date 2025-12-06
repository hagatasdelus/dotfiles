local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<CR><CR>", "<C-w><C-w>")
map("i", "jj", "<ESC>")
map("", "ss", "^")
map("", ";;", "$")
map({ "n", "v" }, "x", '"_x')  -- Delete without yanking
map({ "n", "v" }, "X", '"_d$') -- Delete to end of line without yanking
map("n", "Y", "y$")            -- Yank to end of line
map("x", "y", "mzy`z")         -- return to original position after yanking
map("n", "U", "<C-r>")         -- Redo
map("x", "p", "P")             -- Prevent register changes when pasting Visual to allow continuous pasting
map("n", "p", "]p`]")          -- Auto align indentation of paste and move to the end
map("n", "P", "]P`]")
map("", "gV", "`[v`]")         -- Reselect the previous Visual selection
map({ "o", "x" }, "i<Space>", "iW")
map({ 'n', 'o', 'v' }, 'M', "expand('<cword>') =~# 'end' ? '%' : 'g%'", { expr = true, remap = true })
-- map({ 'n', 'o', 'v' }, 'M', '%', { remap = true })
map("n", "F<CR>", "{")
map("n", "f<CR>", "}")
for _, quote in ipairs({ '"', "'", "`" }) do
    map({ "x", "o" }, "a" .. quote, "2i" .. quote)
end

-- Move & Duplicate Lines/Selections
map("n", "<C-k>", function() -- Move current line up
    return "<Cmd>move-1-" .. vim.v.count1 .. "<CR>=l"
end, { expr = true, silent = true })
map("n", "<C-j>", function() -- Move current line down
    return "<Cmd>move+" .. vim.v.count1 .. "<CR>=l"
end, { expr = true, silent = true })
map("x", "<C-k>", ":move'<-2<CR>gv=gv", { silent = true }) -- Move selected lines up
map("x", "<C-j>", ":move'>+1<CR>gv=gv", { silent = true }) -- Move selected lines down
map("n", "<Space>g", "<Cmd>copy.<CR>")                     -- Duplicate current line down
map("n", "<Space>G", "<Cmd>copy-1<CR>")                    -- Duplicate current line up
map("x", "<Space>g", ":copy'<-1<CR>gv")                    -- Duplicate selected lines up
map("x", "<Space>G", ":copy'>+0<CR>gv")                    -- Duplicate selected lines down

-- Tab Management
map("n", "<Tab>", "<Cmd>tabnext<CR>", opts)
map("n", "<S-Tab>", "<Cmd>tabprevious<CR>", opts)
map("n", "th", "<Cmd>tabfirst<CR>", opts)
map("n", "tj", "<Cmd>tabprevious<CR>", opts)
map("n", "tk", "<Cmd>tabnext<CR>", opts)
map("n", "tl", "<Cmd>tablast<CR>", opts)
map("n", "tt", "<Cmd>tabe .<CR>", opts)
map("n", "tq", "<Cmd>tabclose<CR>", opts)
map("n", "tm", "<Cmd>tab term<CR>", opts)

-- Replace / Substitute
map("n", "S", [[:%s/\V\<<C-r><C-w>\>//g<Left><Left>]])                                    -- Substitute word under cursor in file
map("x", "S", [["zy:%s/\V<C-r><C-r>=escape(@z, '/\\')<CR>//gce<Left><Left><Left><Left>]]) -- Substitute selected text in file (confirm)

-- Search
map("n", "/", "/\\v") -- Search forward with very magic
map("n", "?", "/\\V")

-- Terminal
map("t", [[<ESC><ESC>]], [[<C-\><C-n>]], opts)
map("t", [[<C-[><C-[>]], [[<C-\><C-n>]], opts)

-- Indentation
map("x", "<", "<gv", opts)
map("x", ">", ">gv", opts)

-- Smart Insert / Case Change
map("n", "i", function() -- Smart insert on empty line
    if vim.fn.empty(vim.fn.getline('.')) == 1 then
        return '"_cc'
    end
    return 'i'
end, { expr = true })
map("n", "A", function() -- Smart append on empty line
    if vim.fn.empty(vim.fn.getline('.')) == 1 then
        return '"_cc'
    end
    return 'A'
end, { expr = true })
map("i", "<C-g><C-u>", "<ESC>gUiwgi")
map("i", "<C-g><C-k>", "<ESC>bgUlgi")
-- Command abbreviations
vim.cmd.cnoreabbrev("tn tabnew")
vim.cmd.cnoreabbrev("vs vsplit")
vim.cmd.cnoreabbrev("rst Restart")
