return {
    "https://github.com/keaising/im-select.nvim",
    cond = function()
        return not is_on_vscode() and is_on_mac() and vim.fn.executable("macism") == 1
    end,
    event = "VeryLazy",
    opts = function()
        return {
            -- default_im_select = "com.apple.keylayout.ABC",
            default_im_select = "jp.sourceforge.inputmethod.aquaskk.Ascii",
            default_command = "macism",
            set_default_events = { "InsertLeave", "CmdlineLeave" },
            set_previous_events = {},
            keep_quiet_on_no_binary = false,
            async_switch_im = true,
        }
    end,
    config = function(_, opts)
        require("im_select").setup(opts)
    end,
}
