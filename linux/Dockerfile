FROM ubuntu

# common
RUN apt-get update -y && \
  apt-get install -y \
    tar gpg \
    git \
    curl \
    wget \
    zsh \
    vim



# python
RUN apt-get install -y \
  libffi-dev zlib1g-dev libssl-dev \
  libbz2-dev libsqlite3-dev libreadline-dev

ARG HOME_DIR="/root"
ENV HOME $HOME_DIR

WORKDIR $HOME

# install neovim
# RUN apt-get install -y neovim

# install asdf
RUN git clone https://github.com/asdf-vm/asdf.git .asdf --branch v0.10.2

COPY .zshrc .zshrc
COPY .tool-versions .tool-versions
COPY setup-asdf-plugin.sh setup-asdf-plugin.sh

# SHELL ["/bin/zsh", "-c"]

RUN zsh setup-asdf-plugin.sh neovim latest
RUN zsh setup-asdf-plugin.sh fzf latest
RUN zsh setup-asdf-plugin.sh nodejs latest
# RUN zsh setup-asdf-plugin.sh python latest

COPY .vimrc .vimrc
COPY .config .config

ENTRYPOINT ["zsh"]


