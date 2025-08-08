local vim = vim

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Key mappings
map("n", "<CR><CR>", "<C-w><C-w>")
map("i", "jj", "<ESC>")
map("", "ss", "^")
map("", ";;", "$")
map("n", "<C-k>", function()
    return "<Cmd>move-1-" .. vim.v.count1 .. "<CR>=l"
end, { expr = true, silent = true })
map("n", "<C-j>", function()
    return "<Cmd>move+" .. vim.v.count1 .. "<CR>=l"
end, { expr = true, silent = true })
map("x", "<C-k>", ":move'<-2<CR>gv=gv", { silent = true })
map("x", "<C-j>", ":move'>+1<CR>gv=gv", { silent = true })
map("n", "<Space>g", "<Cmd>copy.<CR>")
map("n", "<Space>G", "<Cmd>copy-1<CR>")
map("x", "<Space>g", ":copy'<-1<CR>gv")
map("x", "<Space>G", ":copy'>+0<CR>gv")

map("n", "<Tab>", "<Cmd>tabnext<CR>", opts)
map("n", "<S-Tab>", "<Cmd>tabprevious<CR>", opts)
map("n", "th", "<Cmd>tabfirst<CR>", opts)
map("n", "tj", "<Cmd>tabprevious<CR>", opts)
map("n", "tk", "<Cmd>tabnext<CR>", opts)
map("n", "tl", "<Cmd>tablast<CR>", opts)
map("n", "tt", "<Cmd>tabe .<CR>", opts)
map("n", "tq", "<Cmd>tabclose<CR>", opts)
map("n", "tm", "<Cmd>tab term<CR>", opts)
map("x", "<", "<gv", opts)
map("x", ">", ">gv", opts)
map({ "n", "v" }, "x", '"_x')  -- Delete without yanking
map({ "n", "v" }, "X", '"_d$') -- Delete to end of line without yanking
map("n", "Y", "y$")
map("x", "y", "mzy`z")
map("n", "U", "<C-r>")
map({ "o", "x" }, "i<Space>", "iW")
map('n', 'M', "expand('<cword>') =~# 'end' ? '%' : 'g%'", {
    expr = true,
    remap = true
})
map("x", "p", "P")
map("n", "i", function()
    if vim.fn.empty(vim.fn.getline('.')) == 1 then
        return '"_cc'
    end
    return 'i'
end, { expr = true })
map("n", "A", function()
    if vim.fn.empty(vim.fn.getline('.')) == 1 then
        return '"_cc'
    end
    return 'A'
end, { expr = true })
map("n", "S", [[:%s/\V\<<C-r><C-w>\>//g<Left><Left>]])                                    -- Substitute word under cursor in file
map("x", "S", [["zy:%s/\V<C-r><C-r>=escape(@z, '/\\')<CR>//gce<Left><Left><Left><Left>]]) -- Substitute selected text in file (confirm)

map("n", "p", "]p`]")
map("n", "P", "]P`]")

map("i", "<C-g><C-u>", "<ESC>gUiwgi")
map("i", "<C-g><C-k>", "<ESC>bgUlgi")

map("n", "/", "/\\v") -- Search forward with very magic
map("n", "?", "/\\V")

map("", "gV", "`[v`]")

map("n", "F<CR>", "{")
map("n", "f<CR>", "}")

-- terminal mode
map("t", [[<ESC><ESC>]], [[<C-\><C-n>]], opts)
map("t", [[<C-[><C-[>]], [[<C-\><C-n>]], opts)
