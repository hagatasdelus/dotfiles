_G.to_bool = function(value)
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

_G.use_in_vscode = function()
    return to_bool(vim.g.vscode)
end
