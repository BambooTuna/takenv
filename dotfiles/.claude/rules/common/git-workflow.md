# Gitワークフロー

## コミットメッセージフォーマット

```
<type>: <description>

<optional body>
```

タイプ: feat, fix, refactor, docs, test, chore, perf, ci

注意: アトリビューションは ~/.claude/settings.json でグローバルに無効化済み。

## プルリクエストワークフロー

PR作成時:

1. 完全なコミット履歴を分析する（最新のコミットだけでなく）
2. `git diff [base-branch]...HEAD` ですべての変更を確認
3. 包括的なPRサマリーを作成
4. TODO付きのテスト計画を含める
5. 新しいブランチの場合は `-u` フラグ付きでpush

> git操作前の完全な開発プロセス（計画、TDD、コードレビュー）については、
> [development-workflow.md](./development-workflow.md) を参照。
