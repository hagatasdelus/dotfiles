return {
    "https://github.com/kdheepak/lazygit.nvim",
    lazy = true,
    cond = not require("hagata.env").is_vscode(),
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },
    keys = {
        { "<leader>lg", "<Cmd>LazyGit<CR>", desc = "LazyGit" },
    },
    config = function()
        vim.g.lazygit_floating_window_scaling_factor = 0.97

        vim.api.nvim_create_augroup("LazygitKeyMapping", {})
        vim.api.nvim_create_autocmd("TermOpen", {
            group = "LazygitKeyMapping",
            pattern = "*",
            callback = function()
                local filetype = vim.bo.filetype
                -- The terminal buffer's filetype is "lazygit", not empty.
                if filetype == "lazygit" then
                    -- This mapping is required; the reason it works is unclear.
                    vim.api.nvim_buf_set_keymap(0, "t", "<ESC>", "<ESC>", { silent = true })
                    -- <C-\><C-n> is Neovim's Escape; Lazygit consumes <ESC>.
                    vim.api.nvim_buf_set_keymap(0, "t", "<C-v><ESC>", [[<C-\><C-n>]], { silent = true })
                end
            end,
        })
    end,
}
