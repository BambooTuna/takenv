# takenv — 個人開発環境構築リポジトリ

ゼロ状態の Mac / Ubuntu VM を、コマンド一発で同じ開発環境にするリポジトリです。

```bash
git clone https://github.com/BambooTuna/takenv.git && cd takenv
./bootstrap.sh
```

冪等なので何度実行しても安全です（導入済みのステップはスキップされます）。

## 何が再現されるか

環境は三層で宣言的に管理されています。

| 層 | 定義ファイル | 担当 |
|---|---|---|
| GUI アプリ・フォント・C ライブラリ | [`Brewfile`](./Brewfile) | Homebrew（Mac のみ） |
| ランタイム・CLI ツール | [`dotfiles/.config/mise/config.toml`](./dotfiles/.config/mise/config.toml) | [mise](https://mise.jdx.dev/)（バージョン固定） |
| 設定ファイル | [`dotfiles/`](./dotfiles) | シンボリックリンク（`make link`） |

`bootstrap.sh` はこの三層を OS を判別して順に適用します。

- **Mac**: Homebrew 導入 → `brew bundle` → oh-my-zsh → dotfiles リンク → `mise install` → Claude Code
- **Ubuntu**: apt（zsh / build ツール / DB クライアント）→ mise 導入 → oh-my-zsh → dotfiles リンク → `mise install` → Claude Code → Docker CE → Tailscale → ログインシェルを zsh 化

Ubuntu では GUI 層（cask）を除いた CLI 環境（zsh + mise + herdr + nvim + Claude Code / Codex）が再現されます。

## セットアップ後の手動ステップ

自動化できないものだけが残ります（`bootstrap.sh` 完了時にも表示されます）。

1. シェルを開き直す: `exec zsh -l`
2. SSH 鍵の作成と GitHub 登録: [git/README.md](./git/README.md)
3. Tailscale に参加: `make tailscale-up`（Ubuntu は `--ssh` 付きで SSH 受付も有効化）
   - Mac から `herdr --remote <user>@<ホスト名>` でリモート接続できるようになる
4. **Mac のみ** Karabiner-Elements の権限承認（初回のみ）
   - システム設定 > 一般 > ログイン項目と機能拡張 > ドライバ機能拡張 を有効化
   - システム設定 > プライバシーとセキュリティ > 入力監視 を許可
5. **Mac のみ** cask が無い/機能しないアプリ: LINE (App Store), tldv (https://tldv.io), Amazon Music (https://music.amazon.co.jp)

## 運用コマンド

```bash
make doctor        # 環境の健全性チェック（リンク・必須コマンド・mise・Brewfile）
make link          # dotfiles のシンボリックリンクを作成
make unlink        # リンクを削除（リンクのみ・実ファイルには触れない）
make tailscale-up  # Tailscale に参加（Linux は --ssh 付きで SSH 受付も有効化）
```

### 更新フロー

設定ファイルはすべてシンボリックリンクなので、リポジトリ内を直接編集すれば即反映されます。

```bash
git pull
./bootstrap.sh   # 新しく宣言されたツールの導入・差分適用
```

- ツールを足す: `Brewfile`（GUI）か `dotfiles/.config/mise/config.toml`（CLI/ランタイム）に追記して `./bootstrap.sh`
- マシン固有・秘匿の設定: `~/.zshrc.local` に書く（git 管理外）

## CI

push / PR のたびに GitHub Actions がゼロ状態の macOS / Ubuntu runner で `./bootstrap.sh` → `make doctor` を実行し、「ゼロから構築できること」を常時検証します（[.github/workflows/bootstrap.yml](./.github/workflows/bootstrap.yml)）。

## 含まれる設定

- **zsh**: oh-my-zsh + af-magic、履歴 50,000 件・重複削除・時間記録、`v`=nvim などの alias
- **Neovim**: LazyVim ベース、Claude Code 統合、Copilot、LazyGit 統合
- **WezTerm + herdr**: ターミナルマルチプレクサは herdr がメイン。Cmd キー操作を herdr の prefix に変換するキーバインド
- **tmux**: mise でグローバル導入。`.tmux.conf` と `tls` / `ta` / `tns` / `ts` エイリアスを同梱
- **Karabiner-Elements**: Caps Lock → Ctrl、右 Cmd → 英数、右 Option → かな
- **AI ツール**: Claude Code（日本語設定・commands / skills / rules 同梱）、Codex（prompts 同梱）
- **SSH 越しのクリップボード**: OSC 52 対応の `bin/osc52-yank`

## ディレクトリ構成

```
takenv/
├── bootstrap.sh             # 唯一のエントリポイント（OS判別・冪等）
├── Makefile                 # link / unlink / doctor
├── Brewfile                 # Homebrew 宣言（Mac）
├── dotfiles/                # 設定ファイル群（~/ へ symlink）
│   ├── .zshrc / .rc         # zsh 設定・共通 alias
│   ├── .config/mise/        # ランタイム・CLIツール宣言（唯一の正）
│   ├── .config/nvim/        # LazyVim 設定
│   ├── .config/wezterm/     # WezTerm 設定
│   ├── .config/karabiner/   # キーリマップ設定
│   ├── .config/herdr/       # herdr 設定
│   ├── .claude/ / .codex/   # AI エージェント設定
│   └── bin/                 # ヘルパースクリプト
├── devcontainer/            # bootstrap.sh を使う開発コンテナ
├── git/                     # コミットテンプレート・SSH 手順
├── scripts/                 # 単発ユーティリティ（train-mode 等）
└── .github/workflows/       # ゼロ構築の CI 検証
```
