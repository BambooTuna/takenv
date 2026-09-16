# takenv — 個人開発環境構築リポジトリ

Mac / Ubuntu / Debian をゼロ状態から同じ開発環境にするリポジトリです。用途に応じてエントリを 2 本用意しています。

```bash
git clone https://github.com/BambooTuna/takenv.git && cd takenv

# VM / 踏み台 / 迷ったらこっち (Ubuntu/Debian のみ、軽量)
./bootstrap.sh

# Mac 母艦・GPU 機・WSL 開発機など全部入り (Mac も対応)
./bootstrap-full.sh
```

どちらも冪等なので何度実行しても安全です。**最小構成を先に叩いてから後でフルに乗せ換える**、という順序も差分だけ足せば済みます。

### 使い分け

| | `./bootstrap.sh` (最小) | `./bootstrap-full.sh` (フル) |
|---|---|---|
| 対象 OS | Ubuntu / Debian / Amazon Linux 2023 (apt/yum 自動判定) | Mac / Ubuntu / Debian |
| 想定用途 | VM・踏み台・SSM で入る作業サーバー | 母艦・GPU 機・普段の開発機 |
| 入るもの | zsh + oh-my-zsh + dotfiles + mise + `nvim / tmux / lazygit / ripgrep / herdr / gh / node` | 上記 + Docker + Tailscale + SSM plugin + Playwright chromium + Claude Code + Codex + Homebrew (Mac) + mise 全ツール (python/go/rust/awscli/gcloud/terraform/firebase/...) |
| 所要時間の目安 | 数分 | 数十分 (mise の全ランタイム DL・chromium 込みのため) |

VM 側で LazyVim を動かすのに必要な `node` は最小構成にも含まれます。`fzf` は LazyVim の `junegunn/fzf` プラグイン経由で供給されるので別途 apt/mise には入れていません。

## 何が再現されるか

環境は三層で宣言的に管理されています。

| 層 | 定義ファイル | 担当 |
|---|---|---|
| GUI アプリ・フォント・C ライブラリ | [`Brewfile`](./Brewfile) | Homebrew（Mac のみ、フル構成） |
| ランタイム・CLI ツール | [`dotfiles/.config/mise/config.toml`](./dotfiles/.config/mise/config.toml) | [mise](https://mise.jdx.dev/)（バージョン固定） |
| 設定ファイル | [`dotfiles/`](./dotfiles) | シンボリックリンク（`make link`） |

`bootstrap-full.sh` はこの三層を OS を判別して順に適用します（Mac は Homebrew → brew bundle → oh-my-zsh → dotfiles リンク → mise 全ツール → Claude Code、Ubuntu/Debian は apt → mise → oh-my-zsh → dotfiles → mise 全ツール → Claude Code → Docker CE → Tailscale）。`bootstrap.sh` は最小のセットのみ適用します。

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
./bootstrap-full.sh   # 新しく宣言されたツールの導入・差分適用 (VM は ./bootstrap.sh)
```

- ツールを足す: `Brewfile`（GUI）か `dotfiles/.config/mise/config.toml`（CLI/ランタイム）に追記して `./bootstrap-full.sh`
- マシン固有・秘匿の設定: `~/.zshrc.local` に書く（git 管理外）

## CI

push / PR のたびに GitHub Actions がゼロ状態の macOS / Ubuntu runner で `./bootstrap-full.sh` → `make doctor` を実行し、「ゼロから構築できること」を常時検証します（[.github/workflows/bootstrap.yml](./.github/workflows/bootstrap.yml)）。最小構成側は shellcheck のみ。

## 含まれる設定

- **zsh**: oh-my-zsh + af-magic、履歴 50,000 件・重複削除・時間記録、`v`=nvim などの alias
- **Neovim**: LazyVim ベース、Claude Code 統合、Copilot、LazyGit 統合
- **WezTerm + herdr**: ターミナルマルチプレクサは herdr がメイン。Cmd キー操作を herdr の prefix に変換するキーバインド
- **tmux**: mise でグローバル導入。`.tmux.conf` と `tls` / `ta` / `tns` / `ts` エイリアスを同梱
- **Karabiner-Elements**: Caps Lock → Ctrl、右 Cmd → 英数、右 Option → かな
- **AI ツール**: Claude Code / Codex の共通指示・スキル（[設定と責任者の使い方](docs/agent-config.md)）
- **SSH 越しのクリップボード**: OSC 52 対応の `bin/osc52-yank`

## ディレクトリ構成

```
takenv/
├── bootstrap.sh             # 最小構成エントリ (VM/踏み台向け、Ubuntu/Debian)
├── bootstrap-full.sh        # フル構成エントリ (Mac 母艦・開発機、Mac/Ubuntu/Debian)
├── bootstrap/               # 上記2本から source される共通セットアップ関数群
├── Makefile                 # link / unlink / doctor
├── Brewfile                 # Homebrew 宣言（Mac）
├── dotfiles/                # 設定ファイル群（~/ へ symlink）
│   ├── .zshrc / .rc         # zsh 設定・共通 alias
│   ├── .config/mise/        # ランタイム・CLIツール宣言（唯一の正）
│   ├── .config/nvim/        # LazyVim 設定
│   ├── .config/wezterm/     # WezTerm 設定
│   ├── .config/karabiner/   # キーリマップ設定
│   ├── .config/herdr/       # herdr 設定
│   ├── .agents/            # AI 共通指示・スキルの正本
│   ├── .claude/ / .codex/   # 各ツール設定・共通設定への参照
│   └── bin/                 # ヘルパースクリプト
├── devcontainer/            # bootstrap.sh を使う開発コンテナ
├── git/                     # コミットテンプレート・SSH 手順
├── scripts/                 # 単発ユーティリティ（train-mode 等）
└── .github/workflows/       # ゼロ構築の CI 検証
```
