#!/bin/zsh
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

# Setup SSH for GitHub (idempotent)
echo ""
echo "🔑 Setting up SSH for GitHub..."

# Create .ssh directory if it doesn't exist
if [ ! -d ~/.ssh ]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo "  ✓ Created ~/.ssh directory"
else
  echo "  ✓ ~/.ssh directory already exists"
fi

# Generate SSH key for GitHub if it doesn't exist
SSH_KEY_PATH=~/.ssh/id_ed25519_github
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "  + Generating SSH key for GitHub..."
  ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "devuser@devcontainer"
  chmod 600 "$SSH_KEY_PATH"
  chmod 644 "${SSH_KEY_PATH}.pub"
  echo "  ✓ Generated SSH key: $SSH_KEY_PATH"
else
  echo "  ✓ SSH key already exists: $SSH_KEY_PATH"
fi

# Create SSH config if it doesn't exist
SSH_CONFIG=~/.ssh/config
if [ ! -f "$SSH_CONFIG" ]; then
  echo "  + Creating SSH config..."
  cat > "$SSH_CONFIG" <<'SSH_CONFIG_EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
SSH_CONFIG_EOF
  chmod 600 "$SSH_CONFIG"
  echo "  ✓ Created SSH config"
else
  echo "  ✓ SSH config already exists"
fi

echo "✓ SSH setup complete"
echo ""
echo "📋 Your SSH public key (copy and paste to GitHub):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat ~/.ssh/id_ed25519_github.pub
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "👉 Add it to: https://github.com/settings/ssh/new"
