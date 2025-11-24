return {
    "https://github.com/zbirenbaum/copilot.lua",
    enabled = true,
    cond = not is_on_vscode(),
    cmd = { "Copilot" },
    event = { "InsertEnter", "VeryLazy" },
    dependencies = {
        { "https://github.com/zbirenbaum/copilot-cmp" },
    },
    config = function()
        vim.defer_fn(function()
            require("copilot").setup({
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    keymap = {
                        accept = "<C-g><C-g>",
                        dismiss = "<C-e>",
                        accept_word = false,
                        accept_line = false,
                        next = "<C-S-n>",
                        prev = "<C-S-p>",
                        -- prev = "<C-m>",
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
                        accept = "<C-y>",
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
        end, 100)

        -- local suggestion = require("copilot.suggestion")
        -- vim.on_key(function(key)
        --     if vim.fn.mode() ~= "i" then
        --         return nil
        --     end
        --     if key == "\r" and suggestion.is_visible() then
        --         suggestion.prev()
        --         return ""
        --     end
        --     return nil
        -- end)
    end,
}
