local wezterm = require("wezterm")

local config = {}
if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.automatically_reload_config = true
config.line_height = 1.0
config.font_size = 15.0
config.font = wezterm.font("HackGen Console NF")
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
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"
config.window_background_opacity = 0.7
config.macos_window_background_blur = 20
config.window_background_gradient = {
    colors = { "#000000" },
    -- colors = { "#f4f0d4" },
}
require("keymaps").apply_to_config(config)
require("tab").apply_to_config(config)
require("events")
require("colors").apply_to_config(config)

return config
