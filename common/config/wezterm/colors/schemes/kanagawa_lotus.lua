local palette = require("colors.palettes.kanagawa")

return {
    palette = "kanagawa",
    setup = function()
        return {
            foreground = palette.lotusInk1, -- lotusInk1
            background = palette.lotusWhite, -- lotusWhite3
            cursor_fg = palette.lotusInk2,
            cursor_bg = palette.lotusBlue2,
            cursor_border = palette.lotusInk2,
            selection_fg = palette.lotusInk2,
            selection_bg = palette.lotusBlue2,
            scrollbar_thumb = palette.lotusWhite5,
            split = palette.lotusWhite0,

            ansi = {
                palette.sumiInk3,
                palette.lotusRed,
                palette.lotusGreen,
                palette.lotusYellow,
                palette.lotusBlue4,
                palette.lotusPink,
                palette.lotusAqua,
                palette.lotusInk1,
            },
            brights = {
                palette.lotusGray3,
                palette.lotusRed2,
                palette.lotusGreen2,
                palette.lotusYellow2,
                palette.lotusTeal2,
                palette.lotusViolet4,
                palette.lotusAqua2,
                palette.lotusInk2,
            },
            indexed = { [16] = palette.lotusOrange2, [17] = palette.lotusRed3 },
        }
    end,
}
