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
