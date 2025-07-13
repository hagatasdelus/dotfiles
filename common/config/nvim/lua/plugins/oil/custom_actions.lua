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

-- Wezterm utilities
local WeztermUtils = {}

WeztermUtils.listPanes = function()
    local cli_result = vim.system({ "wezterm", "cli", "list", ("--format=%s"):format("json") }, { text = true })
        :wait()
    local json = vim.json.decode(cli_result.stdout)
    local panes_list = vim.iter(json):map(lambda(
        "obj: {pane_id = obj.pane_id, tab_id = obj.tab_id, title = obj.title }"))
    return panes_list
end

WeztermUtils.getNeovimPaneId = function()
    local wezterm_pane_id = vim.env.WEZTERM_PANE
    if not wezterm_pane_id then
        vim.notify("Wezterm pane not found", vim.log.levels.ERROR)
        return
    end
    return tonumber(wezterm_pane_id)
end

WeztermUtils.getPreviewPane = function()
    local panes_list = WeztermUtils.listPanes()
    local neovim_wezterm_pane_id = WeztermUtils.getNeovimPaneId()
    local current_tab_id = assert(panes_list:find(function(obj)
        return obj.pane_id == neovim_wezterm_pane_id
    end)).tab_id
    local preview_pane = panes_list:find(function(obj)
        return
            obj.tab_id == current_tab_id
            and tonumber(obj.pane_id) >
            tonumber(neovim_wezterm_pane_id) -- new pane id should be greater than the current one
    end)
    return preview_pane
end

WeztermUtils.getPreviewPaneId = function()
    local preview_pane = WeztermUtils.getPreviewPane()
    return preview_pane ~= nil and preview_pane.pane_id or nil
end

WeztermUtils.getPreviewPaneName = function()
    local preview_pane = WeztermUtils.getPreviewPane()
    return preview_pane ~= nil and preview_pane.title or nil
end

WeztermUtils.activatePane = function(wezterm_pane_id)
    local cmd = { "wezterm", "cli", "activate-pane", ("--pane-id=%s"):format(wezterm_pane_id) }
    vim.system(cmd)
end

WeztermUtils.openNewPane = function(opt)
    local _opt = opt or {}
    local percent = _opt.percent or 30
    local direction = _opt.direction or "right"

    local cmd = { "wezterm", "cli", "split-pane", ("--percent=%d"):format(percent), ("--%s"):format(direction), "--",
        "bash" }
    local obj = vim.system(cmd, { text = true }):wait()
    local wezterm_pane_id = assert(tonumber(obj.stdout))

    return wezterm_pane_id
end

WeztermUtils.closePreviewPane = function(wezterm_pane_id)
    vim.system({ "wezterm", "cli", "kill-pane", ("--pane-id=%s"):format(wezterm_pane_id) })
end

WeztermUtils.sendCommandToPreviewPane = function(wezterm_pane_id, command)
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

WeztermUtils.sendTextToPreviewPane = function(wezterm_pane_id, text)
    local cmd = {
        "echo",
        "-n",
        ("'%s'"):format(text),
        "|",
        "wezterm",
        "cli",
        "send-text",
        ("--pane-id=%s"):format(wezterm_pane_id)
    }
    vim.fn.system(table.concat(cmd, " "))
end

WeztermUtils.ensurePreviewPane = function(opt)
    local preview_pane_id = WeztermUtils.getPreviewPaneId()
    if preview_pane_id == nil then
        preview_pane_id = WeztermUtils.openNewPane(opt)
    end
    return preview_pane_id
end

-- File type utilities
local FileUtils = {}

FileUtils.isImage = function(url)
    local extension = url:match("^.+(%..+)$")
    local imageExt = { ".bmp", ".jpg", ".jpeg", ".png", ".gif" }
    return vim.iter(imageExt):any(function(ext)
        return extension == ext
    end)
end

FileUtils.isViewableInTdf = function(url)
    local extension = url:match("^.+(%..*)$")
    local tdfExt = { ".pdf", ".bmp", ".jpg", ".jpeg", ".png" }
    return vim.iter(tdfExt):any(function(ext)
        return extension == ext
    end)
end

-- Preview manager
local PreviewManager = {}

PreviewManager.getPreviewCommand = function(abspath, cursor_entry, viewerType)
    if cursor_entry.type == "directory" then
        local cmd = "ls -l"
        return { cmd = cmd, ("%s %s"):format(cmd, abspath) }
    elseif cursor_entry.type == "file" then
        if viewerType == "tdf" and FileUtils.isViewableInTdf(abspath) then
            local cmd = "tdf"
            return { cmd = cmd, text = ("%s %s"):format(cmd, abspath) }
        elseif viewerType == "wezterm" and FileUtils.isImage(abspath) then
            local cmd = "wezterm imgcat"
            return { cmd = cmd, text = ("%s %s"):format(cmd, abspath) }
        else
            local cmd = "bat"
            return { cmd = cmd, text = ("%s %s"):format(cmd, abspath) }
        end
    end
    return { cmd = nil, text = "" }
end

PreviewManager.createPreviewAction = function(config)
    local viewerType = config.viewerType or "wezterm"
    local paneOpts = { percent = config.percent or 30, direction = config.direction or "right" }

    return {
        callback = function()
            local open_preview_pane_id = WeztermUtils.getPreviewPaneId()
            if open_preview_pane_id ~= nil then
                WeztermUtils.closePreviewPane(open_preview_pane_id)
            end

            local oil = require("oil")
            local oil_util = require("oil.util")
            local preview_entry_id = nil
            local prev_cmd = nil

            local neovim_wezterm_pane_id = WeztermUtils.getNeovimPaneId()
            local bufnr = vim.api.nvim_get_current_buf()

            local updateWeztermPreview = debounce(
                vim.schedule_wrap(function()
                    if vim.api.nvim_get_current_buf() ~= bufnr then
                        return
                    end
                    local cursor_entry = oil.get_cursor_entry()
                    if cursor_entry ~= nil and not oil_util.is_visual_mode() then
                        local preview_pane_id = WeztermUtils.ensurePreviewPane(paneOpts)
                        WeztermUtils.activatePane(neovim_wezterm_pane_id)

                        if preview_entry_id == cursor_entry.id then
                            return
                        end

                        if prev_cmd == "bat" then
                            WeztermUtils.sendCommand(preview_pane_id, "q")
                            prev_cmd = nil
                        end

                        local abspath = assert(getEntryAbsPath())
                        local command = PreviewManager.getPreviewCommand(abspath, cursor_entry, viewerType)

                        if command.cmd then
                            prev_cmd = command.cmd
                            WeztermUtils.sendCommandToPreviewPane(preview_pane_id, command.text)
                        end
                    end
                end),
                50
            )

            updateWeztermPreview()

            local config_oil = require("oil.config")
            if config_oil.preview_win.update_on_cursor_moved then
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
                    WeztermUtils.closePreviewPane(WeztermUtils.getPreviewPaneId())
                end,
            })
        end,
        desc = ("Open Preview with %s"):format(viewerType == "tdf" and "Wezterm TDF" or "Wezterm"),
    }
end

PreviewManager.createTdfNavigationAction = function(direction)
    local keyToSend = direction == "next" and "l" or "h"

    return {
        callback = function()
            local oil = require("oil")
            local oil_util = require("oil.util")
            local preview_entry_id = nil

            local neovim_wezterm_pane_id = WeztermUtils.getNeovimPaneId()
            local bufnr = vim.api.nvim_get_current_buf()

            local updateTdfNavigation = debounce(
                vim.schedule_wrap(function()
                    if vim.api.nvim_get_current_buf() ~= bufnr then
                        return
                    end
                    local cursor_entry = oil.get_cursor_entry()
                    if cursor_entry ~= nil and not oil_util.is_visual_mode() then
                        local preview_pane_name = WeztermUtils.getPreviewPaneName()
                        if preview_pane_name ~= "tdf" then
                            vim.notify("TDF is not open in wezterm preview", vim.log.levels.ERROR)
                            return
                        end
                        local preview_pane_id = WeztermUtils.ensurePreviewPane()
                        WeztermUtils.activatePane(neovim_wezterm_pane_id)

                        if preview_entry_id == cursor_entry.id then
                            return
                        end
                        WeztermUtils.sendTextToPreviewPane(preview_pane_id, key)
                    end
                end),
                50
            )
            updateTdfNavigation()
        end
    }
end

M.openWithQuickLook = {
    callback = function()
        local abspath = assert(getEntryAbsPath())
        require("core.utils").open_file_with_quicklook(abspath)
    end,
    desc = "Open Preview with QuickLook"
}

-- Refactored actions using the common preview manager
M.openWithWeztermPreview = PreviewManager.createPreviewAction({
    viewerType = "wezterm",
    percent = 30,
    direction = "right"
})

M.openWithTdfWeztermPreview = PreviewManager.createPreviewAction({
    viewerType = "tdf",
    percent = 50,
    direction = "right"
})

M.tdfNext = PreviewManager.createTdfNavigationAction("next")
M.tdfPrev = PreviewManager.createTdfNavigationAction("prev")

return M
