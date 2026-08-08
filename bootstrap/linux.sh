# shellcheck shell=bash
# takenv bootstrap — Linux (Debian/Ubuntu) 用セットアップ

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

  # Chrome for Testing (ヘッドレスブラウザ) 実行に必要な共有ライブラリ
  # Ubuntu 24.04+ は libasound2t64、22.04 系は libasound2 で提供される
  local libasound_pkg=libasound2t64
  apt-cache show libasound2t64 >/dev/null 2>&1 || libasound_pkg=libasound2
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
    libnss3 libnspr4 "$libasound_pkg" libgbm1 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libxfixes3 libcups2 \
    libatk1.0-0 libatk-bridge2.0-0 libpangocairo-1.0-0 libgtk-3-0 libxshmfence1 \
    fonts-noto-cjk fonts-noto-color-emoji

  log "mise"
  if command -v mise >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mise" ]; then
    ok "インストール済み"
  else
    curl -fsSL https://mise.run | sh
  fi
  export PATH="$HOME/.local/bin:$PATH"

  install_docker "$SUDO" "$user"
  install_tailscale
  install_ssm_plugin "$SUDO"

  log "ログインシェルを zsh に変更"
  if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    ok "設定済み"
  elif $SUDO chsh -s "$(command -v zsh)" "$user"; then
    ok "zsh に変更しました（再ログインで反映）"
  else
    warn "chsh に失敗しました。手動で実行してください: chsh -s \$(command -v zsh)"
  fi
}

install_docker() {
  local SUDO="$1"
  local user="$2"
  log "Docker"
  if command -v docker >/dev/null 2>&1; then
    ok "インストール済み"
    return 0
  fi

  # shellcheck source=/dev/null
  local docker_distro
  docker_distro=$(. /etc/os-release && echo "$ID")
  # shellcheck source=/dev/null
  local docker_codename
  docker_codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")

  case "$docker_distro" in
    ubuntu|debian) ;;
    *)
      warn "Docker 公式リポジトリ未対応の distro ($docker_distro) — スキップ"
      return 0
      ;;
  esac

  $SUDO install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    curl -fsSL "https://download.docker.com/linux/${docker_distro}/gpg" | $SUDO tee /etc/apt/keyrings/docker.asc >/dev/null
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc
  fi
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${docker_distro} ${docker_codename} stable" \
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
}

install_tailscale() {
  log "Tailscale"
  if command -v tailscale >/dev/null 2>&1; then
    ok "インストール済み"
  else
    # 公式スクリプトが apt repo 登録〜 systemd サービス有効化まで冪等に行う
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
}

install_ssm_plugin() {
  local SUDO="$1"
  log "AWS SSM Session Manager Plugin"
  # aws ssm start-session の実行に必要。aws CLI とは別配布 (mise/aqua は darwin のみ対応)。
  if command -v session-manager-plugin >/dev/null 2>&1; then
    ok "インストール済み"
    return 0
  fi
  local ssm_arch=""
  case "$(dpkg --print-architecture)" in
    amd64) ssm_arch=ubuntu_64bit ;;
    arm64) ssm_arch=ubuntu_arm64 ;;
    *) warn "未対応アーキ: $(dpkg --print-architecture) — 手動導入してください" ;;
  esac
  if [ -n "$ssm_arch" ]; then
    local ssm_tmp
    ssm_tmp="$(mktemp -d)"
    curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${ssm_arch}/session-manager-plugin.deb" \
      -o "$ssm_tmp/session-manager-plugin.deb"
    $SUDO dpkg -i "$ssm_tmp/session-manager-plugin.deb"
    rm -rf "$ssm_tmp"
  fi
}
