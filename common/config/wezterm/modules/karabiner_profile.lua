local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local KARABINER_CLI = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
local MACSKK_KEYBINDING_SCRIPT = os.getenv("HOME") .. "/dev/ghq/github.com/hagatasdelus/dotfiles/scripts/macskk-keybinding.sh"
local PROFILE_TO_KEYBINDING = {
    US = "AZIK_US",
    JIS = "AZIK_JIS",
}

local function shell_escape(str)
    return "'" .. str:gsub("'", "'\\''") .. "'"
end

local function run_command_capture(command, args)
    local parts = { shell_escape(command) }
    for _, arg in ipairs(args or {}) do
        table.insert(parts, shell_escape(arg))
    end
    local handle = io.popen(table.concat(parts, " ") .. " 2>/dev/null")
    if not handle then
        return nil
    end

    local result = handle:read("*a")
    handle:close()
    if not result then
        return nil
    end

    return result
end

local function run_command(command, args)
    local parts = { shell_escape(command) }
    for _, arg in ipairs(args or {}) do
        table.insert(parts, shell_escape(arg))
    end
    local ok = os.execute(table.concat(parts, " "))
    return ok == true or ok == 0
end

local function get_profiles()
    local result = run_command_capture(KARABINER_CLI, { "--list-profile-names" })
    if not result then
        return {}
    end

    local profiles = {}
    for name in result:gmatch("[^\r\n]+") do
        if name ~= "" then
            table.insert(profiles, name)
        end
    end
    return profiles
end

local function get_current_profile()
    local result = run_command_capture(KARABINER_CLI, { "--show-current-profile-name" })
    if not result then
        return nil
    end
    return result:match("^%s*(.-)%s*$")
end

local function get_switchable_profiles()
    local current = get_current_profile()
    local profiles = get_profiles()
    if not current then
        return profiles
    end

    local filtered = {}
    for _, name in ipairs(profiles) do
        if name ~= current then
            table.insert(filtered, name)
        end
    end
    return filtered
end

local function sync_macskk_keybinding(profile_name)
    local keybinding_id = PROFILE_TO_KEYBINDING[profile_name]
    if not keybinding_id then
        return true
    end
    return run_command(MACSKK_KEYBINDING_SCRIPT, { keybinding_id })
end

local function select_profile(name)
    local current = get_current_profile()
    if current ~= name then
        local ok = run_command(KARABINER_CLI, { "--select-profile", name })
        if not ok then
            wezterm.log_error("Failed to switch Karabiner profile: " .. name)
            return false
        end
    end

    local keybinding_ok = sync_macskk_keybinding(name)
    if not keybinding_ok then
        wezterm.log_error("Failed to sync macSKK keybinding for profile: " .. name)
        return false
    end

    if current == name then
        wezterm.log_info("Karabiner profile already active: " .. name)
    else
        wezterm.log_info("Karabiner profile switched to: " .. name)
    end

    return true
end

local function select_profile_with_feedback(window, name)
    if select_profile(name) then
        local keybinding_id = PROFILE_TO_KEYBINDING[name]
        local msg = keybinding_id and ("Switched to " .. name .. " (" .. keybinding_id .. ")")
            or ("Switched to " .. name)
        window:toast_notification("Karabiner Profile", msg, nil, 2500)
    else
        wezterm.log_error("Failed to switch Karabiner profile: " .. name)
        window:toast_notification("Karabiner Profile", "Failed to switch profile: " .. name, nil, 4000)
    end
end

local function create_profile_selector()
    return wezterm.action_callback(function(window, pane)
        local profiles = get_switchable_profiles()

        if #profiles == 0 then
            window:toast_notification(
                "Karabiner Profile",
                "No other profiles available.",
                nil,
                4000
            )
            return
        end

        local choices = {}
        for _, name in ipairs(profiles) do
            table.insert(choices, { label = name, id = name })
        end

        window:perform_action(
            act.InputSelector({
                title = "Select Karabiner Profile",
                choices = choices,
                fuzzy = true,
                action = wezterm.action_callback(function(_, _, id, _)
                    if not id then
                        return
                    end
                    select_profile_with_feedback(window, id)
                end),
            }),
            pane
        )
    end)
end

function M.get_commands()
    local profiles = get_profiles()
    local commands = {}

    for _, name in ipairs(profiles) do
        local profile_name = name
        table.insert(commands, {
            brief = "Karabiner: " .. profile_name,
            icon = "md_keyboard",
            action = wezterm.action_callback(function(window, _)
                select_profile_with_feedback(window, profile_name)
            end),
        })
    end

    return commands
end

function M.apply_to_config(config)
    table.insert(config.keys, {
        key = "K",
        mods = "LEADER|SHIFT",
        action = create_profile_selector(),
    })
end

return M
