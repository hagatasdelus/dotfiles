vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- lang
vim.cmd.language("en_US.UTF-8")
-- vim.cmd.language("ja_JP.UTF-8")

-- File
vim.opt.swapfile = false
vim.opt.helplang = { "ja", "en" }
vim.opt.hidden = true
vim.opt.fenc = "utf-8"

-- Cursol
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.whichwrap = "b,s,h,l,[,],<,>,~"

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Menu and Command
vim.opt.wildmenu = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.showcmd = true
vim.opt.confirm = true

-- Search and Replace
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.matchtime = 1

-- ColorScheme
vim.opt.termguicolors = true
vim.opt.background = "dark"

-- Indent
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.backspace = {
    "indent",
    "eol",
    "start",
}

-- Display
vim.opt.number = true
vim.opt.wrap = true
vim.opt.showtabline = 2
vim.opt.visualbell = true
vim.opt.errorbells = false
vim.opt.showmatch = true
vim.opt.list = true
vim.opt.listchars = {
    tab = "▸▹┊",
    trail = "▫",
    extends = "❯",
    precedes = "❮",
    nbsp = "␣",
}

-- UI
-- vim.opt.winblend = 0
vim.opt.pumblend = 10
vim.opt.signcolumn = "yes"
vim.opt.splitright = true

-- line number color
-- vim.cmd("highlight LineNr guifg=#8a70ac")

-- vim.o.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

-- signcolumn priority (Error/Warning/Hints）
vim.diagnostic.config({ severity_sort = true, virtual_text = true })
