# Google アカウントの新規作成とエージェント用プロファイル整備(WSL2)

2026-08-30〜31 に misenoren 事業用の Google アカウントを作った際の実測記録。
Google はブラウザ自動化(CDP)を強く検知するため、素直に agent-browser だけでは完結しない。
最終的に動いた手順と、途中で踏んだ問題を残す。

## 結論(動いた手順)

1. **アカウント作成はスマホの Chrome+モバイル回線で行う**(PC からの自動化・半自動はすべて失敗した)
2. パスワードは事前に 1Password で生成・保存しておき、スマホの 1Password アプリから参照する
3. PC 側の初回ログインは**素の Chromium+ユーザー手動入力**で行う:

   ```sh
   DISPLAY=:0 ~/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome \
     --user-data-dir="$PWD/.secrets/browser-<name>" \
     --no-first-run --no-default-browser-check \
     "https://accounts.google.com/" >/tmp/chrome-manual.log 2>&1 &
   ```

   - CDP を繋がない(agent-browser を使わない)ことが重要。ウィンドウは WSLg で Windows 側に出る
   - パスワードは `op ... | tr -d '\n' | /mnt/c/Windows/System32/clip.exe` で Windows クリップボードへ送る。貼り付け(Ctrl+V)はユーザーにやってもらう(WSLg はクリップボード共有される)
4. ログインが通ったら Chromium を閉じ、`SingletonLock`/`SingletonCookie`/`SingletonSocket` を消してから agent-browser で同じプロファイルを開く。Cookie 済みなので以後の Gmail 操作は自動化できる

## 前提・小ネタ

- Playwright の Chromium 実体パス: `~/.cache/ms-playwright/chromium-<rev>/chrome-linux64/chrome`(`chrome-linux` と書いて一度起動に失敗した)
- 1Password はサービスアカウント運用(トークン: `~/.config/op/service-account-token`、vault: `ai`)

  ```sh
  export OP_SERVICE_ACCOUNT_TOKEN=$(cat ~/.config/op/service-account-token)
  $(mise which op) item create --category login --vault ai \
    --title "<email> (Google)" --url https://accounts.google.com \
    username=<email> --generate-password='letters,digits,symbols,20'
  ```

- Gmail アドレスの空き確認は入力してみるまで分からない。候補を複数用意しておく(ドット繋ぎは見た目の評判が悪い。`<name>hq` のような接尾辞が無難)

## 起きた問題と対処

| 症状 | 原因(推定) | 対処 |
|---|---|---|
| サインアップ最終段で「Google アカウントを作成できませんでした」 | agent-browser(CDP)経由の操作を検知。入力途中から人間が引き継いでも同じエラー | PC からの作成を諦め、スマホ Chrome+モバイル回線で作成 → 一発成功 |
| ログインでメール入力直後に「ログインできませんでした」(パスワード入力前) | 同上。CDP 痕跡のあるブラウザはパスワード検証前に拒否される。プロファイルを作り直しても同じ | 素の Chromium(CDP なし)+ユーザー手動入力で成功 |
| 月・性別のドロップダウンが `select` コマンドで選択できない | Google 独自のカスタムドロップダウン(ネイティブ select ではない) | `click` で開いてから option の ref を `click` |
| `type` コマンドで文字が入らない | 環境依存(原因未特定) | `fill` を使う。素の Chromium 相手なら人間に入力してもらう |
| ボタンの `click` が「Element is covered」で失敗 | エラーバナー等のオーバーレイが被さっている | screenshot で実画面を確認してから判断(snapshot だけでは気づけない) |
| xdotool 等でキーボードエミュレーションしようとした | ツール未インストール+auto モードでは apt install が弾かれる | クリップボード経由(clip.exe)で人間に貼ってもらう方式へ切替 |
| 新しいアカウントのセットアップ画面(スマート機能 3 連問)が受信トレイの前に挟まる | 初回ログイン時の仕様 | agent-browser で順に選択して保存すれば通る(ここは自動化可能) |

## 運用メモ

- 作りたての Gmail からリンク付きコールドメールを一斉送信すると迷惑メール判定されやすい。数日ウォームアップ(通常の送受信)+1 日 5〜8 通の分散送信にする
- プロファイルはリポの `.secrets/browser-<name>/` に置く規約(agent-browser-tips スキル参照)。認証情報の保存先とあわせて各リポの CLAUDE.md に記録する
