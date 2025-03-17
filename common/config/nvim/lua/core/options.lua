vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- lang
vim.cmd("language en_US.UTF-8") 
-- vim.cmd("language ja_JP.UTF-8")

-- File
-- vim.opt.fileencoding = "utf-8"
vim.opt.swapfile = false -- スワップファイルを作成しない
vim.opt.helplang = "ja,en"
vim.opt.hidden = true -- バッファを切り替えるときにファイルを保存しなくてもOKに

-- カーソルと表示
vim.opt.cursorline = false -- カーソルがある行を強調
-- vim.opt.cursorcolumn = true -- カーソルがある列を強調

-- クリップボード共有
vim.opt.clipboard:append({ "unnamedplus" }) -- レジスタとクリップボードを共有

-- メニューとコマンド
vim.opt.wildmenu = true -- コマンドラインで補完
vim.opt.cmdheight = 1 -- コマンドラインの表示行数
vim.opt.laststatus = 2
vim.opt.showcmd = true
vim.opt.confirm = true

-- 検索・置換え
vim.opt.hlsearch = true -- ハイライト検索を有効
vim.opt.incsearch = true -- インクリメンタルサーチを有効
vim.opt.matchtime = 1 -- 入力された文字列がマッチするまでにかかる時間

-- カラースキーム
vim.opt.termguicolors = true
vim.opt.background = "dark"

-- インデント
vim.opt.shiftwidth = 4 -- シフト幅4
vim.opt.tabstop = 4 -- タブ幅4
vim.opt.expandtab = true -- タブ文字をスペースに置き換える
vim.opt.autoindent = true -- 自動インデントを有効にする
vim.opt.smartindent = true -- インデントをスマートに調整する

-- 表示
vim.opt.number = true
vim.opt.wrap = true
vim.opt.showtabline = 2 -- タブラインを表示
vim.opt.visualbell = true -- ビープ音を表示する代わりに画面をフラッシュ
vim.opt.showmatch = true -- 対応する括弧をハイライト表示

-- インタフェース
vim.opt.winblend = 0 -- ウィンドウの不透明度
vim.opt.pumblend = 0 -- ポップアップメニューの不透明度
vim.opt.signcolumn = "yes" -- サインカラムを表示
vim.opt.splitright = true -- splitは右に表示

---- 行番号の色を変更
vim.cmd("highlight LineNr guifg=#8a70ac")

-- カーソルの形状
-- vim.o.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

-- カーソル移動
vim.opt.whichwrap = "b,s,h,l,[,],<,>,~"

-- signcolumnの優先順位（エラー/警告/ヒントの表示順）
vim.diagnostic.config({ severity_sort = true })

-- エラーの解消
vim.opt.modifiable = true
