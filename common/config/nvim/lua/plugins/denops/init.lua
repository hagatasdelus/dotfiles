local env = require("hagata.env")

return {
    {
        "https://github.com/vim-denops/denops.vim",
        enabled = true,
        cond = not env.is_vscode(),
        init = function()
            local deno_paths = require("plugins.denops.utils").get_or_install("2.8.1")
            vim.g["denops#deno"] = deno_paths.bin
            vim.g["denops#deno_dir"] = deno_paths.cache
            vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }
        end,
    },
    {
        "https://github.com/yuki-yano/denops-lazy.nvim",
        enabled = true,
        cond = not env.is_vscode(),
        config = function()
            require("denops-lazy").setup()
        end,
    },
}
