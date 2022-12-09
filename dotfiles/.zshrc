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


# 補完機能を有効にする
autoload -Uz compinit
compinit -u

# 補完候補を詰めて表示
setopt list_packed

# 補完候補一覧をカラー表示
autoload colors
zstyle ':completion:*' list-colors ''

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'


# コマンドのスペルを訂正
setopt correct
# ビープ音を鳴らさない
setopt no_beep

# ディレクトリスタック
DIRSTACKSIZE=100
setopt AUTO_PUSHD

# git
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{magenta}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{yellow}+"
zstyle ':vcs_info:*' formats "%F{cyan}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }

# プロンプトカスタマイズ
PROMPT='[%B%F{blue}%n@%m%f%b:%F{green}%~%f]%F{cyan}$vcs_info_msg_0_%f%F{yellow}$%f '

# alias
alias rshell=exec $SHELL -l

# path

## fzf
export PATH="$PATH:$HOME/.vim/plugged/fzf/bin"
[ -f $HOME/.vim/plugged/fzf/shell/completion.zsh ] && source $HOME/.vim/plugged/fzf/shell/completion.zsh
[ -f $HOME/.vim/plugged/fzf/shell/key-bindings.zsh ] && source $HOME/.vim/plugged/fzf/shell/key-bindings.zsh



[ -f $HOME/.zshrc_`uname` ] && . $HOME/.zshrc_`uname`
[ -f $HOME/.zshrc_local ] && . $HOME/.zshrc_local


