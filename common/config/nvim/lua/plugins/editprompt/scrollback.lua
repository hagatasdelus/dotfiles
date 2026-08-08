local M = {}

---Resolve target pane ID from env or buffer filename
---@param bufnr integer
---@return string|nil
local function get_target_pane(bufnr)
    local target = vim.env.EDITPROMPT_TARGET_PANE
    if target and target ~= "" then
        return target
    end
    target = vim.env.HERDR_ACTIVE_PANE_ID
    if target and target ~= "" then
        return target
    end
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local matched = bufname:match("herdr%-scrollback%-(.+)%.txt$")
    if matched then
        return matched:gsub("%-", ":")
    end
    return nil
end

---Send collected yank text to editprompt CLI
---@param yanked_text string
---@param bufnr integer
local function send_collect(yanked_text, bufnr)
    local target = get_target_pane(bufnr)
    local args = { "editprompt", "collect", "--mux", "herdr" }
    if target and target ~= "" then
        table.insert(args, "--target-pane")
        table.insert(args, target)
    end
    vim.list_extend(args, { "--", yanked_text })

    vim.system(args, { text = true }, function(result)
        vim.schedule(function()
            if result.code == 0 then
                Snacks.notify.info("Quote collected for editprompt!", { title = "editprompt" })
            else
                Snacks.notify.error(
                    "Failed to collect quote: " .. (result.stderr or "unknown error"),
                    { title = "editprompt" }
                )
            end
        end)
    end)
end

---Configure scrollback buffer settings and bind TextYankPost event
---@param bufnr integer
function M.setup_scrollback_buffer(bufnr)
    vim.keymap.set("n", "q", "<Cmd>quit!<CR>", { buffer = bufnr, silent = true })

    local group = vim.api.nvim_create_augroup("HerdrScrollbackYank_" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd("TextYankPost", {
        group = group,
        buffer = bufnr,
        callback = function()
            local event_info = vim.v.event
            local regcontents = event_info.regcontents
            if event_info.operator == "y" and type(regcontents) == "table" and #regcontents > 0 then
                local yanked_text = table.concat(regcontents, "\n")
                if yanked_text:find("%S") then
                    send_collect(yanked_text, bufnr)
                end
            end
        end,
    })
end

return M
