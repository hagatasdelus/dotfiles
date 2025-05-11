local formatters = {
    "stylua",
    "shfmt",
    "prettier",
}

local diagnostics = {
    "yamllint",
    "selene",
}

return {
    "nvimtools/none-ls.nvim",
    requires = "nvim-lua/plenary.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cond = not use_in_vscode(),
    config = function()
        local null_ls = require("null-ls")

        -- formatters table
        local formatting_sources = {}
        for _, tool in ipairs(formatters) do
            table.insert(formatting_sources, null_ls.builtins.formatting[tool])
        end

        -- diagnostics table
        local diagnostics_sources = {}
        for _, tool in ipairs(diagnostics) do
            table.insert(diagnostics_sources, null_ls.builtins.diagnostics[tool])
        end

        -- none-ls setup
        null_ls.setup({
            diagnostics_format = "[#{m}] #{s} (#{c})",
            sources = vim.tbl_flatten({ formatting_sources, diagnostics_sources }),
        })
    end,
}
