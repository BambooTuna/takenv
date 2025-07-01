# takenv - 個人開発環境構築リポジトリ

シンプルで実用的な開発環境の自動構築リポジトリです。

## 📋 前提条件

- Git
- zsh (macOS標準、Linux: 要インストール)

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/BambooTuna/takenv.git
cd takenv
```

### 2. 基本環境のセットアップ

```bash
# asdfのインストール
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0

# 手動で実行
mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"

# oh-my-zshとプラグインのインストール
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions

# シェルの再読み込み
source ~/.zshrc
```

### 3. dotfilesの一括セットアップ

```bash
make setup
```

このコマンドで以下のシンボリックリンクが作成されます：
- `~/.zshrc` → `dotfiles/.zshrc`
- `~/.rc` → `dotfiles/.rc`
- `~/.config/nvim` → `dotfiles/.config/nvim`
- `~/.claude` → `dotfiles/.claude`
- `~/.ai` → `dotfiles/.ai`

### 4. プラットフォーム別設定（Mac）

```bash
# Homebrewパッケージの一括インストール
brew bundle --file=mac/brew/Brewfile
```

## 🛠 含まれる設定

### Neovim設定 (LazyVim ベース)
- Claude Code統合プラグイン
- GitHub Copilot
- Markdown preview
- LazyGit統合
- 各種言語サポート

### zsh設定
- oh-my-zsh + af-magic テーマ
- 高機能ヒストリ管理（50,000件、重複削除、時間記録）
- 便利なalias設定（`v`=nvim, `k`=kubectl, `t`=terraform）
- asdf、git、vi-mode プラグイン
- zsh-syntax-highlighting、zsh-autosuggestions

### AI ツール設定
- **Claude Code**: 日本語設定、通知機能、Node.js関連指示
- **AI docs**: 開発言語別の詳細設定

### Git設定補助
- SSH鍵設定手順
- Git template設定

## 📁 ディレクトリ構造

```
takenv/
├── README.md                 # このファイル
├── Makefile                  # dotfiles一括設定
├── dotfiles/                 # 設定ファイル群
│   ├── .zshrc               # zsh設定
│   ├── .rc                  # 共通環境変数・alias
│   ├── .config/nvim/        # LazyVim設定
│   ├── .claude/             # Claude Code設定
│   └── .ai/docs/            # AI関連ドキュメント
├── mac/brew/                # Mac用設定
│   └── Brewfile            # Homebrew設定
└── git/                     # Git設定手順
    └── README.md           # SSH設定等の手順書
```

## 🔧 管理コマンド

```bash
make setup    # dotfilesのシンボリックリンクを作成
make clean    # dotfilesのシンボリックリンクを削除
make help     # ヘルプ表示
```

## 🔄 更新・カスタマイズ

### 設定の更新
```bash
cd takenv
git pull origin main
source ~/.zshrc  # 必要に応じて
```

### 個人設定の追加
設定ファイルは全てシンボリックリンクなので、リポジトリ内のファイルを直接編集すればOK

## 🖥 インストールされるツール（Mac）

### 必須ツール
- zsh, git, mysql, fzf
- Docker, iTerm2

### 便利ツール
- Google Chrome, Slack, Discord
- Amazon Music, Clipy, Toggl Track
- bat (cat代替), exa (ls代替), jq, tree

## ⚠️ 注意事項

- 既存の設定ファイルがある場合は自動でバックアップされません
- 事前に重要な設定のバックアップを推奨
- シンボリックリンク作成時、既存ファイルがある場合はスキップされます

## 🤝 貢献

個人用リポジトリですが、改善提案やIssueは歓迎します。
