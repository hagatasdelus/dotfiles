 return {
	"akinsho/bufferline.nvim",
	event = { "BufAdd", "TabEnter" },
	config = function()
		require("bufferline").setup({
			options = {
				mode = "tabs",
				separator_style = "slope",
				always_show_bufferline = false,
				show_buffer_close_icons = false,
				show_close_icon = false,
				color_icons = true,
                indicator = {
                    style = "underline",
                },
			},
			highlights = {
				separator = {
					fg = "#1e1e1e",
					bg = "#111111",
				},
				separator_selected = {
					fg = "#1e1e1e",
                },
				background = {
					fg = "#9a9a9a",
					bg = "#111111",
				},
				buffer_selected = {
					fg = "#ffdc7a",
					bold = true,
				},
				fill = {
					bg = "#1e1e1e",
				},
			},
		})
	end,
}
