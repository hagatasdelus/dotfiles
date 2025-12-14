local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

-- respect: https://github.com/ryoppippi/dotfiles/
wezterm.on("toggle-opacity", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if not overrides.window_background_opacity then
        overrides.window_background_opacity = 0.5
    else
        overrides.window_background_opacity = nil
    end
    window:set_config_overrides(overrides)
end)

wezterm.on("toggle-blur", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if not overrides.macos_window_background_blur then
        overrides.macos_window_background_blur = 0
    else
        overrides.macos_window_background_blur = nil
    end
    window:set_config_overrides(overrides)
end)

wezterm.on("gui-startup", function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

wezterm.on("user-var-changed", function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    if name == "ZEN_MODE" then
        local incremental = value:find("+")
        local number_value = tonumber(value)
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
    end
    window:set_config_overrides(overrides)
end)
