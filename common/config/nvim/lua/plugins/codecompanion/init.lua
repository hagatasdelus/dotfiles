---@type LazySpec
return {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    enabled = true,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "ravitemer/codecompanion-history.nvim",
    },
    keys = {
        { "<Space>cc",  "<Cmd>CodeCompanion<CR>",       mode = { "n", "v" }, desc = "CodeCompanion" },
        { "<Space>ccc", "<Cmd>CodeCompanionChat<CR>",   mode = { "n", "v" }, desc = "CodeCompanion Chat" },
        { "<Space>cca", "<Cmd>CodeCompanionAction<CR>", mode = { "n", "v" }, desc = "CodeCompanion Action" },
    },
    opts = {
        opts = {
            language = "Japanese",
        },
        adapters = {
            ollama = function()
                return require("codecompanion.adapters").extend("ollama", {
                    schema = {
                        name = "qwen2.5-coder",
                        model = {
                            default = "qwen2.5-coder:latest",
                        },
                    },
                })
            end,
            copilot = function()
                return require("codecompanion.adapters").extend("copilot", {
                    schema = {
                        model = {
                            default = "gpt-4.1",
                        },
                    },
                })
            end,
        },
        strategies = {
            chat = {
                adapter = "copilot",
                keymaps = {
                    send = {
                        modes = { n = "<C-s>", i = "<C-s>" },
                        index = 1,
                        callback = function(chat)
                            vim.cmd("stopinsert")
                            chat:add_buf_message({ role = "llm", content = "" })
                            chat:submit()
                        end,
                    },
                },
                roles = {
                    llm = function(adapter)
                        return " CodeCompanion (" .. adapter.formatted_name .. ")"
                    end,
                    user = " Me",
                },
            },
            inline = {
                adapter = "copilot",
            },
            agent = {
                adapter = "copilot",
            },
        },
        extensions = {
            history = {
                enabled = true,
            },
        },
    },
    config = function(_, opts)
        require("codecompanion").setup(opts)
    end,
    init = function()
        require("plugins.codecompanion.spinner"):init()
    end,
}
