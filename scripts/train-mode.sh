#!/bin/zsh
set -euo pipefail

DURATION=7200

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

cleanup() {
  log "Train mode OFF: disablesleep=0 に戻します"
  sudo pmset -a disablesleep 0
  log "Stopped"
}

trap cleanup EXIT INT TERM

log "Train mode ON"
log "duration=${DURATION}s"

sudo pmset -a disablesleep 1
log "disablesleep=1 を設定しました"

log "現在の pmset 状態確認:"
pmset -g | grep disablesleep || true

log "caffeinate 開始"
log "Ctrl+C で停止できます"

caffeinate -dimsu -t "$DURATION"

log "caffeinate が正常終了しました"
