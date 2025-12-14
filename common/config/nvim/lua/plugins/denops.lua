return {
    "https://github.com/vim-denops/denops.vim",
    lazy = false,
    cond = not is_on_vscode(),
    -- dependencies = {
    --     {
    --         "https://github.com/yuki-yano/denops-lazy.nvim",
    --         opts = {
    --             wait_load = false,
    --         },
    --     },
    -- },
    init = function()
        vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }
    end,
}
