#!/bin/bash

if [ "$(uname)" == "Darwin" ] ; then
  brew bundle --global
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" nodejs latest
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" neovim latest
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" golang latest
elif [ "$(uname)" == "Linux" ] ; then
  # install asdf
  sudo apt-get update -y || apt-get update -y
  sudo apt-get install -y zsh git curl || apt-get install -y zsh git curl wget
  sudo chsh -s /bin/zsh "$USER" || chsh -s /bin/zsh "$USER"

  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.10.2 || echo ".asdf already installed"
  bash "$(dirname $0)/setup-asdf-plugin.bash" nodejs latest

  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  [ -e $HOME/bin/nvim ] && rm -rf $HOME/bin/nvim
  mv ./nvim.appimage $HOME/bin/nvim

  wget https://github.com/juliosueiras/terraform-lsp/releases/download/v0.0.12/terraform-lsp_0.0.12_linux_amd64.tar.gz
  tar -xvf terraform-lsp_0.0.12_linux_amd64.tar.gz && rm -rf terraform-lsp_0.0.12_linux_amd64.tar.gz
  mv ./terraform-lsp $HOME/bin/terraform-lsp

  export PROVIDER={all,google,aws,kubernetes}
  curl -LO https://github.com/GoogleCloudPlatform/terraformer/releases/download/$(curl -s https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest | grep tag_name | cut -d '"' -f 4)/terraformer-${PROVIDER}-linux-amd64
  chmod +x terraformer-${PROVIDER}-linux-amd64
  mv terraformer-${PROVIDER}-linux-amd64 $HOME/bin/terraformer
else
  echo "This is $(uname)"
fi

