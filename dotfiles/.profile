# SSM Session Manager 経由で対話 shell (bash が sh 名で起動される POSIX 互換モード) に入ったとき、
# /etc/passwd の chsh 設定は無視されて sh プロンプトのままになる。ここで zsh に切り替える。
# .bash_profile ではなく .profile なのは、sh 名で invoked された bash は .bash_profile を読まないため。
case $- in
  *i*)
    [ -x "$(command -v zsh)" ] && [ -z "$ZSH_VERSION" ] && exec zsh -l
    ;;
esac
