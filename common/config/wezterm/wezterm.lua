local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on("toggle-opacity", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if not overrides.window_background_opacity then
        overrides.window_background_opacity = 0.60
    else
        overrides.window_background_opacity = nil
    end
    window:set_config_overrides(overrides)
end)

wezterm.on("gui-startup", function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.line_height = 1.0
config.font_size = 16.0
config.font = wezterm.font_with_fallback({
    "HackGen Console NF",
})
config.color_scheme = "Kanagawa Dragon (Gogh)"
config.window_padding = {
    left = 1,
    right = 0,
    top = 0,
    bottom = 0,
}
config.use_ime = true
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.force_reverse_video_cursor = true
config.adjust_window_size_when_changing_font_size = false
-- config.macos_forward_to_ime_modifier_mark = "SHIFT|CTRL"
config.window_background_opacity = 0.70
config.macos_window_background_blur = 20

----------------------------------------------------
-- Tab
----------------------------------------------------
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

----------------------------------------------------
-- keymaps
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keymaps").keys
config.key_tables = require("keymaps").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

require("zen-mode")

return config
