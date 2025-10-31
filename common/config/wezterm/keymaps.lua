local M = {}

local wezterm = require("wezterm")
local act = wezterm.action

-- Show which key table is active in the status area
wezterm.on("update-right-status", function(window, _)
    local name = window:active_key_table()
    if name then
        name = "TABLE: " .. name
    end
    window:set_right_status(name or "")
end)

function keys()
    return {
        -- swich workspace
        {
            key = "w",
            mods = "LEADER",
            action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
        },
        -- rename workspace
        {
            key = "$",
            mods = "LEADER",
            action = act.PromptInputLine({
                description = "(wezterm) Set workspace title:",
                action = wezterm.action_callback(function(_, _, line) -- win, pane, line
                    if line then
                        wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
                    end
                end),
            }),
        },
        {
            key = "W",
            mods = "LEADER|SHIFT",
            action = act.PromptInputLine({
                description = "(wezterm) Create new workspace:",
                action = wezterm.action_callback(function(window, pane, line)
                    if line then
                        window:perform_aciton(
                            act.SwitchToWorkspace({
                                name = line,
                            }),
                            pane
                        )
                    end
                end),
            }),
        },
        -- show command palette
        { key = "p", mods = "SUPER", action = act.ActivateCommandPalette },
        -- go to next tab
        { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
        -- go to prev tab
        { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
        -- move tab
        { key = "{", mods = "LEADER", action = act({ MoveTabRelative = -1 }) },
        -- create new tab
        { key = "t", mods = "SUPER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
        -- close tab
        { key = "w", mods = "SUPER", action = act({ CloseCurrentTab = { confirm = true } }) },
        { key = "}", mods = "LEADER", action = act({ MoveTabRelative = 1 }) },
        -- toggle fullscreen
        { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
        -- enter copy mode
        -- { key = 'X',    mods = 'LEADER',        action = act.ActivateKeyTable{ name = 'copy_mode', one_shot =false } },
        { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
        -- copy
        { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
        -- paste
        { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
        -- create new pane (leader + r or d)
        { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
        { key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        -- close pane (leader + x)
        { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },
        -- maps panes (leader + hlkj)
        { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
        { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
        { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
        { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
        -- select pane
        { key = "[", mods = "CTRL|SHIFT", action = act.PaneSelect },
        -- toggle pane zoom
        { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
        -- increase/decrease font size
        { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
        { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
        -- reset font size
        { key = "0", mods = "CTRL", action = act.ResetFontSize },
        -- switch to tab by number (Cmd + 1, 2, ...)
        { key = "1", mods = "SUPER", action = act.ActivateTab(0) },
        { key = "2", mods = "SUPER", action = act.ActivateTab(1) },
        { key = "3", mods = "SUPER", action = act.ActivateTab(2) },
        { key = "4", mods = "SUPER", action = act.ActivateTab(3) },
        { key = "5", mods = "SUPER", action = act.ActivateTab(4) },
        { key = "6", mods = "SUPER", action = act.ActivateTab(5) },
        { key = "7", mods = "SUPER", action = act.ActivateTab(6) },
        { key = "8", mods = "SUPER", action = act.ActivateTab(7) },
        { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },
        -- command palette
        { key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
        -- reload configuration
        { key = "r", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },
        -- key table
        {
            key = "s",
            mods = "LEADER",
            action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
        },
        {
            key = "a",
            mods = "LEADER",
            action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }),
        },
        { key = "'", mods = "SHIFT|CTRL", action = act.EmitEvent("toggle-opacity") },
    }
end

local function key_tables()
    -- https://wezfurlong.org/wezterm/config/key-tables.html
    return {
        -- resize pane (leader + s)
        resize_pane = {
            { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
            { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
            { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
            { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
            -- Cancel the mode by pressing escape
            { key = "Enter", action = "PopKeyTable" },
        },
        activate_pane = {
            { key = "h", action = act.ActivatePaneDirection("Left") },
            { key = "l", action = act.ActivatePaneDirection("Right") },
            { key = "k", action = act.ActivatePaneDirection("Up") },
            { key = "j", action = act.ActivatePaneDirection("Down") },
        },
        -- copy mode (leader + [)
        copy_mode = {
            -- basic movement
            { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
            { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
            { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
            { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
            -- move to start/end of the line
            { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
            { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
            -- move to start of the line
            { key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
            { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
            { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
            -- move to the other end of the selection
            { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
            { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
            -- move the cursor position one word to the right/left/end
            { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
            { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
            { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
            -- jump to char
            { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
            { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
            { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
            { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
            -- move to bottom of scrollback
            { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
            -- move to top of scrollback
            { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
            -- viewport movement
            { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
            { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
            { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
            -- scrolling
            { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
            { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
            { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
            { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
            -- selection modes
            { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
            { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
            { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
            -- copy selection
            { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },
            -- exit copy mode
            {
                key = "Enter",
                mods = "NONE",
                action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
            },
            { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
            { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
            { key = "q", mods = "NONE", action = act.CopyMode("Close") },
        },
    }
end

local function mouse_bindings()
    return {
        {
            event = { Down = { streak = 3, button = "Left" } },
            action = act.SelectTextAtMouseCursor("SemanticZone"),
            mods = "NONE",
        },
    }
end

function M.apply(config)
    config.disable_default_key_bindings = true
    config.keys = keys()
    config.key_tables = key_tables()
    config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }
    config.mouse_bindings = mouse_bindings()
end

return M
