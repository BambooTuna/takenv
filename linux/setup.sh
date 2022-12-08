#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y zsh vim

# install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

.zshrc ~/.zshrc

zsh setup-asdf-plugin.sh neovim latest
zsh setup-asdf-plugin.sh fzf latest
zsh setup-asdf-plugin.sh nodejs latest

cp .vimrc ~/.vimrc
cp -r .config ~/
