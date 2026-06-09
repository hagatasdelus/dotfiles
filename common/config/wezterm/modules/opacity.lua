local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function reactivate_setting_mode(window)
    window:perform_action(act.ActivateKeyTable({ name = "setting_mode", one_shot = false }), window:active_pane())
end

local function get_base_opacity(config)
    if config and config.window_background_opacity then
        return config.window_background_opacity
    end
    return 0.7
end

local function adjust_opacity(window, delta, config)
    local overrides = window:get_config_overrides() or {}
    local current = overrides.window_background_opacity or get_base_opacity(config)

    local new_opacity = current + delta
    new_opacity = math.max(0.1, math.min(1.0, new_opacity))

    overrides.window_background_opacity = new_opacity
    window:set_config_overrides(overrides)

    reactivate_setting_mode(window)
end

wezterm.on("decrease-opacity", function(window, _, config)
    adjust_opacity(window, -0.1, config)
end)

wezterm.on("increase-opacity", function(window, _, config)
    adjust_opacity(window, 0.1, config)
end)

wezterm.on("reset-opacity", function(window, _, config)
    local overrides = window:get_config_overrides() or {}
    overrides.window_background_opacity = get_base_opacity(config)
    window:set_config_overrides(overrides)
    reactivate_setting_mode(window)
end)

function M.apply_to_config(config)
    if config.key_tables and config.key_tables.setting_mode then
        table.insert(config.key_tables.setting_mode, { key = ";", action = act.EmitEvent("increase-opacity") })
        table.insert(config.key_tables.setting_mode, { key = "-", action = act.EmitEvent("decrease-opacity") })
        table.insert(config.key_tables.setting_mode, { key = "0", action = act.EmitEvent("reset-opacity") })
    end
end

return M
