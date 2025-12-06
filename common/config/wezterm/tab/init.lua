local M = {}

local wezterm = require("wezterm")

local pane_state = {}

---@param pane_id string
---@return table
local function get_pane_state(pane_id)
    if not pane_state[pane_id] then
        pane_state[pane_id] = {
            title = "-",
            ssh_host = nil,
            ssh_init_md = nil,
        }
    end
    return pane_state[pane_id]
end

-- local function get_ghq_root()
--     local home = os.getenv("HOME")
--     local exit_code, stdout, _stderr = wezterm.run_child_process({ "git", "config", "--get", "ghq.root" })
--     local ghq_root
--     if exit_code ~= 0 or stdout == "" then
--         ghq_root = home .. "/ghq"
--     else
--         ghq_root = stdout:gsub("%s+$", ""):gsub("^~", home)
--     end
--
--     local ghq_root_escaped = ghq_root:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
--
--     return string.format(".*%s/github.com/([^/]+)/([^/]+)", ghq_root_escaped)
-- end

---@param matcher string|table
---@param value string
---@return boolean
local function matches_any(matcher, value)
    if not matcher or not value then
        return false
    end
    if type(matcher) == "table" then
        for _, item in ipairs(matcher) do
            if string.find(value, item) then
                return true
            end
        end
    elseif type(matcher) == "string" then
        if string.find(value, matcher) then
            return true
        end
    end
    return false
end

-- Equivalent to POSIX basename(3)
local function basename(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.apply(config)
    config.window_decorations = "RESIZE"
    config.show_tabs_in_tab_bar = true
    config.hide_tab_bar_if_only_one_tab = true
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = false
    config.tab_max_width = 30
    -- Tab Bar Transparency
    -- config.window_frame = {
    -- 	inactive_titlebar_bg = "none",
    -- 	active_titlebar_bg = "none",
    -- }
    config.show_new_tab_button_in_tab_bar = false
    config.show_close_tab_button_in_tabs = false
    config.colors = {
        tab_bar = {
            inactive_tab_edge = "none",
            background = "#B8B8B8",
            -- *_colorは便宜的に設定している
            active_tab = {
                bg_color = "#CDFF04",
                fg_color = "#000000",
                underline = "None",
                strikethrough = false,
            },
            inactive_tab = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                underline = "None",
                strikethrough = false,
            },
            inactive_tab_hover = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
                underline = "None",
                strikethrough = false,
            },
            new_tab = {
                bg_color = "#D6D6D6",
                fg_color = "#404040",
            },
            new_tab_hover = {
                bg_color = "#CDFF04",
                fg_color = "#404040",
            },
        },
    }

    local rules = require("tab.rules")
    wezterm.on("pane-focus-changed", function(_, pane)
        local pane_id = pane.pane_id()
        local state = get_pane_state(pane_id)
        local cmd = pane:get_foreground_process_name() or ""

        if cmd:find("ssh%s+") and not state.ssh_init_cmd then
            state.ssh_init_cmd = cmd
            local host = cmd:match("ssh%s+(__[%w_%-%.]+)")
            if not host then
                host = cmd:match("ssh%s+([%w_%-%.]+)")
            end
            if host then
                host = host:gsub("^__", "")
                state.ssh_host = host
            end
        end
    end)

    wezterm.on("update-status", function(window, pane)
        local pane_id = pane:pane_id()
        local state = get_pane_state(pane_id)
        local user_vars = pane.user_vars or {}

        if user_vars.ssh_host and user_vars.ssh_hsot ~= "" then
            state.ssh_host = user_vars.ssh_host
        end

        if not state.ssh_host then
            state.title = "-"
            local cwd_url = pane:get_current_working_dir()
            if cwd_url then
                local cwd = cwd_url.file_path
                if cwd then
                    local home = os.getenv("HOME")
                    if home and cwd:find("^" .. home) then
                        cwd = cwd:gsub("^" .. home, "~")
                    end

                    local ghq_repo_path = ".*/dev/ghq/github.com/([^/]+)/([^/]+)"
                    -- local ghq_repo_path = get_ghq_root()
                    local owner, repo = cwd:match(ghq_repo_path)
                    if owner and repo then
                        state.title = repo
                    else
                        cwd = cwd:gsub("/$", "")
                        local last_dir = cwd:match("([^/]+)$")
                        state.title = last_dir or cwd
                    end
                end
            end
        end

        local left_status = {}
        local workspace = window:active_workspace()
        table.insert(left_status, " " .. workspace .. " ")

        local key_table = window:active_key_table()
        local workspace_color = rules.colors.tab.BACKGROUND_ACTIVE
        if key_table == "copy_mode" then
            workspace_color = rules.colors.COPY_MODE_COLOR
        end

        window:set_left_status(wezterm.format({
            { Foreground = { Color = workspace_color } },
            { Attribute = { Intensity = "Bold" } },
            { Text = " " .. table.concat(left_status, " | ") .. " " },
        }))
    end)

    wezterm.on("format-tab-title", function(tab, _, _, _, is_hover, max_width)
        -- tab, tabs, panes, config, hover, max_width
        local pane = tab.active_pane
        local pane_id = pane.pane_id
        local state = get_pane_state(pane_id)
        local pane_title = pane.title or ""
        local user_vars = pane.user_vars or {}

        local is_ssh = false
        local ssh_host_from_uservar = user_vars.ssh_host
        if ssh_host_from_uservar and ssh_host_from_uservar ~= "" then
            is_ssh = true
            if not state.ssh_host or state.ssh_host ~= ssh_host_from_uservar then
                state.ssh_host = ssh_host_from_uservar
            end
        elseif state.ssh_host and (not ssh_host_from_uservar or ssh_host_from_uservar == "") then
            state.ssh_host = nil
            state.ssh_init_cmd = nil
            state.title = "-"
            is_ssh = false
        elseif state.ssh_host then
            is_ssh = true
        end

        local background = rules.colors.tab.BACKGROUND_INACTIVE
        local foreground = rules.colors.tab.FOREGROUND_INACTIVE
        local intensity_val = "Normal"
        local italic_val = false
        if tab.is_active and is_ssh then
            background = rules.colors.tab.BACKGROUND_SSH_ACTIVE
            foreground = rules.colors.tab.FOREGROUND_SSH_ACTIVE
            intensity_val = "Bold"
            italic_val = true
        elseif tab.is_active then
            background = rules.colors.tab.BACKGROUND_ACTIVE
            foreground = rules.colors.tab.FOREGROUND_ACTIVE
            intensity_val = "Bold"
            italic_val = true
        elseif is_hover then
            italic_val = true
        end
        local edge_foreground = background
        local edge_background = rules.colors.tab.EDGE_BACKGROUND

        local title_text = state.title
        if is_ssh and state.ssh_host then
            title_text = state.ssh_host
        end

        local tab_icon = rules.fallbackIcon.icon
        local tab_icon_foreground = rules.fallbackIcon.color

        if is_ssh then
            tab_icon = rules.sshIcon.icon
            if tab.is_active then
                tab_icon_foreground = rules.sshIcon.active_color
            else
                tab_icon_foreground = rules.sshIcon.color
            end
        else
            for _, rule in ipairs(rules.iconRules) do
                if matches_any(rule.match_string, pane_title) then
                    tab_icon = rule.icon
                    tab_icon_foreground = rule.color
                    break
                end
            end
        end

        local title = " " .. wezterm.truncate_right(title_text, max_width - 1) .. " "
        return {
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = rules.decorations.SOLID_LEFT_ARROW },
            { Background = { Color = background } },
            { Foreground = { Color = tab_icon_foreground } },
            { Text = tab_icon },
            { Background = { Color = background } },
            { Foreground = { Color = foreground } },
            { Attribute = { Intensity = intensity_val } },
            { Attribute = { Italic = italic_val } },
            { Text = title },
            { Background = { Color = edge_background } },
            { Foreground = { Color = edge_foreground } },
            { Text = rules.decorations.SOLID_RIGHT_ARROW },
        }
    end)
end

return M
