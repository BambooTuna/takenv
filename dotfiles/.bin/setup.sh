#!/bin/bash

if [ "$(uname)" == "Darwin" ] ; then
  brew bundle --global
  zsh setup-asdf-plugin.zsh nodejs latest
  zsh setup-asdf-plugin.zsh fzf latest
  zsh setup-asdf-plugin.zsh neovim latest
elif [ "$(uname)" == "Linux" ] ; then
  sudo apt-get update -y

  # install asdf
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.10.2
  bash setup-asdf-plugin.bash nodejs latest
  bash setup-asdf-plugin.bash fzf latest

  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  sudo move ./nvim.appimage $HOME/bin/nvim
else
  echo "This is $(uname)"
fi

