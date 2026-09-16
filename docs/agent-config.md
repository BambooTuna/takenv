# Claude Code / Codex 共通設定

共通指示の正本は `dotfiles/.agents/AGENTS.md`。Claude は `~/.claude/CLAUDE.md` の import、Codex は `~/.codex/AGENTS.md` の symlink で同じ内容を読む。

`append-system-prompt.txt` と起動時の注入ラッパーは廃止した。新しいセッションで反映される。既存の zsh で古い `claude()` が残っている場合は `unfunction claude` を一度実行するか、新しいシェルを開く。

## スキル

正本は `dotfiles/.agents/skills/<name>/SKILL.md`。`~/.agents/skills` を Codex が直接探索し、Claude は `~/.claude/skills` のディレクトリリンクから読む。`.codex/skills` への個別リンクと `make sync-codex-skills` は不要。

```sh
make link
make check-agent-config
# 同じ配置を採用したプロジェクトも検査する
python3 scripts/check-agent-config.py --repo ~/github/reflllc/bak.pj
```

Claude では `/skill-name`、Codex では `$skill-name` を使う。旧コマンドは同名のスキルへ統合した。

| 旧名 | 新名 |
|---|---|
| `docs:compact` | `docs-compact` |
| `slide:create` | `slide-create` |
| `slide:image2pptx` | `image2pptx` |
| Claude commands の `fix-actions-check` / `fix-conflict` / `prompt-digest` | 同名の共通スキル |
| Codex prompts の `do-issue` | 同名の共通スキル |
| bak.pj の `/do` | repo の `do` スキル（Codex では `$do`） |

新規作成・移動の規約は [skill-authoring](../dotfiles/.agents/skills/skill-authoring/SKILL.md)。モデル・接続先・承認モードは各ツールの設定に置き、スキル本文で重ねて固定しない。

## 責任者の運用

「実装責任者とレビュー責任者を立てて、相談しながら進めて」で担当を分ける。Herdr 内では同じ workspace に1責任者1tabを作り、継続対話に使う。単発調査は subagent、短い作業は直接実行でよい。

```sh
member spawn impl claude
member spawn review codex
herdr agent prompt impl '<目的・対象・編集範囲・完了条件・呼び出し元>'
herdr agent prompt review '<レビュー対象・失敗条件・相談相手>'
member list
herdr agent wait impl --timeout 60000
herdr agent read impl --source recent-unwrapped --lines 200
member close impl
member close review
```

担当名は既存 agent と衝突しないものを使う。モデル指定が必要なら `--` の後へ各CLIの引数を渡す。許可待ちは親が内容を読み、既存のユーザー承認範囲なら応答する。

## bak.pj

takenv は個人用の追加設定。チームメンバーは bak.pj だけを clone すれば、同梱の開発規約と8スキルを使える。チームの必須手順は bak.pj に置き、個人スキルや Herdr の導入を要求しない。チーム向けの導入案内は bak.pj の `docs/agent-setup.md`。

`AGENTS.md` が repo の共通入口で、`CLAUDE.md` はその import。`.agents/skills` が正本、`.claude/skills` は相対リンクなので、既存CIの参照パスも解決する。

`.claude/rules` は領域別規約の正本として維持する。Claude は paths 条件で読み込み、Codex は root AGENTS の作業領域表から必要な規約を読む。Claude の hooks・MCP 設定が Codex に自動移植されるわけではない。UAT は MCP と Playwright スクリプトの双方で同じ成果物契約を使う。

棚卸しの判断と検証結果は [2026-09-06 の記録](audits/2026-09-06-agent-config.md)。
