-- junegunn/fzf は nvim 用途に加えて、シェルの fzf 本体の供給源になっている
-- (.zshrc が ~/.local/share/nvim/lazy/fzf/bin を PATH に追加している)。削除しないこと。
return {
  {
    "junegunn/fzf",
    build = "./install --bin",
  },
  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
  },
}
