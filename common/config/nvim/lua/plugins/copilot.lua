return {
    {
        "github/copilot.vim",
        enabled = false,
        dependencies = {
            { "hrsh7th/cmp-copilot" },
        },
        cmd = { "Copilot" },
        event = { "InsertEnter", "VeryLazy" },
    },
}
