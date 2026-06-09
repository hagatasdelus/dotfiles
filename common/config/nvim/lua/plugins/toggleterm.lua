return {
    "https://github.com/akinsho/toggleterm.nvim",
    event = "VeryLazy",
    init = function()
        vim.keymap.set({ "n", "t" }, "<C-T>", function()
            local ui = require("toggleterm.ui")
            local has_open, windows = ui.find_open_windows()
            if has_open then
                local tabpage = vim.api.nvim_get_current_tabpage()
                if not vim.tbl_contains(vim.api.nvim_tabpage_list_wins(tabpage), windows[1].window) then
                    ui.close_and_save_terminal_view(windows)
                    vim.api.nvim_set_current_tabpage(tabpage)
                end
            end
            vim.cmd(vim.v.count .. "ToggleTerm direction=horizontal")
        end, { desc = "Allow reopen toggleterm in different tabpage" })
        vim.keymap.set("n", "tm", function()
            vim.cmd(vim.v.count .. "ToggleTerm direction=tab")
        end, { silent = true, desc = "Toggleterm in tab" })
        vim.keymap.set("n", "<Space><CR>", "<Cmd>ToggleTermSendCurrentLine<CR>", { silent = true })
        vim.keymap.set("v", "<Space><CR>", "<Cmd>ToggleTermSendVisualSelection<CR>", { silent = true })
    end,
    config = function()
        require("toggleterm").setup({
            open_mapping = false,
            insert_mappings = false,
            shade_terminals = false,
            shading_factor = 0,
            float_opts = {
                border = "curved",
                width = function()
                    return math.floor(vim.o.columns * 0.95)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.9)
                end,
            },
        })
    end,
}
