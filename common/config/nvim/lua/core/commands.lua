vim.api.nvim_create_user_command("QuickLook", function()
    -- get current buffer absolute path
    local current_bf_abspath = vim.fn.expand("%:p")
    require("core.utils").open_file_with_quicklook(current_bf_abspath)
end, { nargs = 0, force = true })
