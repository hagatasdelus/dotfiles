local M = {}

local debounce = require("core.utils").debounce

M.show_hidden = true

local function is_always_hidden(name)
    local ignore = {
        ".DS_Store",
    }
    return vim.tbl_contains(ignore, name)
end

local function is_hidden(name)
    return name:match("^%.") ~= nil and not (name == "." or name == "..")
end

function M.setup_patches()
    local fs = require("fyler.lib.fs")
    local original_ls = fs.ls
    fs.ls = function(opts, _next)
        original_ls(opts, function(err, entries)
            if err or not entries then
                _next(err, entries)
                return
            end

            local filtered = {}
            for _, entry in ipairs(entries) do
                if not is_always_hidden(entry.name) then
                    if M.show_hidden or not is_hidden(entry.name) then
                        table.insert(filtered, entry)
                    end
                end
            end
            _next(nil, filtered)
        end)
    end
end

local function getEntryAbsPath(self)
    local entry = self:cursor_node_entry()
    if not entry then
        return
    end

    local full_path = entry.path
    local escaped_path = vim.fn.fnameescape(full_path)
    return escaped_path, entry, self:getcwd()
end

local function listPanes()
    local cli_result = vim.system({ "wezterm", "cli", "list", ("--format=%s"):format("json") }, { text = true }):wait()
    local json = vim.json.decode(cli_result.stdout)
    local panes_list = vim.iter(json)
        :map(lambda("obj: {pane_id = obj.pane_id, tab_id = obj.tab_id, title = obj.title }"))
    return panes_list
end

local function getNeovimPaneId()
    local wezterm_pane_id = vim.env.WEZTERM_PANE
    if not wezterm_pane_id then
        vim.notify("Wezterm pane not found", vim.log.levels.ERROR)
        return
    end
    return tonumber(wezterm_pane_id)
end

local function getPreviewPane()
    local panes_list = listPanes()
    local neovim_wezterm_pane_id = getNeovimPaneId()
    if not neovim_wezterm_pane_id then
        return
    end

    local current_tab_obj = panes_list:find(function(obj)
        return obj.pane_id == neovim_wezterm_pane_id
    end)
    if not current_tab_obj then
        return
    end

    local current_tab_id = current_tab_obj.tab_id
    local preview_pane = panes_list:find(function(obj)
        return obj.tab_id == current_tab_id and tonumber(obj.pane_id) > tonumber(neovim_wezterm_pane_id)
    end)
    return preview_pane
end

local function getPreviewPaneId()
    local preview_pane = getPreviewPane()
    return preview_pane ~= nil and preview_pane.pane_id or nil
end

local function getPreviewPaneName()
    local preview_pane = getPreviewPane()
    return preview_pane ~= nil and preview_pane.title or nil
end

local function activatePane(wezterm_pane_id)
    local cmd = { "wezterm", "cli", "activate-pane", ("--pane-id=%s"):format(wezterm_pane_id) }
    vim.system(cmd):wait()
end

local function openNewPane(opt)
    local _opt = opt or {}
    local percent = _opt.percent or 30
    local direction = _opt.direction or "right"

    local cmd = {
        "wezterm",
        "cli",
        "split-pane",
        ("--percent=%d"):format(percent),
        ("--%s"):format(direction),
        "--",
        "bash",
    }
    local obj = vim.system(cmd, { text = true }):wait()
    local wezterm_pane_id = assert(tonumber(obj.stdout))

    return wezterm_pane_id
end

local function closePreviewPane(wezterm_pane_id)
    vim.system({ "wezterm", "cli", "kill-pane", ("--pane-id=%s"):format(wezterm_pane_id) })
end

local function sendCommandToPreviewPane(wezterm_pane_id, command)
    local cmd = {
        "echo",
        ("'%s'"):format(command),
        "|",
        "wezterm",
        "cli",
        "send-text",
        "--no-paste",
        ("--pane-id=%s"):format(wezterm_pane_id),
    }
    vim.fn.system(table.concat(cmd, " "))
end

local function sendKeyToPreviewPane(wezterm_pane_id, key)
    local cmd = {
        "echo",
        "-n",
        ("'%s'"):format(key),
        "|",
        "wezterm",
        "cli",
        "send-text",
        ("--pane-id=%s"):format(wezterm_pane_id),
    }
    vim.fn.system(table.concat(cmd, " "))
end

local function ensurePreviewPane(opt)
    local preview_pane_id = getPreviewPaneId()
    if preview_pane_id == nil then
        preview_pane_id = openNewPane(opt)
    end
    return preview_pane_id
end

local function isImage(url)
    local extension = url:match("^.+(%..+)$")
    local imageExt = { ".bmp", ".jpg", ".jpeg", ".png", ".gif", ".tif", ".tiff", ".ico" }
    return vim.iter(imageExt):any(function(ext)
        return extension == ext
    end)
end

local function isViewableInTdf(url)
    local extension = url:match("^.+(%..*)$")
    local tdfExt = { ".pdf", ".bmp", ".jpg", ".jpeg", ".png" }
    return vim.iter(tdfExt):any(function(ext)
        return extension == ext
    end)
end

local function getPreviewCommand(abspath, cursor_entry)
    local cmd
    if cursor_entry.type == "file" then
        if isImage(abspath) then
            cmd = "wezterm imgcat"
        elseif isViewableInTdf(abspath) then
            cmd = "tdf"
        else
            cmd = "bat"
        end
    else
        if vim.fn.executable("eza") == 1 then
            cmd = "eza -l --header --icons"
        else
            cmd = "ls -l"
        end
    end

    local command = ("%s %s"):format(cmd, abspath)
    return command
end

local function createPreviewAction(config)
    local paneOpts = { percent = config.percent or 30, direction = config.direction or "right" }

    return function(self)
        local open_preview_pane_id = getPreviewPaneId()
        if open_preview_pane_id ~= nil then
            closePreviewPane(open_preview_pane_id)
        end

        local neovim_wezterm_pane_id = getNeovimPaneId()
        local bufnr = vim.api.nvim_get_current_buf()

        local updateWeztermPreview = debounce(function()
            if vim.api.nvim_get_current_buf() ~= bufnr then
                return
            end
            local cursor_entry = self:cursor_node_entry()
            if cursor_entry ~= nil then
                local preview_pane_id = ensurePreviewPane(paneOpts)
                if neovim_wezterm_pane_id then
                    activatePane(neovim_wezterm_pane_id)
                end

                local preview_pane_name = getPreviewPaneName()
                if vim.fn.index({ "bat", "tdf" }, preview_pane_name) ~= -1 then
                    sendKeyToPreviewPane(preview_pane_id, "q")
                end

                local abspath = assert(getEntryAbsPath(self))
                local command = getPreviewCommand(abspath, cursor_entry)

                sendCommandToPreviewPane(preview_pane_id, command)
            end
        end, 50)

        updateWeztermPreview()

        vim.api.nvim_create_autocmd({ "BufLeave", "BufDelete", "VimLeave" }, {
            desc = "Close fyler wezterm preview",
            group = vim.api.nvim_create_augroup("Fyler", { clear = false }),
            buffer = bufnr,
            callback = function()
                local preview_id = getPreviewPaneId()
                if preview_id then
                    closePreviewPane(preview_id)
                end
            end,
        })
    end
end

local function createTdfNavigationAction(key)
    return function(self)
        local neovim_wezterm_pane_id = getNeovimPaneId()
        local bufnr = vim.api.nvim_get_current_buf()

        local updateTdfNavigation = debounce(function()
            if vim.api.nvim_get_current_buf() ~= bufnr then
                return
            end
            local cursor_entry = self:cursor_node_entry()
            if cursor_entry ~= nil then
                local preview_pane_name = getPreviewPaneName()
                if preview_pane_name ~= "tdf" then
                    vim.notify("TDF is not open in wezterm preview", vim.log.levels.ERROR)
                    return
                end
                local preview_pane_id = ensurePreviewPane()
                if neovim_wezterm_pane_id then
                    activatePane(neovim_wezterm_pane_id)
                end

                sendKeyToPreviewPane(preview_pane_id, key)
            end
        end, 50)
        updateTdfNavigation()
    end
end

M.openWithWeztermPreview = createPreviewAction({
    percent = 50,
    direction = "right",
})

M.closeWeztermPreview = function(self)
    local preview_pane_id = getPreviewPaneId()
    if preview_pane_id then
        closePreviewPane(preview_pane_id)
    end
end

M.tdfNext = createTdfNavigationAction("l")
M.tdfPrev = createTdfNavigationAction("h")
M.tdfFullScreen = createTdfNavigationAction("f")
M.tdfInvert = createTdfNavigationAction("i")

M.openWithQuickLook = function(self)
    local abspath = assert(getEntryAbsPath(self))
    require("core.utils").open_file_with_quicklook(abspath)
end

M.open_external = function(self)
    local abspath = assert(getEntryAbsPath(self))
    vim.ui.open(abspath)
end

M.refresh = function(self)
    self:dispatch_refresh({ force_update = true })
end

M.open_cwd = function(self)
    local cwd = vim.fn.getcwd()
    self:change_root(cwd):dispatch_refresh({ force_update = true })
end

M.cd = function(self)
    local path = self:getcwd()
    vim.api.nvim_set_current_dir(path)
    vim.notify(string.format("cd to %s", path), vim.log.levels.INFO)
end

M.tcd = function(self)
    local path = self:getcwd()
    vim.cmd.tcd(path)
    vim.notify(string.format("tcd to %s", path), vim.log.levels.INFO)
end

M.toggle_hidden = function(self)
    M.show_hidden = not M.show_hidden
    self:dispatch_refresh({ force_update = true })
end

M.openPdfInWezterm = function(self)
    local escaped_path, cursor_entry = getEntryAbsPath(self)
    if not escaped_path or not cursor_entry then
        return
    end

    if not isViewableInTdf(escaped_path) then
        vim.notify("Not a PDF or viewable in TDF", vim.log.levels.WARN)
        return
    end

    local open_preview_pane_id = getPreviewPaneId()
    if open_preview_pane_id ~= nil then
        closePreviewPane(open_preview_pane_id)
    end

    local neovim_wezterm_pane_id = getNeovimPaneId()
    local preview_pane_id = ensurePreviewPane({ percent = 50, direction = "right" })
    if neovim_wezterm_pane_id then
        activatePane(neovim_wezterm_pane_id)
    end

    local preview_pane_name = getPreviewPaneName()
    if vim.fn.index({ "bat", "tdf" }, preview_pane_name) ~= -1 then
        sendKeyToPreviewPane(preview_pane_id, "q")
    end

    local command = getPreviewCommand(escaped_path, cursor_entry)
    sendCommandToPreviewPane(preview_pane_id, command)

    vim.api.nvim_create_autocmd("VimLeave", {
        desc = "Close fyler wezterm PDF preview on Vim exit",
        group = vim.api.nvim_create_augroup("FylerPdfPreviewCleanup", { clear = true }),
        callback = function()
            local preview_id = getPreviewPaneId()
            if preview_id then
                closePreviewPane(preview_id)
            end
        end,
    })
end

function M.pdfNext()
    local preview_pane_id = getPreviewPaneId()
    if not preview_pane_id then
        return
    end

    local preview_pane_name = getPreviewPaneName()
    if preview_pane_name ~= "tdf" then
        return
    end

    local neovim_wezterm_pane_id = getNeovimPaneId()
    if neovim_wezterm_pane_id then
        activatePane(neovim_wezterm_pane_id)
    end
    sendKeyToPreviewPane(preview_pane_id, "l")
end

function M.pdfPrev()
    local preview_pane_id = getPreviewPaneId()
    if not preview_pane_id then
        return
    end

    local preview_pane_name = getPreviewPaneName()
    if preview_pane_name ~= "tdf" then
        return
    end

    local neovim_wezterm_pane_id = getNeovimPaneId()
    if neovim_wezterm_pane_id then
        activatePane(neovim_wezterm_pane_id)
    end
    sendKeyToPreviewPane(preview_pane_id, "h")
end

function M.pdfClose()
    local preview_pane_id = getPreviewPaneId()
    if preview_pane_id then
        closePreviewPane(preview_pane_id)
    end
end

M.show_help = function(self)
    -- oil.nvim のヘルプのように、主要なマッピングを通知で表示する
    local help_msg = [[
Fyler Mappings (oil.nvim-like):
- <CR>: Select
- -: GotoParent
- <C-s>: SelectVSplit
- <C-h>: SelectSplit
- <C-b>: SelectTab
- gp: Open Wezterm Preview
- gP: Open PDF (Persistent Preview)
- gc: Close Wezterm Preview
- gl/gh/gs/gv: Tdf Navigation
- g<leader>: Open with QuickLook
- gx: Open External
- <C-l>: Refresh
- _: Open Cwd
- `: cd to current dir
- ~: tcd to current dir
- g.: Toggle Hidden Files
- ?: Show Help
- <ESC>: Close Fyler

Global PDF Preview Controls:
- <leader>n: Next page in PDF Preview
- <leader>p: Prev page in PDF Preview
- <leader>c: Close PDF Preview
]]
    vim.notify(help_msg, vim.log.levels.INFO, { title = "Fyler Help" })
end

return M
