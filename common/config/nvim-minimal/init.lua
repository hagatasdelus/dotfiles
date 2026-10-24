-- Minimal reproduction init.lua for nvim-cmp + cmp-skkeleton issue
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"https://github.com/vim-denops/denops.vim",
	},
	{
		"https://github.com/vim-skk/skkeleton",
		dependencies = { "vim-denops/denops.vim" },
		config = function()
			vim.fn["skkeleton#config"]({
				eggLikeNewline = true,
			})
			vim.fn["skkeleton#initialize"]()
		end,
	},
	{
		"https://github.com/rinx/cmp-skkeleton",
		dependencies = { "vim-skk/skkeleton", "hrsh7th/nvim-cmp" },
	},
	{
		"https://github.com/hrsh7th/nvim-cmp",
		dependencies = { "rinx/cmp-skkeleton" },
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				sources = cmp.config.sources({
					{ name = "skkeleton" },
				}),
			})
		end,
	},
})

vim.keymap.set({ "i", "c", "t" }, "<C-j>", "<Plug>(skkeleton-enable)", { remap = true, silent = true })
