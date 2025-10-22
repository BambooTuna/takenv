#!/bin/bash

apt-get update && apt-get install -y \
  git \
  curl \
  wget \
  zsh \
  sudo \
  ripgrep \
  postgresql-client \
  build-essential \
  unzip \
  locales \
  ca-certificates \
  tmux \
  apt-transport-https \
  gnupg \
  lsb-release \
  # Python build dependencies
  libssl-dev \
  libffi-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncurses-dev \
  liblzma-dev \
  zlib1g-dev &&
  rm -rf /var/lib/apt/lists/*

# Install docker (idempotent)
if ! command -v docker >/dev/null 2>&1; then
  # Add Docker's official GPG key
  install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
  fi

  # Add the repository to Apt sources
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

USER_UID=1000
USER_GID=1000

# Create development user with specified UID/GID (idempotent)
# If user already exists with the name 'devuser', skip creation
if ! id -u devuser >/dev/null 2>&1; then
  # Remove existing user/group if they exist with the same UID/GID
  if getent passwd ${USER_UID} >/dev/null 2>&1; then
    userdel -r $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true
  fi

  if getent group ${USER_GID} >/dev/null 2>&1; then
    existing_group=$(getent group ${USER_GID} | cut -d: -f1)
    if [ "$existing_group" != "devuser" ]; then
      groupdel "$existing_group" 2>/dev/null || true
    fi
  fi

  # Create group if it doesn't exist
  if ! getent group devuser >/dev/null 2>&1; then
    groupadd -g ${USER_GID} devuser
  fi

  useradd -m -s /bin/zsh -u ${USER_UID} -g ${USER_GID} -G sudo devuser
fi

# Allow devuser to use sudo without password (idempotent)
if [ ! -f /etc/sudoers.d/devuser ]; then
  echo "devuser ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/devuser
  chmod 0440 /etc/sudoers.d/devuser
fi

# Add devuser to docker group (idempotent)
groupadd -f docker
if ! groups devuser | grep -q docker; then
  usermod -aG docker devuser
fi

# Run setup as devuser
sudo -u devuser zsh <<'EOF'
set -e

mkdir -p ~/workspace

# Install asdf (idempotent)
if [ ! -d ~/.asdf/bin ]; then
  ARCH=$(uname -m)
  case ${ARCH} in
    x86_64) ASDF_ARCH="linux-amd64" ;;
    aarch64) ASDF_ARCH="linux-arm64" ;;
    i386|i686) ASDF_ARCH="linux-386" ;;
    *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;;
  esac

  wget -q https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-${ASDF_ARCH}.tar.gz -O /tmp/asdf.tar.gz
  mkdir -p ~/.asdf/bin
  tar -xzf /tmp/asdf.tar.gz -C ~/.asdf/bin
  rm /tmp/asdf.tar.gz
fi

# Install oh-my-zsh (idempotent)
if [ ! -d ~/.oh-my-zsh ]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
fi

# Install oh-my-zsh plugins (idempotent)
if [ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
fi

if [ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
fi

if [ ! -d ~/workspace/BambooTuna/takenv ]; then
  git clone https://github.com/BambooTuna/takenv.git ~/workspace/BambooTuna/takenv
fi

cd ~/workspace/BambooTuna/takenv && make clean && make setup

# Source .zshrc to load asdf configuration
source ~/.zshrc

# Define asdf tools and versions
typeset -A asdf_tools=(
  neovim "0.11.4"
  lazygit "0.55.1"
  python "3.12.8"
  nodejs "24.10.0"
)

# Add plugins in parallel (idempotent)
echo "📦 Adding asdf plugins..."
for tool in "${(@k)asdf_tools}"; do
  (
    if asdf plugin list | grep -q "^${tool}$"; then
      echo "  ✓ Plugin $tool already exists"
    else
      echo "  + Adding plugin $tool..."
      asdf plugin add "$tool" && echo "  ✓ Added plugin $tool"
    fi
  ) &
done
wait
echo "✓ All plugins added"

# Install tools in parallel (idempotent)
echo ""
echo "⚙️  Installing asdf tools..."
for tool in "${(@k)asdf_tools}"; do
  (
    if asdf list "$tool" 2>/dev/null | grep -q "${asdf_tools[$tool]}"; then
      echo "  ✓ $tool ${asdf_tools[$tool]} already installed"
    else
      echo "  + Installing $tool ${asdf_tools[$tool]}..."
      asdf install "$tool" "${asdf_tools[$tool]}" && echo "  ✓ Installed $tool ${asdf_tools[$tool]}"
    fi
  ) &
done
wait
echo "✓ All tools installed"

# Set global versions
echo ""
echo "🔧 Setting global versions..."
for tool in "${(@k)asdf_tools}"; do
  echo "  + Setting $tool to ${asdf_tools[$tool]}..."
  asdf set -u "$tool" "${asdf_tools[$tool]}" && echo "  ✓ Set $tool to ${asdf_tools[$tool]}"
done
echo "✓ All versions set"

EOF
