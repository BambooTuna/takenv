# shellcheck shell=bash
# takenv bootstrap — macOS 用セットアップ

setup_darwin() {
  log "Homebrew"
  if command -v brew >/dev/null 2>&1; then
    ok "インストール済み"
  else
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # PATH が通っていないシェル（初回）でも使えるようにする
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  log "brew bundle (Brewfile)"
  local brewfile="$REPO_DIR/Brewfile"
  if [ "$SKIP_CASKS" = "1" ]; then
    warn "TAKENV_SKIP_CASKS=1: cask をスキップします"
    brewfile="$(mktemp)"
    grep -v '^cask ' "$REPO_DIR/Brewfile" > "$brewfile"
  fi
  # 導入済みツールの意図しないアップグレードはしない（更新は明示的に brew upgrade で行う）
  export HOMEBREW_BUNDLE_NO_UPGRADE=1
  if brew bundle check --file="$brewfile" >/dev/null 2>&1; then
    ok "すべて導入済み"
  else
    brew bundle --file="$brewfile"
  fi
}
