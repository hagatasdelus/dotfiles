-- ref: https://blog.atusy.net/2025/11/28/fyler-nvim/
local function open()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if vim.startswith(buf_name, "fyler://") then
            vim.api.nvim_set_current_win(win)
            return
        end
    end

    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if vim.startswith(buf_name, "fyler://") then
            vim.api.nvim_win_set_buf(0, buf)
            return
        end
    end

    if vim.v.count > 0 then
        require("fyler").close()
    end
    require("fyler").open()
end

---@type LazySpec
return {
    "https://github.com/A7Lavinraj/fyler.nvim",
    dependencies = { "https://github.com/nvim-mini/mini.icons" },
    branch = "stable",
    event = "VeryLazy",
    cmd = { "Fyler" },
    init = function()
        local group = vim.api.nvim_create_augroup("FylerWinbar", {})

        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = group,
            pattern = "fyler://*",
            callback = function(ctx)
                local winid = vim.api.nvim_get_current_win()

                if vim.w[winid].fyler_prev_winbar == nil then
                    vim.w[winid].fyler_prev_winbar = vim.wo[winid].winbar or ""
                end

                local buf_name = vim.api.nvim_buf_get_name(0)
                local _scheme, path = buf_name:match("^(.*://)(.*)$")
                if path then
                    local title = vim.fn.fnamemodify(path, ":~")
                    vim.wo[winid].winbar = title
                end
            end,
        })
        vim.api.nvim_create_autocmd("BufWinLeave", {
            group = group,
            pattern = "fyler://*",
            callback = function()
                local winid = vim.api.nvim_get_current_win()
                if vim.w[winid].fyler_prev_winbar ~= nil then
                    vim.wo[winid].winbar = vim.w[winid].fyler_prev_winbar
                    vim.w[winid].fyler_prev_winbar = nil
                end
            end,
        })
        vim.keymap.set("n", "<leader>fn", open)
    end,
    opts = function()
        return {
            views = {
                finder = {
                    close_on_select = false,
                    confirm_simple = true,
                    follow_current_file = false,
                },
            },
        }
    end,
    config = function(_, opts)
        require("fyler").setup(opts)
    end,
}
