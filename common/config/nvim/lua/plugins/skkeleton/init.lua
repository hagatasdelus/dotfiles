return {
    {
        "https://github.com/vim-skk/skkeleton",
        event = "VeryLazy",
        dependencies = {
            "https://github.com/vim-denops/denops.vim",
            "https://github.com/delphinus/skkeleton_indicator.nvim",
        },
        cond = not is_on_vscode(),
        keys = {
            {
                "<C-j>",
                "a<Plug>(skkeleton-enable)",
                mode = "n",
                remap = true,
                silent = true,
            },
            {
                "<C-j>",
                "<Plug>(skkeleton-enable)",
                mode = { "i", "c", "t" },
                remap = true,
                silent = true,
            },
        },
        config = function()
            local function dict(ext)
                local lazy_root = require("lazy.core.config").options.root
                return vim.fs.joinpath(lazy_root, "dict", "SKK-JISYO." .. ext)
            end
            local function cache_dir(file)
                return vim.fs.joinpath(vim.fn.stdpath("cache"), file)
            end
            local azik = require("plugins.skkeleton.azik")
            azik.register()

            local function toggle_keyboard_layout()
                local current = azik.get_layout()
                local next_layout = current == "us" and "jis" or "us"
                azik.register(next_layout)
                Snacks.notify.info("Keyboard Layout: " .. next_layout:upper(), { title = "skkeleton" })
            end

            vim.keymap.set("n", "<Leader>kl", toggle_keyboard_layout, { desc = "Toggle AZIK US/JIS" })

            vim.fn["skkeleton#config"]({
                kanaTable = "azik",
                databasePath = cache_dir("skkeleton-dictionary.sqlite3"),
                sources = { "deno_kv" },
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
            })
            vim.fn["skkeleton#initialize"]()
        end,
    },
    {
        "https://github.com/delphinus/skkeleton_indicator.nvim",
        config = function()
            local indicator = require("skkeleton_indicator")

            indicator.setup({
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
    },
    {
        dir = "~/dev/ghq/github.com/hagatasdelus/skkeleton-pickers.nvim",
        lazy = false,
        dependencies = {
            "https://github.com/vim-skk/skkeleton",
        },
        config = function()
            require("skkeleton-pickers").setup()
        end,
    },
    { "https://github.com/skk-dev/dict", lazy = true },
}
