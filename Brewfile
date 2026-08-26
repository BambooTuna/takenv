# アプリの保存場所を指定
cask_args appdir: "/Applications", adopt: true  # 手動インストール済みアプリも brew 管理に取り込む

## 必須ツール
### 現在のシェル: echo $SHELL
### シェル一覧: cat /etc/shells
### 切り替え: chsh -s /bin/zsh
### zsh-syntax-highlighting / autosuggestions は oh-my-zsh の custom plugin として bootstrap.sh が導入
brew 'zsh'
brew 'git'

### ランタイム・CLIツールのバージョン管理（dotfiles/.config/mise/config.toml）
### CLI ツールは基本 mise に寄せる。ここは C ライブラリ依存が重い / OS 統合が重要なものだけ残す。
brew 'mise'

## ターミナル環境
cask "wezterm"
cask "karabiner-elements"
cask "font-hack-nerd-font"
cask "font-daddy-time-mono-nerd-font"

## CLIツール (C ライブラリ・OS 統合が重要なものだけ。他は mise で管理)
brew 'jq'
brew 'tree'
brew 'ffmpeg'   # 音声・動画処理 (macOS は VideoToolbox 対応版が入る)
### AWS SSM Session Manager (aws ssm start-session 実行に必要な公式プラグイン)
cask 'session-manager-plugin'

### DBクライアント（サーバはDockerで立てる）
### psql (link: true で keg-only を強制リンク)
brew 'libpq', link: true
### mysql: PATHに $(brew --prefix)/opt/mysql-client/bin を追加
brew 'mysql-client'

## 開発ツール
cask "docker-desktop"
cask "ngrok"

## GUIアプリ
cask "google-chrome"
cask "slack"
cask "discord"
cask "zoom"
cask "microsoft-teams"
cask "microsoft-excel"
cask "microsoft-word"
cask "microsoft-powerpoint"
cask "typora"
cask "claude"
cask "tailscale-app"
cask "clipy"

## caskが存在しない・caskが機能しないため手動インストール
# - tldv (https://tldv.io)
# - LINE (App Store)
# - Amazon Music (cask はインストーラーが現行 macOS 非対応。https://music.amazon.co.jp から手動導入)
