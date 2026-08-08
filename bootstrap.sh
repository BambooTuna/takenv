#!/usr/bin/env bash
# takenv bootstrap — ゼロ状態の Mac / Linux (Debian/Ubuntu) を同じ開発環境にする唯一のエントリポイント
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
  setup_headless_browser
  print_manual_steps
}

main "$@"
