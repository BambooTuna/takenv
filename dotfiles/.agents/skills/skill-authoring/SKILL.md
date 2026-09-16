---
name: skill-authoring
description: takenv の共通スキルとリポジトリ固有スキルを作成・移動・整理するときの配置規約。
---

# スキルの配置

- 個人の汎用手順は `~/takenv/dotfiles/.agents/skills/<name>/SKILL.md`。
- プロジェクトのコード・データ・業務仕様に依存する手順は `<repo>/.agents/skills/<name>/SKILL.md`。
- チームが必須とする手順は、汎用的な内容でもチームの repo に同梱する。個人の takenv を clone していなくても規約・スキル・CI の参照が解決すること。短い手順なら repo の規約に直接書き、個人スキルへの必須依存を作らない。
- Codex は `~/.agents/skills` と repo の `.agents/skills` を直接読む。`.codex/skills` への個別リンクは不要。
- Claude 用には `.claude/skills` を `../.agents/skills` への相対 symlink にする。既存の実ディレクトリがあれば内容を統合してからリンクに置き換える。
- 共通設定のホームへのリンクは `make link`。検証は `make check-agent-config`。

# 内容と形式

YAML frontmatter に `name` と `description` を書く。name はディレクトリと一致する小文字英数字・ハイフン（例: `docs-compact`）。既存・組み込みスキルと同名にしない。

説明には用途と発火する場面を書く。本文には、モデルがコードから推測できない手順・組織固有の判断・実際の失敗を防ぐ条件を残す。一般的な心構えや、利用モデル・人数・承認の一律指定を足さない。

長い使用例・詳細基準は `references/` に分け、必要な場面からリンクする。補助ファイルはこのスキルからの相対パスで参照し、個人ホームの絶対パスに依存させない。

作成・移動後はリンクと参照先、frontmatter、代表的な呼び出しを確認する。コミットや他リポジトリの変更は依頼範囲に従う。中央へ移したスキルを CI が読む場合、CI にも導入経路が必要。個人ホームへのリンクを共有 repo にコミットしない。
