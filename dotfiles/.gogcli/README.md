権限制限しています。

```
$ gog auth add <your-email> --services calendar,gmail,drive --drive-scope readonly
```

## SSH 越しの VM で認証する場合

ローカルコールバックサーバーが立てられない（リダイレクト先がブラウザを開いた端末の localhost になってしまう）ので、`--manual` を使ってブラウザレスフローで実行する。

```
$ gog auth add <your-email> --services calendar,gmail,drive --drive-scope readonly --manual
```

1. VM に表示された URL を手元のブラウザに貼って認可
2. 認可後にリダイレクトされた URL（`http://localhost/...?code=...&state=...`）をまるごとコピー
3. VM のプロンプトに貼り付け

SSH ポートフォワーディング（`ssh -L 8080:localhost:8080 <vm>` + `--listen-addr 127.0.0.1:8080`）でも可能だが、`--manual` のほうが接続を張り直さなくてよい。
