-- skkelua の変換候補を nvim-cmp に流す source。

local M = {}

local source = {}

function source:is_available()
    local skk = package.loaded["skkelua"]
    return skk ~= nil and skk.is_enabled()
end

function source:get_keyword_pattern()
    -- 行頭から一致させると entry.offset がずれて候補が消えるため、
    -- pre-edit そのものだけをキーワードにする。
    local skk = package.loaded["skkelua"]
    if skk and skk.is_enabled() then
        local pre_edit = skk.get_pre_edit()
        if pre_edit ~= "" then
            return vim.pesc(pre_edit)
        end
    end
    return "[[:keyword:]*]*"
end

function source:get_position_encoding_kind()
    -- skkelua の textEdit の range は UTF-8 バイト位置
    return "utf-8"
end

function source:complete(_, callback)
    local empty = { isIncomplete = true, items = {} }
    local skk = package.loaded["skkelua"]
    if not skk or not skk.is_enabled() then
        return callback(empty)
    end

    -- _make_completion_list は completeopt を書き換えるので戻す
    local completeopt = vim.bo.completeopt
    local ok, list = pcall(require("skkelua.lsp")._make_completion_list)
    pcall(function()
        vim.bo.completeopt = completeopt
    end)
    if not ok or type(list) ~= "table" then
        return callback(empty)
    end

    for _, item in ipairs(list.items or {}) do
        -- 読みを detail に入れると documentation が開く
        item.detail = nil
    end
    callback(list)
end

function source:execute(item, callback)
    local data = item.data
    if type(data) == "table" and data.skkelua then
        if data.register then
            vim.schedule(function()
                require("skkelua").handle("handleKey", { ["function"] = "registerWord" })
            end)
        elseif not data.raw then
            require("skkelua").complete_callback(data.midasi, data.word, data.type)
        end
    end
    callback()
end

---@return boolean
function M.active()
    local skk = package.loaded["skkelua"]
    if not skk or not skk.is_enabled() then
        return false
    end
    local phase = skk.phase()
    return phase == "input:okurinasi" or phase == "input:okuriari" or phase == "henkan"
end

-- かな入力では cmp の自動補完が走らないため、状態変化時に補完し直す
function M.refresh()
    local cmp = package.loaded["cmp"]
    if not cmp then
        return
    end
    if M.active() then
        cmp.complete({ config = { sources = { { name = "skkelua" } } } })
        return
    end
    if not cmp.visible() then
        return
    end
    for _, entry in ipairs(cmp.get_entries()) do
        if entry.source and entry.source.name == "skkelua" then
            cmp.close()
            return
        end
    end
end

function M.setup()
    require("cmp").register_source("skkelua", source)
    vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("config.skkelua.cmp.refresh", { clear = true }),
        pattern = "skkelua-handled",
        callback = function()
            if package.loaded["cmp"] then
                vim.schedule(M.refresh)
            end
        end,
    })
end

return M
