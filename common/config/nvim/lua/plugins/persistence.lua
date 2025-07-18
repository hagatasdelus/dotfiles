return {
    "folke/persistence.nvim",
    event = { "BufReadPre" },
    keys = {
        {
            "<leader>qs",
            function()
                require("persistence").load()
            end,
            desc = "Restore Session",
        },
        {
            "<leader>qS",
            function()
                require("persistence").select()
            end,
            desc = "Select Session",
        },
        {
            "<leader>ql",
            function()
                require("persistence").load({ last = true })
            end,
            desc = "Restore Last Session",
        },
        {
            "<leader>qd",
            function()
                require("persistence").stop()
            end,
            desc = "Don't Save Current Session",
        },
    },
    config = function()
        require("persistence").setup({
            options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
        })
    end,
}
