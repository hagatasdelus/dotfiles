local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function copy_last_command_output()
    return wezterm.action_callback(function(window, pane)
        window:perform_action(act.ActivateCopyMode, pane)
        window:perform_action(act.CopyMode({ MoveBackwardZoneOfType = "Input" }), pane)
        window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)
        window:perform_action(act.CopyMode({ MoveForwardZoneOfType = "Prompt" }), pane)
        window:perform_action(act.CopyMode("MoveUp"), pane)
        window:perform_action(act.CopyMode("MoveToEndOfLineContent"), pane)
        window:perform_action(
            act.Multiple({
                { CopyTo = "ClipboardAndPrimarySelection" },
                { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
            }),
            pane
        )
        window:set_right_status("📋 Copied!")
        wezterm.time.call_after(3, function()
            window:set_right_status("")
        end)
    end)
end

M.custom_title = {}

local function rename_tab()
    return wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        local tab_id = tab:tab_id()
        local current = M.custom_title[tab_id] or ""

        window:perform_action(
            act.PromptInputLine({
                description = "(wezterm) Rename tab (empty to reset):",
                initial_value = current,
                action = wezterm.action_callback(function(_, inner_pane, line)
                    if line == nil then
                        return
                    end
                    local t = inner_pane:tab()
                    if line == "" then
                        M.custom_title[t:tab_id()] = nil
                    else
                        M.custom_title[t:tab_id()] = line
                    end
                end),
            }),
            pane
        )
    end)
end

function M.apply_to_config(config)
    table.insert(config.keys, { key = "z", mods = "LEADER", action = copy_last_command_output() })
    table.insert(config.keys, { key = ",", mods = "LEADER", action = rename_tab() })
end

return M
