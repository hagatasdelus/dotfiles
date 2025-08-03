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
            require("typst-preview").setup({})
        end,
        init = function()
            -- local command = require("plugins.typst.command")
            -- command.setup()
            vim.api.nvim_create_user_command("TypstSetRoot", function(args)
                local root = args.args
                if root == "" then
                    root = vim.fn.getcwd()
                end
                vim.g.typst_root = root
                require("snacks.notify").info("Set Root: " .. root, { title = "Typst" })
            end, {
                nargs = "?",
            })
        end
    },

}
