return {
    "https://github.com/delphinus/skkeleton_indicator.nvim",
    dependencies = {
        "https://github.com/vim-skk/skkeleton",
    },
    config = function()
        local indicator = require("skkeleton_indicator")

        indicator.setup({
            border = "none",

            alwaysShown = false,
            fadeOutMs = 2000,

            ignoreFt = {
                "TelescopePrompt",
                "lazy",
                "mason",
                "alpha",
                "dashboard",
            },
        })

        local function set_indicator_hl(group, link_target)
            vim.api.nvim_set_hl(0, group, { link = link_target, default = false })
        end

        set_indicator_hl("SkkeletonIndicatorEiji", "Comment")
        set_indicator_hl("SkkeletonIndicatorHira", "String")
        set_indicator_hl("SkkeletonIndicatorKata", "Constant")
        set_indicator_hl("SkkeletonIndicatorHankata", "Number")
        set_indicator_hl("SkkeletonIndicatorZenkaku", "Special")
        set_indicator_hl("SkkeletonIndicatorAbbrev", "Identifier")
    end,
}
