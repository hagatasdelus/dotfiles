return {
    "https://github.com/folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    init = function()
        _G.dd = function(...)
            Snacks.debug.inspect(...)
        end
        _G.bt = function()
            Snacks.debug.backtrace()
        end
        vim.print = _G.dd

        vim.api.nvim_create_user_command("Lazygit", function()
            Snacks.lazygit()
        end, { nargs = 0 })
        vim.api.nvim_create_user_command("Bdelete", function()
            Snacks.bufdelete()
        end, { nargs = 0 })
        vim.api.nvim_create_user_command("Bdeleteall", function()
            Snacks.bufdelete.all()
        end, { nargs = 0 })
    end,
    keys = {
        {
            ",B",
            function()
                Snacks.picker.buffers()
            end,
            desc = "Buffers",
        },
        {
            ",<Space>",
            function()
                Snacks.picker.grep({ hidden = true })
            end,
            desc = "Grep",
        },
        {
            ",s",
            function()
                Snacks.picker.grep_word()
            end,
            desc = "Visual selection or word",
        },
        {
            ",f",
            function()
                Snacks.picker.files({ hidden = true })
            end,
            desc = "Find file",
        },
        {
            ",P",
            function()
                Snacks.picker.projects()
            end,
            desc = "Projects",
        },
        {
            ",g",
            function()
                Snacks.picker.git_branches()
            end,
            desc = "Git branches",
        },
        -- {
        --     ",o",
        --     function()
        --         Snacks.picker.git_log_file()
        --     end,
        --     desc = "Git Log File",
        -- },
        {
            ",p",
            function()
                Snacks.picker.commands()
            end,
            desc = "Commands",
        },
        {
            ",d",
            function()
                Snacks.picker.diagnostics()
            end,
            desc = "Diagnostics",
        },
        {
            ",D",
            function()
                Snacks.picker.diagnostics_buffer()
            end,
            desc = "Buffer Diagnostics",
        },
        {
            ",h",
            function()
                Snacks.picker.help()
            end,
            desc = "Help Pages",
        },
        {
            ",i",
            function()
                Snacks.picker.icons()
            end,
            desc = "Icons",
        },
        {
            ",j",
            function()
                Snacks.picker.jumps()
            end,
            desc = "Jumps",
        },
        {
            ",m",
            function()
                Snacks.picker.marks()
            end,
            desc = "Marks",
        },
        {
            ",l",
            function()
                Snacks.picker.lazy()
            end,
            desc = "Lazy",
        },
        {
            ",q",
            function()
                Snacks.picker.qflist()
            end,
            desc = "Quickfix List",
        },
        {
            ",r",
            function()
                Snacks.picker.resume()
            end,
            desc = "Resume",
        },
        {
            ",c",
            function()
                Snacks.picker.colorschemes()
            end,
            desc = "Colorschemes",
        },
        {
            ",k",
            function()
                Snacks.picker.keymaps()
            end,
            desc = "Keymaps",
        },
        {
            "<Leader>z",
            function()
                Snacks.zen()
            end,
            desc = "Zen",
        },
        {
            "<Leader>lg",
            function()
                Snacks.lazygit()
            end,
            desc = "Lazygit",
        },
        {
            "<Leader>ll",
            function()
                Snacks.lazygit.log()
            end,
            desc = "Lazygit Log",
        },
        {
            "<Leader>lk",
            function()
                Snacks.lazygit.log_file()
            end,
            desc = "Lazygit Log File",
        },
        {
            "<Leader>d",
            function()
                if Snacks.dim.enabled() then
                    Snacks.dim.disable()
                else
                    Snacks.dim.enable()
                end
            end,
            desc = "Toggle Dim",
        },
    },
    opts = {
        dashboard = {
            preset = {
                keys = {
                    {
                        icon = "",
                        key = "e",
                        action = "<Cmd>enew<CR>",
                        desc = "New file",
                    },
                    {
                        icon = "",
                        key = "s",
                        section = "session",
                        desc = "Restore Session",
                    },
                    {
                        icon = "",
                        key = "f",
                        action = "<Cmd>Telescope smart_open<CR>",
                        desc = "Files",
                    },
                    {
                        icon = "󰈙",
                        key = ".",
                        action = "<Cmd>Oil<CR>",
                        desc = "Explorer",
                    },
                    {
                        icon = "",
                        key = "t",
                        action = "<Cmd>ToggleTerm direction=float<CR>",
                        desc = "Terminal",
                    },
                    {
                        icon = "",
                        key = "d",
                        action = "<Cmd>EditConfig<CR>",
                        desc = "Edit Config",
                    },
                    {
                        icon = "󰒲",
                        key = "z",
                        action = "<Cmd>Lazy<CR>",
                        desc = "Lazy",
                    },
                    {
                        icon = "󰅚",
                        key = "q",
                        action = "<Cmd>qa<CR>",
                        desc = "Quit",
                    },
                },
                header = [[
/\\\\\     /\\\                                                                                
\/\\\\\\   \/\\\                                                                               
 \/\\\/\\\  \/\\\                                                 /\\\                         
  \/\\\//\\\ \/\\\     /\\\\\\\\      /\\\\\       /\\\    /\\\   \///     /\\\\\  /\\\\\      
   \/\\\\//\\\\/\\\   /\\\/////\\\   /\\\///\\\    \//\\\  /\\\     /\\\  /\\\///\\\\\///\\\   
    \/\\\ \//\\\/\\\  /\\\\\\\\\\\   /\\\  \//\\\    \//\\\/\\\     \/\\\ \/\\\ \//\\\  \/\\\  
     \/\\\  \//\\\\\\ \//\\///////   \//\\\  /\\\      \//\\\\\      \/\\\ \/\\\  \/\\\  \/\\\ 
      \/\\\   \//\\\\\  \//\\\\\\\\\\  \///\\\\\/        \//\\\       \/\\\ \/\\\  \/\\\  \/\\\
       \///     \/////    \//////////     \/////           \///        \///  \///   \///   \///]],
            },
            sections = {
                { section = "header" },
                { icon = " ", title = "Recent files", section = "recent_files", indent = 2, padding = 1 },
                { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                { section = "startup" },
            },
            autokeys = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
        },
        input = { enabled = true },
        scroll = { enabled = false },
        picker = {
            ui_select = true,
            win = {
                input = {
                    keys = {
                        ["h"] = { "toggle_hidden", mode = "n" },
                        ["<C-i>"] = { "toggle_ignored", mode = "n" },
                    },
                },
            },
            formatters = {
                file = {
                    filename_first = true,
                },
            },
        },
        bigfile = {
            enabled = true,
        },
        debug = {
            enabled = true,
        },
        lazygit = {
            enabled = true,
        },
        zen = {
            enabled = true,
        },
    },
}
