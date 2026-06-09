local wezterm = require("wezterm")
local utilities = require("modules.utilities")
local M = {}

local nerdfonts = wezterm.nerdfonts

local ICONS = {
    nvim = nerdfonts.linux_neovim,
    vim = nerdfonts.dev_vim,
    shell = nerdfonts.dev_terminal,
    docker = nerdfonts.md_docker,
    fallback = nerdfonts.md_console_network,
}

local ICON_COLORS = {
    nvim = "#57A143",
    vim = "#179A33",
    shell = "#769FF0",
    docker = "#4169E1",
    fallback = "#AE8B2D",
}

local TAB_COLORS = {
    fg_inactive = "#404040",
    bg_inactive = "#D6D6D6",
    fg_active = "#000000",
    bg_active = "#CDFF04",
    edge_bg = "#B8B8B8",
}

local DECORATIONS = {
    left = nerdfonts.ple_lower_right_triangle,
    right = nerdfonts.ple_upper_left_triangle,
}

local ICON_RULES = {
    { pattern = "nvim", icon = ICONS.nvim, color = ICON_COLORS.nvim },
    { pattern = "vim", icon = ICONS.vim, color = ICON_COLORS.vim },
    { pattern = { "bash", "zsh", "fish" }, icon = ICONS.shell, color = ICON_COLORS.shell },
    { pattern = "docker", icon = ICONS.docker, color = ICON_COLORS.docker },
}

local pane_state = {}

local function get_pane_state(pane_id)
    if not pane_state[pane_id] then
        pane_state[pane_id] = {
            title = "-",
        }
    end
    return pane_state[pane_id]
end

local function matches_any(pattern, value)
    if not pattern or not value then
        return false
    end

    local normalized = value:lower()

    if type(pattern) == "table" then
        for _, p in ipairs(pattern) do
            if normalized:find(p, 1, true) then
                return true
            end
        end
        return false
    end

    return normalized:find(pattern, 1, true) ~= nil
end

local function basename(path)
    if not path or path == "" then
        return ""
    end
    return path:match("([^/]+)$") or path
end

local function extract_project_name(cwd)
    if not cwd then
        return "-"
    end

    local home = os.getenv("HOME")
    if home and cwd:find("^" .. home) then
        cwd = cwd:gsub("^" .. home, "~")
    end

    local _, repo = cwd:match(".*/dev/ghq/github.com/([^/]+)/([^/]+)")
    if repo then
        return repo
    end

    cwd = cwd:gsub("/$", "")
    return cwd:match("([^/]+)$") or cwd
end

local function get_icon_and_color(process_name, pane_title)
    if matches_any("nvim", process_name) then
        return ICONS.nvim, ICON_COLORS.nvim
    end

    if matches_any("vim", process_name) then
        return ICONS.vim, ICON_COLORS.vim
    end

    for _, rule in ipairs(ICON_RULES) do
        if matches_any(rule.pattern, pane_title) or matches_any(rule.pattern, process_name) then
            return rule.icon, rule.color
        end
    end

    return ICONS.fallback, ICON_COLORS.fallback
end

local function get_tab_colors(is_active)
    if is_active then
        return TAB_COLORS.bg_active, TAB_COLORS.fg_active
    end
    return TAB_COLORS.bg_inactive, TAB_COLORS.fg_inactive
end

function M.apply_to_config(_)
    wezterm.on("update-status", function(_, pane)
        local pane_id = pane:pane_id()
        local state = get_pane_state(pane_id)
        state.title = "-"
        local cwd_url = pane:get_current_working_dir()
        if cwd_url then
            state.title = extract_project_name(cwd_url.file_path)
        end
    end)

    wezterm.on("format-tab-title", function(tab, _, _, _, is_hover, max_width)
        local pane = tab.active_pane
        local pane_id = pane.pane_id
        local state = get_pane_state(pane_id)
        local pane_title = pane.title or ""
        local process_name = basename(pane.foreground_process_name)

        local background, foreground = get_tab_colors(tab.is_active)
        local edge_bg = TAB_COLORS.edge_bg
        local edge_fg = background

        local custom_title = utilities.custom_title[tab.tab_id]
        local title_text = custom_title or state.title

        local icon, icon_color = get_icon_and_color(process_name, pane_title)

        local intensity = tab.is_active and "Bold" or "Normal"
        local italic = tab.is_active or is_hover

        local title = " " .. wezterm.truncate_right(title_text, max_width - 1) .. " "

        return {
            { Background = { Color = edge_bg } },
            { Foreground = { Color = edge_fg } },
            { Text = DECORATIONS.left },
            { Background = { Color = background } },
            { Foreground = { Color = icon_color } },
            { Text = icon },
            { Background = { Color = background } },
            { Foreground = { Color = foreground } },
            { Attribute = { Intensity = intensity } },
            { Attribute = { Italic = italic } },
            { Text = title },
            { Background = { Color = edge_bg } },
            { Foreground = { Color = edge_fg } },
            { Text = DECORATIONS.right },
        }
    end)
end

return M
