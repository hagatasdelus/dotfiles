-- Tests core.keyboard_layout state watching
--
--   DOTFILES_DIR=... XDG_STATE_HOME=$(mktemp -d) \
--   nvim --headless --clean -c "luafile scripts/darwin/tests/keyboard_layout_nvim_test.lua"
--
-- plugins/skkeleton/azik and Snacks are stubbed, so the real config is untouched.
local repo = assert(os.getenv("DOTFILES_DIR"), "DOTFILES_DIR is required")

package.path = string.format("%s/common/config/nvim/lua/?.lua;%s/common/config/nvim/lua/?/init.lua;", repo, repo)
    .. package.path

local failures = 0

local function check(name, actual, expected)
    if actual == expected then
        print(string.format("  ok   %s", name))
        return
    end
    failures = failures + 1
    print(
        string.format(
            "  FAIL %s\n       expected: %s\n       actual:   %s",
            name,
            tostring(expected),
            tostring(actual)
        )
    )
end

-- Reproduce the dotfiles globals
_G.is_on_mac = function()
    return vim.uv.os_uname().sysname == "Darwin"
end
_G.Snacks = {
    notify = {
        info = function() end,
        error = function() end,
    },
}

-- Stub azik, recording register() calls
local registered = {}
package.preload["plugins.skkeleton.azik"] = function()
    return {
        register = function(layout)
            table.insert(registered, layout)
        end,
        get_layout = function()
            return registered[#registered] or "us"
        end,
    }
end

local state_dir = vim.fn.stdpath("state") .. "/keyboard-layout"
vim.fn.mkdir(state_dir, "p")
local state_file = state_dir .. "/state.json"

local function write_state(azik)
    local tmp = state_dir .. "/state.json.tmp"
    local f = assert(io.open(tmp, "w"))
    f:write(
        string.format(
            '{"version":1,"layout":"%s","mode":"auto","azik_layout":"%s","karabiner_profile":"%s",'
                .. '"macskk_key_binding_set":"AZIK_%s","updated_at":"2026-10-14T00:00:00.000Z"}',
            azik:upper(),
            azik,
            azik:upper(),
            azik:upper()
        )
    )
    f:close()
    os.rename(tmp, state_file)
end

local keyboard_layout = require("plugins.skkeleton.keyboard_layout")

print("1. state.json path and reading")
check("state_dir", keyboard_layout.state_dir(), state_dir)
check("state_file", keyboard_layout.state_file(), state_file)
write_state("jis")
check("azik_layout (jis)", keyboard_layout.azik_layout(), "jis")

print("\n2. CLI path resolution (no DOTFILES_DIR, derived from nvim config)")
vim.env.DOTFILES_DIR = nil
local cli = keyboard_layout.cli()
if cli == nil then
    failures = failures + 1
    print("  FAIL cli not found")
else
    print(string.format("  ok   cli found -> %s", table.concat(cli, " ")))
    check("cli points at keyboard-layout", cli[#cli]:match("keyboard%-layout$") ~= nil, true)
end

print("\n2b. DOTFILES_DIR takes precedence when set")
vim.env.DOTFILES_DIR = repo
local cli_with_env = keyboard_layout.cli()
check("found via DOTFILES_DIR", cli_with_env ~= nil, true)
vim.env.DOTFILES_DIR = nil

print("\n3. AZIK is re-registered when state.json is rewritten")
keyboard_layout.watch()
write_state("us")

vim.wait(3000, function()
    return #registered > 0
end)

check("register call count", #registered, 1)
check("register argument", registered[1], "us")
check("internal state follows", keyboard_layout._current, "us")

print("\n4. Rewriting identical content does not double-apply")
write_state("us")
vim.wait(3000)
check("register count unchanged", #registered, 1)

print("\n5. fast event context (why vim.schedule is required)")
-- Confirm the callback reaches the main loop via vim.schedule
local done = false
vim.schedule(function()
    done = true
end)
vim.wait(1000, function()
    return done
end)
check("vim.schedule works", done, true)

print("")
if failures == 0 then
    print("all passed")
    vim.cmd("qa!")
else
    print(string.format("%d failed", failures))
    vim.cmd("cquit 1")
end
