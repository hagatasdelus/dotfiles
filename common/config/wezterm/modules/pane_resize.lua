local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local pane_height_store = {}

local function apply_pane_height_percent(window, pane, percent)
    local tab = pane:tab()
    local tab_size = tab:get_size()
    local pane_dims = pane:get_dimensions()
    local pane_id = pane:pane_id()

    local is_top_pane = false
    for _, info in ipairs(tab:panes_with_info()) do
        if info.pane:pane_id() == pane_id then
            is_top_pane = (info.top == 0)
            break
        end
    end

    local target_rows = math.floor(tab_size.rows * percent)
    local current_rows = pane_dims.viewport_rows
    local diff = current_rows - target_rows

    if is_top_pane then
        if diff > 0 then
            window:perform_action(act.AdjustPaneSize({ "Up", diff }), pane)
        elseif diff < 0 then
            window:perform_action(act.AdjustPaneSize({ "Down", -diff }), pane)
        end
    else
        if diff > 0 then
            window:perform_action(act.AdjustPaneSize({ "Down", diff }), pane)
        elseif diff < 0 then
            window:perform_action(act.AdjustPaneSize({ "Up", -diff }), pane)
        end
    end
end

local function set_pane_height_percent(percent)
    return wezterm.action_callback(function(window, pane)
        apply_pane_height_percent(window, pane, percent)
    end)
end

local function set_pane_width_percent(percent)
    return wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        local tab_size = tab:get_size()
        local pane_dims = pane:get_dimensions()
        local pane_id = pane:pane_id()

        local is_left_pane = false
        for _, info in ipairs(tab:panes_with_info()) do
            if info.pane:pane_id() == pane_id then
                is_left_pane = (info.left == 0)
                break
            end
        end

        local target_cols = math.floor(tab_size.cols * percent)
        local current_cols = pane_dims.cols
        local diff = current_cols - target_cols

        if is_left_pane then
            if diff > 0 then
                window:perform_action(act.AdjustPaneSize({ "Left", diff }), pane)
            elseif diff < 0 then
                window:perform_action(act.AdjustPaneSize({ "Right", -diff }), pane)
            end
        else
            if diff > 0 then
                window:perform_action(act.AdjustPaneSize({ "Right", diff }), pane)
            elseif diff < 0 then
                window:perform_action(act.AdjustPaneSize({ "Left", -diff }), pane)
            end
        end
    end)
end

local function toggle_pane_minimize()
    return wezterm.action_callback(function(window, pane)
        local pane_dims = pane:get_dimensions()
        local pane_id = pane:pane_id()

        if pane_dims.viewport_rows <= 1 then
            local restore_percent = pane_height_store[pane_id] or 0.5
            pane_height_store[pane_id] = nil
            apply_pane_height_percent(window, pane, restore_percent)
            return
        end

        local tab = pane:tab()
        local tab_size = tab:get_size()
        pane_height_store[pane_id] = pane_dims.viewport_rows / tab_size.rows

        local title = pane:get_title()
        local cwd_uri = pane:get_current_working_dir()
        local cwd = cwd_uri and cwd_uri.file_path:match("([^/]+)/?$") or ""

        local name
        if title ~= "" and title ~= cwd then
            name = title
        else
            local process = pane:get_foreground_process_name()
            name = process and process:match("([^/]+)$") or "?"
        end
        local label = cwd ~= "" and (name .. " (" .. cwd .. ")") or name

        apply_pane_height_percent(window, pane, 0)

        wezterm.time.call_after(0.05, function()
            pane:inject_output("\r\x1b[2K\x1b[33m◀ " .. label .. " ▶\x1b[0m")
        end)
    end)
end

function M.apply_to_config(config)
    table.insert(config.keys, { key = "c", mods = "CTRL|SHIFT", action = toggle_pane_minimize() })
    config.key_tables = config.key_tables or {}
    config.key_tables.setting_mode = config.key_tables.setting_mode or {}

    local setting_mode = config.key_tables.setting_mode

    for i = 1, 9 do
        table.insert(setting_mode, { key = tostring(i), action = set_pane_height_percent(i * 0.1) })
    end

    for i = 1, 9 do
        table.insert(setting_mode, { key = tostring(i), mods = "CTRL", action = set_pane_width_percent(i * 0.1) })
    end

    table.insert(setting_mode, { key = "Escape", action = "PopKeyTable" })
    table.insert(setting_mode, { key = "q", action = "PopKeyTable" })
    table.insert(setting_mode, { key = "c", mods = "CTRL", action = "PopKeyTable" })
end

return M
