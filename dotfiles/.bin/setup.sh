#!/bin/bash

if [ "$(uname)" == "Darwin" ] ; then
  brew bundle --global
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" nodejs latest
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" neovim latest
elif [ "$(uname)" == "Linux" ] ; then
  # install asdf
  sudo apt-get update -y || apt-get update -y
  sudo apt-get install -y zsh git curl || apt-get install -y zsh git curl
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.10.2 || echo ".asdf already installed"
  bash "$(dirname $0)/setup-asdf-plugin.bash" nodejs latest

  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  [ -e $HOME/bin/nvim ] && rm -rf $HOME/bin/nvim
  mv ./nvim.appimage $HOME/bin/nvim
else
  echo "This is $(uname)"
fi

