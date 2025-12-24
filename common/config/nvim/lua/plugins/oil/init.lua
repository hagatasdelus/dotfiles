return {
    "https://github.com/stevearc/oil.nvim",
    event = "VeryLazy",
    cmd = { "Oil" },
    dependencies = {
        "https://github.com/nvim-mini/mini.icons",
        "https://github.com/refractalize/oil-git-status.nvim",
        "https://github.com/folke/snacks.nvim",
    },
    keys = {
        {
            "<leader>nn",
            function()
                vim.cmd.Oil()
            end,
        },
    },
    init = function()
        local group = vim.api.nvim_create_augroup("OilWinbar", {})
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = group,
            pattern = "oil://*",
            callback = function()
                local winid = vim.api.nvim_get_current_win()

                if vim.w[winid].oil_prev_winbar == nil then
                    vim.w[winid].oil_prev_winbar = vim.wo[winid].winbar or ""
                end

                local buf_name = vim.api.nvim_buf_get_name(0)
                local _scheme, path = buf_name:match("^(.*://)(.*)$")
                if path then
                    local title = vim.fn.fnamemodify(path, ":~")
                    vim.wo[winid].winbar = title
                end
            end,
        })
        vim.api.nvim_create_autocmd("BufWinLeave", {
            group = group,
            pattern = "oil://*",
            callback = function()
                local winid = vim.api.nvim_get_current_win()
                if vim.w[winid].oil_prev_winbar ~= nil then
                    vim.wo[winid].winbar = vim.w[winid].oil_prev_winbar
                    vim.w[winid].oil_prev_winbar = nil
                end
            end,
        })
    end,
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
                ["gc"] = custom_actions.closeWeztermPreview,
                ["gl"] = custom_actions.tdfNext,
                ["gh"] = custom_actions.tdfPrev,
                ["gs"] = custom_actions.tdfFullScreen,
                ["gv"] = custom_actions.tdfInvert,
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
