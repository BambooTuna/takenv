# shellcheck shell=bash
# takenv bootstrap — Linux (Debian/Ubuntu) 用セットアップ
#
# 最小構成用と full 構成用で共通の部品を関数として提供する。
# 呼び出し側 (bootstrap.sh / bootstrap-full.sh) で必要なものだけ組み合わせる。

# 最小構成でも必ず入れる apt パッケージ (Debian/Ubuntu)。VM/踏み台での「編集・閲覧・grep・git」ができる最小限。
# ripgrep / fd は AL2023 対応と Debian の fd-find バイナリ名問題のため mise 側に寄せた (setup_mise_minimal_tools)。
install_apt_minimal() {
  local SUDO="$1"
  log "apt パッケージ (最小)"
  $SUDO apt-get update -y
  # build-essential: mise の neovim / treesitter コンパイル用
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
    git curl wget unzip zsh build-essential ca-certificates locales gnupg \
    jq tree

  if ! locale -a 2>/dev/null | grep -qi 'ja_JP.utf8'; then
    $SUDO locale-gen ja_JP.UTF-8
    ok "ja_JP.UTF-8 ロケールを生成"
  fi
}

# 最小構成の yum/dnf 版 (Amazon Linux 2023 / RHEL / Rocky / AlmaLinux)。
# AL2023 は dnf ネイティブだが yum が dnf の symlink として同梱されている。
# ripgrep / fd は AL 標準リポジトリに無いので mise 経由 (setup_mise_minimal_tools) で入れる。
install_yum_minimal() {
  local SUDO="$1"
  log "yum/dnf パッケージ (最小)"
  # curl は install list に入れない: AL2023 は curl-minimal がデフォで入っており、
  # curl フル版とは共存不可 (--allowerasing が要る)。curl-minimal で `curl -fsSL` は動くのでそのまま使う。
  # "Development Tools" group が Debian の build-essential 相当なので gcc/gcc-c++/make を個別指定。
  $SUDO yum install -y \
    git wget unzip zsh gcc gcc-c++ make ca-certificates \
    jq tree

  if ! locale -a 2>/dev/null | grep -qi 'ja_JP.utf8'; then
    $SUDO yum install -y glibc-langpack-ja glibc-locale-source || true
    $SUDO localedef -i ja_JP -f UTF-8 ja_JP.UTF-8 || true
    ok "ja_JP.UTF-8 ロケールを生成"
  fi
}

# full 構成でだけ入れる追加 apt パッケージ (DB クライアント + Chrome/Playwright 用ライブラリ)。
install_apt_full_extras() {
  local SUDO="$1"
  log "apt パッケージ (full 追加分)"
  # python-is-python3: gcloud SDK の install.sh 等が `python` コマンドを直接呼ぶため必要
  # ffmpeg: 音声・動画処理 (mise で管理しにくい C ライブラリ塊)
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
    postgresql-client default-mysql-client python-is-python3 ffmpeg

  # Chrome for Testing (ヘッドレスブラウザ) 実行に必要な共有ライブラリ
  # Ubuntu 24.04+ は libasound2t64、22.04 系は libasound2 で提供される
  local libasound_pkg=libasound2t64
  apt-cache show libasound2t64 >/dev/null 2>&1 || libasound_pkg=libasound2
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y \
    libnss3 libnspr4 "$libasound_pkg" libgbm1 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libxfixes3 libcups2 \
    libatk1.0-0 libatk-bridge2.0-0 libpangocairo-1.0-0 libgtk-3-0 libxshmfence1 \
    fonts-noto-cjk fonts-noto-color-emoji
}

install_mise_binary() {
  log "mise"
  if command -v mise >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mise" ]; then
    ok "インストール済み"
  else
    curl -fsSL https://mise.run | sh
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

chsh_to_zsh() {
  local SUDO="$1"
  local user="$2"
  log "ログインシェルを zsh に変更"
  if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    ok "設定済み"
  elif $SUDO chsh -s "$(command -v zsh)" "$user"; then
    ok "zsh に変更しました（再ログインで反映）"
  else
    warn "chsh に失敗しました。手動で実行してください: chsh -s \$(command -v zsh)"
  fi
}

# 最小構成: apt/yum 最小 + mise 本体 + zsh 化のみ
# Debian/Ubuntu (apt) と Amazon Linux 2023 等 (yum/dnf) を自動判定する。
setup_linux_minimal() {
  local SUDO=""
  local user
  user="$(id -un)"
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"

  if command -v apt-get >/dev/null 2>&1; then
    install_apt_minimal "$SUDO"
  elif command -v yum >/dev/null 2>&1; then
    install_yum_minimal "$SUDO"
  else
    echo "apt-get / yum どちらも見つかりません。未対応の Linux ディストリビューションです。" >&2
    exit 1
  fi
  install_mise_binary
  chsh_to_zsh "$SUDO" "$user"
}

# full 構成: 最小 + DB/Playwright libs + Docker + Tailscale + SSM plugin
setup_linux_full() {
  local SUDO=""
  local user
  user="$(id -un)"
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"

  install_apt_minimal "$SUDO"
  install_apt_full_extras "$SUDO"
  install_mise_binary
  install_docker "$SUDO" "$user"
  install_tailscale
  install_ssm_plugin "$SUDO"
  chsh_to_zsh "$SUDO" "$user"
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
