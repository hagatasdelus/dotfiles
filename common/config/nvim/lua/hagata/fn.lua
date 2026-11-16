local M = {}

---@param value any
---@return boolean
function M.to_bool(value)
    if value == nil then
        return false
    elseif type(value) == "boolean" then
        return value
    elseif type(value) == "number" then
        return value ~= 0
    elseif type(value) == "string" then
        return string.lower(value) == "true"
    else
        return false
    end
end

---@param str string
---@return function
function M.lambda(str)
    local chunk = [[
    return function(%s)
        return %s
    end
    ]]
    local arg, body = str:match("(.*):(.*)")
    return assert(load(chunk:format(arg, body)))()
end

return M
