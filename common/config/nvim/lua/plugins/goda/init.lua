return {
    {
        "https://github.com/Shougo/goda-cmp.vim",
        enabled = true,
        cond = not is_on_vscode(),
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "https://github.com/Shougo/goda.vim",
            "https://github.com/Shougo/pum.vim",
        },
        config = function()
            require("plugins.goda.cmp").setup()
        end,
    },
}
