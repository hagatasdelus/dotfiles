local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local function spawn_overlay_pane(command)
    return wezterm.action_callback(function(window, pane)
        local new_pane = pane:split({
            direction = "Bottom",
            size = 1.0,
            args = { os.getenv("SHELL"), "-lc", command },
        })
        window:perform_action(act.TogglePaneZoomState, new_pane)
    end)
end

wezterm.on("augment-command-palette", function(_, _)
    local commands = {
        {
            brief = "Launch: bash",
            icon = "md_terminal",
            action = spawn_overlay_pane("bash"),
        },
        {
            brief = "Launch: Lazygit",
            icon = "md_git",
            action = spawn_overlay_pane("lazygit"),
        },
        {
            brief = "Launch: Neovim",
            icon = "md_vim",
            action = spawn_overlay_pane("nvim"),
        },
        {
            brief = "Launch: htop",
            icon = "md_chart_bar",
            action = spawn_overlay_pane("htop"),
        },
        {
            brief = "GitHub: Browse (gh browse)",
            icon = "md_github",
            action = spawn_overlay_pane("gh browse"),
        },
    }

    local karabiner = require("modules.karabiner_profile")
    for _, cmd in ipairs(karabiner.get_commands()) do
        table.insert(commands, cmd)
    end

    local caffeinate = require("modules.caffeinate")
    for _, cmd in ipairs(caffeinate.get_commands()) do
        table.insert(commands, cmd)
    end

    return commands
end)

function M.apply_to_config(_) end

M.spawn_overlay_pane = spawn_overlay_pane

return M
