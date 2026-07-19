return {
    "https://github.com/phrmendes/notes.nvim",
    cmd = { "Notes" },
    keys = {
        {
            "<Leader>nn",
            function()
                require("notes").new()
            end,
            desc = "Notes: New",
        },
        {
            "<Leader>ns",
            function()
                require("notes").search()
            end,
            desc = "Notes: Search",
        },
        {
            "<Leader>ng",
            function()
                require("notes").grep()
            end,
            desc = "Notes: Grep",
        },
        {
            "<Leader>nj",
            function()
                require("notes").journal()
            end,
            desc = "Notes: Journal",
        },
    },
    config = function()
        local snacks_picker = {
            files = function(items, dir, on_choice)
                local snacks = require("snacks")
                local picker_items = {}
                for _, path in ipairs(items) do
                    table.insert(picker_items, {
                        text = vim.fs.relative(path, dir) or path,
                        file = path,
                        value = path,
                    })
                end

                snacks.picker.pick({
                    items = picker_items,
                    title = "Notes",
                    confirm = function(picker, item)
                        picker:close()
                        if item then
                            on_choice(item.value)
                        end
                    end,
                })
            end,

            grep = function(dir, glob, on_choice)
                local snacks = require("snacks")
                snacks.picker.grep({
                    cwd = dir,
                    glob = glob,
                    title = "Search in notes",
                    confirm = function(picker, item)
                        picker:close()
                        if item then
                            local choice = item.file
                            if item.line then
                                choice = choice .. ":" .. item.line
                            end
                            on_choice(choice)
                        end
                    end,
                })
            end,
        }

        require("notes.picker").snacks = snacks_picker

        require("notes").setup({
            path = vim.fn.expand("~/dev/ghq/github.com/hagatasdelus/life/notes"),
            picker = "snacks",
            lsp = {
                marksman = { enabled = false },
                ltex_plus = { enabled = false },
            },
            journal = { title_format = "%Y-%m-%d" },
        })
    end,
}
