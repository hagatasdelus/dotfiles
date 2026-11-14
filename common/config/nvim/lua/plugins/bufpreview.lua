return {
    "https://github.com/kat0h/bufpreview.vim",
    cond = not require("hagata.env").is_vscode(),
    build = "deno task prepare",
    ft = {
        "markdown",
    },
    dependencies = {
        "https://github.com/vim-denops/denops.vim",
    },
}
