return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPost" },
	cmds = { "Gitsigns" },
	opts = function()
		return {
			signcolumn = true,
			numhl = true,
			attach_to_untracked = true,
		}
	end,
	config = function(_, opts)
		local gitsigns = require("gitsigns")
		gitsigns.setup(opts)
	end,
}
