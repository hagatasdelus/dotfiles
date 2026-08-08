local M = {}

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
    vim.opt.winbar = ""

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

---Check if the buffer content is empty or contains only whitespace
---@param bufnr integer buffer number
---@return boolean
function M.is_buffer_blank(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return table.concat(lines, "\n"):find("%S") == nil
end

---Send current buffer content to the target pane via editprompt CLI
function M.send_buffer_auto_send()
    local editprompt_utils = require("editprompt.utils")
    editprompt_utils.save_buffer()

    local original = editprompt_utils.get_buffer_content()
    local content = M.normalize_content(original)
    if content:match("^%s*$") then
        return
    end

    local editprompt = require("editprompt")
    editprompt.input_auto_send()
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

---Handle <CR> key behavior in the editprompt buffer.
---If the buffer is empty, it acts as a normal <CR> or forwards keys.
---@param bufnr integer buffer number
---@return string keys to feed or empty string
function M.handle_cr(bufnr)
    local mode = vim.api.nvim_get_mode().mode

    if M.is_buffer_blank(bufnr) then
        local editprompt = require("editprompt")
        if mode:sub(1, 1) == "i" then
            vim.schedule(function()
                editprompt.press("<CR>")
            end)
        else
            editprompt.press("<CR>")
        end
        return ""
    end

    if mode:sub(1, 1) == "i" then
        return "<CR>"
    end

    vim.schedule(M.send_buffer_auto_send)
    return ""
end

---Get target pane ID for editprompt CLI operations (Target Pane, NOT Editor Pane)
---@return string|nil
local function get_target_pane_id()
    local env_target = vim.env.EDITPROMPT_TARGET_PANE
    if env_target and env_target ~= "" then
        return env_target
    end

    local current_pane = vim.env.HERDR_PANE_ID
    if current_pane and current_pane ~= "" then
        local res = vim.system({ "herdr", "pane", "get", current_pane }, { text = true }):wait()
        if res.code == 0 and res.stdout then
            local target_id = res.stdout:match("Prompting for.-%((%w+:%w+)%)")
                or res.stdout:match("Prompting for%s+(%w+:%w+)")
            if target_id and target_id ~= "" then
                return target_id
            end
        end
    end

    local list_res = vim.system({ "herdr", "pane", "list" }, { text = true }):wait()
    if list_res.code == 0 and list_res.stdout then
        local target_id = list_res.stdout:match("Prompting for.-%((%w+:%w+)%)")
            or list_res.stdout:match("Prompting for%s+(%w+:%w+)")
        if target_id and target_id ~= "" then
            return target_id
        end
    end

    local active = vim.env.HERDR_ACTIVE_PANE_ID
    if active and active ~= "" and active ~= current_pane then
        return active
    end

    return nil
end

---Parse raw dump output into quote text blocks
---@param raw_output string
---@return string[]
local function parse_quote_blocks(raw_output)
    raw_output = raw_output:gsub("\n$", "")
    if raw_output:match("^%s*$") then
        return {}
    end

    local blocks = {}
    local current_block = {}

    for _, line in ipairs(vim.split(raw_output, "\n", { plain = true })) do
        if line:match("^%s*$") then
            if #current_block > 0 then
                table.insert(blocks, table.concat(current_block, "\n"))
                current_block = {}
            end
        else
            table.insert(current_block, line)
        end
    end

    if #current_block > 0 then
        table.insert(blocks, table.concat(current_block, "\n"))
    end

    return blocks
end

---Restore unselected quote blocks back to editprompt collect storage
---@param blocks string[]
---@param on_complete? function
local function restore_quote_blocks(blocks, on_complete)
    if #blocks == 0 then
        if on_complete then
            on_complete()
        end
        return
    end

    local target = get_target_pane_id()
    if not target or target == "" then
        Snacks.notify.error("Cannot restore quotes: Target pane ID is missing.", { title = "editprompt" })
        if on_complete then
            on_complete()
        end
        return
    end

    local combined = table.concat(blocks, "\n\n")
    local args = { "editprompt", "collect", "--mux", "herdr", "--target-pane", target, "--no-quote", "--", combined }

    vim.system(args, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                Snacks.notify.error(
                    "Failed to restore quotes: " .. (result.stderr or "unknown error"),
                    { title = "editprompt" }
                )
            end
            if on_complete then
                on_complete()
            end
        end)
    end)
end

---Truncate a string to at most `n` characters, appending "..." if it was cut
---@param s string
---@param n integer
---@return string
local function truncate(s, n)
    if #s > n then
        return s:sub(1, n) .. "..."
    end
    return s
end

---Convert a quote block into a Snacks.picker item
---@param i integer
---@param block string
---@return { idx: integer, text: string, label: string }
local function to_item(i, block)
    local first_line = vim.split(block, "\n", { plain = true })[1] or ""
    first_line = truncate((first_line:gsub("^>%s*", "")), 60)
    return {
        idx = i,
        text = block,
        label = string.format("[%d] %s", i, first_line),
    }
end

---Resolve which quote blocks to insert and restore
---@param blocks string[]
---@param selected { idx: integer, text: string }[]
---@param item { idx: integer, text: string }|nil
---@return { to_insert: string[], to_restore: string[] }
local function resolve_selection(blocks, selected, item)
    local chosen = {}
    if #selected > 0 then
        chosen = selected
    elseif item then
        chosen = { item }
    end

    local selected_set = {}
    local to_insert = {}
    for _, sel in ipairs(chosen) do
        selected_set[sel.idx] = true
        table.insert(to_insert, sel.text)
    end

    local to_restore = {}
    for i, block in ipairs(blocks) do
        if not selected_set[i] then
            table.insert(to_restore, block)
        end
    end

    return { to_insert = to_insert, to_restore = to_restore }
end

---Present Snacks.picker to select quotes to insert
---@param blocks string[]
local function show_quote_picker(blocks)
    local editprompt_utils = require("editprompt.utils")

    local items = vim.iter(ipairs(blocks)):map(to_item):totable()

    local is_confirmed = false

    Snacks.picker.pick({
        source = "editprompt_quotes",
        items = items,
        format = function(item)
            return { { item.label, "SnacksPickerLabel" } }
        end,
        preview = function(ctx)
            ctx.preview:set_lines(vim.split(ctx.item.text, "\n", { plain = true }))
        end,
        on_close = function()
            if is_confirmed then
                return
            end
            restore_quote_blocks(blocks, function()
                Snacks.notify.info("Selection cancelled. All quotes retained.", { title = "editprompt" })
            end)
        end,
        actions = {
            confirm = function(picker, item)
                is_confirmed = true
                picker:close()

                local plan = resolve_selection(blocks, picker:selected(), item)

                if #plan.to_insert > 0 then
                    editprompt_utils.insert_to_buffer(table.concat(plan.to_insert, "\n\n"))
                end

                restore_quote_blocks(plan.to_restore, function()
                    if #plan.to_restore > 0 then
                        Snacks.notify.info(
                            string.format(
                                "Inserted %d quote(s). %d quote(s) retained.",
                                #plan.to_insert,
                                #plan.to_restore
                            ),
                            { title = "editprompt" }
                        )
                    else
                        Snacks.notify.info(
                            string.format("Inserted %d quote(s).", #plan.to_insert),
                            { title = "editprompt" }
                        )
                    end
                end)
            end,
        },
    })
end

---Dump collected quotes and present an interactive picker
function M.dump_select()
    local editprompt_utils = require("editprompt.utils")
    editprompt_utils.save_buffer()

    vim.system({ "editprompt", "dump" }, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                Snacks.notify.error(
                    "editprompt dump failed: " .. (result.stderr or "Unknown error"),
                    { title = "editprompt" }
                )
                return
            end

            local blocks = parse_quote_blocks(result.stdout or "")
            if #blocks == 0 then
                Snacks.notify.info("No collected quotes to dump.", { title = "editprompt" })
                return
            end

            if #blocks == 1 then
                editprompt_utils.insert_to_buffer(blocks[1])
                return
            end

            show_quote_picker(blocks)
        end)
    end)
end

return M
