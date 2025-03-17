return {
    {
        "rebelot/kanagawa.nvim",
        event = { "UiEnter", "ColorScheme" },
        priority = 1000,
        build = ":KanagawaCompile",
        opts = function()
            return {
                theme = "wave",
                background = {
                    dark = "dragon",
                    light = "lotus",
                },
                compile = true,
                transparent = true,
                dimInactive = false,
                colors = {
                    theme = {
                        all = {
                            ui = {
                                bg_gutter = "none",
                            },
                        },
                    },
                },
                overrides = function(colors)
                    local theme = colors.theme
                    return {
                        StatusLine = { link = "Normal" },
                        StatusLineNC = { link = "Normal" },

                        SatelliteBar = { bg = theme.ui.special },

                        TelescopeTitle = { fg = theme.ui.special, bold = true },
                        TelescopePromptNormal = { bg = theme.ui.bg_p1 },
                        TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
                        TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
                        TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
                        TelescopePreviewNormal = { bg = theme.ui.bg_dim },
                        TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

                        NoiceVirtualText = { bg = theme.ui.bg_search },

                        CursorLine = { bg = theme.ui.bg_m1 },
                        NormalFloat = { bg = "none" },
                        FloatBorder = { bg = "none" },
                        FloatTitle = { bg = "none" },
                    }
                end,
            }
        end,
        config = function(_, opts)
            local kanagawa = require("kanagawa")
            kanagawa.setup(opts)
            vim.cmd.colorscheme("kanagawa")
        end,
    },
}
