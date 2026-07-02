local wezterm = require("wezterm")

local config = {}
if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.automatically_reload_config = true
config.line_height = 1.0
config.font_size = 15.0
config.font = wezterm.font("UDEV Gothic 35NFLG")
config.window_padding = {
    left = 1,
    right = 0,
    top = 0,
    bottom = 0,
}
config.use_ime = false
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
config.force_reverse_video_cursor = true
config.adjust_window_size_when_changing_font_size = false
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"
config.window_background_opacity = 0.7
config.macos_window_background_blur = 20
config.window_background_gradient = {
    colors = { "#000000" },
}
config.disable_default_quick_select_patterns = true
config.quick_select_patterns = {
    "\\bhttps?://[\\w\\-._~:/?#@!$&'()*+,;=%]+",
    "(?<=[\\s:=(\"'`])(?:~|/)[/\\w\\-.@~]+",
    "(?m)^(?:~|/)[/\\w\\-.@~]+(?=\\s*$)",
    "\\b[0-9a-f]{7,40}\\b",
    "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b",
    "\\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\b",
}

require("keymaps").apply_to_config(config)
require("appearance").apply_to_config(config)
require("tab").apply_to_config(config)
require("statusbar").apply_to_config(config)

require("modules.workspace").apply_to_config(config)
require("modules.pane_resize").apply_to_config(config)
require("modules.blur").apply_to_config(config)
require("modules.opacity").apply_to_config(config)
require("modules.window_size").apply_to_config(config)
require("modules.zen_mode").apply_to_config(config)
require("modules.command_palette").apply_to_config(config)
require("modules.utilities").apply_to_config(config)
require("modules.karabiner_profile").apply_to_config(config)

return config
