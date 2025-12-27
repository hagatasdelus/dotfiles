local palette = require("colors.palettes.kanagawa")

return {
    palette = "kanagawa",
    setup = function()
        return {
            foreground = palette.dragonWhite,
            background = palette.dragonBlack3,
            cursor_bg = palette.oldWhite,
            cursor_fg = palette.dragonBlack3,
            cursor_border = palette.oldWhite,
            selection_fg = palette.dragonWhite,
            selection_bg = palette.waveBlue2,
            scrollbar_thumb = palette.dragonBlack4,
            split = palette.dragonBlack0,
            ansi = {
                palette.dragonBlack0, -- Black
                palette.dragonRed, -- Red
                palette.dragonGreen2, -- Green
                palette.dragonYellow, -- Yellow
                palette.dragonBlue2, -- Blue
                palette.dragonPink, -- Magenta
                palette.dragonAqua, -- Cyan
                palette.oldWhite, -- White
            },
            brights = {
                palette.dragonGray, -- Bright Black
                palette.waveRed, -- Bright Red
                palette.dragonGreen, -- Bright Green
                palette.carpYellow, -- Bright Yellow
                palette.springBlue, -- Bright Blue
                palette.springViolet1, -- Bright Magenta
                palette.waveAqua2, -- Bright Cyan
                palette.dragonWhite, -- Bright White
            },
            indexed = {
                [16] = palette.dragonOrange,
                [17] = palette.dragonOrange2,
            },
        }
    end,
}
