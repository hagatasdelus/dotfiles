return {
    "CopilotC-Nvim/CopilotChat.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- "zbirenbaum/copilot.lua",
    },
    build = "make tiktoken",
    keys = {
        { "cpc", "CopilotChat", mode = "ca" },
    },
    opts = {
        debug = true,
        chat_autocomplete = true,
        model = "gpt-4.1",
        -- model = "claude-4.0-sonnet",
    },
}
