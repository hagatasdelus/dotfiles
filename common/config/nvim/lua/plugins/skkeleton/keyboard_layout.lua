--- Shared keyboard layout state (Karabiner / macSKK / AZIK) for Neovim.
---
--- The CLI owns state.json; this only reads it and re-registers AZIK, and
--- delegates writes (toggle) so every layer shares one path.
local M = {}

local POLL_INTERVAL = 500
local FALLBACK_LAYOUT = "us"

M.enabled = is_on_mac()

--- The CLI writes state.json to $XDG_STATE_HOME/keyboard-layout, so read that
--- base directly: stdpath("state") returns ~/.local/state/nvim, which differs
function M.state_dir()
    local base = vim.env.XDG_STATE_HOME
    if not base or base == "" then
        base = vim.fs.joinpath(vim.uv.os_homedir(), ".local/state")
    end
    return vim.fs.joinpath(base, "keyboard-layout")
end

function M.state_file()
    return vim.fs.joinpath(M.state_dir(), "state.json")
end

--- nvim has no DOTFILES_DIR (only the LaunchAgent does), so derive it
function M.dotfiles_root()
    local config = vim.fn.stdpath("config")
    if config == "" then
        return nil
    end

    -- stdpath does not resolve symlinks
    local resolved = vim.uv.fs_realpath(config) or config
    return vim.fs.normalize(vim.fs.joinpath(resolved, "..", "..", ".."))
end

function M.cli()
    if vim.g.keyboard_layout_cli then
        return { vim.g.keyboard_layout_cli }
    end
    if vim.env.KEYBOARD_LAYOUT_CLI then
        return { vim.env.KEYBOARD_LAYOUT_CLI }
    end

    local roots = {}
    if vim.env.DOTFILES_DIR then
        table.insert(roots, vim.env.DOTFILES_DIR)
    end
    local derived = M.dotfiles_root()
    if derived then
        table.insert(roots, derived)
    end

    for _, root in ipairs(roots) do
        local compiled = vim.fs.joinpath(root, "scripts/darwin/bin/keyboard-layout")
        if vim.uv.fs_stat(compiled) then
            return { compiled }
        end
    end

    for _, root in ipairs(roots) do
        local source = vim.fs.joinpath(root, "scripts/darwin/keyboard-layout.ts")
        if vim.uv.fs_stat(source) and vim.fn.executable("bun") == 1 then
            return { "bun", source }
        end
    end

    return nil
end

function M.read_state()
    local path = M.state_file()
    if not vim.uv.fs_stat(path) then
        return nil
    end

    local ok, content = pcall(vim.fn.readfile, path)
    if not ok or not content or #content == 0 then
        return nil
    end

    local parsed_ok, state = pcall(vim.json.decode, table.concat(content, "\n"))
    if not parsed_ok or type(state) ~= "table" then
        return nil
    end
    return state
end

function M.azik_layout()
    local state = M.read_state()
    if state and type(state.azik_layout) == "string" then
        return state.azik_layout
    end
    return vim.g.keyboard_layout_fallback or FALLBACK_LAYOUT
end

function M.apply(layout)
    local azik = require("plugins.skkeleton.azik")
    if azik.register(layout) then
        Snacks.notify.info("Keyboard Layout: " .. layout:upper(), { title = "skkeleton" })
    end
end

--- Watch the directory, not the file: watching the file itself misses the
--- "created while absent" event. Callbacks run in a fast event context where
--- Vimscript functions are unavailable, hence vim.schedule.
function M.watch()
    if not M.enabled then
        return
    end

    local dir = M.state_dir()
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end

    local handle = assert(vim.uv.new_fs_poll(), "fs_poll is unavailable")
    M._current = M.azik_layout()

    handle:start(dir, POLL_INTERVAL, function()
        vim.schedule(function()
            local layout = M.azik_layout()
            if layout ~= M._current then
                M._current = layout
                M.apply(layout)
            end
        end)
    end)

    M._poll = handle
end

function M.run_cli(args, on_exit)
    local cli = M.cli()
    if not cli then
        Snacks.notify.error(
            "keyboard-layout CLI not found (run scripts/darwin/install-keyboard-layout.sh)",
            { title = "keyboard-layout" }
        )
        return
    end

    vim.system(vim.list_extend(cli, args), { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                Snacks.notify.error(
                    "keyboard-layout " .. table.concat(args, " ") .. " failed",
                    { title = "keyboard-layout" }
                )
                return
            end
            if on_exit then
                on_exit(result)
            end
        end)
    end)
end

--- Re-resolve from the currently connected devices (safety net / debugging)
function M.sync()
    M.run_cli({ "sync", "--source", "nvim" }, function()
        local layout = M.azik_layout()
        if layout ~= M._current then
            M._current = layout
        end
        M.apply(layout)
    end)
end

function M.toggle()
    M.run_cli({ "toggle", "--source", "nvim" }, function()
        local layout = M.azik_layout()
        M._current = layout
        M.apply(layout)
    end)
end

return M
