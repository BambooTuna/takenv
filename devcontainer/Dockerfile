FROM ubuntu:24.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
  LANG=ja_JP.UTF-8 \
  TZ=Asia/Tokyo

# Install basic packages
RUN apt-get update && apt-get install -y \
  git \
  curl \
  wget \
  zsh \
  sudo \
  ripgrep \
  build-essential \
  unzip \
  locales \
  ca-certificates \
  tmux \
  # Python build dependencies
  libssl-dev \
  libffi-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncurses-dev \
  liblzma-dev \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# Setup locale
RUN locale-gen ja_JP.UTF-8

# Create development user
RUN useradd -m -s /bin/zsh -G sudo devuser

# Allow devuser to use sudo without password
RUN echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
  chmod 0440 /etc/sudoers.d/devuser

USER devuser
WORKDIR /home/devuser

# Install asdf v0.18.0
RUN ARCH=$(uname -m) && \
  case ${ARCH} in \
  x86_64) ASDF_ARCH="linux-amd64" ;; \
  aarch64) ASDF_ARCH="linux-arm64" ;; \
  i386|i686) ASDF_ARCH="linux-386" ;; \
  *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
  esac && \
  wget -q https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-${ASDF_ARCH}.tar.gz -O /tmp/asdf.tar.gz && \
  mkdir -p ~/.asdf/bin && \
  tar -xzf /tmp/asdf.tar.gz -C ~/.asdf/bin && \
  rm /tmp/asdf.tar.gz

# Setup asdf environment variables
ENV PATH="/home/devuser/.asdf/shims:/home/devuser/.asdf/bin:${PATH}" \
  ASDF_DATA_DIR="/home/devuser/.asdf"

# Install oh-my-zsh
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

# Install oh-my-zsh plugins
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting && \
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions

# Copy repository
COPY --chown=devuser:devuser . /home/devuser/takenv

# Setup dotfiles
WORKDIR /home/devuser/takenv
RUN make setup

# Setup asdf completion
RUN mkdir -p "${ASDF_DATA_DIR}/completions" && \
  ~/.asdf/bin/asdf completion zsh > "${ASDF_DATA_DIR}/completions/_asdf"

# Install neovim
RUN asdf plugin add neovim && \
  asdf install neovim 0.11.4 && \
  asdf set -u neovim 0.11.4

# Install lazygit
RUN asdf plugin add lazygit && \
  asdf install lazygit 0.55.1 && \
  asdf set -u lazygit 0.55.1

# Install python
RUN asdf plugin add python && \
  asdf install python 3.12.8 && \
  asdf set -u python 3.12.8

# Install node
RUN asdf plugin add nodejs && \
  asdf install nodejs 24.10.0 && \
  asdf set -u nodejs 24.10.0

# Install pm2
RUN npm install -g pm2 @anthropic-ai/claude-code

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/zsh"]
