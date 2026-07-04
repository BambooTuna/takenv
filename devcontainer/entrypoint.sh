#!/bin/bash
set -e

# Adjust docker group GID to match host docker socket
if [ -S /var/run/docker.sock ]; then
  DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

  # sg で再実行した2周目以降は既にこのGIDを保持しているので何もしない（無限再実行防止）
  if ! id -G | tr ' ' '\n' | grep -qx "$DOCKER_SOCK_GID"; then
    # Docker Desktop (Mac/Windows) では docker.sock が root(GID 0) 所有のことがあり、
    # その場合 groupmod -g 0 docker は既存GIDとの衝突でエラーになる。
    # 対象GIDのグループが既に存在するならそちらに参加し、無ければ従来通り docker グループのGIDを合わせる。
    EXISTING_GROUP="$(getent group "${DOCKER_SOCK_GID}" | cut -d: -f1)"
    if [ -n "$EXISTING_GROUP" ]; then
      sudo usermod -aG "$EXISTING_GROUP" "$(whoami)"
    else
      sudo groupmod -g "${DOCKER_SOCK_GID}" docker
      EXISTING_GROUP=docker
    fi
    # Re-login to apply new group membership
    # sg はコマンドを単一の文字列として受け取るため、"$0 $@" のような素朴な連結だと
    # 引数が複数ある場合に単語分割されて sg に複数の位置引数として渡り、
    # 2番目以降の引数が意図せず欠落する（`echo hello` の hello が消える等）。
    # printf %q で全体を1つの安全な文字列に畳み込んでから渡す。
    exec sg "$EXISTING_GROUP" "$(printf '%q ' "$0" "$@")"
  fi
fi

# Execute the command
exec "$@"
