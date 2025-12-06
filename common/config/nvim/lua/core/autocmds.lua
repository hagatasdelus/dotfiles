local debounce = require("core.utils").debounce
local augroup = vim.api.nvim_create_augroup("augroup_global", { clear = true })

local function create_autocmd(event, opts)
    local final_opts = vim.tbl_extend("keep", { group = augroup }, opts)
    vim.api.nvim_create_autocmd(event, final_opts)
end

create_autocmd("TermOpen", {
    pattern = "*",
    desc = "Enter insert mode when opening a terminal",
    callback = function()
        vim.cmd.startinsert()
    end,
})

create_autocmd("BufReadPost", {
    pattern = "*",
    desc = "Restore cursor position",
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
        -- vim.api.nvim_exec('silent! normal! g`"zv', false)
    end,
})

create_autocmd("TextYankPost", {
    desc = "Highlight on yank",
    callback = function()
        vim.highlight.on_yank()
    end,
})

local function set_input_source(source)
    if is_on_mac() and vim.fn.executable("macism") == 1 then
        vim.system({ "macism", source }, { text = true }, function(out)
            if out.code ~= 0 then
                vim.schedule(function()
                    vim.notify("macism error: " .. out.stderr, vim.log.levels.ERROR)
                end)
            end
        end)
    end
end

local switch_ime = debounce(set_input_source, 100)

create_autocmd({ "FocusGained", "VimEnter" }, {
    pattern = "*",
    desc = "Set input source to ABC when Neovim gains focus",
    callback = function()
        switch_ime("com.apple.keylayout.ABC")
    end,
})

create_autocmd({ "FocusLost", "VimLeave" }, {
    pattern = "*",
    desc = "Set input source to AquaSKK when Neovim loses focus",
    callback = function()
        switch_ime("jp.sourceforge.inputmethod.aquaskk")
    end,
})
