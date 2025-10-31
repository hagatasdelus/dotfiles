local M = {}

local wezterm = require("wezterm")

function M.apply(config)
    config.window_decorations = "RESIZE"
    config.show_tabs_in_tab_bar = true
    config.hide_tab_bar_if_only_one_tab = true
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = false

    -- Tab Bar Transparency
    -- config.window_frame = {
    -- 	inactive_titlebar_bg = "none",
    -- 	active_titlebar_bg = "none",
    -- }

    -- Match tab bar to background color
    config.window_background_gradient = {
        colors = { "#000000" },
    }

    config.show_new_tab_button_in_tab_bar = false
    config.show_close_tab_button_in_tabs = false

    config.colors = {
        tab_bar = {
            inactive_tab_edge = "none",
            background = "#B8B8B8",
            -- *_colorは便宜的に設定している
            active_tab = {
                bg_color = "#CDFF04",
                fg_color = "#000000",
                intensity = "Bold",
                underline = "None",
                italic = true,
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                intensity = "Normal",
                underline = "None",
                italic = false,
                strikethrough = false,
            },
            inactive_tab_hover = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                intensity = "Normal",
                underline = "None",
                italic = true,
                strikethrough = false,
            },
            new_tab = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                italic = false,
            },
            new_tab_hover = {
                bg_color = "#CDFF04",
                fg_color = "#404040",
                italic = false,
            },
        },
    }

    local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
    local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

    wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width) -- tab, tabs, panes, config, hover, max_width
        local background = "#D6D6D6"
        local foreground = "#404040"
        local edge_background = "#B8B8B8"
        if tab.is_active then
            background = "#CDFF04"
            foreground = "#000000"
        end
        local edge_foreground = background
        local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "
        return {
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = SOLID_LEFT_ARROW },
            { Background = { Color = background } },
            { Foreground = { Color = foreground } },
            { Text = title },
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = SOLID_RIGHT_ARROW },
        }
    end)
end

return M
