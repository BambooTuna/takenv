---
description: 最近の作業をOpenAI Codex CLIに送信して独立した監査/レビューを実施する
allowed-tools: Bash(git:*), Bash(codex:*), Bash(git diff:*)
---

# Codex監査

## コンテキストの収集

レビュー対象の最近の変更を収集する:

- Git diff（ステージ済み + 未ステージ）: !`git diff HEAD`
- このブランチの最近のコミット: !`git log --oneline -10`
- Gitステータス: !`git status --short`

## タスク

1. 上記のdiffと最近のコミットを確認し、変更内容のサマリーを準備する。

2. 以下のコマンドを実行する。`<DIFF_SUMMARY>` を変更内容の簡潔な説明に置き換え、完全なdiffをstdin経由でパイプする:

```
git diff HEAD > /tmp/audit_diff.txt && codex exec -m "gpt-5.4" -c 'model_reasoning_effort="xhigh"' -c 'service_tier="fast"' --dangerously-bypass-approvals-and-sandbox -C "$(pwd)" "You are a READ-ONLY code reviewer. Read the file /tmp/audit_diff.txt which contains a git diff. Review it for: bugs, security issues, performance problems, logic errors, and style concerns. Be specific about file names and line numbers. You may read files and run tests to verify your findings. SAFETY RULES: Do NOT delete files, edit existing files, change branches, checkout, reset, revert, amend, or undo commits. Do NOT run git push, git checkout, git reset, git clean, rm, or any destructive command. You may create temporary files if needed for debugging. Your job is strictly to READ and REPORT. Do a deep audit and think from first principles. Leave no question unanswered. Here is context about what changed: <DIFF_SUMMARY>"
```

`git diff HEAD` が空の場合（コミットされていない変更がない場合）、代わりに最新のコミットをレビューする:

```
git diff HEAD~1 HEAD > /tmp/audit_diff.txt && codex exec -m "gpt-5.4" -c 'model_reasoning_effort="xhigh"' -c 'service_tier="fast"' --dangerously-bypass-approvals-and-sandbox -C "$(pwd)" "You are a READ-ONLY code reviewer. Read the file /tmp/audit_diff.txt which contains a git diff. Review it for: bugs, security issues, performance problems, logic errors, and style concerns. Be specific about file names and line numbers. You may read files and run tests to verify your findings. SAFETY RULES: Do NOT delete files, edit existing files, change branches, checkout, reset, revert, amend, or undo commits. Do NOT run git push, git checkout, git reset, git clean, rm, or any destructive command. You may create temporary files if needed for debugging. Your job is strictly to READ and REPORT. Here is context about what changed: <DIFF_SUMMARY>"
```

3. **すべての指摘事項を提示前に検証すること。** 監査者（Codex）は限られたコンテキストで動作する。プロジェクトのビジョン、戦略的目標、アーキテクチャの根拠を把握していない。誤解に基づいて重大な問題を捏造したり、意図的な設計上の選択の深刻度を過大評価することがよくある。Codexが返す各指摘に対して、以下を必ず実施すること:
   - 実際のソースコードを確認し、問題が実在するものであり、ハルシネーションや誤読ではないことを確認する。
   - ローカルの戦略/計画ドキュメント（例: `agents.md`、`README.md`、`CLAUDE.md`、`current_*.md`、またはリポジトリ内の類似ドキュメントや /docs/ フォルダ内の `DEV_JOURNAL.md` など）を確認し、指摘がプロジェクトの意図と矛盾していないかを確認する。
   - 自問する: 「これは本当のバグか、それともCodexがコンテキストを誤解しているのか？」そして「仮に実在するとしても、これは意味のある問題か、それとも些細な/スタイル上のノイズか？」
   - 実在かつ意味のある問題の両方を満たさない指摘がある場合、ユーザーに共有するが、その旨と理由を明確にラベル付けする。

4. 検証済みの指摘事項をユーザーに提示する。各指摘について、正当であると判断した理由を簡潔に記載する。Codexが問題なしと判断した場合、またはすべての指摘が検証に失敗した場合は、その旨を伝える。

5. 検証済みのフィードバックに対処するかどうかをユーザーに確認する。
