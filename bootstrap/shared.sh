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

# 最小構成: VM/踏み台で編集・閲覧に必須のツールだけ入れる。
# node は LazyVim の Mason (typescript-language-server 等) が要求するので必須枠。
# fzf は junegunn/fzf 経由で LazyVim が入れるので mise には含めない。
# ripgrep / fd は Amazon Linux 標準リポに無い + Debian の fd-find は fdfind バイナリ名になり
# LazyVim (fd を探す) と噛み合わないため、OS 非依存の mise 側で入れて統一する。
setup_mise_minimal_tools() {
  log "mise install (最小: nvim/tmux/lazygit/herdr など)"
  mise install node
  mise install neovim
  mise install tmux
  mise install lazygit
  mise install ripgrep
  mise install fd
  mise install "github:ogulcancelik/herdr"
  mise install github-cli
  ok "最小ツールを導入しました"
}

# full 構成: mise/config.toml で宣言された全ツールを入れる。
setup_mise_all_tools() {
  log "mise install (全ツール)"
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
