local wezterm = require("wezterm")
local M = {}

local COLORS = {
    default = "#CDFF04",
    copy_mode = "#FFD700",
}

function M.apply_to_config(_)
    wezterm.on("update-status", function(window, _)
        local workspace = window:active_workspace()
        local key_table = window:active_key_table()
        local color = COLORS[key_table] or COLORS.default

        window:set_left_status(wezterm.format({
            { Foreground = { Color = color } },
            { Attribute = { Intensity = "Bold" } },
            { Text = "  " .. workspace .. "  " },
        }))
    end)
end

return M
