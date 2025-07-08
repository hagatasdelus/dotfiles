---@type LazySpec
return {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    cmd = { "Oil" },
    dependencies = {
        "echasnovski/mini.icons",
        "refractalize/oil-git-status.nvim",
        "folke/snacks.nvim",
    },
    keys = {
        {
            "<leader>nn",
            function()
                vim.cmd.Oil()
            end,
        },
    },
    opts = function()
        local custom_actions = require("plugins.oil.custom_actions")
        return {
            keymaps = {
                ["?"] = "actions.show_help",
                ["gx"] = "actions.open_external",
                ["<CR>"] = "actions.select",
                ["-"] = "actions.parent",
                ["<C-p>"] = "actions.preview",
                ["gp"] = custom_actions.openWithWeztermPreview,
                -- ["gv"] = custom_actions.openWithWeztermPreviewTdf,
                ["g<leader>"] = custom_actions.openWithQuickLook,
                ["<ESC>"] = "actions.close",
                ["q"] = nil,
                ["<C-l>"] = "actions.refresh",
                ["_"] = "actions.open_cwd",
                ["`"] = "actions.cd",
                ["~"] = "actions.tcd",
                ["g."] = "actions.toggle_hidden",
                ["<C-s>"] = "actions.select_vsplit",
                ["<C-h>"] = "actions.select_split",
                ["<C-t>"] = "actions.select_tab",
            },
            view_options = {
                show_hidden = true,
                is_always_hidden = function(name, _)
                    local ignore = {
                        ".DS_Store",
                    }
                    return vim.tbl_contains(ignore, name)
                end,
            },
            use_default_keymaps = false,
            delete_to_trash = true,
            experimental_watch_for_changes = false,
            win_options = {
                signcolumn = "yes:2",
            },
            preview_win = {
                update_on_cursor_moved = false,
            },
        }
    end,
    config = function(_, opts)
        require("oil").setup(opts)
        require("oil-git-status").setup()
    end,
}
