local highlights = {}

highlights.yellow = {
    separator = {
        fg = "#1E1E1E",
        bg = "#111111",
    },
    separator_selected = {
        fg = "#1E1E1E",
    },
    background = {
        fg = "#9A9A9A",
        bg = "#111111",
    },
    buffer_selected = {
        fg = "#FFDC7A",
        bold = true,
        italic = true,
    },
    fill = {
        bg = "#1E1E1E",
    },
}

highlights.yg = {
    separator = {
        fg = "#B8B8B8",
        bg = "#D6D6D6",
    },
    separator_selected = {
        fg = "#B8B8B8",
    },
    background = {
        fg = "#404040",
        bg = "#D6D6D6",
    },
    buffer_selected = {
        fg = "#CDFF04",
        bg = "#000000",
        bold = true,
        italic = true,
    },
    fill = {
        bg = "#B8B8B8",
    },
}

highlights.yg_wt = {
    separator = {
        fg = "#B8B8B8",
        bg = "#D6D6D6",
    },
    separator_selected = {
        fg = "#B8B8B8",
        bg = "#CDFF04",
    },
    background = {
        fg = "#404040",
        bg = "#D6D6D6",
    },
    buffer_selected = {
        fg = "#000000",
        bg = "#CDFF04",
        bold = true,
        italic = true,
    },
    fill = {
        bg = "#B8B8B8",
    },
    modified = {
        fg = "#707070",
        bg = "#D6D6D6",
    },
    modified_selected = {
        fg = "#3D3D3D",
        bg = "#CDFF04",
    },
}

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
                    style = "none", -- underline
                },
                tab_size = 19,
                name_formatter = function(buf)
                    return " " .. buf.name
                end,
            },
            highlights = highlights.yg_wt,
        })
    end,
}
