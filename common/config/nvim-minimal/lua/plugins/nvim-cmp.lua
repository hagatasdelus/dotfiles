local M = {
    "https://github.com/hrsh7th/nvim-cmp",
    enabled = true,
    commit = "7d850f3",
    pin = true,
    cond = not is_on_vscode(),
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
        "https://github.com/hrsh7th/cmp-nvim-lsp",
        "https://github.com/hrsh7th/cmp-nvim-lua",
        "https://github.com/hrsh7th/cmp-buffer",
        "https://github.com/hrsh7th/cmp-path",
        "https://github.com/hrsh7th/cmp-cmdline",
        "https://github.com/f3fora/cmp-spell",
        "https://github.com/saadparwaiz1/cmp_luasnip",
        "https://github.com/L3MON4D3/LuaSnip",
        "https://github.com/rafamadriz/friendly-snippets",
    },
    config = function()
        local cmp = require("cmp")
        local types = require("cmp.types")
        local lspkind = require("lspkind")
        vim.opt.completeopt = { "menu", "menuone", "noselect" }

        -- skkelua の <expr> lmap から呼ばれると cmp.sync の vim.wait が E565 になる。
        -- 表示状態を読むだけなので同期なしにする。
        cmp.visible = function()
            return cmp.core.view:visible()
        end
        cmp.get_active_entry = function()
            return cmp.core.view:get_active_entry()
        end

        local skk = require("plugins.skkelua.cmp")
        skk.setup()

        local function is_skkelua(entry)
            return entry.source ~= nil and entry.source.name == "skkelua"
        end

        -- 変換中は skkelua の候補を先に並べる
        local function skkelua_first(a, b)
            if is_skkelua(a) ~= is_skkelua(b) then
                return is_skkelua(a)
            end
            return nil
        end

        -- 変換中はバッファを書き換えず選択だけ動かす
        local function move_selection(delta)
            local behavior = skk.active() and types.cmp.SelectBehavior.Select or types.cmp.SelectBehavior.Insert
            if not cmp.visible() then
                if skk.active() then
                    cmp.complete({ config = { sources = { { name = "skkelua" } } } })
                else
                    cmp.complete()
                end
            elseif delta > 0 then
                cmp.select_next_item({ behavior = behavior })
            else
                cmp.select_prev_item({ behavior = behavior })
            end
        end

        cmp.setup({
            formatting = {
                format = lspkind.cmp_format({
                    mode = "symbol",
                    maxwidth = 50,
                    ellipsis_char = "...",
                    before = function(entry, vim_item)
                        return vim_item
                    end,
                }),
            },
            snippet = {
                expand = function(args)
                    require("luasnip").lsp_expand(args.body)
                end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            performance = {
                debounce = 60,
                throttle = 30,
                fetching_timeout = 500,
                filtering_context_budget = 3,
                confirm_resolve_timeout = 80,
                async_budget = 1,
                -- 辞書候補が 200 件を超えると末尾の [辞書登録] が切れる
                max_view_entries = 1000,
            },
            mapping = cmp.mapping.preset.insert({
                -- 変換中は pre-edit を壊さないよう何もしない
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if skk.active() then
                        return
                    elseif cmp.visible() then
                        cmp.select_next_item({ behavior = types.cmp.SelectBehavior.Insert })
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if skk.active() then
                        return
                    elseif cmp.visible() then
                        cmp.select_prev_item({ behavior = types.cmp.SelectBehavior.Insert })
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<C-n>"] = cmp.mapping(function()
                    move_selection(1)
                end, { "i" }),
                ["<C-p>"] = cmp.mapping(function()
                    move_selection(-1)
                end, { "i" }),
                ["<Down>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        move_selection(1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<Up>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        move_selection(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-l>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping(function(fallback)
                    local entry = cmp.get_selected_entry()
                    if cmp.visible() and entry ~= nil then
                        cmp.confirm({ select = false })
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            sorting = {
                -- sources の優先度ボーナスの重み
                priority_weight = 2,
                comparators = {
                    skkelua_first,
                    cmp.config.compare.sort_text,
                    cmp.config.compare.offset,
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    cmp.config.compare.recently_used,
                    cmp.config.compare.locality,
                    cmp.config.compare.kind,
                    cmp.config.compare.length,
                    cmp.config.compare.order,
                },
            },
            sources = cmp.config.sources({
                { name = "skkelua" },
                { name = "nvim_lsp" },
                { name = "nvim_lua" },
                { name = "luasnip" }, -- For luasnip users
                -- { name = "orgmode" },
            }, {
                { name = "buffer" },
                { name = "path" },
            }),
        })
    end,
}

return M
