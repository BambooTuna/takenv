.PHONY: setup clean help

# dotfilesセットアップ
setup:
	@echo "dotfilesのセットアップを開始します..."
	
	# .zshrcのリンク作成
	@test ! -e ~/.zshrc && ln -sf $(PWD)/dotfiles/.zshrc ~/.zshrc && echo "✓ ~/.zshrc のリンクを作成しました" || echo "✓ ~/.zshrc は既に存在します"
	
	# .rcのリンク作成
	@test ! -e ~/.rc && ln -sf $(PWD)/dotfiles/.rc ~/.rc && echo "✓ ~/.rc のリンクを作成しました" || echo "✓ ~/.rc は既に存在します"
	
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
	@echo "  ~/.config/nvim -> $(PWD)/dotfiles/.config/nvim"
	@echo "  ~/.claude -> $(PWD)/dotfiles/.claude"

# リンクの削除
clean:
	@echo "dotfilesのリンクを削除します..."
	@rm -f ~/.zshrc
	@rm -f ~/.rc
	@rm -rf ~/.config/nvim
	@rm -rf ~/.claude
	@echo "✓ dotfilesのリンクを削除しました"

# ヘルプ
help:
	@echo "利用可能なコマンド:"
	@echo "  make setup  - dotfilesのシンボリックリンクを作成"
	@echo "  make clean  - dotfilesのシンボリックリンクを削除"
	@echo "  make help   - このヘルプを表示"