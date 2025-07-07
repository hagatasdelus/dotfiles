return {
    {
        "github/copilot.vim",
        enabled = false,
        cond = not is_on_vscode(),
        dependencies = {
            { "hrsh7th/cmp-copilot" },
        },
        cmd = { "Copilot" },
        event = { "InsertEnter", "VeryLazy" },
    },
    {
        "zbirenbaum/copilot.lua",
        enabled = true,
        cond = not is_on_vscode(),
        cmd = { "Copilot" },
        event = { "InsertEnter", "VeryLazy" },
        dependencies = {
            { "zbirenbaum/copilot-cmp" },
        },
        config = function()
            require("copilot").setup({
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = "<C-g><C-g>",
                        dismiss = "<C-e>",
                        accept_word = false,
                        accept_line = false,
                        next = "<C-n>",
                        prev = "<C-m>",
                    },
                },
                panel = {
                    -- enabled = false,
                    auto_refresh = true,
                    layout = {
                        position = "right",
                    },
                    keymap = {
                        jump_prev = "_",
                        jump_next = "-",
                        accept = "<CR>",
                        refresh = false,
                        open = "<C-S-CR>",
                    },
                },
                copilot_node_command = "node",
                filetypes = {
                    yaml = true,
                    markdown = true,
                    help = false,
                    gitcommit = true,
                    gitrebase = true,
                    hgcommit = false,
                    svn = false,
                    cvs = false,
                    ["."] = false,
                    ["*"] = true,
                },
            })
        end,
    },
}
