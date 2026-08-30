---
name: agent-browser-tips
description: ブラウザ操作の標準手段 agent-browser CLI の使い方。ログイン済みプロファイルの指定、セッション分離、context を増やさないコツ、Gmail/SPA のハマりどころ。「ブラウザで開いて」「X のページ見て」「Gmail 確認して」等のブラウザ操作全般で参照。
---

# agent-browser の使い方(グローバル)

ブラウザ操作は agent-browser CLI(Bash 実行)で行う。Playwright スキル(browser)と使い分け: ログイン済みプロファイルでの閲覧・軽操作はこちら、素の多段自動化・PDF 化は browser。

## プロファイル

ログイン済みプロファイルは**各リポの `.secrets/browser-<name>/`** に置く規約(リポ固有の一覧はそのリポの CLAUDE.md を見る)。

```sh
agent-browser --session <作業名> --profile "$PWD/.secrets/browser-<name>" open <url>
```

- `--profile` は Chromium user-data-dir をそのまま開く。公開ページを見るだけなら **--profile 不要**
- **同一プロファイルを同時に 2 箇所から開けない**(Chromium Singleton ロック)。並行作業したいときはディレクトリごと複製する(`rsync -a --exclude 'Singleton*'` — ロックファイルを除外するのがキモ。複製後は独立ドリフト)
- **`--session` は必ず付ける**。無名セッションは全エージェント共有で他セッションの画面を潰す。以降のコマンドも同じ `--session`(または `export AGENT_BROWSER_SESSION=<作業名>`)
- 作業が終わったら `agent-browser --session <作業名> close`

## 基本ループ

```sh
agent-browser --session t open <url>     # 開く(返るのはタイトル+URL の数十バイトのみ)
agent-browser --session t snapshot -i    # インタラクティブ要素のみの一覧(@eN ref 付き)
agent-browser --session t click @e3      # ref で操作(返るのは ✓ Done のみ)
agent-browser --session t snapshot -i    # ページが変わったら再 snapshot(ref は毎回振り直し)
```

- 記事・本文を読むだけなら `read [url]` 一発(note のログイン壁も越えられる実績あり)
- ref (`@eN`) はページ遷移・再レンダリングで stale になる。操作のたびに再 snapshot

## 節約ルール

1. **`snapshot` は必ず `-i`**。フル snapshot は Gmail で 150k 字、`-i` でも 100k 超のことがある
2. 大きいページは `-d <depth>` / `-s <css>` / `-c` で局所化し、**出力は grep で必要行だけ拾う**:
   `agent-browser --session t snapshot -i | grep -E 'row|検索語' | head -20`
3. 一覧から探すより URL 直接遷移(Gmail 検索: `#search/from%3A<encoded>`、X: `https://x.com/i/status/<tweet_id>`)
4. スクショが要るときだけ `screenshot <path>`。判断は snapshot/read でする
5. スマホ表示の確認は `set viewport 390 844` → open → screenshot

## Gmail 特有

- 検索 URL: `#search/from%3A<encoded>`(`%3A`=`:`, `%40`=`@`)、未読絞りは `%20is%3Aunread`
- SPA 遷移直後の操作は `wait 2000` を挟む
- auto mode classifier が Gmail への書き込み系操作を弾くことがある → default mode か個別許可

## 録画

`record start <path> [url]` / `record stop`(WebM)。

## ハマりどころ

- 応答が返らない/変な挙動 → `agent-browser --session t close` してやり直し。全滅させるときは `close --all`(他エージェントのセッションも落ちるので最終手段)
- プロファイルが「使用中」エラー → 別セッション・別プロセスが同プロファイルを開いている。相手の終了を待つ。プロセスが死んでいるのにロックが残る場合のみ `SingletonLock`/`SingletonCookie`/`SingletonSocket` の 3 ファイルを削除
- daemon は 1 時間 idle で自動終了(状態は破棄)。長時間空けたら open からやり直し
- bot 検知の強いサイト(J-PlatPat 等)はヘッドレス全拒否(403)。代替サイトを探すか手動依頼に切り替える

## 追記ルール

新しい落とし穴を踏んだら該当節に 1〜数行足す。理論の再説明はしない、実測と再現手順のみ。リポ固有の事情(プロファイル一覧・他ツールとの競合)はここでなく各リポの CLAUDE.md に書く。
