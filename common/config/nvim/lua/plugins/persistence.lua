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
    },
    config = function()
        require("persistence").setup({
            options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
        })
    end,
}
