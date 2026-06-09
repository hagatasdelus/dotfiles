local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function apply_zen_mode(window, pane, value)
    local number_value = tonumber(value)
    if not number_value then
        return
    end

    local overrides = window:get_config_overrides() or {}
    local incremental = value:find("+", 1, true)

    if incremental ~= nil then
        while number_value > 0 do
            window:perform_action(act.IncreaseFontSize, pane)
            number_value = number_value - 1
        end
        overrides.enable_tab_bar = false
    elseif number_value < 0 then
        window:perform_action(act.ResetFontSize, pane)
        overrides.font_size = nil
        overrides.enable_tab_bar = true
    else
        overrides.font_size = number_value
        overrides.enable_tab_bar = false
    end

    window:set_config_overrides(overrides)
end

wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "ZEN_MODE" then
        apply_zen_mode(window, pane, value)
    end
end)

function M.apply_to_config(config)
    config.key_tables = config.key_tables or {}
    config.key_tables.setting_mode = config.key_tables.setting_mode or {}
    local setting_mode = config.key_tables.setting_mode

    table.insert(setting_mode, {
        key = "z",
        action = wezterm.action_callback(function(window, pane)
            apply_zen_mode(window, pane, "+1")
        end),
    })
    table.insert(setting_mode, {
        key = "Z",
        action = wezterm.action_callback(function(window, pane)
            apply_zen_mode(window, pane, "-1")
        end),
    })
end

return M
