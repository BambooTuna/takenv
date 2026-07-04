# takenv Development Container

ホストと同じ環境定義（`bootstrap.sh`）から作られる開発コンテナです。
Dockerfile は最小限のベースを用意して `TAKENV_SKIP_CASKS=1 ./bootstrap.sh` を実行するだけの薄いラッパーで、環境の中身はホストと同じ一箇所（bootstrap.sh / mise config / dotfiles）で管理されます。

## セットアップ

```bash
cd /path/to/takenv
USER_UID=$(id -u) USER_GID=$(id -g) docker compose up -d --build
```

## コンテナに入る

```bash
docker exec -it takenv-dev zsh
```

セッションの永続化・分割は herdr（`mise install` で導入済み）を使います。

## 管理コマンド

```bash
docker compose ps        # 状態確認
docker compose logs      # ログ
docker compose restart   # 再起動
docker compose down      # 停止
docker compose up -d --build  # 再ビルド
```
