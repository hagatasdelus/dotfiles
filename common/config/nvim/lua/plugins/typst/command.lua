local M = {}

local original_typst_root = vim.env.TYPST_ROOT

local function is_preview_running()
    local success, servers = pcall(require, 'typst-preview.servers')
    if not success then
        return false
    end
    local config = require("typst-preview.config")

    local current_bufpath = vim.api.nvim_buf_get_name(0)
    if current_bufpath == '' then
        return false
    end

    local main_file = config.opts.get_main_file(current_bufpath)
    local server_instance = servers.get(main_file)

    if server_instance ~= nil then
        return true
    end
    return false
end

local function restart_preview_if_running()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

    if filetype == "typst" then
        if is_preview_running() then
            local restart_preview = vim.schedule_wrap(function()
                pcall(vim.cmd, "TypstPreviewStop")
                vim.defer_fn(function()
                    pcall(vim.cmd, "TypstPreview")
                end, 100)
                Snacks.notify.info("Restarting Typst Preview with new root", { title = "Typst" })
            end)
            restart_preview()
        end
    end
end

local function get_current_root()
    return vim.env.TYPST_ROOT
end

function M.set_root(args)
    local root = args.args

    root = vim.fn.fnamemodify(root, ":p:h")
    root = root:gsub("/$", "")

    if vim.fn.isdirectory(root) == 0 then
        Snacks.notify.error("No such directory: " .. root, { title = "Typst" })
        return
    end

    vim.env.TYPST_ROOT = root
    Snacks.notify.info("Set Typst Root to " .. root, { title = "Typst" })
    restart_preview_if_running()
end

function M.show_current_root()
    local current_root = get_current_root()
    if current_root ~= nil then
        Snacks.notify.info("Current Typst Root is " .. current_root, { title = "Typst" })
    else
        Snacks.notify.warn("No Typst Root set", { title = "Typst" })
    end
end

function M.reset_root()
    if original_typst_root then
        vim.env.TYPST_ROOT = original_typst_root
    else
        vim.env.TYPST_ROOT = nil
    end

    Snacks.notify.info("Reset Typst Root to default", { title = "Typst" })
    restart_preview_if_running()
end

function M.command()
    vim.api.nvim_create_user_command("TypstSetRoot", M.set_root, {
        nargs = "?",
        complete = "dir",
        desc = "Set Typst root directory for current Neovim session"
    })
    vim.api.nvim_create_user_command("TypstShowRoot", M.show_current_root, {
        nargs = 0,
        desc = "Show current Typst root directory",
    })
    vim.api.nvim_create_user_command("TypstResetRoot", M.reset_root, {
        nargs = 0,
        desc = "Reset Typst root to default",
    })
end

return M
