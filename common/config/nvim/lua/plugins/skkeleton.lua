local jisyo_dir = vim.fn.expand("~/.local/share/skk")

return {
    "https://github.com/vim-skk/skkeleton",
    event = "InsertEnter",
    enabled = true,
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
        local db_path = jisyo_dir .. "/skkeleton.db"
        vim.fn["skkeleton#config"]({
            databasePath = db_path,
            sources = { "deno_kv" },
            eggLikeNewline = true,
            globalDictionaries = {
                jisyo_dir .. "/SKK-JISYO.L",
                jisyo_dir .. "/SKK-JISYO.emoji.utf8",
                jisyo_dir .. "/SKK-JISYO.law",
                jisyo_dir .. "/SKK-JISYO.propernoun",
                jisyo_dir .. "/SKK-JISYO.geo",
                jisyo_dir .. "/SKK-JISYO.station",
                jisyo_dir .. "/SKK-JISYO.jinmei",
            },
            -- userDictionary = vim.fn.expand(jisyo_dir .. "/skk-jisyo.utf8"),
            -- completionRankFile = vim.fn.expand(jisyo_dir .. "/rank.json"),
            immediatelyCancel = false,
            -- registerConvertResult = true,
        })
        vim.fn["skkeleton#initialize"]()
    end,
}
