local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

wezterm.on("toggle-blur", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if not overrides.macos_window_background_blur then
        overrides.macos_window_background_blur = 0
    else
        overrides.macos_window_background_blur = nil
    end
    window:set_config_overrides(overrides)
end)

wezterm.on("window-focus-changed", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if window:is_focused() then
        overrides.macos_window_background_blur = nil
    else
        overrides.macos_window_background_blur = 0
    end
    window:set_config_overrides(overrides)
end)

function M.apply_to_config(config)
    if config.key_tables and config.key_tables.setting_mode then
        table.insert(config.key_tables.setting_mode, { key = "b", action = act.EmitEvent("toggle-blur") })
    end
end

return M
