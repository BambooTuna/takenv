# takenv Development Container

開発環境をコンテナ化したシンプルな構成です。

## 📦 含まれる機能

- **開発ツール**: asdf, neovim, lazygit, zsh (oh-my-zsh)
- **セッション管理**: tmux

## 🚀 セットアップ

### 1. イメージのビルドとコンテナ起動

```bash
cd /path/to/takenv
USER_UID=$(id -u) USER_GID=$(id -g) docker compose up -d --build
```

ビルドには5-10分程度かかります。

### 2. コンテナに入る

```bash
docker exec -it takenv-dev zsh
```

## 🔧 tmux でセッション永続化

コンテナから抜けても処理を継続させるために tmux を使います。

### 基本的な使い方:

```bash
# コンテナ内で tmux を起動
tmux

# 長時間処理を実行
python main.py
# または
npm run dev
# または
nvim /workspace/README.md

# デタッチ（セッションを保持したまま切り離す）
# Ctrl+B を押してから D を押す

# コンテナから抜ける
exit
```

### 再接続:

```bash
# 再度コンテナに入る
docker exec -it takenv-dev zsh

# tmuxセッションにアタッチ（元の画面に復帰）
tmux attach
# または
tmux a
```

### その他のtmuxコマンド:

```bash
# セッション一覧
tmux ls

# 新しいウィンドウを作成: Ctrl+B → C
# ウィンドウ切り替え: Ctrl+B → 数字(0,1,2...)
# ペイン分割（横）: Ctrl+B → "
# ペイン分割（縦）: Ctrl+B → %
# ペイン移動: Ctrl+B → 矢印キー
```

## 📝 使用例

### neovimでファイルを編集

```bash
docker exec -it takenv-dev zsh
nvim /workspace/README.md
```

### lazygitを使用

```bash
docker exec -it takenv-dev zsh
cd /workspace
lazygit
```

### asdfでツールをインストール

```bash
docker exec -it takenv-dev zsh
asdf plugin add nodejs
asdf install nodejs latest
asdf global nodejs latest
```

## 🛠 管理コマンド

### コンテナの状態確認

```bash
docker compose ps
docker compose logs
```

### コンテナの再起動

```bash
docker compose restart
```

### コンテナの停止

```bash
docker compose down
```

### コンテナの再ビルド

```bash
docker compose up -d --build
```

## ⚠️ トラブルシューティング

### コンテナが起動しない

```bash
# ログを確認
docker compose logs

# 強制的に再ビルド
docker compose down
docker compose up -d --build
```

### tmuxセッションがない

```bash
# コンテナ内で確認
tmux ls

# セッションがない場合は新規作成
tmux
```

## 🌐 クラウド展開

GCE/AWS/Azure などのクラウド環境への展開方法は [gce/README.md](../gce/README.md) を参照してください。

## 📚 参考

- [asdf documentation](https://asdf-vm.com/)
- [Neovim documentation](https://neovim.io/doc/)
- [lazygit documentation](https://github.com/jesseduffield/lazygit)
- [oh-my-zsh documentation](https://ohmyz.sh/)
- [tmux cheatsheet](https://tmuxcheatsheet.com/)
