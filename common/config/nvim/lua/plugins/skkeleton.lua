return {
    {
        "https://github.com/vim-skk/skkeleton",
        event = "InsertEnter",
        enabled = false,
        dependencies = {
            "https://github.com/vim-denops/denops.vim",
            "https://github.com/delphinus/skkeleton_indicator.nvim",
        },
        cond = not is_on_vscode(),
        keys = {
            {
                "<C-j>",
                "a<Plug>(skkeleton-toggle)",
                mode = "n",
                remap = true,
                silent = true,
            },
            {
                "<C-j>",
                "<Plug>(skkeleton-toggle)",
                mode = { "i", "c", "t" },
                remap = true,
                silent = true,
            },
        },
        -- init = function()
        --     vim.keymap.set("n", "<C-j>", "a<Plug>(skkeleton-toggle)", { noremap = true, silent = true })
        --     vim.keymap.set({ "i", "c", "t" }, "<C-j>", "<Plug>(skkeleton-toggle)", { noremap = true, silent = true })
        -- end,
        config = function()
            local function dict(ext)
                local jisyo_dir = vim.fn.expand("~/.local/share/skk")
                return vim.fs.joinpath(jisyo_dir, "SKK-JISYO.", ext)
            end
            vim.fn["skkeleton#config"]({
                databasePath = vim.fs.joinpath(vim.fn.stdpath("cache") .. "skkeleton-dictionary.sqlite3"),
                sources = { "deno_kv" },
                eggLikeNewline = true,
                globalDictionaries = {
                    dict("L"),
                    dict("emoji"),
                    dict("law"),
                    dict("proeprnoun"),
                    dict("geo"),
                    dict("station"),
                    dict("jinmei"),
                },
                -- userDictionary = vim.fn.expand(jisyo_dir .. "/skk-jisyo.utf8"),
                -- completionRankFile = vim.fn.expand(jisyo_dir .. "/rank.json"),
                immediatelyCancel = false,
            })
            vim.fn["skkeleton#initialize"]()
            local debounce = require("core.utils").debounce
            local function set_input_source(source)
                if is_on_mac() and vim.fn.executable("macism") == 1 then
                    vim.system({ "macism", source }, { text = true }, function(out)
                        if out.code ~= 0 then
                            vim.schedule(function()
                                vim.notify("macism error: " .. out.stderr, vim.log.levels.ERROR)
                            end)
                        end
                    end)
                end
            end

            local switch_ime = debounce(set_input_source, 100)

            local augroup_ime = vim.api.nvim_create_augroup("augroup_ime", { clear = true })
            vim.api.nvim_create_autocmd({ "FocusGained", "VimEnter" }, {
                group = augroup_ime,
                pattern = "*",
                desc = "Set input source to ABC when Neovim gains focus",
                callback = function()
                    switch_ime("com.apple.keylayout.ABC")
                end,
            })

            vim.api.nvim_create_autocmd("FocusLost", {
                group = augroup_ime,
                pattern = "*",
                desc = "Set input source to macSKK when Neovim loses focus",
                callback = function()
                    switch_ime("net.mtgto.inputmethod.macSKK.hiragana")
                end,
            })

            vim.api.nvim_create_autocmd("VimLeave", {
                group = augroup_ime,
                pattern = "*",
                desc = "Set input source to macSKK when Neovim exits",
                callback = function()
                    if is_on_mac() and vim.fn.executable("macism") == 1 then
                        vim.system({ "macism", "net.mtgto.inputmethod.macSKK.hiragana" }):wait()
                    end
                end,
            })
        end,
    },
    {
        "https://github.com/delphinus/skkeleton_indicator.nvim",
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
}
