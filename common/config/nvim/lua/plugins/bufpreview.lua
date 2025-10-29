return {
    "https://github.com/kat0h/bufpreview.vim",
    cond = not is_on_vscode(),
    build = "deno task prepare",
    ft = {
        "markdown",
    },
    dependencies = {
        "https://github.com/vim-denops/denops.vim",
    },
}
