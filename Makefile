.PHONY: setup clean setup-docker-compose help

# dotfilesセットアップ
setup:
	@echo "dotfilesのセットアップを開始します..."
	
	# .zshrcのリンク作成
	@test ! -e ~/.zshrc && ln -sf $(PWD)/dotfiles/.zshrc ~/.zshrc && echo "✓ ~/.zshrc のリンクを作成しました" || echo "✓ ~/.zshrc は既に存在します"
	
	# .rcのリンク作成
	@test ! -e ~/.rc && ln -sf $(PWD)/dotfiles/.rc ~/.rc && echo "✓ ~/.rc のリンクを作成しました" || echo "✓ ~/.rc は既に存在します"

	# .tmux.confのリンク作成
	@test ! -e ~/.tmux.conf && ln -sf $(PWD)/dotfiles/.tmux.conf ~/.tmux.conf && echo "✓ ~/.tmux.conf のリンクを作成しました" || echo "✓ ~/.tmux.conf は既に存在します"

	# .config/nvimのリンク作成
	@mkdir -p ~/.config
	@test ! -e ~/.config/nvim && ln -sf $(PWD)/dotfiles/.config/nvim ~/.config/nvim && echo "✓ ~/.config/nvim のリンクを作成しました" || echo "✓ ~/.config/nvim は既に存在します"
	
	# .claudeのリンク作成
	@test ! -e ~/.claude && ln -sf $(PWD)/dotfiles/.claude ~/.claude && echo "✓ ~/.claude のリンクを作成しました" || echo "✓ ~/.claude は既に存在します"

	# .aiのリンク作成
	@test ! -e ~/.ai && ln -sf $(PWD)/dotfiles/.ai ~/.ai && echo "✓ ~/.ai のリンクを作成しました" || echo "✓ ~/.ai は既に存在します"
	
	@echo ""
	@echo "🎉 dotfilesのセットアップが完了しました！"
	@echo "作成されたリンク:"
	@echo "  ~/.zshrc -> $(PWD)/dotfiles/.zshrc"
	@echo "  ~/.rc -> $(PWD)/dotfiles/.rc"
	@echo "  ~/.tmux.conf -> $(PWD)/dotfiles/.tmux.conf"
	@echo "  ~/.config/nvim -> $(PWD)/dotfiles/.config/nvim"
	@echo "  ~/.claude -> $(PWD)/dotfiles/.claude"

# リンクの削除
clean:
	@echo "dotfilesのリンクを削除します..."
	@rm -f ~/.zshrc
	@rm -f ~/.rc
	@rm -f ~/.tmux.conf
	@rm -rf ~/.config/nvim
	@rm -rf ~/.claude
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
