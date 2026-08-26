#!/usr/bin/env bash
# takenv bootstrap (最小構成) — VM / 踏み台 / 迷ったらこっち
#
#   git clone https://github.com/BambooTuna/takenv.git && cd takenv && ./bootstrap.sh
#
# 入るもの: zsh + oh-my-zsh + dotfiles + mise + nvim/tmux/lazygit/ripgrep/herdr/gh + node(LazyVim用)
# 入らないもの: Docker / Tailscale / SSM plugin / Playwright / Claude Code / Codex / 各種ランタイム
#
# フル構成 (Docker やクラウド CLI 込み) が欲しくなったら ./bootstrap-full.sh を叩く。
# 最小の後にフルを重ねても冪等 (既に入ってるものはスキップ)。
#
# Mac は最小構成の実需が無いので ./bootstrap-full.sh を案内して終了する。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
SKIP_CASKS="${TAKENV_SKIP_CASKS:-0}"

# 各セットアップスクリプトを読み込む
# shellcheck source=bootstrap/common.sh
. "$REPO_DIR/bootstrap/common.sh"
# shellcheck source=bootstrap/darwin.sh
. "$REPO_DIR/bootstrap/darwin.sh"
# shellcheck source=bootstrap/linux.sh
. "$REPO_DIR/bootstrap/linux.sh"
# shellcheck source=bootstrap/shared.sh
. "$REPO_DIR/bootstrap/shared.sh"
# shellcheck source=bootstrap/manual-steps.sh
. "$REPO_DIR/bootstrap/manual-steps.sh"

main() {
  log "takenv bootstrap 最小構成 ($OS)"
  case "$OS" in
    Linux) setup_linux_minimal ;;
    Darwin)
      warn "Mac は最小構成に非対応です。フル構成で入れてください:"
      warn "  ./bootstrap-full.sh"
      exit 1
      ;;
    *) echo "未対応の OS: $OS" >&2; exit 1 ;;
  esac
  setup_zsh
  setup_dotfiles
  setup_mise_minimal_tools
  print_manual_steps_minimal
}

main "$@"
