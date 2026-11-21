local M = {}

local TARGET_SOURCE = "net.mtgto.inputmethod.macSKK.hiragana"
local ABC_SOURCE = "com.apple.keylayout.ABC"

local SETTLE_SECONDS = 0.3
local RETRY_SECONDS = 0.5
local RESTART_WAIT_SECONDS = 1.5
local MAX_TRIES = 4
local RESTART_COOLDOWN_SECONDS = 30

local enabled = true
local lastRestartAt = 0

local function isAbc()
    return hs.keycodes.currentSourceID() == ABC_SOURCE
end

local function restartMacSKK()
    lastRestartAt = os.time()
    hs.execute("/usr/bin/killall macSKK")
end

local function canRestartMacSKK()
    return os.time() - lastRestartAt > RESTART_COOLDOWN_SECONDS
end

local function restore(tries)
    if not enabled or not isAbc() then
        return
    end
    -- macOS forces ABC in password fields, so switching back there would fight the OS.
    if hs.eventtap.isSecureInputEnabled() then
        return
    end
    if hs.keycodes.currentSourceID(TARGET_SOURCE) then
        return
    end

    if tries < MAX_TRIES then
        hs.timer.doAfter(RETRY_SECONDS, function()
            restore(tries + 1)
        end)
    elseif canRestartMacSKK() then
        restartMacSKK()
        hs.timer.doAfter(RESTART_WAIT_SECONDS, function()
            restore(1)
        end)
    end
end

local function toggleEnabled()
    enabled = not enabled
    hs.alert.show("IME guard: " .. (enabled and "ON" or "OFF"))
end

function M.start()
    M.watcher = hs.keycodes.inputSourceChanged(function()
        if not isAbc() then
            return
        end
        hs.timer.doAfter(SETTLE_SECONDS, function()
            restore(1)
        end)
    end)
    hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "I", toggleEnabled)
end

return M
