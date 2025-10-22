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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo -u devuser zsh "${SCRIPT_DIR}/devuser-setup.zsh"
