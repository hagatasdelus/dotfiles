return {
    "https://github.com/vim-denops/denops.vim",
    lazy = true,
    cond = not is_on_vscode(),
    -- dependencies = {
    --     {
    --         "https://github.com/yuki-yano/denops-lazy.nvim",
    --         opts = {
    --             wait_load = false,
    --         },
    --     },
    -- },
    -- event = { "VeryLazy" },
    -- priority = 1000,
}
