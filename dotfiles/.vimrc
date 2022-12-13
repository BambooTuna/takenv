let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif



" ファイルを上書きする前にバックアップを作ることを無効化
set nowritebackup
" ファイルを上書きする前にバックアップを作ることを無効化
set nobackup
" vim の矩形選択で文字が無くても右へ進める
set virtualedit=block
" 挿入モードでバックスペースで削除できるようにする
set backspace=indent,eol,start
" 全角文字専用の設定
set ambiwidth=double
" wildmenuオプションを有効(vimバーからファイルを選択できる)
set wildmenu

"----------------------------------------
" 検索
"----------------------------------------
" 検索するときに大文字小文字を区別しない
set ignorecase
" 小文字で検索すると大文字と小文字を無視して検索
set smartcase
" 検索がファイル末尾まで進んだら、ファイル先頭から再び検索
set wrapscan
" インクリメンタル検索 (検索ワードの最初の文字を入力した時点で検索が開始)
set incsearch
" 検索結果をハイライト表示
set hlsearch
" esc2回で文字列検索のハイライトオフ
nmap <silent> <Esc><Esc> :<C-u>nohlsearch<CR><Esc>
"----------------------------------------
" 表示設定
"----------------------------------------
" エラーメッセージの表示時にビープを鳴らさない
set noerrorbells
" Windowsでパスの区切り文字をスラッシュで扱う
set shellslash
" 対応する括弧やブレースを表示
set showmatch matchtime=1
" インデント方法の変更
set cinoptions+=:0
" メッセージ表示欄を2行確保
set cmdheight=2
" ステータス行を常に表示
set laststatus=2
" ウィンドウの右下にまだ実行していない入力中のコマンドを表示
set showcmd
" 省略されずに表示
set display=lastline
" タブ文字を CTRL-I で表示し、行末に $ で表示する
set list
" 行末のスペースを可視化
set listchars=tab:^\ ,trail:~
" コマンドラインの履歴を10000件保存する
set history=10000
" コメントの色を水色
hi Comment ctermfg=3
" 入力モードでTabキー押下時に半角スペースを挿入
set expandtab
" インデント幅
set shiftwidth=2
" タブキー押下時に挿入される文字幅を指定
set softtabstop=2
" ファイル内にあるタブ文字の表示幅
set tabstop=2
" ツールバーを非表示にする
set guioptions-=T
" yでコピーした時にクリップボードに入る
set guioptions+=a
" メニューバーを非表示にする
set guioptions-=m
" 右スクロールバーを非表示
set guioptions+=R
" 対応する括弧を強調表示
set showmatch
" 改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set smartindent
" スワップファイルを作成しない
set noswapfile
" 検索にマッチした行以外を折りたたむ(フォールドする)機能
set nofoldenable
" タイトルを表示
set title
" 行番号の表示
set number
" ヤンクでクリップボードにコピー
set clipboard=unnamed
" Escの2回押しでハイライト消去
nnoremap <Esc><Esc> :nohlsearch<CR><ESC>
" シンタックスハイライト
syntax on
" すべての数を10進数として扱う
set nrformats=
" 行をまたいで移動
set whichwrap=b,s,h,l,<,>,[,],~
" バッファスクロール
set mouse=a
" 折り返さない
set nowrap

" auto reload .vimrc
augroup source-vimrc
  autocmd!
  autocmd BufWritePost *vimrc source $MYVIMRC | set foldmethod=marker
  autocmd BufWritePost *gvimrc if has('gui_running') source $MYGVIMRC
augroup END

" auto comment off
augroup auto_comment_off
  autocmd!
  autocmd BufEnter * setlocal formatoptions-=r
  autocmd BufEnter * setlocal formatoptions-=o
augroup END

" HTML/XML閉じタグ自動補完
augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

" 編集箇所のカーソルを記憶
if has("autocmd")
  augroup redhat
    " In text files, always limit the width of text to 78 characters
    autocmd BufRead *.txt set tw=78
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
  augroup END
endif

" モード毎にカーソルの表示方法を変更
if has('vim_starting')
    " 挿入モード時に非点滅の縦棒タイプのカーソル
    let &t_SI .= "\e[6 q"
    " ノーマルモード時に非点滅のブロックタイプのカーソル
    let &t_EI .= "\e[2 q"
    " 置換モード時に非点滅の下線タイプのカーソル
    let &t_SR .= "\e[4 q"
endif
"----------------------------------------
" カスタムキーバインド
"----------------------------------------
let mapleader = "\<Space>"

inoremap <silent> jj <ESC>

" insert mode edit
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>
inoremap <C-d> <BackSpace>
inoremap <silent> <C-b> <C-\><C-O>b
inoremap <silent> <C-w> <C-\><C-O>w
inoremap <silent> <C-e> <C-\><C-O>e
inoremap <silent> <C-p> <C-\><C-O>P


" tab
nnoremap at :<C-u>tabnew<CR>
nnoremap a] gt
nnoremap a[ gT

" window
nnoremap aj <C-w>j
nnoremap ak <C-w>k
nnoremap al <C-w>l
nnoremap ah <C-w>h
nnoremap aJ <C-w>J
nnoremap aK <C-w>K
nnoremap aL <C-w>L
nnoremap aH <C-w>H

nnoremap a<Right> <C-w>>
nnoremap a<Left> <C-w><
nnoremap a<Up> <C-w>-
nnoremap a<Down> <C-w>+

" エディタ
noremap <S-h> 0
noremap <S-l> $

" 折り返し移動(https://zenn.dev/mattn/articles/83c2d4c7645faa)
nmap gj gj<SID>g
nmap gk gk<SID>g
nnoremap <script> <SID>gj gj<SID>g
nnoremap <script> <SID>gk gk<SID>g
nmap <SID>g <Nop>

" 禁忌
noremap <Left> <Nop>
noremap <Down> <Nop>
noremap <Up> <Nop>
noremap <Right> <Nop>

inoremap <Left> <Nop>
inoremap <Down> <Nop>
inoremap <Up> <Nop>
inoremap <Right> <Nop>

"----------------------------------------
" カスタムキーマッピング
"----------------------------------------
" 削除のみ
vnoremap d "_d
nnoremap d "_d
vnoremap D "_D
nnoremap D "_D
vnoremap x "_x
nnoremap x "_x
vnoremap s "_s
nnoremap s "_s

" 切り取り(レジスタに保存)
nnoremap t d
vnoremap t x
nnoremap tt dd
nnoremap T D


"----------------------------------------
" カスタムプラグイン
"----------------------------------------
call plug#begin('~/.vim/plugged')

" 自動保存
Plug 'vim-scripts/vim-auto-save'

" コメントアウト gcc
Plug 'tpope/vim-commentary'

" 括弧
" Plug 'cohama/lexima.vim'
Plug 'terryma/vim-expand-region'

" ステータスバー
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Plug 'junegunn/fzf.vim'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/fern-git-status.vim'
Plug 'yuki-yano/fern-preview.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
Plug 'lambdalisue/glyph-palette.vim'

Plug 'lambdalisue/gina.vim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'sainnhe/gruvbox-material'

Plug 'dart-lang/dart-vim-plugin'
" let g:dart_format_on_save = 1

call plug#end()


"----------------------------------------
" Common
"----------------------------------------
" vim-auto-save
let g:auto_save = 1
let g:auto_save_no_updatetime = 1
let g:auto_save_in_insert_mode = 0
" let g:auto_save_postsave_hook = 'TagsGenerate'

" vim-expand-region
map J <Plug>(expand_region_expand)
map K <Plug>(expand_region_shrink)

"----------------------------------------
" IDE: coc.nvim
"----------------------------------------
let g:coc_global_extensions = [
      \'coc-flutter',
      \'coc-sql',
      \'coc-go',
      \'coc-rls',
      \'coc-omnisharp',
      \'coc-svelte',
      \'coc-tsserver',
      \'coc-vetur',
      \'coc-vimlsp',
      \'coc-docker',
      \'coc-markdownlint',
      \'coc-json',
      \'coc-xml',
      \'coc-yaml',
      \'coc-css',
      \'coc-cssmodules',
      \'coc-spell-checker',
      \'coc-snippets',
      \'coc-tsserver',
      \'coc-eslint',
      \'coc-prettier',
      \'coc-git',
      \'coc-fzf-preview',
      \'coc-lists',
      \'coc-lua',
      \'coc-jedi',
      \'coc-diagnostic',
      \]

" 予測変換
""" <Tab>で候補をナビゲート
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

" autocomplete
inoremap <silent><expr> <Enter> coc#pum#visible() ? coc#pum#confirm() : "\<Enter>"
inoremap <silent><expr> <Esc> coc#pum#visible() ? coc#pum#cancel() : "\<Esc>"

" <Tab>で次、<S+Tab>で前
inoremap <silent><expr> <TAB>
  \ coc#pum#visible() ? coc#pum#next(1):
  \ <SID>check_back_space() ? "\<Tab>" :
  \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<S-TAB>" " "\<C-h>"


" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')


" 定義閲覧
nnoremap <silent> K       :<C-u>call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" 定義ジャンプ
function! ChoseAction(actions) abort
  echo join(map(copy(a:actions), { _, v -> v.text }), ", ") .. ": "
  let result = getcharstr()
  let result = filter(a:actions, { _, v -> v.text =~# printf(".*\(%s\).*", result)})
  return len(result) ? result[0].value : ""
endfunction
function! CocJumpAction() abort
  let actions = [
        \ {"text": "(s)plit", "value": "split"},
        \ {"text": "(v)slit", "value": "vsplit"},
        \ {"text": "(t)ab", "value": "tabedit"},
        \ ]
  return ChoseAction(actions)
endfunction
nnoremap <silent> <C-t> :<C-u>call CocActionAsync('jumpDefinition', CocJumpAction())<CR>


"----------------------------------------
" Finder: fzf-preview
"----------------------------------------
let $BAT_THEME                     = 'gruvbox-dark'
let $FZF_PREVIEW_PREVIEW_BAT_THEME = 'gruvbox-dark'

nnoremap <silent> <C-p>  :<C-u>CocCommand fzf-preview.FromResources buffer project_mru project<CR>
nnoremap <silent> [ff]s  :<C-u>CocCommand fzf-preview.GitStatus<CR>
nnoremap <silent> [ff]gg :<C-u>CocCommand fzf-preview.GitActions<CR>
nnoremap <silent> [ff]b  :<C-u>CocCommand fzf-preview.Buffers<CR>
nnoremap          [ff]f  :<C-u>CocCommand fzf-preview.ProjectGrep --add-fzf-arg=--exact --add-fzf-arg=--no-sort<Space>
xnoremap          [ff]f  "sy:CocCommand fzf-preview.ProjectGrep --add-fzf-arg=--exact --add-fzf-arg=--no-sort<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"

nnoremap <silent> [ff]q  :<C-u>CocCommand fzf-preview.CocCurrentDiagnostics<CR>
nnoremap <silent> [ff]rf :<C-u>CocCommand fzf-preview.CocReferences<CR>
nnoremap <silent> [ff]d  :<C-u>CocCommand fzf-preview.CocDefinition<CR>
nnoremap <silent> [ff]t  :<C-u>CocCommand fzf-preview.CocTypeDefinition<CR>
nnoremap <silent> [ff]o  :<C-u>CocCommand fzf-preview.CocOutline --add-fzf-arg=--exact --add-fzf-arg=--no-sort<CR>




"----------------------------------------
" Filer: fern
"----------------------------------------

" 隠しファイルを表示
let g:fern#default_hidden=1

nnoremap <silent> <Leader>e :<C-u>Fern . -drawer<CR>
nnoremap <silent> <Leader>E :<C-u>Fern . -drawer -reveal=%<CR>

" デフォルトのキーマップを無効
let g:fern#disable_default_mappings = 1

function! FernInit() abort
  nmap <buffer> E <Plug>(fern-action-open:side)
  nmap <buffer> K <Plug>(fern-action-new-dir)
  nmap <buffer> ! <Plug>(fern-action-hidden:toggle)
  nmap <buffer> - <Plug>(fern-action-mark:toggle)
  vmap <buffer> - <Plug>(fern-action-mark:toggle)
  nmap <buffer> C <Plug>(fern-action-clipboard-copy)
  nmap <buffer> R <Plug>(fern-action-clipboard-move)
  nmap <buffer> P <Plug>(fern-action-clipboard-paste)
  nmap <buffer> h <Plug>(fern-action-collapse)
  nmap <buffer> c <Plug>(fern-action-copy)
  nmap <buffer> <leader>h <Plug>(fern-action-leave)
  nmap <buffer> m <Plug>(fern-action-move)
  nmap <buffer> N <Plug>(fern-action-new-file)
  nmap <buffer> <cr> <Plug>(fern-action-open-or-enter)
  nmap <buffer> l <Plug>(fern-action-open-or-expand)
  nmap <buffer> s <Plug>(fern-action-open:select)
  nmap <buffer> t <Plug>(fern-action-open:tabedit)
  nmap <buffer> <C-l> <Plug>(fern-action-reload)
  nmap <buffer> <BS> <Plug>(fern-action-leave)
  nmap <buffer> r <Plug>(fern-action-rename)
  nmap <buffer> i <Plug>(fern-action-reveal)
  nmap <buffer> D <Plug>(fern-action-trash)
  nmap <buffer> y <Plug>(fern-action-yank)
  nmap <buffer> gr <Plug>(fern-action-grep)
  nmap <buffer> d <Plug>(fern-action-remove)
  nmap <buffer> B <Plug>(fern-action-save-as-bookmark)
  nmap <buffer> cd <Plug>(fern-action-tcd)
  nmap <buffer> <C-h> <C-w>h
  nmap <buffer> <C-l> <C-w>l
endfunction
augroup FernEvents
  autocmd!
  autocmd FileType fern call FernInit()
augroup END

function! s:fern_settings() abort
  nmap <silent> <buffer> p     <Plug>(fern-action-preview:toggle)
  nmap <silent> <buffer> <C-p> <Plug>(fern-action-preview:auto:toggle)
  nmap <silent> <buffer> <C-d> <Plug>(fern-action-preview:scroll:down:half)
  nmap <silent> <buffer> <C-u> <Plug>(fern-action-preview:scroll:up:half)
endfunction

augroup fern-settings
  autocmd!
  autocmd FileType fern call s:fern_settings()
augroup END

" アイコン
let g:fern#renderer = 'nerdfont'
augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END

"----------------------------------------
" ColorScheme: gruvbox
"----------------------------------------
colorscheme gruvbox-material



"----------------------------------------
" Terminal
"----------------------------------------
if has('nvim')
  " Ctrl + q でターミナルを終了
  tnoremap <C-q> <C-\><C-n>:q<CR>
  " ESCでターミナルモードからノーマルモードへ
  tnoremap <Esc> <C-\><C-n>
  tnoremap jj <C-\><C-n>
  " 常にインサートモードで開く
  autocmd TermOpen * startinsert
  command! -nargs=* T split | wincmd j | resize 12 | terminal <args>
endif

