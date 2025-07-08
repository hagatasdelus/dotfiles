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

_G.debounce = function(func, wait)
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

_G.is_on_vscode = function()
    return to_bool(vim.g.vscode)
end

_G.lambda = function(str)
    local chunk = [[
    return function(%s)
        return %s
    end
    ]]
    local arg, body = str:match("(.*):(.*)")
    return assert(load(chunk:format(arg, body)))
end
