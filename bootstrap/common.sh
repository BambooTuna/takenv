# shellcheck shell=bash
# takenv bootstrap — 共通ユーティリティと定数
# 直接実行せず、bootstrap.sh から source される前提。

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m⚠\033[0m %s\n' "$*"; }
