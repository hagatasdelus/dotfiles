local M = {}

---@param file_path string
M.open_file_with_quicklook = function(file_path)
    if vim.fn.executable("qlmanage") == 1 then
        local command = { "silent", "!qlmanage", "-p", vim.fn.shellescape(file_path), "&" }
        vim.cmd(table.concat(command, " "))
    else
        vim.notify("QuickLook is not available on this system.", vim.log.levels.ERROR)
    end
end

-- ---@param func function
-- ---@param wait number
-- function M.debounce(func, wait)
--     local timer_id
--     return function(...)
--         if timer_id ~= nil then
--             vim.uv.timer_stop(timer_id)
--         end
--         local args = { ... }
--         timer_id = assert(vim.uv.new_timer())
--         vim.uv.timer_start(timer_id, wait, 0, function()
--             func(unpack(args))
--             timer_id = nil
--         end)
--     end
-- end

---@param func function
---@param ms number
function M.debounce(func, ms)
    local timer = assert(vim.uv.new_timer())
    local wrapped_func = vim.schedule_wrap(func)

    return function(...)
        local args = { ... }

        timer:stop()

        timer:start(ms, 0, function()
            wrapped_func(unpack(args))
        end)
    end
end

---@param on_attach OnAttachCallback
function M.on_attach(on_attach)
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local buffer = args.buf
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
            on_attach(client, buffer)
        end,
    })
end

return M
