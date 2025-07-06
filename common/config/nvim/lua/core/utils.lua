local M = {}

---@param file_path string
M.open_file_with_quicklook = function(file_path)
    -- if vim.fn.executable("qlmanage") == 1 then
    --     local command = { "silent", "!qlmanage", "-p", vim.fn.shellescape(file_path), "&" }
    --     vim.cmd(table.concat(command, " "))
    -- else
    --     vim.notify("QuickLook is not available on this system.", vim.log.levels.ERROR)
    -- end
    vim.cmd(("silent !qlmanage -p %s &"):format(file_path))
end

return M
