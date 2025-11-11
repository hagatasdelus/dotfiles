local M = {
    "https://github.com/hrsh7th/nvim-cmp",
    enabled = true,
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
        "https://github.com/rinx/cmp-skkeleton",
    },
    config = function()
        local cmp = require("cmp")
        local types = require("cmp.types")
        local lspkind = require("lspkind")
        vim.opt.completeopt = { "menu", "menuone", "noselect" }

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
            mapping = cmp.mapping.preset.insert({
                -- <C-n>: down, <C-p>: up
                ["<Tab>"] = cmp.mapping.select_next_item({ behavior = types.cmp.SelectBehavior.Insert }),
                ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = types.cmp.SelectBehavior.Insert }),
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
            sources = cmp.config.sources({
                { name = "skkeleton" },
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
