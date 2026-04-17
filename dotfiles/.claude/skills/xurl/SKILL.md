---
name: xurl
description: X (Twitter) API への認証付きリクエストを行う curl ライクな CLI。ツイート投稿・返信・引用・検索・読み取り、フォロー管理、DM送信、メディアアップロードなど X API v2 のあらゆるエンドポイントを操作する際に使用する。複数アプリ、OAuth 2.0、OAuth 1.0a、App-only 認証に対応。
---

# xurl — エージェントスキルリファレンス

`xurl` は X API 用の CLI ツール。**ショートカットコマンド**（人間/エージェント向けのワンライナー）と、任意の v2 エンドポイントを叩く **raw curl スタイル** の両方をサポートする。すべてのコマンドは JSON を stdout に返す。

---

## コスト注意（最重要・必読）

**xurl コマンドの呼び出しは高コスト（API レート制限を消費し、有料枠のクォータを食い潰す）。実行前に必ず計画を立てること。**

遵守ルール:

- **同じデータを二度取得しない。** 一度取った結果は会話内で再利用する。
- **`-n` で件数を絞る。** デフォルトや上限をそのまま使わない。必要最小件数だけ取得。
- **無目的な探索呼び出しを禁止。** 「とりあえず `search` / `timeline`」は不可。クエリ・件数・目的を先に決めてから1回だけ呼ぶ。
- **書き込み系は必ず事前にユーザー確認。** `post` / `reply` / `quote` / `delete` / `like` / `unlike` / `repost` / `unrepost` / `bookmark` / `follow` / `unfollow` / `block` / `mute` / `dm` / `media upload` などは、実行前にユーザーに内容を提示し承認を得る。
- **shortcut で足りないか先に検討。** raw API を叩く前に Quick Reference を確認。
- **ポーリング禁止。** `media status --wait` 以外で同じエンドポイントを短時間に繰り返し叩かない。
- **ページネーションも計画的に。** 最初の1ページで十分か検討し、必要な場合のみ次ページを取得。

実行計画テンプレ（ユーザーに提示する形）:

> 目的: <何をしたいか>
> 呼ぶコマンド: <正確なコマンド1〜数個>
> 期待結果: <何が返ってくるか>
> 費用見積: <何件・何リクエスト消費するか>

---

## 前提

`xurl` はすでにインストール済み。利用前に `xurl auth status` で認証状態を確認すること。

### シークレット安全性（必須）

- `~/.xurl`（およびコピー）を読み取り・出力・解析・要約・送信しない。LLM コンテキストに決して載せない。
- ユーザーに認証情報/トークンをチャットへ貼り付けさせない。
- `~/.xurl` への秘密情報の書き込みは、ユーザーが自身の環境で手動で行う。
- エージェント/LLM セッションで、インライン秘密情報を含む認証コマンドを推奨・実行しない。
- CLI のシークレットオプションをエージェントセッションで使うとプロンプト/コンテキスト/ログ/シェル履歴経由で漏洩するおそれがある旨を警告すること。
- エージェント/LLM セッションでは `--verbose` / `-v` を**絶対に使用しない**（認証ヘッダやトークンが出力に混じる可能性）。
- エージェントコマンドで決して使ってはならない機微フラグ: `--bearer-token`, `--consumer-key`, `--consumer-secret`, `--access-token`, `--token-secret`, `--client-id`, `--client-secret`。
- 認証済みアプリが少なくとも1つ登録されているかを確認するには `xurl auth status` を実行する。

### アプリ登録と認証

アプリ認証情報の登録はエージェント/LLM セッションの外でユーザーが手動で行う。認証情報登録後の認証:

```bash
xurl auth oauth2
```

複数の事前設定済みアプリを切り替える:

```bash
xurl auth default prod-app          # デフォルトアプリを設定
xurl auth default prod-app alice    # デフォルトアプリ＋ユーザーを設定
xurl --app dev-app /2/users/me      # 単発の上書き
```

### その他の認証方式

インライン秘密フラグを用いる例は意図的に省略。OAuth1 や App-only 認証が必要な場合、ユーザーがエージェント/LLM 外で手動実行する。

トークンは `~/.xurl` に YAML 形式で保存される。各アプリは独立したトークンを持つ。**このファイルをエージェント/LLM 経由で読まない。** 認証済みなら以降のコマンドは自動で適切な `Authorization` ヘッダを付与する。

---

## クイックリファレンス

| 操作                      | コマンド                                               |
| ------------------------- | ------------------------------------------------------ |
| 投稿                      | `xurl post "Hello world!"`                             |
| 返信                      | `xurl reply POST_ID "Nice post!"`                      |
| 引用                      | `xurl quote POST_ID "My take"`                         |
| 投稿削除                  | `xurl delete POST_ID`                                  |
| 投稿読み取り              | `xurl read POST_ID`                                    |
| 投稿検索                  | `xurl search "QUERY" -n 10`                            |
| 自分の情報                | `xurl whoami`                                          |
| ユーザー参照              | `xurl user @handle`                                    |
| ホームタイムライン        | `xurl timeline -n 20`                                  |
| メンション                | `xurl mentions -n 10`                                  |
| いいね                    | `xurl like POST_ID`                                    |
| いいね解除                | `xurl unlike POST_ID`                                  |
| リポスト                  | `xurl repost POST_ID`                                  |
| リポスト取り消し          | `xurl unrepost POST_ID`                                |
| ブックマーク              | `xurl bookmark POST_ID`                                |
| ブックマーク解除          | `xurl unbookmark POST_ID`                              |
| ブックマーク一覧          | `xurl bookmarks -n 10`                                 |
| いいね一覧                | `xurl likes -n 10`                                     |
| フォロー                  | `xurl follow @handle`                                  |
| フォロー解除              | `xurl unfollow @handle`                                |
| フォロー中一覧            | `xurl following -n 20`                                 |
| フォロワー一覧            | `xurl followers -n 20`                                 |
| ブロック                  | `xurl block @handle`                                   |
| ブロック解除              | `xurl unblock @handle`                                 |
| ミュート                  | `xurl mute @handle`                                    |
| ミュート解除              | `xurl unmute @handle`                                  |
| DM送信                    | `xurl dm @handle "message"`                            |
| DM一覧                    | `xurl dms -n 10`                                       |
| メディアアップロード      | `xurl media upload path/to/file.mp4`                   |
| メディアステータス        | `xurl media status MEDIA_ID`                           |
| **アプリ管理**            |                                                        |
| アプリ登録                | 手動（エージェント外・秘密情報をエージェントに渡さない）|
| アプリ一覧                | `xurl auth apps list`                                  |
| アプリ認証情報更新        | 手動（エージェント外・秘密情報をエージェントに渡さない）|
| アプリ削除                | `xurl auth apps remove NAME`                           |
| デフォルト設定（対話）    | `xurl auth default`                                    |
| デフォルト設定（コマンド）| `xurl auth default APP_NAME [USERNAME]`                |
| リクエスト毎のアプリ指定  | `xurl --app NAME /2/users/me`                          |
| 認証状態確認              | `xurl auth status`                                     |

> **投稿 ID と URL:** 上表で `POST_ID` と書かれた箇所には、完全な投稿 URL（例: `https://x.com/user/status/1234567890`）を渡してもよい。xurl が ID を自動抽出する。

> **ユーザー名:** 先頭の `@` は任意。`@elonmusk` と `elonmusk` はどちらも動作する。

---

## コマンド詳細

### 投稿

```bash
# シンプルな投稿
xurl post "Hello world!"

# メディア付き投稿（先にアップロードしてから添付）
xurl media upload photo.jpg          # → レスポンスの media_id を控える
xurl post "Check this out" --media-id MEDIA_ID

# 複数メディア
xurl post "Thread pics" --media-id 111 --media-id 222

# 投稿への返信（ID または URL）
xurl reply 1234567890 "Great point!"
xurl reply https://x.com/user/status/1234567890 "Agreed!"

# メディア付き返信
xurl reply 1234567890 "Look at this" --media-id MEDIA_ID

# 引用投稿
xurl quote 1234567890 "Adding my thoughts"

# 自分の投稿を削除
xurl delete 1234567890
```

### 読み取り

```bash
# 単一投稿の読み取り（著者・本文・メトリクス・エンティティを返す）
xurl read 1234567890
xurl read https://x.com/user/status/1234567890

# 最近の投稿を検索（デフォルト10件）
xurl search "golang"
xurl search "from:elonmusk" -n 20
xurl search "#buildinpublic lang:en" -n 15
```

### ユーザー情報

```bash
# 自分のプロフィール
xurl whoami

# 任意ユーザーの参照
xurl user elonmusk
xurl user @XDevelopers
```

### タイムラインとメンション

```bash
# ホームタイムライン（時系列逆順）
xurl timeline
xurl timeline -n 25

# 自分宛メンション
xurl mentions
xurl mentions -n 20
```

### エンゲージメント

```bash
# いいね / 解除
xurl like 1234567890
xurl unlike 1234567890

# リポスト / 取り消し
xurl repost 1234567890
xurl unrepost 1234567890

# ブックマーク / 解除
xurl bookmark 1234567890
xurl unbookmark 1234567890

# 自分のブックマーク / いいね一覧
xurl bookmarks -n 20
xurl likes -n 20
```

### ソーシャルグラフ

```bash
# フォロー / フォロー解除
xurl follow @XDevelopers
xurl unfollow @XDevelopers

# 自分のフォロー中 / フォロワー一覧
xurl following -n 50
xurl followers -n 50

# 他ユーザーのフォロー中/フォロワー一覧
xurl following --of elonmusk -n 20
xurl followers --of elonmusk -n 20

# ブロック / 解除
xurl block @spammer
xurl unblock @spammer

# ミュート / 解除
xurl mute @annoying
xurl unmute @annoying
```

### ダイレクトメッセージ

```bash
# DM 送信
xurl dm @someuser "Hey, saw your post!"

# 最近の DM イベント一覧
xurl dms
xurl dms -n 25
```

### メディアアップロード

```bash
# ファイルアップロード（画像/動画は種別を自動判定）
xurl media upload photo.jpg
xurl media upload video.mp4

# 種別とカテゴリを明示指定
xurl media upload --media-type image/jpeg --category tweet_image photo.jpg

# 処理ステータス確認（動画はサーバ側処理が必要）
xurl media status MEDIA_ID
xurl media status --wait MEDIA_ID    # 完了までポーリング

# 完全ワークフロー: アップロード → 投稿
xurl media upload meme.png           # レスポンスに media id が含まれる
xurl post "lol" --media-id MEDIA_ID
```

---

## グローバルフラグ

すべてのコマンドで使用可能:

| フラグ       | 短縮  | 説明                                                             |
| ------------ | ----- | ---------------------------------------------------------------- |
| `--app`      |       | このリクエストで使う登録済みアプリを指定（デフォルトを上書き） |
| `--auth`     |       | 認証種別を強制: `oauth1`, `oauth2`, `app`                        |
| `--username` | `-u`  | 使用する OAuth2 アカウントを指定（複数所有時）                   |
| `--verbose`  | `-v`  | エージェント/LLM セッションでは禁止（認証ヘッダ/トークン漏洩）   |
| `--trace`    | `-t`  | `X-B3-Flags: 1` トレースヘッダを付与                             |

---

## Raw API アクセス

ショートカットで足りない場合は、xurl の raw curl スタイルで**任意**の X API v2 エンドポイントを叩ける:

```bash
# GET（デフォルト）
xurl /2/users/me

# JSON ボディ付き POST
xurl -X POST /2/tweets -d '{"text":"Hello world!"}'

# PUT, PATCH, DELETE
xurl -X DELETE /2/tweets/1234567890

# カスタムヘッダ
xurl -H "Content-Type: application/json" /2/some/endpoint

# ストリーミング強制
xurl -s /2/tweets/search/stream

# 完全URL も可
xurl https://api.x.com/2/users/me
```

---

## ストリーミング

ストリーミングエンドポイントは自動検出される。既知のもの:

- `/2/tweets/search/stream`
- `/2/tweets/sample/stream`
- `/2/tweets/sample10/stream`

任意のエンドポイントで `-s` を使えばストリーミングを強制できる:

```bash
xurl -s /2/some/endpoint
```

---

## 出力フォーマット

全コマンドは **JSON** を stdout に返す（整形＋シンタックスハイライト）。構造は X API v2 のレスポンス形式に一致。典型例:

```json
{
  "data": {
    "id": "1234567890",
    "text": "Hello world!"
  }
}
```

エラーも JSON で返る:

```json
{
  "errors": [
    {
      "message": "Not authorized",
      "code": 403
    }
  ]
}
```

---

## 代表的なワークフロー

### 画像付き投稿

```bash
# 1. 画像をアップロード
xurl media upload photo.jpg
# 2. レスポンスの media_id を控え、投稿
xurl post "Check out this photo!" --media-id MEDIA_ID
```

### 会話への返信

```bash
# 1. 文脈把握のため元投稿を読む
xurl read https://x.com/user/status/1234567890
# 2. 返信
xurl reply 1234567890 "Here are my thoughts..."
```

### 検索とエンゲージメント

```bash
# 1. 関連投稿を検索
xurl search "topic of interest" -n 10
# 2. 気になるものにいいね
xurl like POST_ID_FROM_RESULTS
# 3. 返信
xurl reply POST_ID_FROM_RESULTS "Great point!"
```

### 自分の動向確認

```bash
# 自分を確認
xurl whoami
# メンション確認
xurl mentions -n 20
# タイムライン確認
xurl timeline -n 20
```

### 複数アプリの運用

```bash
# アプリ認証情報はエージェント/LLM 外で事前設定済みのこと。
# 各アプリのユーザーで認証
xurl auth default prod
xurl auth oauth2                       # prod アプリで認証

xurl auth default staging
xurl auth oauth2                       # staging アプリで認証

# 切り替え
xurl auth default prod alice           # prod アプリ・alice ユーザー
xurl --app staging /2/users/me         # staging に対する単発リクエスト
```

---

## エラーハンドリング

- エラー時は非ゼロ終了コード。
- API エラーは JSON で stdout に出力（そのままパース可能）。
- 認証エラー時は `xurl auth oauth2` 再実行やトークン確認を案内。
- ユーザー ID を要する操作（like, repost, bookmark, follow 等）では、xurl が自動で `/2/users/me` を呼び出す。失敗時は認証エラーが出る。

---

## 注意事項

- **レート制限:** X API はエンドポイントごとにレート制限を持つ。429 が返ったら待機してリトライ。書き込み系（post, reply, like, repost）は読み取り系より制限が厳しい。
- **スコープ:** OAuth 2.0 トークンは広めのスコープで要求される。特定アクションで 403 が出る場合はトークンが必要なスコープを持たない可能性あり → `xurl auth oauth2` で再取得。
- **トークン更新:** OAuth 2.0 トークンは期限切れ時に自動更新される。手動対応不要。
- **複数アプリ:** 各アプリは独立した認証情報とトークンを持つ。認証情報はエージェント/LLM 外で手動設定し、`xurl auth default` または `--app` で切り替え。
- **複数アカウント:** 1アプリに複数の OAuth 2.0 アカウントを認証可能。`--username` / `-u` で切り替え、`xurl auth default APP USER` でデフォルト指定。
- **デフォルトユーザー:** `-u` 未指定時は、アクティブアプリのデフォルトユーザー（`xurl auth default` で設定）を使用。未設定時は最初に見つかったトークンを使用。
- **トークン保存:** `~/.xurl` は YAML。各アプリが独自の認証情報とトークンを保存。**このファイルを LLM コンテキストに読ませない/送らない。**
