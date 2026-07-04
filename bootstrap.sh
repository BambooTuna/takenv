#!/usr/bin/env bash
# takenv bootstrap — ゼロ状態の Mac / Ubuntu を同じ開発環境にする唯一のエントリポイント
#
#   git clone https://github.com/BambooTuna/takenv.git && cd takenv && ./bootstrap.sh
#
# 冪等: 何度実行しても安全。導入済みのステップはスキップされる。
#
# 環境変数:
#   TAKENV_SKIP_CASKS=1     GUIアプリ(cask)を入れない（CI・ヘッドレス用）
#   TAKENV_IN_CONTAINER=1   コンテナ内として扱い Docker は CLI のみ導入
#                           （docker build の RUN 中は /.dockerenv が無いため明示が必要）
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
SKIP_CASKS="${TAKENV_SKIP_CASKS:-0}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m⚠\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- macOS
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

# ---------------------------------------------------------------- Ubuntu
setup_linux() {
  local SUDO=""
  local user
  user="$(id -un)"
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"

  log "apt パッケージ"
  $SUDO apt-get update -y
  # python-is-python3: gcloud SDK の install.sh 等が `python` コマンドを直接呼ぶため必要
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
    git curl wget unzip zsh build-essential ca-certificates locales gnupg \
    jq bat tree postgresql-client default-mysql-client python-is-python3

  if ! locale -a 2>/dev/null | grep -qi 'ja_JP.utf8'; then
    $SUDO locale-gen ja_JP.UTF-8
    ok "ja_JP.UTF-8 ロケールを生成"
  fi

  log "mise"
  if command -v mise >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mise" ]; then
    ok "インストール済み"
  else
    curl -fsSL https://mise.run | sh
  fi
  export PATH="$HOME/.local/bin:$PATH"

  log "Docker"
  if command -v docker >/dev/null 2>&1; then
    ok "インストール済み"
  else
    $SUDO install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.asc ]; then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO tee /etc/apt/keyrings/docker.asc >/dev/null
      $SUDO chmod a+r /etc/apt/keyrings/docker.asc
    fi
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
      # shellcheck source=/dev/null
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
        | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi
    $SUDO apt-get update -y
    if [ -f /.dockerenv ] || [ "${TAKENV_IN_CONTAINER:-0}" = "1" ]; then
      # コンテナ内はホストの docker.sock を使うため CLI のみ
      $SUDO apt-get install -y docker-ce-cli docker-compose-plugin
    else
      $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      $SUDO usermod -aG docker "$user" || true
      warn "docker グループ反映には再ログインが必要です"
    fi
  fi

  log "ログインシェルを zsh に変更"
  if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    ok "設定済み"
  elif $SUDO chsh -s "$(command -v zsh)" "$user"; then
    ok "zsh に変更しました（再ログインで反映）"
  else
    warn "chsh に失敗しました。手動で実行してください: chsh -s \$(command -v zsh)"
  fi
}

# ---------------------------------------------------------------- 共通
setup_zsh() {
  log "oh-my-zsh"
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "インストール済み"
  else
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi

  local custom="$HOME/.oh-my-zsh/custom/plugins"
  local repo
  for repo in zsh-syntax-highlighting zsh-autosuggestions; do
    # 旧配置 (~/.oh-my-zsh/plugins) に clone 済みならそちらを尊重する
    if [ -d "$custom/$repo" ] || [ -d "$HOME/.oh-my-zsh/plugins/$repo/.git" ]; then
      ok "$repo インストール済み"
    else
      git clone --depth=1 "https://github.com/zsh-users/$repo.git" "$custom/$repo"
    fi
  done
}

setup_dotfiles() {
  log "dotfiles のシンボリックリンク (make link)"
  # bootstrap 経由では既存ファイルを .bak に退避してリンクを張る
  TAKENV_LINK_BACKUP=1 make -C "$REPO_DIR" link
}

setup_mise_tools() {
  log "mise install (ランタイム・CLIツール)"
  # npm バックエンド (codex) が node を要求するため node を先に入れる
  mise install node
  mise install
  ok "mise のツールを導入しました"
}

setup_claude_code() {
  log "Claude Code"
  if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    ok "インストール済み"
  else
    curl -fsSL https://claude.ai/install.sh | bash
  fi
}

print_manual_steps() {
  log "完了 🎉 — 残りの手動ステップ"
  cat <<'EOS'
  1. シェルを開き直す（exec zsh -l）
  2. SSH 鍵の作成と GitHub 登録: git/README.md 参照
EOS
  if [ "$OS" = "Darwin" ]; then
    cat <<'EOS'
  3. Karabiner-Elements の権限承認（初回のみ）
     - システム設定 > 一般 > ログイン項目と機能拡張 > ドライバ機能拡張 を有効化
     - システム設定 > プライバシーとセキュリティ > 入力監視 を許可
  4. cask が無い/機能しないアプリ: LINE (App Store), tldv (https://tldv.io), Amazon Music
EOS
  fi
  printf '\n  環境の健全性チェック: make doctor\n\n'
}

# ---------------------------------------------------------------- main
main() {
  log "takenv bootstrap ($OS)"
  case "$OS" in
    Darwin) setup_darwin ;;
    Linux)  setup_linux ;;
    *) echo "未対応の OS: $OS" >&2; exit 1 ;;
  esac
  setup_zsh
  setup_dotfiles
  setup_mise_tools
  setup_claude_code
  print_manual_steps
}

main "$@"
