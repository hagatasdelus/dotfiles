-- local default_scheme = "kanagawa-lotus"
-- local default_scheme = "kanagawa-dragon"
local default_scheme = nil

local M = {}
local wezterm = require("wezterm")

local function normalize_name(name)
    return name:gsub("-", "_")
end

function M.apply(config, _scheme_name)
    local scheme_name = _scheme_name or default_scheme
    if scheme_name then
        local module_name = normalize_name(scheme_name)

        local status_scheme, scheme_mod = pcall(require, "colors.schemes." .. module_name)

        if status_scheme then
            local palette_name = scheme_mod.palette or "kanagawa"
            local status_palette, palette_data = pcall(require, "colors.palettes." .. palette_name)

            if status_palette then
                if scheme_mod.setup and type(scheme_mod.setup) == "function" then
                    config.colors = scheme_mod.setup(palette_data)
                    wezterm.log_info(
                        string.format("Applied custom color scheme: '%s' with palette: '%s'", module_name, palette_name)
                    )
                    return
                else
                    wezterm.log_error(
                        string.format("Custom scheme module '%s' does not have a valid setup function", module_name)
                    )
                end
            else
                wezterm.log_error(string.format("Palette module not found: '%s'", palette_name))
            end
        else
            wezterm.log_error(string.format("Custom scheme module not found: '%s'", module_name))
        end
    end

    config.color_scheme = "Kanagawa Dragon (Gogh)"
end

return M
