local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local previous_workspace = nil

local function toggle_scratch_workspace()
    return wezterm.action_callback(function(window, pane)
        local current = wezterm.mux.get_active_workspace()

        if current == "scratch" then
            local target = previous_workspace or "default"
            window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
        else
            previous_workspace = current
            window:perform_action(act.SwitchToWorkspace({ name = "scratch" }), pane)
        end
    end)
end

local function switch_to_next_workspace()
    return wezterm.action_callback(function(window, pane)
        local workspaces = wezterm.mux.get_workspace_names()
        local current = wezterm.mux.get_active_workspace()

        local filtered = {}
        for _, ws in ipairs(workspaces) do
            if ws ~= "scratch" then
                table.insert(filtered, ws)
            end
        end

        local current_index = 1
        for i, ws in ipairs(filtered) do
            if ws == current then
                current_index = i
                break
            end
        end

        local next_index = current_index + 1
        if next_index > #filtered then
            next_index = 1
        end

        if #filtered > 0 then
            window:perform_action(act.SwitchToWorkspace({ name = filtered[next_index] }), pane)
        end
    end)
end

local function switch_to_prev_workspace()
    return wezterm.action_callback(function(window, pane)
        local workspaces = wezterm.mux.get_workspace_names()
        local current = wezterm.mux.get_active_workspace()

        local filtered = {}
        for _, ws in ipairs(workspaces) do
            if ws ~= "scratch" then
                table.insert(filtered, ws)
            end
        end

        local current_index = 1
        for i, ws in ipairs(filtered) do
            if ws == current then
                current_index = i
                break
            end
        end

        local prev_index = current_index - 1
        if prev_index < 1 then
            prev_index = #filtered
        end

        if #filtered > 0 then
            window:perform_action(act.SwitchToWorkspace({ name = filtered[prev_index] }), pane)
        end
    end)
end
function M.apply_to_config(config)
    table.insert(config.keys, { key = "s", mods = "CTRL|CMD", action = toggle_scratch_workspace() })
    table.insert(config.keys, { key = "n", mods = "CTRL|CMD", action = switch_to_next_workspace() })
    table.insert(config.keys, { key = "p", mods = "CTRL|CMD", action = switch_to_prev_workspace() })
end

return M
