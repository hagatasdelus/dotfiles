return {
    {
        "https://github.com/kjuq/skkelua.nvim",
        enabled = true,
        event = "VeryLazy",
        cond = not is_on_vscode(),
        keys = {
            {
                "<C-j>",
                "a<Plug>(skkelua-enable)",
                mode = "n",
                remap = true,
                silent = true,
            },
            {
                "<C-j>",
                "<Plug>(skkelua-enable)",
                mode = { "i", "c", "t" },
                remap = true,
                silent = true,
            },
        },
        opts = function()
            local function dict(ext)
                local lazy_root = require("lazy.core.config").options.root
                return vim.fs.joinpath(lazy_root, "dict", "SKK-JISYO." .. ext)
            end

            local function cache_dir(file)
                return vim.fs.joinpath(vim.fn.stdpath("cache"), file)
            end

            local function set_indicator_hl(group, link_target)
                vim.api.nvim_set_hl(0, group, { link = link_target, default = false })
            end

            set_indicator_hl("SkkeluaIndicatorEiji", "Comment")
            set_indicator_hl("SkkeluaIndicatorHira", "String")
            set_indicator_hl("SkkeluaIndicatorKata", "Constant")
            set_indicator_hl("SkkeluaIndicatorHankata", "Number")
            set_indicator_hl("SkkeluaIndicatorZenkaku", "Special")
            set_indicator_hl("SkkeluaIndicatorAbbrev", "Identifier")

            local azik = require("plugins.skkelua.azik")
            azik.register()

            return {
                kanaTable = "azik",
                databasePath = cache_dir("skkelua-dictionary.sqlite3"),
                eggLikeNewline = true,
                globalDictionaries = {
                    dict("L"),
                    dict("emoji"),
                    dict("law"),
                    dict("propernoun"),
                    dict("geo"),
                    dict("station"),
                    dict("hukugougo"),
                    dict("jinmei"),
                    dict("fullname"),
                    dict("edict2"),
                    dict("assoc"),
                },
                completionRankFile = cache_dir("rank.json"),
                immediatelyCancel = false,
                markerHenkan = "",
                markerHenkanSelect = "",
                indicator = {
                    border = "none",
                    alwaysShown = true,
                    fadeOutMs = 2000,
                    eijiText = "A",
                    ignoreFt = {
                        "TelescopePrompt",
                        "lazy",
                        "mason",
                        "snacks_dashboard",
                        "snacks_picker_input",
                    },
                },
            }
        end,
        config = function(_, opts)
            local skkelua = require("skkelua")
            skkelua.setup(opts)
            skkelua.initialize()
        end,
    },
    { "https://github.com/skk-dev/dict", lazy = true },
}
