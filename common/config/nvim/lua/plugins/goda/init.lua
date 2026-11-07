return {
    {
        "https://github.com/Shougo/goda-cmp.vim",
        enabled = true,
        cond = not is_on_vscode(),
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "https://github.com/Shougo/goda.vim",
            "https://github.com/Shougo/pum.vim",
            "https://github.com/L3MON4D3/LuaSnip",
            "https://github.com/rafamadriz/friendly-snippets",
        },
        config = function()
            require("plugins.goda.cmp").setup()
        end,
    },
}
