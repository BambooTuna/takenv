#!/bin/bash

if [ "$(uname)" == "Darwin" ] ; then
  brew bundle --global
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" nodejs latest
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" neovim latest
  zsh "$(dirname $0)/setup-asdf-plugin.zsh" golang latest
  # go install golang.org/x/tools/gopls@latest
elif [ "$(uname)" == "Linux" ] ; then
  # pre install
  apt-get update -y
  apt-get install -y \
    zsh git curl wget peco google-cloud-sdk-gke-gcloud-auth-plugin
  chsh -s /bin/zsh "$USER"

  # install asdf
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.10.2 || echo ".asdf already installed"

  # install nvim depends nodejs
  bash "$(dirname $0)/setup-asdf-plugin.bash" nodejs latest
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  [ -e $HOME/bin/nvim ] && rm -rf $HOME/bin/nvim
  mv ./nvim.appimage $HOME/bin/nvim

  # install astronvim and config
  rm -rf ~/.config/nvim
  git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
  git clone https://github.com/BambooTuna/astronvim_config.git ~/.config/nvim/lua/user

  # install python
  apt-get install -y \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libsasl2-dev python3-dev libldap2-dev
  # bash "$(dirname $0)/setup-asdf-plugin.bash" python latest
  # python3 -m pip install jedi-language-server flake8 black

  # install terraform
  # wget https://github.com/juliosueiras/terraform-lsp/releases/download/v0.0.12/terraform-lsp_0.0.12_linux_amd64.tar.gz
  # tar -xvf terraform-lsp_0.0.12_linux_amd64.tar.gz && rm -rf terraform-lsp_0.0.12_linux_amd64.tar.gz
  # mv ./terraform-lsp $HOME/bin/terraform-lsp

  # install terraformer
  # export PROVIDER={all,google,aws,kubernetes}
  # curl -LO https://github.com/GoogleCloudPlatform/terraformer/releases/download/$(curl -s https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest | grep tag_name | cut -d '"' -f 4)/terraformer-${PROVIDER}-linux-amd64
  # chmod +x terraformer-${PROVIDER}-linux-amd64
  # mv terraformer-${PROVIDER}-linux-amd64 $HOME/bin/terraformer

  # install kubectl
  # bash "$(dirname $0)/setup-asdf-plugin.bash" kubectl latest
else
  echo "This is $(uname)"
fi

