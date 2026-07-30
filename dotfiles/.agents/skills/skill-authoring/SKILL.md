---
name: skill-authoring
description: takenv 環境で新規スキルを作る／既存スキルを昇格・移動する際の配置ルールと手順。「スキル作る」「skill 追加」「skill 昇格」「skill を dotfiles に移動」「スキル置き場どこ」「新しい skill 書きたい」などで発火する。中央 (dotfiles/.agents/skills/) と repo-local (<repo>/.claude/skills/) の使い分け判断、frontmatter 規約、Claude/Codex 両方から見えるようにする Makefile 手順、命名ルールを規定する。
---

# takenv スキル運用ガイド

このスキルは、`~/takenv` を中心とした takeo 個人の開発環境で **新しいスキルを追加する／既存スキルを整理する** ときの、置き場・フォーマット・展開手順を定める正本ドキュメントです。

## 前提: takenv のスキル配置構造

```
~/takenv/dotfiles/
├── .agents/skills/         # ★ 正本（ツール非依存、git 管理下）
├── .claude/skills → ../.agents/skills                (dir symlink)
└── .codex/skills/<name>   → ../../.agents/skills/<name>   (per-skill symlink)
```

Runtime:
```
~/.agents  → ~/takenv/dotfiles/.agents
~/.claude  → ~/takenv/dotfiles/.claude
~/.codex   → ~/takenv/dotfiles/.codex
```

つまり `dotfiles/.agents/skills/` に置いたものは **Claude Code / Codex CLI の両方から自動的にグローバル可視** になる。追加リンクは不要。

## 配置判断: 中央 vs repo-local

新規スキルを書き始める前に必ず選ぶ:

| 判定軸 | 中央 (`dotfiles/.agents/skills/`) | repo-local (`<repo>/.claude/skills/`) |
|---|---|---|
| 依存する資産 | 一般的な CLI / ツール / 汎用ワークフロー | そのリポジトリ内のファイル (`DESIGN.md`, `cases/`, 特定ライブラリ設定) |
| 対象者 | 自分だけ (dotfiles は個人) | チーム全員 (repo 共有) |
| 再利用性 | 他プロジェクトでも同じ手順で走る | そのプロジェクトでしか意味を持たない |
| 例 | `japanese-tech-writing`, `gogcli`, `browser`, `issue-triage` | `bak.pj/react-doctor`, `sekine-be/inquiry-response` |

**迷ったら中央**。後から「これ repo 固有だった」と気づいたら repo-local に降格すれば良い。逆（repo → 中央）はもっと簡単（下記「昇格手順」）。

## SKILL.md フォーマット規約

必ず YAML frontmatter で開始する:

```markdown
---
name: <kebab-case-slug>
description: <発火条件 + 用途を1〜3文で。「〜のときに使う」「〜で発火する」を含める>
---

# <人間可読タイトル>

<本文: Markdown。When to Use / Steps / Tips 等を任意に構造化>
```

### name の規則
- **kebab-case**: `zero-base-check`, `japanese-tech-writing`（アンダースコアは使わない）
- **短く specific**: `authoring-skills` より `skill-authoring` のように動作対象が読める形
- **ネームスペース区切りは `:`**: `docs:compact`, `slide:marp` のように用途を階層化したいとき
- **既存名との衝突禁止**: Codex `.system/` にある `skill-creator`, `skill-installer`, `imagegen` などを避ける
- **プレフィックス活用**: プロジェクト固有は `<project>-*` など

### description の書き方
Claude Code / Codex は description を見て「今この skill を使うべきか」を判断するため、以下を必ず含める:
- **発火条件**: どんなユーザー発話・状況で呼び出すべきか（「〜のとき」「〜で発火」）
- **できること**: 何を返すか、何をするか
- **NOT 使わない場合**: 紛らわしい類似 skill があるなら明示

悪い例: `description: 便利ツール`
良い例: `description: GitHub Issueを棚卸し・トリアージするスキル。「issue トリアージ」「issue 棚卸し」で起動。個別issueの調査は subagent で並列化する。`

### 薄さの基準
SKILL.md 本文は薄く保つ。LLM なら指示なしでも当然やる判断プロセス（「まず状況を整理する」等）は明文化しない。残す価値があるのは、ツールの正しい呼び出し方・環境や組織固有の規範・過去の実事故に基づくガード・実測に基づく数値基準の4種のみ。2026年の SkillsBench 等でスキルは厳選・簡潔なほど精度が上がることが定量的に示されている。サブエージェント起動プロンプトは本体に全文埋め込まず `agents/*.md` に外出しし、本体の長大化を防ぐ。

## 中央スキル作成の手順

```bash
# 1. 既存スキルの重複がないか確認（find-skills スキルを使うか grep）
ls ~/takenv/dotfiles/.agents/skills/

# 2. ディレクトリ + SKILL.md 作成
mkdir -p ~/takenv/dotfiles/.agents/skills/<name>
$EDITOR ~/takenv/dotfiles/.agents/skills/<name>/SKILL.md

# 3. 必要に応じて補助ファイル（scripts/, templates/, references/ 等）を配置
# 中央スキル配下のパスは ~/.agents/skills/<name>/... で参照できる（symlink 経由でも解決される）

# 4. Codex CLI 側にも見えるように per-skill symlink を張る
cd ~/takenv
make sync-codex-skills   # idempotent、既存はスキップされる

# 5. 動作確認
ls ~/.claude/skills/<name>/   # Claude 側から見える
ls ~/.codex/skills/<name>/    # Codex 側から見える

# 6. コミット
git add dotfiles/.agents/skills/<name> dotfiles/.codex/skills/<name>
git commit -m "feat: skill <name> 追加"
```

Claude Code のこのセッションからは、次のプロンプト送信時に system-reminder で `New skills discovered` として認識される。

## repo-local スキル作成の手順

```bash
cd <repo>
mkdir -p .claude/skills/<name>
$EDITOR .claude/skills/<name>/SKILL.md

# Codex 側にも欲しければ手動で symlink
mkdir -p .codex/skills
ln -s ../../.claude/skills/<name> .codex/skills/<name>

git add .claude/skills/<name> .codex/skills/<name>
git commit -m "feat: skill <name> 追加"
```

Claude Code は cwd が `<repo>` のとき `<repo>-name:<skill-name>` としてスコープ表示する（例: `bak.pj:react-doctor`）。

## repo-local → 中央への昇格

「これ他 project でも使える」と気づいた時:

```bash
# 1. 中央に移動
mv <repo>/.claude/skills/<name> ~/takenv/dotfiles/.agents/skills/<name>

# 2. Codex 側リンク更新
cd ~/takenv
make sync-codex-skills

# 3. コミット
git add dotfiles/.agents/skills/<name> dotfiles/.codex/skills/<name>
git commit -m "feat: skill <name> を中央に昇格"

# 4. 元 repo にも残したい場合は symlink で戻す
cd <repo>
ln -s ~/.agents/skills/<name> .claude/skills/<name>
git add .claude/skills/<name>
git commit -m "refactor: skill <name> を中央から参照"
```

## 中央 → repo-local への降格

「これ実は特定 project 依存だった」と気づいた時:

```bash
mv ~/takenv/dotfiles/.agents/skills/<name> <repo>/.claude/skills/<name>
cd ~/takenv
rm dotfiles/.codex/skills/<name>   # 中央側の Codex symlink を消す
git add -A dotfiles/.agents/skills dotfiles/.codex/skills
git commit -m "refactor: skill <name> を repo-local に降格"

cd <repo>
git add .claude/skills/<name>
git commit -m "feat: skill <name> 追加 (dotfiles から移設)"
```

## 命名衝突と重複の解消

- **中央と repo に同名スキル**: どちらか消す。「repo-local が中央より新しい機能を持つ」なら repo 側を残して中央のみ消す or 中央側にマージ
- **同一 repo 内で `.claude/skills/` と `.agents/skills/` の両方に同じスキル**: symlink 化して片方を正本にする
- **中央 skill と Codex `.system/*` の名前衝突**: 中央側をリネーム（例: `imagegen` は `.system` にあるので中央は `codex-imagegen` にしてある）

## Tips

- **スキルを書く前に類似検索**: `find-skills` スキルを呼んで既存に無いか確認する
- **description は 1〜3 文**: 長すぎると LLM の判定コストが上がる。しかし短すぎて発火条件が曖昧だと呼ばれない
- **本文は Markdown で自由に構造化**: `## When to Use`, `## Steps`, `## Examples` などの節を切ると LLM が拾いやすい
- **補助ファイル**: `scripts/`, `templates/`, `references/` を skill dir 配下に置ける。skill 本文からの参照は `~/.agents/skills/<name>/...` の絶対パス、または `$SKILL_DIR/...` 相当の相対
- **秘密情報はコミットしない**: dotfiles/.gitignore で `**/.env`, `**/.credentials.json` は除外済み。ペルソナ等の個人情報は `dotfiles/.gitignore` の `/.agents/skills/x-ops/persona/` 例に倣ってピンポイント除外
- **中央 skill の破壊的変更**: 個人 dotfiles なので他人に影響しないが、自分自身の他プロジェクトで動作している skill を変える時は影響範囲を意識する

## 参考

- 集約作業のコミット: `git log --oneline dotfiles/.agents/`（初回集約は `refactor: skill を dotfiles/.agents/ に集約`）
- Makefile: `~/takenv/Makefile` の `sync-codex-skills` target
- gitignore: `~/takenv/dotfiles/.gitignore`, `~/takenv/dotfiles/.agents/.gitignore`, `~/takenv/dotfiles/.codex/.gitignore`
