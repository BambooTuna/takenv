.PHONY: setup clean setup-docker-compose help

# リンク作成: $(call link,リンク先,dotfiles内のソース)
# 既にリンク済みならスキップ、無関係な既存ファイルがある場合は警告して退避を促す
define link
	@if [ -L "$(1)" ] && [ "$$(readlink "$(1)")" = "$(2)" ]; then \
		echo "✓ $(1) はリンク済みです"; \
	elif [ -e "$(1)" ] || [ -L "$(1)" ]; then \
		echo "⚠️  $(1) に既存のファイルがあるためリンクを作成できません"; \
		echo "    削除または退避（mv $(1) $(1).bak）してから make setup を再実行してください"; \
	else \
		ln -s "$(2)" "$(1)" && echo "✓ $(1) のリンクを作成しました"; \
	fi
endef

# dotfilesセットアップ
# herdrディレクトリはログ・ソケットも置かれるためconfig.tomlのみファイル単位でリンク
setup:
	@echo "dotfilesのセットアップを開始します..."
	@mkdir -p ~/.config ~/.config/herdr ~/.local/bin
	$(call link,$(HOME)/.zshrc,$(PWD)/dotfiles/.zshrc)
	$(call link,$(HOME)/.rc,$(PWD)/dotfiles/.rc)
	$(call link,$(HOME)/.tmux.conf,$(PWD)/dotfiles/.tmux.conf)
	$(call link,$(HOME)/.config/nvim,$(PWD)/dotfiles/.config/nvim)
	$(call link,$(HOME)/.config/wezterm,$(PWD)/dotfiles/.config/wezterm)
	$(call link,$(HOME)/.config/herdr/config.toml,$(PWD)/dotfiles/.config/herdr/config.toml)
	$(call link,$(HOME)/.claude,$(PWD)/dotfiles/.claude)
	$(call link,$(HOME)/.gogcli,$(PWD)/dotfiles/.gogcli)
	$(call link,$(HOME)/.local/bin/osc52-yank,$(PWD)/dotfiles/bin/osc52-yank)
	@echo ""
	@echo "🎉 dotfilesのセットアップが完了しました（⚠️ がある場合は指示に従って再実行してください）"

# リンクの削除
clean:
	@echo "dotfilesのリンクを削除します..."
	@rm -f ~/.zshrc
	@rm -f ~/.rc
	@rm -f ~/.tmux.conf
	@rm -rf ~/.config/nvim
	@rm -rf ~/.config/wezterm
	@rm -f ~/.config/herdr/config.toml
	@rm -rf ~/.claude
	@rm -rf ~/.gogcli
	@rm -f ~/.local/bin/osc52-yank
	@echo "✓ dotfilesのリンクを削除しました"

# GCEインスタンス用: Docker Composeセットアップ
setup-docker-compose:
	@echo "Docker Composeのセットアップを開始します..."
	@mkdir -p ~/.docker/cli-plugins
	@ARCH=$$(uname -m); \
	case $$ARCH in \
		x86_64) COMPOSE_ARCH="x86_64" ;; \
		aarch64) COMPOSE_ARCH="aarch64" ;; \
		*) echo "❌ サポートされていないアーキテクチャ: $$ARCH" && exit 1 ;; \
	esac; \
	echo "アーキテクチャ: $$COMPOSE_ARCH を検出しました"; \
	curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$$COMPOSE_ARCH -o ~/.docker/cli-plugins/docker-compose
	@chmod +x ~/.docker/cli-plugins/docker-compose
	@echo "✓ Docker Composeをインストールしました"
	@sudo mount -o exec,remount /home 2>/dev/null || true
	@sudo usermod -aG docker $$USER
	@echo "✓ ユーザーをdockerグループに追加しました"
	@echo ""
	@echo "⚠️  グループ変更を反映するため、一度ログアウトして再ログインしてください"
	@echo "   または以下のコマンドを実行してください: newgrp docker"

# ヘルプ
help:
	@echo "利用可能なコマンド:"
	@echo "  make setup                - dotfilesのシンボリックリンクを作成"
	@echo "  make clean                - dotfilesのシンボリックリンクを削除"
	@echo "  make setup-docker-compose - GCEインスタンスにDocker Composeをセットアップ"
	@echo "  make help                 - このヘルプを表示"
