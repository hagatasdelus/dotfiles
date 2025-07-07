return {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cond = not is_on_vscode(),
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
                -- filetypeにはlazygitが渡る。空文字ではない
                if filetype == "lazygit" then
                    -- このkeymapが肝。なんでこれで動くのかは謎
                    vim.api.nvim_buf_set_keymap(0, "t", "<ESC>", "<ESC>", { silent = true })
                    -- <C-\><C-n>がNeovimとしてのESC。<ESC>はLazygitが奪う
                    vim.api.nvim_buf_set_keymap(0, "t", "<C-v><ESC>", [[<C-\><C-n>]], { silent = true })
                end
            end,
        })
    end,
}
