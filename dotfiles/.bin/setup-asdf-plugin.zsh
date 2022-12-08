#!/bin/zsh

source $HOME/.zshrc

asdf plugin add $1
asdf install $1 $2
asdf global $1 $2
