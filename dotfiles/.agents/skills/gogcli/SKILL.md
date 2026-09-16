---
name: gogcli
description: gog CLI で Gmail・Google Calendar・Drive・Slides・Sheets を操作する。
---

# Google サービスの操作

この環境では `gog` を使う。`gog --help` と必要なサブコマンドの help で構文を確認する。既存の認証アカウント・対象リソースを確認し、依頼範囲で操作する。

- [Gmail](references/gmail.md): 検索・本文・添付・ドラフト・送信
- [Calendar](references/calendar.md): 予定・空き時間・参加者・通知
- [Drive](references/drive.md): 検索・転送・共有
- [Slides](references/slides.md): プレゼンテーション
- [Sheets](references/sheets.md): 表データ

必要なサービスの例だけ読む。本文はファイルで渡し、宛先・対象ID・通知の有無を操作前に確認する。検索・閲覧の依頼から送信や共有を追加しない。例と実際の CLI が異なる場合はインストール済みバージョンの help を優先する。
