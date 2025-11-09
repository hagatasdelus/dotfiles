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
config.font_size = 15.0
config.font = wezterm.font_with_fallback({
    "HackGen Console NF",
})
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
config.window_background_opacity = 0.70
config.macos_window_background_blur = 20
-- config.enable_kitty_keyboard = true
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
    regex = [[["]?([\w\d]{1}[-\w\d]+)/([-\w\d\.]+)["]?]],
    format = "https://github.com/$1/$2",
})
table.insert(config.hyperlink_rules, {
    regex = [[github\.com/([\w\d]{1}[-\w\d]+)/([-\w\d\.]+)]],
    format = "https://github.com/$1/$2",
})

require("color").apply(config)
require("keymaps").apply(config)
require("tab").apply(config)
require("zen-mode")

return config
