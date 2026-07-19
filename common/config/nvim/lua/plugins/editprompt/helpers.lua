local M = {}

local editprompt_chunk_bytes = 8000

---Check if current environment is editprompt
---@return boolean
function M.is_editprompt()
    return vim.env.EDITPROMPT == "1" or vim.g.editprompt == 1
end

---Normalize content by replacing tabs with spaces and ensuring trailing newline
---@param content string original content
---@return string normalized content
function M.normalize_content(content)
    local normalized = content:gsub("\t", "  ")
    if not normalized:find("\n$") then
        normalized = normalized .. "\n"
    end
    return normalized
end

---Check if buffer content should be copied to clipboard
---@param content string content to check
---@return boolean
function M.should_save_clipboard(content)
    if type(content) ~= "string" or content == "" then
        return false
    end

    local lines = vim.split(content, "\n", { plain = true })
    local first_line = lines[1] or ""
    if not first_line:find("^/") then
        return true
    end

    local first_line_args = first_line:match("^/%S*%s*(.*)$") or ""
    if first_line_args:find("%S") ~= nil then
        return true
    end

    local trailing_text = table.concat(vim.list_slice(lines, 2), "\n")
    return trailing_text:find("%S") ~= nil
end

---Get the byte length of a UTF-8 character based on its first byte
---@param first_byte integer first byte of the character
---@return integer length byte length (1 to 4)
local function utf8_char_byte_length(first_byte)
    if first_byte < 0x80 then
        return 1
    elseif first_byte < 0xE0 then
        return 2
    elseif first_byte < 0xF0 then
        return 3
    elseif first_byte < 0xF8 then
        return 4
    end
    return 1
end

---Split content by maximum byte size into multiple chunks
---@param content string content to split
---@param max_bytes integer maximum bytes per chunk
---@return string[] chunks list of split content chunks
local function split_by_utf8_bytes(content, max_bytes)
    local chunks = {}
    local len = #content
    local chunk_start = 1
    local chunk_bytes = 0
    local pos = 1

    while pos <= len do
        local char_bytes = utf8_char_byte_length(content:byte(pos))
        if chunk_bytes > 0 and chunk_bytes + char_bytes > max_bytes then
            table.insert(chunks, content:sub(chunk_start, pos - 1))
            chunk_start = pos
            chunk_bytes = 0
        end
        pos = pos + char_bytes
        chunk_bytes = chunk_bytes + char_bytes
    end

    if chunk_start <= len then
        table.insert(chunks, content:sub(chunk_start))
    end

    return chunks
end

---Apply minimal UI settings for editprompt buffer
function M.apply_mode_opts()
    if vim.g.quick_ime_opts_applied == 1 then
        return
    end
    vim.g.quick_ime_opts_applied = 1

    vim.g.enable_number = false
    vim.g.enable_relative_number = false
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.showmode = true
    vim.opt.laststatus = 0
    vim.opt.cmdheight = 0
    vim.opt.signcolumn = "no"

    vim.cmd([[
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NonText guibg=NONE ctermbg=NONE
    highlight EndOfBuffer guibg=NONE ctermbg=NONE
    highlight LineNr guibg=NONE ctermbg=NONE
    highlight SignColumn guibg=NONE ctermbg=NONE
  ]])
end

---Move cursor to the start of the buffer (line 1, col 0)
---@param bufnr integer|nil buffer number (defaults to current)
function M.move_cursor_to_start(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 then
        vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end
end

---Restore editor focus back to the tmux or WezTerm pane
local function restore_editor_focus()
    local tmux_pane = vim.env.TMUX_PANE
    if tmux_pane and tmux_pane ~= "" and vim.fn.executable("tmux") == 1 then
        vim.system({ "tmux", "select-pane", "-t", tmux_pane }, { text = true })
        return
    end

    local wezterm_pane = vim.env.WEZTERM_PANE
    if wezterm_pane and wezterm_pane ~= "" and vim.fn.executable("wezterm") == 1 then
        vim.system({ "wezterm", "cli", "activate-pane", "--pane-id", wezterm_pane }, { text = true })
        return
    end
end

---Check if the buffer content is empty or contains only whitespace
---@param bufnr integer buffer number
---@return boolean
function M.is_buffer_blank(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return table.concat(lines, "\n"):find("%S") == nil
end

---Send content via editprompt CLI default handler
local function send_via_default()
    local editprompt = require("editprompt")
    editprompt.input_auto_send()
end

---Send content directly via herdr commands
local function send_via_herdr(content, original)
    local editprompt = require("editprompt")
    local editprompt_history = require("editprompt.history")
    local editprompt_utils = require("editprompt.utils")

    local target = vim.env.EDITPROMPT_TARGET_PANE
    if not target or target == "" then
        Snacks.notify.error("Target pane (EDITPROMPT_TARGET_PANE) is not specified.")
        return
    end

    local chunks = split_by_utf8_bytes(content, editprompt_chunk_bytes)
    local index = 1

    local function send_next_chunk()
        local is_last = index == #chunks
        local args = { "herdr", "pane", "send-text", target, chunks[index] }

        vim.system(args, { text = true }, function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    Snacks.notify.error("herdr send-text failed: " .. (result.stderr or "unknown error"))
                    return
                end

                if not is_last then
                    index = index + 1
                    send_next_chunk()
                    return
                end

                -- Final chunk sent successfully, trigger submission with Enter key
                vim.system({ "herdr", "pane", "send-keys", target, "enter" }, { text = true }, function(enter_res)
                    vim.schedule(function()
                        if enter_res.code ~= 0 then
                            Snacks.notify.error("herdr send-keys failed")
                        end

                        editprompt_utils.clear_buffer()
                        editprompt_history.push(original)
                        if M.should_save_clipboard(original) then
                            vim.fn.system("pbcopy", original)
                        end
                        editprompt.stash_pop_latest()
                    end)
                end)
            end)
        end)
    end

    send_next_chunk()
end

-- Send chunked content via editprompt CLI
local function send_via_tmux_wezterm_chunks(content, original)
    local editprompt = require("editprompt")
    local editprompt_history = require("editprompt.history")
    local editprompt_utils = require("editprompt.utils")

    local chunks = split_by_utf8_bytes(content, editprompt_chunk_bytes)
    local index = 1

    local function send_next_chunk()
        local is_last = index == #chunks
        local args = { "editprompt", "input" }
        if is_last then
            table.insert(args, "--auto-send")
        end
        vim.list_extend(args, { "--", chunks[index] })

        vim.system(args, { text = true }, function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    restore_editor_focus()
                    Snacks.notify.error("editprompt send failed: " .. (result.stderr or "unknown error"))
                    return
                end

                if not is_last then
                    index = index + 1
                    send_next_chunk()
                    return
                end

                -- All chunks sent successfully
                editprompt_utils.clear_buffer()
                editprompt_history.push(original)
                if M.should_save_clipboard(original) then
                    vim.fn.system("pbcopy", original)
                end
                editprompt.stash_pop_latest()
                restore_editor_focus()
            end)
        end)
    end

    send_next_chunk()
end

---Send current buffer content to the target pane.
---Dispatches sending strategy based on active multiplexer and content size.
function M.send_buffer_auto_send()
    local editprompt_utils = require("editprompt.utils")
    editprompt_utils.save_buffer()

    local original = editprompt_utils.get_buffer_content()
    local content = M.normalize_content(original)
    if content:match("^%s*$") then
        return
    end

    -- For herdr environment, always bypass editprompt CLI and send directly
    if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
        send_via_herdr(content, original)
        return
    end

    -- For tmux/wezterm, use default auto-send if content is short
    if #content <= editprompt_chunk_bytes then
        send_via_default()
        return
    end

    -- For tmux/wezterm, use chunked sending if content is long
    send_via_tmux_wezterm_chunks(content, original)
end

---Save the current buffer content to the history and push to stash.
function M.stash_buffer_to_history()
    local editprompt = require("editprompt")
    local editprompt_history = require("editprompt.history")
    local editprompt_utils = require("editprompt.utils")

    editprompt_utils.save_buffer()
    local original = editprompt_utils.get_buffer_content()

    if original:find("%S") ~= nil then
        editprompt_history.push(original)
    end

    editprompt.stash_push()
end

---Press a key in the target pane.
---For herdr environment, directly sends the key using 'herdr pane' command.
---For other environments, falls back to editprompt's press function.
---@param key string key to press (e.g. "1", "<CR>", etc.)
function M.press_key(key)
    local editprompt = require("editprompt")

    -- For herdr environment, bypass editprompt CLI and send key directly
    if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
        local target = vim.env.EDITPROMPT_TARGET_PANE
        if not target or target == "" then
            Snacks.notify.error("Target pane (EDITPROMPT_TARGET_PANE) is not specified.")
            return
        end

        local send_value = key
        local cmd = "send-text"

        if key == "<CR>" or key == "enter" or key == "Enter" then
            send_value = "enter"
            cmd = "send-keys"
        end

        vim.system({ "herdr", "pane", cmd, target, send_value }, { text = true }, function(result)
            if result.code ~= 0 then
                vim.schedule(function()
                    Snacks.notify.error("herdr press failed: " .. (result.stderr or "unknown error"))
                end)
            end
        end)
        return
    end

    -- For tmux/wezterm, fallback to editprompt API
    editprompt.press(key)
end

---Handle <CR> key behavior in the editprompt buffer.
---If the buffer is empty, it acts as a normal <CR> or forwards keys.
---@param bufnr integer buffer number
---@return string keys to feed or empty string
function M.handle_cr(bufnr)
    local mode = vim.api.nvim_get_mode().mode

    if M.is_buffer_blank(bufnr) then
        if mode:sub(1, 1) == "i" then
            vim.schedule(function()
                M.press_key("<CR>")
            end)
        else
            M.press_key("<CR>")
        end
        return ""
    end

    if mode:sub(1, 1) == "i" then
        return "<CR>"
    end

    vim.schedule(M.send_buffer_auto_send)
    return ""
end

return M
