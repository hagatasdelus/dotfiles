local M = {}

local function unescape(value)
    return value:gsub("&comma;", ","):gsub("&sharp;", "#")
end

local function default_rule_path()
    return vim.fs.joinpath(
        vim.fn.expand("~"),
        "Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Settings/kana-rule-azik.conf"
    )
end

local function parse_rule_line(line)
    if line:match("^%s*#") or line:match("^%s*$") then
        return nil
    end
    local cols = vim.split(line, ",", { plain = true })
    if #cols < 2 then
        return nil
    end
    local from = unescape(cols[1])
    local output = unescape(cols[2]):gsub("<okuri>", "")
    if from == "" or output == "" then
        return nil
    end
    local remain = cols[5] and unescape(cols[5]) or ""
    return from, output, remain
end

local function layout_cache_path()
    local state_dir = vim.fn.stdpath("state")
    if not state_dir or state_dir == "" then
        state_dir = vim.fn.stdpath("data")
    end
    return vim.fs.joinpath(state_dir, "skkeleton_layout")
end

local function save_layout(layout)
    local path = layout_cache_path()
    local f = io.open(path, "w")
    if f then
        f:write(layout)
        f:close()
    end
end

local function load_saved_layout()
    local path = layout_cache_path()
    local f = io.open(path, "r")
    if f then
        local layout = f:read("*a")
        f:close()
        layout = vim.trim(layout)
        if layout == "us" or layout == "jis" then
            return layout
        end
    end
    return nil
end

local current_layout = nil

function M.load(layout, path)
    layout = layout or current_layout or load_saved_layout() or "us"
    path = path or default_rule_path()
    local rules = {}
    local shift_aliases = {}
    local lines = vim.fn.readfile(path)
    for _, line in ipairs(lines) do
        local from, output, remain = parse_rule_line(line)
        if from and output ~= nil then
            if output:match("^<shift>") then
                shift_aliases[from] = output:gsub("^<shift>", "")
            else
                rules[from] = { output, remain }
            end
        end
    end
    for from, target in pairs(shift_aliases) do
        local base = rules[target]
        if base then
            rules[from] = { base[1], base[2] }
        else
            Snacks.notify.error("Unresolved <shift> target: " .. target, { title = "skkeleton azik" })
        end
    end
    rules[" "] = "henkanFirst"
    rules["/"] = "abbrev"
    rules["q"] = "katakana"
    rules["Q"] = "hankatakana"
    rules[";"] = "henkanPoint"
    rules["@"] = "zenkaku"

    if layout == "jis" then
        rules[":"] = "disable"
        rules["'"] = false
    else
        rules["'"] = "disable"
        rules[":"] = false
    end
    return rules
end

function M.register(layout, path)
    layout = layout or load_saved_layout() or "us"
    path = path or default_rule_path()
    if vim.fn.filereadable(path) ~= 1 then
        Snacks.notify.error("Rule file not found: " .. path, { title = "skkeleton azik" })
        return
    end
    local rules = M.load(layout, path)
    vim.fn["skkeleton#register_kanatable"]("azik", rules, true)
    current_layout = layout
    save_layout(layout)
end

function M.get_layout()
    if not current_layout then
        current_layout = load_saved_layout() or "us"
    end
    return current_layout
end

return M
