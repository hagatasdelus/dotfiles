return {
    "https://github.com/folke/noice.nvim",
    event = "VeryLazy",
    cond = not is_on_vscode(),
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    opts = function()
        return {
            lsp = {
                overrice = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = false,
            },
        }
    end,
    config = true,
}
