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

            vim.iter({
                Eiji = "Comment",
                Hira = "String",
                Kata = "Constant",
                Hankata = "Number",
                Zenkaku = "Special",
                Abbrev = "Identifier",
            }):each(function(mode, link)
                vim.api.nvim_set_hl(0, "SkkeluaIndicator" .. mode, { link = link })
            end)

            local azik = require("plugins.skkelua.azik")
            azik.register()

            local keyboard_layout = require("plugins.skkelua.keyboard_layout")
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

            return {
                kanaTable = "azik",
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
                completionRankFile = vim.fs.joinpath(vim.fn.stdpath("cache"), "rank.json"),
                immediatelyCancel = false,
                markerHenkan = "",
                markerHenkanSelect = "",
                completion = { enabled = false }, -- 候補は nvim-cmp が表示する
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

            -- skkelua の <Tab> は direct モードで生のタブを入れるため、
            -- Neovim 本来の Tab に任せる (変換中は cmp 側で止める)。
            vim.api.nvim_create_autocmd("User", {
                group = vim.api.nvim_create_augroup("config.skkelua.cmp", { clear = true }),
                pattern = "skkelua-enable-pre",
                callback = function()
                    local keys = vim.tbl_filter(function(key)
                        return not vim.tbl_contains({ "<tab>", "<s-tab>" }, key:lower())
                    end, skkelua.get_default_mapped_keys())
                    skkelua.config({ mappedKeys = keys })
                end,
            })

            -- skkelua は選択中の項目を complete_info() から読む。
            -- nvim-cmp の選択項目を補って [辞書登録] の判定を成立させる。
            if not skkelua._cmp_vim_status then
                skkelua._cmp_vim_status = true
                local orig_vim_status = skkelua.vim_status
                skkelua.vim_status = function()
                    local status = orig_vim_status()
                    local cmp = package.loaded["cmp"]
                    if status.completeType == "cmp" and cmp and cmp.visible() then
                        local entry = cmp.get_active_entry()
                        if entry then
                            status.completeInfo.selected = 0
                            status.completeInfo.items = {
                                {
                                    user_data = {
                                        nvim = { lsp = { completion_item = entry.completion_item } },
                                    },
                                },
                            }
                        end
                    end
                    return status
                end
            end
        end,
    },
    { "https://github.com/skk-dev/dict", lazy = true },
}
