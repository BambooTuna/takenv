source $HOME/.rc

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
shopt -u histappend


# git
prompt_git() {
  local branchName='';
  # ワークツリー内にいるか確認
  if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo $?) == '0' ]; then

    # branch名、またはhashの短縮表記を取得
    branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
      git rev-parse --short HEAD 2> /dev/null || \
      echo '(unknown)')";

    echo -e "${branchName}";
  else
    return;
  fi;
}

PS1="\e[32m\u@\h:\e[34m\w]\e[36m[\$(prompt_git)]\n\e[0m\$ "


# asdf
. $HOME/.asdf/asdf.sh

