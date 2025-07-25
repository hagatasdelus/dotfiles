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
    "jay-babu/mason-null-ls.nvim",
    enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    cond = not is_on_vscode(),
    cmd = "Mason",
    dependencies = {
        "williamboman/mason.nvim",
        "nvimtools/none-ls.nvim",
    },
    config = function()
        require("mason-null-ls").setup({
            automatic_setup = true,
            ensure_installed = vim.tbl_flatten({ formatters, diagnostics }),
            handlers = {},
        })
    end,
}
