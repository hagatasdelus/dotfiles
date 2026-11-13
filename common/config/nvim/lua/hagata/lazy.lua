local M = {}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

function M.install()
    if vim.uv.fs_stat(lazypath) then
        return
    end

    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })

    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

function M.setup()
    M.install()
    vim.opt.runtimepath:prepend(lazypath)

    require("lazy").setup({
        defaults = { lazy = true },
        spec = { { import = "plugins" } },
        concurrency = 10,
        dev = { path = "~/ghq/github.com/hagatasdelus/" },
        install = { missing = true, colorscheme = { "backpack" } },
        checker = { enabled = false },
        performance = {
            cache = { enabled = false },
            rtp = {
                disabled_plugins = {
                    "gzip",
                    "matchparen",
                    "netrwPlugin",
                    "tarPlugin",
                    "tar",
                    "tohtml",
                    "tutor",
                    "zipPlugin",
                    "zip",
                },
            },
        },
    })
end

return M
