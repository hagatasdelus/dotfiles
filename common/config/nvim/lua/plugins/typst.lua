---@type LazySpec
return {
    {
        "kaarmu/typst.vim",
        ft = "typst",
        -- lazy = false,
        config = function()
            vim.g.typst_pdf_view = "tdf"
        end,
    },
}
