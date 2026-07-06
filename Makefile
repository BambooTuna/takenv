.DEFAULT_GOAL := help
.PHONY: link unlink doctor help

# リンク定義: <リンク先>:<リポジトリ内の相対パス>
# herdr/mise/codex はディレクトリにログ・認証情報等も置かれるため設定ファイルのみリンクする
DOTFILES := \
	$(HOME)/.zshrc:dotfiles/.zshrc \
	$(HOME)/.rc:dotfiles/.rc \
	$(HOME)/.tmux.conf:dotfiles/.tmux.conf \
	$(HOME)/.config/nvim:dotfiles/.config/nvim \
	$(HOME)/.config/wezterm:dotfiles/.config/wezterm \
	$(HOME)/.config/karabiner:dotfiles/.config/karabiner \
	$(HOME)/.config/herdr/config.toml:dotfiles/.config/herdr/config.toml \
	$(HOME)/.config/mise/config.toml:dotfiles/.config/mise/config.toml \
	$(HOME)/.claude:dotfiles/.claude \
	$(HOME)/.codex/prompts:dotfiles/.codex/prompts \
	$(HOME)/.gogcli:dotfiles/.gogcli \
	$(HOME)/.local/bin/osc52-yank:dotfiles/bin/osc52-yank

# 環境変数 TAKENV_LINK_BACKUP=1 で既存ファイルを .bak に退避してリンクを張る（bootstrap.sh が使用）
link:
	@mkdir -p ~/.config/herdr ~/.config/mise ~/.codex ~/.local/bin
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

help:
	@echo "takenv — 開発環境構築リポジトリ"
	@echo ""
	@echo "  ./bootstrap.sh   ゼロ状態からの一括セットアップ（OS自動判別・冪等）"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  make link    - dotfiles のシンボリックリンクを作成"
	@echo "  make unlink  - dotfiles のシンボリックリンクを削除（リンクのみ・実ファイルは残る）"
	@echo "  make doctor  - 環境の健全性チェック"
	@echo "  make help    - このヘルプを表示"
