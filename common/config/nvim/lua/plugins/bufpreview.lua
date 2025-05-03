return {
    "kat0h/bufpreview.vim",
    cond = not use_in_vscode(),
    build = "deno task prepare",
    ft = {
        "markdown",
    },
    dependencies = {
        "vim-denops/denops.vim",
    },
}
