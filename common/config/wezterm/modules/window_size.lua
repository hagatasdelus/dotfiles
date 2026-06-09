local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local M = {}

local maximized_state = setmetatable({}, { __mode = "k" })

local function maximize(window)
    window:maximize()
    maximized_state[window] = true
end

local function restore(window)
    window:restore()
    maximized_state[window] = false
end

local function is_maximized(window)
    return maximized_state[window] == true
end

wezterm.on("gui-startup", function(cmd)
    local _, _, window = mux.spawn_window(cmd or {})
    maximize(window)
end)

wezterm.on("maximize-window", function(window, _)
    maximize(window)
end)

wezterm.on("restore-window", function(window, _)
    restore(window)
end)

wezterm.on("toggle-maximize-window", function(window, _)
    if is_maximized(window) then
        restore(window)
    else
        maximize(window)
    end
end)

function M.apply_to_config(config)
    table.insert(config.keys, { key = "m", mods = "LEADER", action = act.EmitEvent("toggle-maximize-window") })
    table.insert(config.keys, { key = "M", mods = "LEADER|SHIFT", action = act.EmitEvent("maximize-window") })
    table.insert(config.keys, { key = "n", mods = "LEADER", action = act.EmitEvent("restore-window") })
end

return M
