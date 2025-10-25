-- config of lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })

    --  If an error occurs, display the error message and exit.
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
vim.opt.runtimepath:prepend(lazypath)

local plugins = {
    { import = "plugins" },
}

-- lazy.nvim setup
local lazy = require("lazy")
lazy.setup({
    root = vim.fn.stdpath("data") .. "lazy",
    defaults = { lazy = true },
    spec = plugins,
    concurrency = 10,
    dev = { path = "~/dev/ghq/github.com/hagatasdelus/" },
    install = { missing = true, colorscheme = { "kanagawa" } },
    checker = { enabled = false },
    performance = {
        cache = { enalbed = true },
        rtp = {
            disabled_plugins = {
                "gzip",
                -- "matchit",
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
    -- log = { level = "info" },
})
