return {
    "kat0h/bufpreview.vim",
    cond = not is_on_vscode(),
    build = "deno task prepare",
    ft = {
        "markdown",
    },
    dependencies = {
        "vim-denops/denops.vim",
    },
}
