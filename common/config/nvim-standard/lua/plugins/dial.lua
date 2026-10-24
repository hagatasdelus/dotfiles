return {
    "monaqa/dial.nvim",
    keys = {
        {
            "<C-a>",
            function()
                require("dial.map").manipulate("increment", "normal")
            end,
            mode = "n",
            desc = "Dial Increment",
        },
        {
            "<C-x>",
            function()
                require("dial.map").manipulate("decrement", "normal")
            end,
            mode = "n",
            desc = "Dial Decrement",
        },
        {
            "g<C-a>",
            function()
                require("dial.map").manipulate("increment", "gnormal")
            end,
            mode = "n",
            desc = "Dial Increment(g)",
        },
        {
            "g<C-x>",
            function()
                require("dial.map").manipulate("decrement", "gnormal")
            end,
            mode = "n",
            desc = "Dial Decrement(g)",
        },
        {
            "<C-a>",
            function()
                require("dial.map").manipulate("increment", "visual")
            end,
            mode = "v",
            desc = "Dial Increment",
        },
        {
            "<C-x>",
            function()
                require("dial.map").manipulate("decrement", "visual")
            end,
            mode = "v",
            desc = "Dial Decrement",
        },
        {
            "g<C-a>",
            function()
                require("dial.map").manipulate("increment", "gvisual")
            end,
            mode = "v",
            desc = "Dial Increment(g)",
        },
        {
            "g<C-x>",
            function()
                require("dial.map").manipulate("decrement", "gvisual")
            end,
            mode = "v",
            desc = "Dial Decrement(g)",
        },
    },

    config = function()
        local augend = require("dial.augend")
        local config = require("dial.config")

        local default = {
            augend.integer.alias.decimal,
            augend.integer.alias.hex,
            augend.integer.alias.binary,
            augend.date.alias["%Y/%m/%d"],
            augend.date.alias["%Y-%m-%d"],
            augend.date.alias["%Y年%-m月%-d日(%ja)"],
            augend.date.alias["%H:%M:%S"],
            augend.date.alias["%-m/%-d"],
            augend.constant.alias.ja_weekday,
            augend.constant.alias.ja_weekday_full,
            augend.hexcolor.new({ case = "lower" }),
            augend.semver.alias.semver,
            augend.case.new({
                types = { "camelCase", "snake_case", "PascalCase", "SCREAMING_SNAKE_CASE" },
                cyclic = true,
            }),
        }

        config.augends:register_group({
            default = default,
        })

        local function with_default(extras)
            return vim.iter({ default, extras }):flatten():totable()
        end

        local function redetect_filetype()
            vim.bo.filetype = vim.bo.filetype
        end

        local bool_lower = augend.constant.alias.bool
        local andor_word = augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true })

        config.augends:on_filetype({
            lua = with_default({
                bool_lower,
                andor_word,
                augend.constant.new({ elements = { "==", "~=" }, word = false, cyclic = true }),
            }),
        })

        config.augends:on_filetype({
            markdown = with_default({
                augend.misc.alias.markdown_header,
                augend.constant.new({ elements = { "[ ]", "[-]", "[x]" }, word = false, cyclic = true }),
            }),
        })

        local js_family = with_default({
            bool_lower,
            augend.paren.alias.quote,
            augend.constant.new({ elements = { "let", "const" }, word = true, cyclic = true }),
            augend.constant.new({ elements = { "===", "!==" }, word = false, cyclic = true }),
        })
        vim.iter({
            "typescript",
            "javascript",
            "typescriptreact",
            "javascriptreact",
            "tsx",
            "jsx",
            "svelte",
            "vue",
            "astro",
        }):each(function(ft)
            config.augends:on_filetype({ [ft] = js_family })
        end)

        config.augends:on_filetype({
            python = with_default({
                augend.constant.new({ elements = { "True", "False" }, word = true, cyclic = true }),
                andor_word,
                augend.constant.new({ elements = { "in", "not in" }, word = true, cyclic = true }),
                augend.constant.new({ elements = { "is", "is not" }, word = true, cyclic = true }),
            }),
        })

        config.augends:on_filetype({
            go = with_default({
                bool_lower,
                augend.constant.new({ elements = { ":=", "=" }, word = false, cyclic = true }),
            }),
        })

        config.augends:on_filetype({
            rust = with_default({
                bool_lower,
                augend.constant.new({ elements = { "Some", "None" }, word = true, cyclic = true }),
                augend.constant.new({ elements = { "Ok", "Err" }, word = true, cyclic = true }),
            }),
        })

        config.augends:on_filetype({
            typst = with_default({
                bool_lower,
            }),
        })

        config.augends:on_filetype({
            zig = with_default({
                bool_lower,
                augend.constant.new({ elements = { "var", "const" }, word = true, cyclic = true }),
            }),
        })

        redetect_filetype()
    end,
}
