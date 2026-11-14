local fn = require("hagata.fn")

local M = {}

---@return boolean
function M.is_vscode()
    return fn.to_bool(vim.g.vscode)
end

---@return boolean
function M.is_macos()
    return vim.uv.os_uname().sysname == "Darwin"
end

return M
