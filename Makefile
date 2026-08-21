.DEFAULT_GOAL := help
.PHONY: link unlink doctor tailscale-up gpu-setup btop-gpu up help sync-codex-skills

# リンク定義: <リンク先>:<リポジトリ内の相対パス>
# herdr/mise はディレクトリにログ・認証情報等も置かれるため設定ファイルのみリンクする
# .claude / .codex は丸ごとリンクし、実行時データは各配下の .gitignore で除外する
# .agents は SKILL.md 群の正本置き場（Claude / Codex 双方から参照される）
DOTFILES := \
	$(HOME)/.zshrc:dotfiles/.zshrc \
	$(HOME)/.rc:dotfiles/.rc \
	$(HOME)/.gitconfig:dotfiles/.gitconfig \
	$(HOME)/.tmux.conf:dotfiles/.tmux.conf \
	$(HOME)/.config/nvim:dotfiles/.config/nvim \
	$(HOME)/.config/wezterm:dotfiles/.config/wezterm \
	$(HOME)/.config/karabiner:dotfiles/.config/karabiner \
	$(HOME)/.config/cli-proxy-api:dotfiles/.config/cli-proxy-api \
	$(HOME)/.ssh/config:dotfiles/.ssh/config \
	$(HOME)/.config/herdr/config.toml:dotfiles/.config/herdr/config.toml \
	$(HOME)/.config/mise/config.toml:dotfiles/.config/mise/config.toml \
	$(HOME)/.agents:dotfiles/.agents \
	$(HOME)/.claude:dotfiles/.claude \
	$(HOME)/.codex:dotfiles/.codex \
	$(HOME)/.gogcli:dotfiles/.gogcli \
	$(HOME)/.local/bin/osc52-yank:dotfiles/bin/osc52-yank \
	$(HOME)/.local/bin/serve:dotfiles/bin/tailserve \
	$(HOME)/.local/bin/dropserve:dotfiles/bin/tailserve \
	$(HOME)/.local/bin/fwd:dotfiles/bin/fwd \
	$(HOME)/.local/bin/killport:dotfiles/bin/killport \
	$(HOME)/.local/bin/pcpow:dotfiles/bin/pcpow

# 環境変数 TAKENV_LINK_BACKUP=1 で既存ファイルを .bak に退避してリンクを張る（bootstrap.sh が使用）
link:
	@mkdir -p ~/.config/herdr ~/.config/mise ~/.local/bin ~/.ssh
	@chmod 700 ~/.ssh
	@for pair in $(DOTFILES); do \
		dst="$${pair%%:*}"; src="$(PWD)/$${pair##*:}"; \
		if [ -L "$$dst" ] && [ "$$(readlink "$$dst")" = "$$src" ]; then \
			echo "✓ $$dst はリンク済みです"; \
		elif [ -e "$$dst" ] || [ -L "$$dst" ]; then \
			if [ -n "$$TAKENV_LINK_BACKUP" ]; then \
				mv "$$dst" "$$dst.bak" && ln -s "$$src" "$$dst" && echo "✓ $$dst を作成しました（既存は $$dst.bak に退避）"; \
			else \
				echo "⚠️  $$dst に既存のファイルがあります。退避して再実行してください: mv $$dst $$dst.bak"; \
			fi; \
		else \
			ln -s "$$src" "$$dst" && echo "✓ $$dst を作成しました"; \
		fi; \
	done

# dotfiles/.agents/skills/ 配下の各 skill を Codex 側からも見えるように per-skill symlink を張る。
# Claude Code は dotfiles/.claude/skills が ../.agents/skills への dir symlink なので追加作業は不要。
# Codex は skills/ 直下に .system/ という配布物があり dir 丸ごとリンクにできないので個別リンクにする。
sync-codex-skills:
	@codex_dir="dotfiles/.codex/skills"; \
	mkdir -p "$$codex_dir"; \
	for skill_dir in dotfiles/.agents/skills/*/; do \
		[ -d "$$skill_dir" ] || continue; \
		name=$$(basename "$$skill_dir"); \
		dst="$$codex_dir/$$name"; \
		target="../../.agents/skills/$$name"; \
		if [ -L "$$dst" ] && [ "$$(readlink "$$dst")" = "$$target" ]; then \
			echo "✓ $$dst はリンク済みです"; \
		elif [ -e "$$dst" ] || [ -L "$$dst" ]; then \
			echo "⚠️  $$dst に別物があります。手動で確認してください"; \
		else \
			ln -s "$$target" "$$dst" && echo "✓ $$dst を作成しました"; \
		fi; \
	done

# シンボリックリンクのみ削除する（実ファイルには触れない）
unlink:
	@for pair in $(DOTFILES); do \
		dst="$${pair%%:*}"; \
		if [ -L "$$dst" ]; then rm "$$dst" && echo "✓ $$dst を削除しました"; fi; \
	done

# 環境の健全性チェック（CI でも使用。問題があれば非ゼロ終了）
doctor:
	@status=0; \
	echo "== dotfiles リンク =="; \
	for pair in $(DOTFILES); do \
		dst="$${pair%%:*}"; src="$(PWD)/$${pair##*:}"; \
		if [ -L "$$dst" ] && [ "$$(readlink "$$dst")" = "$$src" ]; then \
			echo "  ✓ $$dst"; \
		else \
			echo "  ✗ $$dst が未リンクです"; status=1; \
		fi; \
	done; \
	echo "== 必須コマンド =="; \
	export PATH="$$HOME/.local/bin:$$PATH"; \
	for cmd in zsh git mise nvim lazygit herdr claude codex; do \
		if command -v "$$cmd" >/dev/null 2>&1 || mise which "$$cmd" >/dev/null 2>&1; then \
			echo "  ✓ $$cmd"; \
		else \
			echo "  ✗ $$cmd が見つかりません"; status=1; \
		fi; \
	done; \
	echo "== mise =="; \
	if mise ls 2>/dev/null | grep -q missing; then \
		echo "  ✗ 未インストールのツールがあります (mise install で導入):"; \
		mise ls | grep missing | sed 's/^/    /'; status=1; \
	else \
		echo "  ✓ 宣言済みツールはすべて導入済みです"; \
	fi; \
	if [ "$$(uname -s)" = "Darwin" ]; then \
		echo "== Homebrew =="; \
		if [ "$$TAKENV_SKIP_CASKS" = "1" ]; then \
			echo "  - cask はスキップ対象のためチェックしません"; \
		elif HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --file=Brewfile >/dev/null 2>&1; then \
			echo "  ✓ Brewfile はすべて導入済みです"; \
		else \
			echo "  ✗ Brewfile に未導入があります (brew bundle で導入):"; \
			HOMEBREW_BUNDLE_NO_UPGRADE=1 brew bundle check --file=Brewfile --verbose 2>/dev/null | sed 's/^/    /' || true; status=1; \
		fi; \
	fi; \
	exit $$status

# Tailscale に参加する（Linux は SSH 受付も有効化し、Mac から herdr --remote で接続できる）
# 認証はブラウザで対話的に行うため bootstrap には含めない
tailscale-up:
	@if ! command -v tailscale >/dev/null 2>&1; then \
		echo "✗ tailscale が見つかりません。先に ./bootstrap.sh を実行してください"; exit 1; \
	fi
	@if [ "$$(uname -s)" = "Linux" ]; then \
		sudo tailscale up --ssh; \
	else \
		tailscale up; \
	fi
	@tailscale status

# NVIDIA GPU をコンテナから使えるようにする（NVIDIA Container Toolkit の導入と docker 連携設定）。
# GPU の有無はマシン依存のため bootstrap には含めず、必要なマシンでだけ手動実行する。
gpu-setup:
	@./scripts/gpu-setup

# btop の GPU 対応版 (apt 版) だけを入れ直す。gpu-setup と違い docker daemon には触らないので、
# GPU で動いている処理やコンテナに影響なく実行できる。
# 背景: mise 経由の btop は musl 静的リンクで GPU_SUPPORT=false 固定のため、bootstrap.sh の
# `mise install` が走ると CPU 版が復活して PATH で apt 版に勝ってしまう。都度この target で戻す。
btop-gpu:
	@sudo apt-get install -y btop
	@sudo rm -f /usr/local/bin/btop
	@command -v mise >/dev/null 2>&1 && mise uninstall btop >/dev/null 2>&1 || true
	@btop --version | head -1

# 普段起動しておきたい常駐サービスを foreground で一括起動する。
# 各サービスは背景ジョブとして走り、ログはこの端末にまとめて流れる。
# Ctrl+C ですべて止まる。追加するサービスは scripts/up の下部に1行足す。
up:
	@./scripts/up

help:
	@echo "takenv — 開発環境構築リポジトリ"
	@echo ""
	@echo "  ./bootstrap.sh   ゼロ状態からの一括セットアップ（OS自動判別・冪等）"
	@echo ""
	@echo "セットアップ・診断:"
	@echo "  make link    - dotfiles のシンボリックリンクを作成"
	@echo "  make unlink  - dotfiles のシンボリックリンクを削除（リンクのみ・実ファイルは残る）"
	@echo "  make doctor  - 環境の健全性チェック"
	@echo "  make sync-codex-skills - dotfiles/.agents/skills/ の新規 skill を Codex 側からも見えるようにリンクする"
	@echo "  make tailscale-up - Tailscale に参加（Linux は --ssh 付きで SSH 受付も有効化）"
	@echo ""
	@echo "オプション（マシン依存で bootstrap から切り出したもの）:"
	@echo "  make gpu-setup - NVIDIA GPU をコンテナ／btop から使えるようにする（Container Toolkit + docker 連携 + btop GPU 表示）"
	@echo "  make btop-gpu  - btop の GPU 対応版 (apt 版) だけを入れ直す（docker には触らない）"
	@echo ""
	@echo "常駐サービス:"
	@echo "  make up      - 普段起動しておきたい常駐サービスを foreground で一括起動 (Ctrl+C で全停止)"
	@echo "                 サービス追加は scripts/up に1行足す"
	@echo ""
	@echo "別プロジェクト:"
	@echo "  irodori-tts/ - zero-shot voice cloning + 音声分解パイプライン。make -C irodori-tts help"
	@echo ""
	@echo "  make help    - このヘルプを表示"
