---@type LazySpec
return {
    {
        "kaarmu/typst.vim",
        enabled = false,
        ft = { "typst" },
        -- lazy = false,
        -- config = function()
        --     vim.g.typst_pdf_viewer = ""
        -- end,
    },
    {
        "chomosuke/typst-preview.nvim",
        enabled = true,
        ft = { "typst" },
        config = function()
            require("typst-preview").setup()
        end,
        init = function()
            local typst_command = require("plugins.typst.command")
            typst_command.command()
        end
    },

}
