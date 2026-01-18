return {
    {
        "https://github.com/vim-denops/denops.vim",
        enable = false,
        cond = not is_on_vscode(),
        init = function()
            local deno_paths = require("plugins.denops.utils").get_or_install()
            vim.g["denops#deno"] = deno_paths.bin
            vim.g["denops#deno_dir"] = deno_paths.cache
            vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }
        end,
    },
    {
        "https://github.com/yuki-yano/denops-lazy.nvim",
        enable = false,
        cond = not is_on_vscode(),
        config = function()
            require("denops-lazy").setup()
        end,
    },
}
