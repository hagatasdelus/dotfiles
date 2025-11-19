local M = {}

local nerdfonts = require("wezterm").nerdfonts

M.iconRules = {
    {
        match_string = { "python", "uv" },
        icon = nerdfonts.dev_python,
        color = "#FFD700",
    },
    {
        match_string = "node",
        icon = nerdfonts.md_language_typescript,
        color = "#1E90FF",
    },
    {
        match_string = "deno",
        icon = nerdfonts.dev_denojs,
        color = "#000000",
    },
    {
        match_string = "nvim",
        icon = nerdfonts.linux_neovim,
        color = "#57A143",
    },
    {
        match_string = "vim",
        icon = nerdfonts.dev_vim,
        color = "#179A33",
    },
    {
        match_string = { "bash", "zsh", "fish" },
        icon = nerdfonts.dev_terminal,
        color = "#769FF0",
    },
    {
        match_string = "docker",
        icon = nerdfonts.md_docker,
        color = "#4169E1",
    },
}

M.sshIcon = {
    icon = nerdfonts.md_lan,
    color = "#FF6B6B",
    active_color = "#FFFFFF",
}

M.fallbackIcon = {
    icon = nerdfonts.md_console_network,
    color = "#AE8B2D",
}

M.colors = {
    tab = {
        FOREGROUND_INACTIVE = "#404040",
        BACKGROUND_INACTIVE = "#D6D6D6",
        FOREGROUND_ACTIVE = "#000000",
        BACKGROUND_ACTIVE = "#CDFF04",
        FOREGROUND_SSH_ACTIVE = "#FFFFFF",
        BACKGROUND_SSH_ACTIVE = "#FF6B6B",
        EDGE_BACKGROUND = "#B8B8B8",
    },
    COPY_MODE_COLOR = "#FFD700",
}

M.decorations = {
    -- SOLID_LEFT_CIRCLE = nerdfonts.ple_left_half_circle_thick,
    -- SOLID_RIGHT_CIRCLE = nerdfonts.ple_right_half_circle_thick,
    SOLID_LEFT_ARROW = nerdfonts.ple_lower_right_triangle,
    SOLID_RIGHT_ARROW = nerdfonts.ple_upper_left_triangle,
}

return M
