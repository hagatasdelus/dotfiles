local wezterm = require("wezterm")
local M = {}

local appearance = {
    window_decorations = "RESIZE",

    show_tabs_in_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,
    use_fancy_tab_bar = false,
    tab_bar_at_bottom = false,
    tab_max_width = 30,
    show_new_tab_button_in_tab_bar = false,
    show_close_tab_button_in_tabs = false,

    colors = {
        tab_bar = {
            background = "#B8B8B8",
            inactive_tab_edge = "none",
            active_tab = {
                bg_color = "#CDFF04",
                fg_color = "#000000",
                underline = "None",
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                underline = "None",
                strikethrough = false,
            },
            inactive_tab_hover = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                underline = "None",
                strikethrough = false,
            },
            new_tab = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
            },
            new_tab_hover = {
                bg_color = "#CDFF04",
                fg_color = "#404040",
            },
        },
    },
}

local function apply_color_scheme(config, scheme_name)
    if not scheme_name then
        config.color_scheme = "Kanagawa Dragon (Gogh)"
        return
    end

    local module_name = scheme_name:gsub("-", "_")
    local ok, scheme_mod = pcall(require, "colors.schemes." .. module_name)

    if ok and scheme_mod.setup then
        local palette_name = scheme_mod.palette or "kanagawa"
        local palette_ok, palette_data = pcall(require, "colors.palettes." .. palette_name)

        if palette_ok then
            local scheme_colors = scheme_mod.setup(palette_data)
            for k, v in pairs(scheme_colors) do
                config.colors[k] = v
            end
            return
        end
    end

    config.color_scheme = "Kanagawa Dragon (Gogh)"
end

function M.apply_to_config(config, scheme_name)
    for k, v in pairs(appearance) do
        config[k] = v
    end

    apply_color_scheme(config, scheme_name)
end

return M
