source $HOME/.rc

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# 直前のコマンドの重複を削除
setopt hist_ignore_dups

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# 同時に起動したzshの間でヒストリを共有
setopt share_history

# 時間表記の追加
setopt extended_history
alias history='history -t "%F %T"'

# コマンドのスペルを訂正
setopt correct
# ビープ音を鳴らさない
setopt no_beep

# ディレクトリスタック
DIRSTACKSIZE=100
setopt AUTO_PUSHD

# alias
alias rshell=exec $SHELL -l

# autocompletion
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="af-magic"
plugins=(
  asdf
  git
  vi-mode
  zsh-syntax-highlighting
  zsh-autosuggestions
  timer
)
source $ZSH/oh-my-zsh.sh


## fzf
export PATH="$PATH:$HOME/.local/share/nvim/lazy/fzf/bin"
[ -f $HOME/.local/share/nvim/lazy/fzf/shell/completion.zsh ] && source $HOME/.local/share/nvim/lazy/fzf/shell/completion.zsh
[ -f $HOME/.local/share/nvim/lazy/fzf/shell/key-bindings.zsh ] && source $HOME/.local/share/nvim/lazy/fzf/shell/key-bindings.zsh


[ -f $HOME/.zshrc_`uname` ] && . $HOME/.zshrc_`uname`
[ -f $HOME/.zshrc_local ] && . $HOME/.zshrc_local

# asdf
## required
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
## append completions to fpath
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
## initialise completions with ZSH's compinit
autoload -Uz compinit && compinit


# export GOOGLE_CLOUD_PROJECT="bak-pj"

# pnpm
export PNPM_HOME="$HOME/.pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
