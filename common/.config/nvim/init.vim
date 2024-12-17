syntax on

set number
set autoindent	
set confirm
set tabstop=4
set shiftwidth=4
set expandtab
set splitright
set clipboard=unnamed
set whichwrap+=h,l,b,s,<,>,[,]
set hls

" Color
" hi Search cterm=NONE ctermfg=black ctermbg=191
" hi Visual cterm=NONE ctermfg=black ctermbg=191
" hi StatusLine term=NONE cterm=NONE ctermfg=230 ctermbg=22



" Move betwenn windows
nnoremap <Return><Return> <c-w><c-w>

cnoreabbrev tn tabnew
cnoreabbrev vs vsplit


au FileType cpp set tabstop=2
au FileType cpp set shiftwidth=2
au FileType cpp set expandtab

au FileType c set tabstop=2

au FileType c set expandtab

au FileType markdown set expandtab
au FileType markdown set expandtab
au FileType markdown set expandtab

au FileType javascript set tabstop=2
au FileType javascript set shiftwidth=2
au FileType javascript set expandtab
" au FileType javascript noremap <buffer> = :ClangFormat<cr>

au FileType typescript set tabstop=2
au FileType typescript set shiftwidth=2
au FileType typescript set expandtab
" au FileType typescript noremap <buffer> = :ClangFormat<cr>

au FileType json set tabstop=2
au FileType json set shiftwidth=2
au FileType json set expandtab
" au FileType json noremap <buffer> <c-f> :call JsonBeautify()<cr>
" au FileType json vnoremap <buffer> <c-f> :call RangeJsonBeautify()<cr>

au FileType html set tabstop=2
au FileType html set shiftwidth=2
au FileType html set expandtab
au FileType html set noautoindent
au FileType html set nocindent
au FileType html set nosmartindent
" au FileType html noremap <buffer> <c-f> :call HtmlBeautify()<cr>
" au FileType html vnoremap <buffer> <c-f> :call RangeHtmlBeautify()<cr>
