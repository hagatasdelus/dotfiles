vim.api.nvim_create_user_command("QuickLook", function()
    -- get current buffer absolute path
    local current_bf_abspath = vim.fn.expand("%:p")
    require("core.utils").open_file_with_quicklook(current_bf_abspath)
end, { nargs = 0, force = true })

vim.api.nvim_create_user_command("Restart", function()
    if vim.v.count > 0 then
        vim.cmd("restart")
        return
    end

    -- cleanup session-unfriendly buffers (e.g., terminal)
    local bufname = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufname) do
        if vim.bo[buf].buftype == "terminal" then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
    local session_file = vim.fs.joinpath(tostring(vim.fn.stdpath("state")), "session.vim")
    vim.cmd(string.format("mksession! %s | :restart +xa source %s", session_file, session_file))
end, { desc = "Restart current Neovim session" })
