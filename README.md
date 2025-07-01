# takenv - 個人環境構築リポジトリ

開発環境の構築を自動化するためのリポジトリです。

## 📋 前提条件

- Git
- zsh
- curl または wget

## 🚀 セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/BambooTuna/takenv.git
cd takenv
```

### 2. asdf（パッケージマネージャー）のセットアップ

```bash
# asdfのインストール
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0

# .zshrcに追加（手動で実行）
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.zshrc

# シェルの再読み込み
source ~/.zshrc
```

### 3. 各設定のセットアップ

#### 3.1 vim環境（LazyVim）

```bash
# 既存のnvim設定をバックアップ（必要に応じて）
mv ~/.config/nvim ~/.config/nvim.bak

# 設定ファイルをシンボリックリンクで配置
ln -sf $(pwd)/dotfiles/.config/nvim ~/.config/nvim
```

#### 3.2 zsh設定

```bash
# 既存の.zshrcをバックアップ
mv ~/.zshrc ~/.zshrc.bak

# 設定ファイルをシンボリックリンクで配置
ln -sf $(pwd)/dotfiles/.zshrc ~/.zshrc

# シェルの再読み込み
source ~/.zshrc
```

#### 3.3 プラットフォーム別セットアップ

**Mac:**
```bash
# Homebrewでパッケージをインストール
brew bundle --file=mac/brew/Brewfile
```

**Linux:**
```bash
# 基本パッケージのインストール
sudo bash linux/setup.sh
```

### 4. asdfで開発ツールをインストール

```bash
# 必要なプラグインとツールをインストール
./scripts/setup-tools.sh
```

## 🛠 含まれる設定

### vim/neovim設定
- **LazyVim**ベースの設定
- Claude Code連携
- Copilot統合
- Markdown preview
- 各種プラグイン

### zsh設定
- 履歴管理の最適化
- Git情報表示
- kubectl補完
- GKE接続簡易化
- fzf統合

### 開発ツール（asdf管理）
- Node.js
- Python
- Go
- Terraform
- その他必要に応じて

### AI ツール設定
- Claude Code
- Gemini CLI

## 📁 ディレクトリ構造

```
takenv/
├── README.md                 # このファイル
├── config/                   # AI ツール設定
│   ├── claude-code/         # Claude Code設定
│   └── gemini-cli/          # Gemini CLI設定
├── dotfiles/                # 共通設定ファイル
│   ├── .config/
│   │   └── nvim/           # Neovim設定
│   ├── .zshrc              # zsh設定
│   └── Makefile            # dotfiles管理用
├── mac/                     # Mac固有設定
│   └── brew/
│       └── Brewfile        # Homebrew設定
├── linux/                  # Linux固有設定
│   ├── setup.sh            # セットアップスクリプト
│   └── setup-asdf-plugin.sh
└── scripts/                # セットアップスクリプト
    └── setup-tools.sh      # 開発ツール一括インストール
```

## 🔧 カスタマイズ

### 環境固有の設定
- `~/.zshrc_local` - ローカル固有のzsh設定
- `~/.zshrc_Darwin` - Mac固有のzsh設定
- `~/.zshrc_Linux` - Linux固有のzsh設定

### 追加パッケージ
asdfで管理されているパッケージは以下のコマンドで追加できます：

```bash
asdf plugin add <package-name>
asdf install <package-name> <version>
asdf global <package-name> <version>
```

## 🔄 更新方法

```bash
cd takenv
git pull origin main

# 必要に応じて新しい設定を適用
source ~/.zshrc
```

## ⚠️ 注意事項

- 既存の設定ファイルは事前にバックアップしておくことを推奨
- プラットフォーム固有の設定は該当するディレクトリの設定を使用
- asdfで管理されているツールのバージョンは`.tool-versions`ファイルで管理

## 🤝 貢献

このリポジトリは個人使用を想定していますが、改善提案やバグ報告は歓迎します。

## 📄 ライセンス

個人使用のため、特定のライセンスは設定していません。