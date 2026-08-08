# shellcheck shell=bash
# takenv bootstrap — OS 共通セットアップ (zsh / dotfiles / mise / claude / browser)

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

setup_headless_browser() {
  # Playwright ライブラリ本体は mise の [tools] で管理。ここでは chromium バイナリと
  # 対話スクリプト用の scratch ディレクトリを整える。冪等: 既に導入済みなら再DLしない。
  log "Playwright chromium (ヘッドレスブラウザ)"
  mise x -- playwright install chromium
  # ESM の `import { chromium } from 'playwright'` を任意の .mjs から通せるよう
  # scratch/node_modules/playwright を mise 管理のライブラリへ張る
  local scratch="$HOME/.cache/browser-scratch"
  local pw_lib="$HOME/.local/share/mise/installs/npm-playwright/latest/lib/node_modules/playwright"
  mkdir -p "$scratch/node_modules"
  ln -sfn "$pw_lib" "$scratch/node_modules/playwright"
}
