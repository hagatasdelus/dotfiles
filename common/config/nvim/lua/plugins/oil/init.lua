---@type LazySpec
return {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    cmd = { "Oil" },
    dependencies = {
        "echasnovski/mini.icons",
        "refractalize/oil-git-status.nvim",
        "folke/snacks.nvim",
    },
    keys = {
        {
            "<leader>e",
            function()
                vim.cmd.Oil()
            end,
        },
    },
    opts = function()
        ---@type oil.setupOpts
        return {}
    end,
    config = function(_, opts)
        require("oil").setup(opts)
        require("oil-git-status").setup()
    end,
}
