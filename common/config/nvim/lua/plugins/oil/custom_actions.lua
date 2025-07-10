local M = {}

local debounce = require("core.utils").debounce

local function getEntryAbsPath()
    local oil = require("oil")
    local cursor_entry = oil.get_cursor_entry()
    local current_dir = oil.get_current_dir()
    if not cursor_entry or not current_dir then
        return
    end
    return current_dir .. cursor_entry.name, cursor_entry, current_dir
end

M.openWithQuickLook = {
    callback = function()
        local abspath = assert(getEntryAbsPath())
        require("core.utils").open_file_with_quicklook(abspath)
    end,
    desc = "Open Preview with QuickLook"
}

local function listWeztermPanes()
    local cli_result = vim.system({ "wezterm", "cli", "list", ("--format=%s"):format("json") }, { text = true }):wait()
    local json = vim.json.decode(cli_result.stdout)
    local panes_list = vim.iter(json):map(lambda("obj: {pane_id = obj.pane_id, tab_id = obj.tab_id, title = obj.title }"))
    return panes_list
end

local function getNeovimPaneIdFromWezterm()
    local wezterm_pane_id = vim.env.WEZTERM_PANE
    if not wezterm_pane_id then
        vim.notify("Wezterm pane not found", vim.log.levels.ERROR)
        return
    end
    return tonumber(wezterm_pane_id)
end

local function getPreviewPaneIdFromWezterm()
    local panes_list = listWeztermPanes()
    local neovim_wezterm_pane_id = getNeovimPaneIdFromWezterm()
    local current_tab_id = assert(panes_list:find(function(obj)
        return obj.pane_id == neovim_wezterm_pane_id
    end)).tab_id
    local preview_pane = panes_list:find(function(obj)
        return
            obj.tab_id == current_tab_id
            and tonumber(obj.pane_id) >
            tonumber(neovim_wezterm_pane_id) -- new pane id should be greater than the current one
    end)
    -- https://qiita.com/gyu-don/items/a0aed0f94b8b35c43290
    -- preview_pane ~= nil ? preview_pane.pane_id : nil
    return preview_pane ~= nil and preview_pane.pane_id or nil
end

local function getPreviewPaneNameFromWezterm()
    local panes_list = listWeztermPanes()
    local neovim_wezterm_pane_id = getNeovimPaneIdFromWezterm()
    local current_tab_id = assert(panes_list:find(function(obj)
        return obj.pane_id == neovim_wezterm_pane_id
    end)).tab_id
    local preview_pane = panes_list:find(function(obj)
        return
            obj.tab_id == current_tab_id
            and tonumber(obj.pane_id) > tonumber(neovim_wezterm_pane_id)
    end)
    return preview_pane ~= nil and preview_pane.title or nil
end

local activeWeztermPane = function(wezterm_pane_id)
    local cmd = { "wezterm", "cli", "activate-pane", ("--pane-id=%s"):format(wezterm_pane_id) } --
    vim.system(cmd)
end

local openNewWeztermPane = function(opt)
    local _opt = opt or {}
    local percent = _opt.percent or 30
    local direction = _opt.direction or "right"

    local cmd = { "wezterm", "cli", "split-pane", ("--percent=%d"):format(percent), ("--%s"):format(direction), "--",
        "bash" }
    local obj = vim.system(cmd, { text = true }):wait()
    local wezterm_pane_id = assert(tonumber(obj.stdout))

    return wezterm_pane_id
end

local closeWeztermPane = function(wezterm_pane_id)
    vim.system({ "wezterm", "cli", "kill-pane", ("--pane-id=%s"):format(wezterm_pane_id) })
end

local sendCommandToWeztermPane = function(wezterm_pane_id, command)
    local cmd = {
        "echo",
        ("'%s'"):format(command),
        "|",
        "wezterm",
        "cli",
        "send-text",
        "--no-paste",
        ("--pane-id=%s"):format(wezterm_pane_id)
    }
    vim.fn.system(table.concat(cmd, " "))
end

local sendTextToTdfWeztermPane = function(wezterm_pane_id, text)
    local cmd = {
        "echo",
        "-n",
        ("'%s'"):format(text),
        "|",
        "wezterm",
        "cli",
        "send-text",
        "--no-paste",
        ("--pane-id=%s"):format(wezterm_pane_id)
    }
    vim.fn.system(table.concat(cmd, " "))
end

local ensureWeztermPreviewPane = function(opt)
    local preview_pane_id = getPreviewPaneIdFromWezterm()
    if preview_pane_id == nil then
        preview_pane_id = openNewWeztermPane(opt)
    end
    return preview_pane_id
end

local function isImage(url)
    local extension = url:match("^.+(%..+)$")
    local imageExt = { ".bmp", ".jpg", ".jpeg", ".png", ".gif" }

    return vim.iter(imageExt):any(function(ext)
        return extension == ext
    end)
end

local function canTdfBeRecognized(url)
    local extension = url:match("^.+(%..*)$")
    local tdfExt = { ".pdf", ".bmp", ".jpg", ".jpeg", ".png" }

    return vim.iter(tdfExt):any(function(ext)
        return extension == ext
    end)
end

local isWeztermPreviewOpen = function(pane_id)
    return pane_id ~= nil
end

M.openWithWeztermPreview = {
    callback = function()
        local open_preview_pane_id = getPreviewPaneIdFromWezterm()
        if isWeztermPreviewOpen(open_preview_pane_id) then
            closeWeztermPane(open_preview_pane_id)
        end
        local oil = require("oil")
        local oil_util = require("oil.util")
        local preview_entry_id = nil
        local prev_cmd = nil

        local neovim_wezterm_pane_id = getNeovimPaneIdFromWezterm()
        local bufnr = vim.api.nvim_get_current_buf()

        local updateWeztermPreview = debounce(
            vim.schedule_wrap(function()
                if vim.api.nvim_get_current_buf() ~= bufnr then
                    return
                end
                local cursor_entry = oil.get_cursor_entry()
                -- Don't update in visual mode. Visual mode implies editing not browsing,
                -- and updating the preview can cause flicker and stutter.
                if cursor_entry ~= nil and not oil_util.is_visual_mode() then
                    local preview_pane_id = ensureWeztermPreviewPane()
                    activeWeztermPane(neovim_wezterm_pane_id)

                    if preview_entry_id == cursor_entry.id then
                        return
                    end

                    if prev_cmd == "bat" then
                        sendCommandToWeztermPane(preview_pane_id, "q")
                        prev_cmd = nil
                    end

                    local abspath = assert(getEntryAbsPath())
                    local command = ""
                    if cursor_entry.type == "directory" then
                        local cmd = "ls -l"
                        command = command .. ("%s %s"):format(cmd, abspath)
                        prev_cmd = cmd
                    elseif cursor_entry.type == "file" and isImage(abspath) then
                        local cmd = "wezterm imgcat"
                        command = command .. ("%s %s"):format(cmd, abspath)
                        prev_cmd = cmd
                    elseif cursor_entry.type == "file" then
                        local cmd = "bat"
                        command = command .. ("%s %s"):format(cmd, abspath)
                        prev_cmd = cmd
                    end

                    sendCommandToWeztermPane(preview_pane_id, command)
                end
            end),
            50
        )

        updateWeztermPreview()

        local config = require("oil.config")
        if config.preview_win.update_on_cursor_moved then
            vim.api.nvim_create_autocmd("CursorMoved", {
                desc = "Update oil wezterm preview",
                group = "Oil",
                buffer = bufnr,
                callback = function()
                    updateWeztermPreview()
                end,
            })
        end

        vim.api.nvim_create_autocmd({ "BufLeave", "BufDelete", "VimLeave" }, {
            desc = "Close oil wezterm preview",
            group = "Oil",
            buffer = bufnr,
            callback = function()
                closeWeztermPane(getPreviewPaneIdFromWezterm())
            end,
        })
    end,
    desc = "Open Preview with Wezterm",
}

M.openWithTdfWeztermPreview = {
    callback = function()
        local open_preview_pane_id = getPreviewPaneIdFromWezterm()
        if isWeztermPreviewOpen(open_preview_pane_id) then
            closeWeztermPane(open_preview_pane_id)
        end
        local oil = require("oil")
        local oil_util = require("oil.util")
        local preview_entry_id = nil
        local prev_cmd = nil

        local neovim_wezterm_pane_id = getNeovimPaneIdFromWezterm()
        local bufnr = vim.api.nvim_get_current_buf()

        local updateWeztermPreview = debounce(
            vim.schedule_wrap(function()
                if vim.api.nvim_get_current_buf() ~= bufnr then
                    return
                end
                local cursor_entry = oil.get_cursor_entry()
                -- Don't update in visual mode. Visual mode implies editing not browsing,
                -- and updating the preview can cause flicker and stutter.
                if cursor_entry ~= nil and not oil_util.is_visual_mode() then
                    local preview_pane_id = ensureWeztermPreviewPane({ percent = 50, direction = "right" })
                    activeWeztermPane(neovim_wezterm_pane_id)

                    if preview_entry_id == cursor_entry.id then
                        return
                    end

                    if prev_cmd == "bat" then
                        sendCommandToWeztermPane(preview_pane_id, "q")
                        prev_cmd = nil
                    end

                    local abspath = assert(getEntryAbsPath())
                    local command = ""
                    if cursor_entry.type == "directory" then
                        local cmd = "ls -l"
                        command = command .. ("%s %s"):format(cmd, abspath)
                        prev_cmd = cmd
                    elseif cursor_entry.type == "file" and canTdfBeRecognized(abspath) then
                        local cmd = "tdf"
                        command = command .. ("%s %s"):format(cmd, abspath)
                        prev_cmd = cmd
                    elseif cursor_entry.type == "file" then
                        local cmd = "bat"
                        command = command .. ("%s %s"):format(cmd, abspath)
                        prev_cmd = cmd
                    end

                    sendCommandToWeztermPane(preview_pane_id, command)
                end
            end),
            50
        )

        updateWeztermPreview()

        local config = require("oil.config")
        if config.preview_win.update_on_cursor_moved then
            vim.api.nvim_create_autocmd("CursorMoved", {
                desc = "Update oil tdf wezterm preview",
                group = "Oil",
                buffer = bufnr,
                callback = function()
                    updateWeztermPreview()
                end,
            })
        end

        vim.api.nvim_create_autocmd({ "BufLeave", "BufDelete", "VimLeave" }, {
            desc = "Close oil tdf wezterm preview",
            group = "Oil",
            buffer = bufnr,
            callback = function()
                closeWeztermPane(getPreviewPaneIdFromWezterm())
            end,
        })
    end,
    desc = "Open Preview with Wezterm",
}

M.tdfNext = {
    callback = function()
        local oil = require("oil")
        local oil_util = require("oil.util")
        local preview_entry_id = nil

        local neovim_wezterm_pane_id = getNeovimPaneIdFromWezterm()
        local bufnr = vim.api.nvim_get_current_buf()

        local updateNextTdfWeztermPreview = debounce(
            vim.schedule_wrap(function()
                if vim.api.nvim_get_current_buf() ~= bufnr then
                    return
                end
                local cursor_entry = oil.get_cursor_entry()
                if cursor_entry ~= nil and not oil_util.is_visual_mode() then
                    local preview_pane_name = getPreviewPaneNameFromWezterm()
                    if preview_pane_name ~= "tdf" then
                        vim.notify("TDF is not open in wezterm preview", vim.log.levels.ERROR)
                        return
                    end
                    local preview_pane_id = ensureWeztermPreviewPane()
                    activeWeztermPane(neovim_wezterm_pane_id)

                    if preview_entry_id == cursor_entry.id then
                        return
                    end
                    sendTextToTdfWeztermPane(preview_pane_id, "l")
                end
            end),
            50
        )
        updateNextTdfWeztermPreview()
    end
}

M.tdfPrev = {
    callback = function()
        local oil = require("oil")
        local oil_util = require("oil.util")
        local preview_entry_id = nil

        local neovim_wezterm_pane_id = getNeovimPaneIdFromWezterm()
        local bufnr = vim.api.nvim_get_current_buf()

        local updateNextTdfWeztermPreview = debounce(
            vim.schedule_wrap(function()
                if vim.api.nvim_get_current_buf() ~= bufnr then
                    return
                end
                local cursor_entry = oil.get_cursor_entry()
                if cursor_entry ~= nil and not oil_util.is_visual_mode() then
                    local preview_pane_name = getPreviewPaneNameFromWezterm()
                    if preview_pane_name ~= "tdf" then
                        vim.notify("TDF is not open in wezterm preview", vim.log.levels.ERROR)
                        return
                    end
                    local preview_pane_id = ensureWeztermPreviewPane()
                    activeWeztermPane(neovim_wezterm_pane_id)

                    if preview_entry_id == cursor_entry.id then
                        return
                    end
                    sendTextToTdfWeztermPane(preview_pane_id, "h")
                end
            end),
            50
        )
        updateNextTdfWeztermPreview()
    end
}

return M
