local jisyo_dir = vim.fn.expand("~/.local/share/skk")

return {
    "vim-skk/skkeleton",
    event = "InsertEnter",
    enabled = true,
    dependencies = {
        "vim-denops/denops.vim",
    },
    cond = not is_on_vscode(),
    keys = {
        {
            "<C-j>",
            "<Plug>(skkeleton-enable)",
            mode = { "i", "c" },
            desc = "Enable skkeleton",
        },
        {
            "<C-l>",
            "<Plug>(skkeleton-disable)",
            mode = { "i", "c" },
            desc = "Disable skkeleton",
        },
    },
    config = function()
        vim.fn["skkeleton#config"]({
            eggLikeNewline = true,
            globalDictionaries = {
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.L"),
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.emoji.utf8"),
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.law"),
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.propernoun"),
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.geo"),
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.station"),
                vim.fn.expand(jisyo_dir .. "/SKK-JISYO.jinmei"),
            },
            userDictionary = vim.fn.expand(jisyo_dir .. "/skk-jisyo.utf8"),
            -- completionRankFile = vim.fn.expand(jisyo_dir .. "/rank.json"),
            immediatelyCancel = false,
            immediatelyOkuriConvert = true,
            registerConvertResult = true,
        })
    end,
}
