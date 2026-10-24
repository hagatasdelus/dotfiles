return {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    branch = "main",
    event = {
        "BufRead",
        "BufNewFile",
        "InsertEnter",
    },
    build = ":TSUpdate",
    config = function()
        local install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "/treesitter")
        require("nvim-treesitter").setup({ install_dir = install_dir })
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("vim-treesitter-start", { clear = true }),
            callback = function()
                pcall(require, "nvim-treesitter")
                pcall(vim.treesitter.start)
            end,
        })
    end,
}
