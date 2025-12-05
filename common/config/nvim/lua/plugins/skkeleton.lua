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
    init = function()
        vim.keymap.set("n", "<C-j>", "a<Plug>(skkeleton-toggle)", { noremap = true, silent = true })
        vim.keymap.set({ "i", "c", "t" }, "<C-j>", "<Plug>(skkeleton-toggle)", { noremap = true, silent = true })
    end,
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
        })
    end,
}
