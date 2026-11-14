return {
    {
        "https://github.com/vim-skk/skkeleton",
        event = "VeryLazy",
        dependencies = {
            "https://github.com/vim-denops/denops.vim",
            "https://github.com/delphinus/skkeleton_indicator.nvim",
            "https://hagatasdelus/skkeleton-for-pickers.nvim",
        },
        cond = not require("hagata.env").is_vscode(),
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

            local keyboard_layout = require("plugins.skkeleton.keyboard_layout")
            vim.keymap.set("n", "<Leader>kl", keyboard_layout.toggle, {
                desc = "Toggle AZIK US/JIS (Karabiner / macSKK Sync)",
            })
            vim.keymap.set("n", "<Leader>kL", keyboard_layout.sync, {
                desc = "Re-resolve keyboard layout from connected devices",
            })
            vim.api.nvim_create_user_command("KeyboardLayoutSync", keyboard_layout.sync, {
                desc = "Re-resolve keyboard layout from connected devices",
            })
            vim.api.nvim_create_user_command("KeyboardLayoutToggle", keyboard_layout.toggle, {
                desc = "Toggle keyboard layout (US/JIS)",
            })
            keyboard_layout.watch()

            vim.fn["skkeleton#config"]({
                kanaTable = "azik",
                databasePath = cache_dir("skkeleton-dictionary.sqlite3"),
                sources = { "deno_kv" },
                eggLikeNewline = true,
                globalDictionaries = vim.tbl_map(dict, {
                    "L",
                    "emoji",
                    "law",
                    "propernoun",
                    "geo",
                    "station",
                    "hukugougo",
                    "jinmei",
                    "fullname",
                    "edict2",
                    "assoc",
                }),
                completionRankFile = cache_dir("rank.json"),
                immediatelyCancel = false,
                markerHenkan = "",
                markerHenkanSelect = "",
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

            vim.iter({
                Eiji = "Comment",
                Hira = "String",
                Kata = "Constant",
                Hankata = "Number",
                Zenkaku = "Special",
                Abbrev = "Identifier",
            }):each(function(mode, link)
                vim.api.nvim_set_hl(0, "SkkeletonIndicator" .. mode, { link = link })
            end)
        end,
    },
    {
        "https://github.com/hagatasdelus/skkeleton-for-pickers.nvim",
        config = function()
            require("skkeleton-for-pickers").setup({
                telescope = { enabled = true },
                mini_pick = { enabled = true },
            })
        end,
    },
    { "https://github.com/skk-dev/dict", lazy = true },
}
