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
-- タイトルバーを非表示
config.window_decorations = "RESIZE"
-- タブバーの表示
config.show_tabs_in_tab_bar = true
-- タブが一つの時は非表示
config.hide_tab_bar_if_only_one_tab = true
-- falseにするとタブバーの透過が効かなくなる
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

-- タブバーの透過
config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}

-- タブバーを背景色に合わせる
config.window_background_gradient = {
	colors = { "#000000" },
}

-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false
-- nightlyのみ使用可能
-- タブの閉じるボタンを非表示
config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
config.colors = {
	tab_bar = {
		inactive_tab_edge = "none",
		background = "#B8B8B8",

		active_tab = {
			bg_color = "#CDFF04",
			fg_color = "#B8B8B8",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#C6C6C6",
			fg_color = "#B8B8B8",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab_hover = {
			bg_color = "#B8B8B8",
			fg_color = "#C6C6C6",
			intensity = "Normal",
			underline = "None",
			italic = true,
			strikethrough = false,
		},
		new_tab = {
			bg_color = "#B8B8B8",
			fg_color = "#C6C6C6",
			italic = false,
		},
		new_tab_hover = {
			bg_color = "#CDFF04",
			fg_color = "#B8B8B8",
			italic = false,
		},
	},
}

-- タブの形をカスタマイズ
-- タブの左側の装飾
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- タブの右側の装飾
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
	local background = "#5C6D74"
	local foreground = "#FFFFFF"
	local edge_background = "none"
	if tab.is_active then
		background = "#AE8B2D"
		foreground = "#FFFFFF"
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
-- keybinds
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keymaps").keys
config.key_tables = require("keymaps").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

return config
