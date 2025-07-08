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

function M.debounce(func, wait)
    local timer_id
    return function(...)
        if timer_id ~ nil then
            vim.uv.timer_stop(timer_id)
        end
        local args = { ... }
        timer_id = assert(vim.uv.new_timer())
        vim.uv.timer_start(timer_id, wait, 0, function()
            func(unpack(args))
            timer_id = nil
        end)
    end
end


return M
