set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc


"----------------------------------------
" SyntaxHighlight: treesitter
"---------------------------------------- 
if has('lua')
lua <<EOF
 require('nvim-treesitter.configs').setup {
   ensure_installed = {
     "json",
     "go",
     "dart",
     "javascript",
     "typescript",
     "tsx",
   },
   sync_install = false,
   auto_install = true,
   highlight = {
     enable = true,
   },
 }
EOF
endif



