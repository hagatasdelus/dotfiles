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
    event = { "BufReadPre", "BufNewFile" },
    cond = not use_in_vscode(),
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
