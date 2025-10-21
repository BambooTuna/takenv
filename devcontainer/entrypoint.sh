#!/bin/bash
set -e

# Adjust docker group GID to match host docker socket
if [ -S /var/run/docker.sock ]; then
  DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
  CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)

  if [ "$DOCKER_SOCK_GID" != "$CURRENT_DOCKER_GID" ]; then
    sudo groupmod -g ${DOCKER_SOCK_GID} docker
    # Re-login to apply new group membership
    exec sg docker "$0 $@"
  fi
fi

# Execute the command
exec "$@"
