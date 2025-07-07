return {
    {
        "nvim-telescope/telescope.nvim",
        cond = not is_on_vscode(),
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-fzf-native.nvim",    build = "make" },
            { "nvim-telescope/telescope-live-grep-args.nvim" },
            { "nvim-telescope/telescope-symbols.nvim" },
            {
                "danielfalk/smart-open.nvim",
                dependencies = {
                    "kkharji/sqlite.lua",
                    "nvim-telescope/telescope-fzy-native.nvim",
                },
            },
        },
        cmd = { "Telescope" },
        keys = {
            {
                "<leader>ff",
                function()
                    require("telescope.builtin").find_files()
                end,
                desc = "Find Files",
            },
            {
                "<leader>fg",
                function()
                    require("telescope.builtin").live_grep()
                end,
                desc = "Live Grep",
            },
            {
                "<leader>fb",
                function()
                    require("telescope.builtin").buffers()
                end,
                desc = "Find Buffers",
            },
            {
                "<leader>fh",
                function()
                    require("telescope.builtin").help_tags()
                end,
                desc = "Help Tags",
            },
            {
                ",,",
                "<Cmd>Telescope smart_open<CR>",
                desc = "Smart Open",
            },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local themes = require("telescope.themes")
            local previewers = require("telescope.previewers")

            -- 大きなファイルのプレビューを制限
            local new_maker = function(filepath, bufnr, opts)
                opts = opts or {}
                local expand_filepath = vim.fn.expand(filepath)
                -- local async = require("plenary.async")

                local stat = vim.loop.fs_stat(expand_filepath)

                if not stat then
                    return
                end

                -- 100KB以上のファイルはプレビューしない
                if stat.size > 100000 then
                    vim.schedule(function()
                        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "File too large to preview" })
                    end)
                else
                    previewers.buffer_previewer_maker(filepath, bufnr, opts)
                end

                -- async.void(function()
                -- 	local err, stat = async.uv.fs_stat(expand_filepath)
                -- 	assert(not err, err)
                -- 	if not stat then
                -- 		return
                -- 	end
                --
                -- 	if stat.size > 100000 then
                -- 		return
                -- 	else
                -- 		return previewers.buffer_previewer_maker(filepath, bufnr, opts)
                -- 	end
                -- end)
            end

            telescope.setup({
                defaults = themes.get_dropdown({
                    file_ignore_patterns = {
                        "^.git/",
                        "^.svn/",
                        "^node_modules/",
                        "^.class$",
                    },
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--hidden",
                        "-uu",
                    },
                    layout_config = {
                        width = 0.8,
                        height = 0.8,
                        horizontal = {
                            mirror = false,
                            prompt_position = "top",
                            preview_width = 0.5,
                        },
                        vertical = {
                            mirror = false,
                            prompt_position = "top",
                            preview_height = 0.3,
                        },
                    },
                    mapping = {
                        -- insert mode
                        i = {
                            ["<C-s>"] = actions.send_selected_to_qflist + actions.open_qflist, -- 選択項目をquickfix listに送信して開く
                            ["<C-l>"] = actions.send_to_loclist + actions.open_loclist,        -- 検索結果全体をlocation listに送信して開く
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,          -- 検索結果全体をquickfix listに送信して開く
                            ["<CR>"] = function(prompt_bufnr)                                  -- Enterキーの挙動
                                require("telescope.actions").select_default(prompt_bufnr)
                                vim.cmd.stopinsert()                                           -- インサートモードを抜ける
                            end,
                        },
                        -- normal mode
                        n = {
                            ["<ESC>"] = actions.close, -- 閉じる
                            ["q"] = actions.close,     -- 閉じる
                            ["<C-s>"] = actions.send_selected_to_qflist + actions.open_qflist,
                            ["<C-l>"] = actions.send_to_loclist + actions.open_loclist,
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist, -- quickfixリストへ送信
                        },
                    },

                    prompt_prefix = "🔍 ",
                    selection_caret = "❯ ",
                    initial_mode = "insert",
                    color_devicons = true,
                    winblend = 20, -- 透明度設定

                    -- 大きなファイルのプレビュー制限
                    buffer_previewer_maker = new_maker,
                }),
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    file_browser = {
                        initial_mode = "normal",
                    },
                },
            })
            telescope.load_extension("fzf")
        end,
    },
}
