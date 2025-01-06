-- lazy.nvim の repo の設定
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    lazyrepo,
    lazypath,
  })

  -- エラーが発生したらエラ〜メッセージを表示して終了させる
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

local plugins = {
    { import = 'plugins' },
}

local opts = {
    root = vim.fn.stdpath('data') .. "/lazy",
    lockfile = vim.fn.stdpath('config') .. "/lazy-lock.json",
    concurrency = 10,
    checker = { enabled = false },
    log = { level = 'info' },
}

-- lazy.nvim のセットアップ
require('lazy').setup(plugins, opts)
