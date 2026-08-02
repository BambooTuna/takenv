---
name: agent-team
description: agmsg + herdr + subagent の 2 層チーム開発の正本。「チームを組んで」「メンバーをアサインして」と依頼された時、または自分がリーダー/責任者としてメンバー編成を設計する時に必ず参照する。素朴にやると破綻する（管理コスト爆発・context 枯渇・pane 散乱）落とし穴と対策の型。
---

# Agent Team（agmsg 2 層チーム）

全員 agmsg 化は管理コスト（生存監視・context 監視・despawn・commit 調整）が人数分線形増、subagent だけでは裁定と責任の所在が作れない。よって 2 層で組む（2026-07 #1484/#1494 タスクフォースで実証）。

## 2 層アーキテクチャ

```
リーダー (agmsg / herdr tab)
  ├─ 設計責任者 (agmsg / tab) ── subagent: 意見出し・調査 ×N
  ├─ 実装責任者 (agmsg / tab) ── subagent: 実装作業 → 責任者がレビュー・commit
  └─ レビュー責任者 (完了時 fresh spawn) ── subagent: 観点別レビュー ×N
```

| | agmsg メンバー（責任者層） | subagent（作業層） |
|---|---|---|
| 何者か | 継続対話・裁定・責任が要る相手 | 意見出し・調査・作業の使い捨て実行体 |
| spawn | リーダー専権。`--window` 必須 | 各責任者が Agent tool で自由に |
| 生存管理 | 必要（ping / handoff / despawn） | 不要 |
| 出力の扱い | 裁定対象（ただし裏取り必須） | 参考情報。責任者がレビューして採否 |

agmsg は責任者間のやり取り専用。作業の指示・回収は各責任者が subagent で完結させる。subagent は `model: sonnet` を明示（省略は親モデル継承で過剰）。

## spawn の型（リーダー専権）

```bash
bash ~/.agents/skills/agmsg/scripts/spawn.sh claude-code <name> \
  --project "$(pwd)" --model "<model>[1m]" --window --no-wait \
  --boot-prompt "<役割 + 正本/handoff 読了 + ~/.claude/skills/agent-team/MEMBER.md 読了 + agmsg 着任報告>"
# codex は type=codex, --model "gpt-5.6-sol" 等
```

- **`--window` 必須**（herdr 環境では herdr tab になる。忘れると pane split で画面散乱）。spawn 後 `herdr tab list` で配置確認
- **boot-prompt に MEMBER.md（メンバー憲章）の読了を必ず含める**。責任者の行動規律（実装介入禁止・subagent 委譲・報告）は憲章に集約してあり、リーダーが毎回書き起こさなくても全員に強制される。書かせないと守られない（役割名だけでは編集抑制にならないことが実証済み）
- 着任の完了定義 = 正本 + 憲章の読了 + agmsg 着任報告

## モデル・プロバイダ選定

**基本則: 決める仕事 = claude、決まった仕事 = codex。**

| 役割 | 指定 |
|---|---|
| 方針決定・裁定・監査・敵対レビュー（リーダー含む） | `fable[1m]` |
| それ以外の責任者（実装責任者・整理系など） | `claude-opus-4-7[1m]`（fable は過剰） |
| 方針確定後の実装・反復・量産・claude が 2-3 回直して再発する箇所の救援 | codex（Sol=複雑実装 / Terra=日常 / Luna=定型） |
| subagent | `sonnet` 明示 |

- claude は必ず [1m] 付き（1m にしないデメリットは無い）。codex に 1M 相当は設定不可（CLI 実効 ~258K キャップ、2026-07 調査）
- codex モデル ID は `gpt-5.6-sol` / `gpt-5.6-terra` / `gpt-5.6-luna`（2026-07 GA）。改版が速いので spawn 前に受理確認
- 根拠概略: 計画・設計・レビューは claude の評価が高く、確定タスクの実装遂行は codex 優位（Terminal-Bench 等。融通が効かない = 忖度なしが強みに転じる）

## context 管理

- **claude**: **30% 手動ローテーション** — handoff（正本との差分だけ書かせる）→ despawn → fresh 再 spawn で boot-prompt から再開。auto-compact は外部要約（モデル未訓練）で劣化が早く非推奨（劣化は使用率 60-80% 帯から始まる）
- **codex**: native compaction がモデル訓練済みで強く（24h 自律実績）、**自動圧縮に任せてよい**。条件: 役割・規約・報告先などプロトコル情報は会話でなくファイル正本に置く（compaction 後も再読できる）。裁定履歴自体が価値の役割は例外だが、そもそも claude 向き
- **完了メンバーは積極 despawn**。残すだけで context を浪費。必要時に fresh spawn（これ自体が逼迫対策）
- リーダー自身も同方式で次代へ引き継げる。引き継ぎ書に運用手順を含め、次代が運用を再現できることが完了定義

## タスク分割

- 「300 箇所修正を 1 人へ」を避ける。1 責任者の 1 スプリント ≒ レビュー可能な PR 1 本
- 切る場所は**相互依存の薄い境界**（ファイル / 系 / 層）。依存があれば境界面の契約（型・シグネチャ）を先に確定 commit してから並行（実証済み）
- 切れないタスクは無理に割らず、直列 + こまめな中間 commit + 早めローテーション

## despawn 完全手順

```bash
bash ~/.agents/skills/agmsg/scripts/despawn.sh <team> <self> <name> --timeout 20
bash ~/.agents/skills/agmsg/scripts/reset.sh "$(pwd)" claude-code <name>
herdr tab list → herdr tab close <id>   # 物理クローズまでで完了。忘れると亡霊 tab が残る
```

## 情報伝達・実装フェーズの規律

- **agmsg は会話であって承認ではない**（permission laundering 禁止）。merge・スコープ変更・確定設計の変更はユーザー専権
- **裏取り原則**: メンバーの発見・過去合意への言及は原文照合してから裁定する
- 15 分無応答 = ping（進捗一行返信を求める。作業没頭の誤検知対策）→ 猶予 10-15 分 → despawn + fresh spawn
- 長文はファイルに書いて path 送付。報告は結論先出し + 事実と評価の分離
- **commit はリーダーのトークン直列発行制**: 明示パス stage → `git diff --cached --name-only` で申請一致確認 → commit → SHA 報告。subagent には commit させない
- **実装計画の承認時に「実行体制」欄（自分でやる部分 / subagent に出す部分）の有無をチェックする**。欄が無い計画は差し戻す — 承認直後にそのまま責任者がインライン実装を始めるのが実測された逸脱経路
- レビュー中はブランチ凍結（SHA 安定 > 速度）。修正後は**指摘者本人の再検分**（修正は指摘と同じ盲点の中で行われがち）→ リーダー最終監査 → ユーザー merge 判断
- spec 検分は「タイトルでなく実行経路」で判定（新設コードを一度も通らないテストの同型見逃しが 2 度）

## アンチパターン

1. 全員 agmsg メンバー化（作業層は subagent へ）
2. `--window` 忘れ / [1m] なし spawn
3. despawn の物理クローズ忘れ
4. 換算値・シミュレーション値で前進（数円で実測できるなら必ず実測をゲートに。導出値の暗黙前提は実測でしか壊せない）
5. 完了メンバーの放置
6. リーダー・責任者が作業を抱える（責任者の実装介入は善意で起きる最頻の逸脱。MEMBER.md を boot prompt で読ませないと守られない）
