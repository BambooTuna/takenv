---
name: llm-design-check
description: LLM を使う機能の入出力設計・プロンプト・schema・後処理からアンチパターンを検出する監査スキル。LLM に DB ID や createdAt 等の永続化情報をそのまま渡していないか、不要なトレース情報や低レベル差分を出力させていないか、schema が細かすぎて精度を落としていないか、LLM の失敗をバリデーションで後追いしていないか、generateObject / structured output / prompt 設計 / JSON 生成の設計を見直す時に使用する。LLM 利用箇所の棚卸しや全コードベーススキャンにも使う。「LLM 設計チェック」「LLM アンチパターン」「プロンプト設計レビュー」「JSON 出力が不安定」「差分生成がうまくいかない」「llm-design-check」と依頼された時に使用する。
---

# LLM Design Check

## Purpose

LLM を使う機能を、プロダクト品質と実装保守性の両方から監査する。

このスキルは **検出・設計レビュー専用**。実装変更まで求められた場合は、指摘後に最小変更で直す。

## You Must Read

- [references/checklist.md](./references/checklist.md) — 監査チェックリスト。必ず読む。
- 対象の prompt / schema / action / usecase / repository / UI 呼び出し元。
- LLM 出力を保存する DB JSON 型、レビュー履歴、生成ライフサイクルがある場合はその型定義。
- 変更差分がある場合は `git diff`。

## 基本姿勢

- **LLM に考えさせる対象を絞る。** DB id、createdAt、sourceRefs、status enum、内部 version などロジックで構築できる情報を LLM に渡さない。
- **出力 field に不要な context を渡さない。** trace 用の sourceRefs / 行番号 / 内部 alias などが必要な構造化 field と、人間が読む本文 field を混ぜない。本文 field に不要な情報が出るなら、後段で削る前に input / prompt / schema を分ける。
- **出力粒度は業務操作に合わせる。** 低レベル patch 羅列が精度を落とすなら、対象 aggregate / process / section の局所全量生成に寄せる。
- **schema は精度のために使う。** schema を細かくしすぎて「正しいが不自然な出力」を誘導していないかを見る。
- **バリデーションを品質生成の代替にしない。** 保存時検証は最後の防波堤。理想出力は prompt / context / schema / output contract で得にいく。
- **LLM の確率的な違反を前提に検証を設計する。** 不正状態は schema で表現不可能にし（判別 union）、原文照合は完全一致でなく fuzzy 一本、検証違反は全件収集 + 失敗単位の 1 回リトライ + fail-fast。個別の null チェック・正規化ルールを実機エラーのたびに後追いで足す設計にしない（checklist の該当項目と §7「LLM 出力検証の 3 層」参照）。
- **prompt の要求粒度と schema の受け皿を一致させる。** prompt が項目単位の根拠・分類を要求するなら schema にも同じ粒度の slot を用意する。受け皿が無いと LLM は自由文 field へはみ出す。分類・スコープ判定の基準は除外列挙だけで書かず、肯定軸 + 境界の正例・負例で書く。
- **根拠付け方式はタスク性質で選ぶ。** quote が成果物データなら逐語 + fuzzy、参照導線なら行番号/ID 転記。どちらも「実在するが無関係な根拠」は検出できないため、業務判断に直結する根拠は後段の独立検証 call で守る。
- **UX 品質をブラックリストで作らない。** LLM 出力の「意味のない文言」「内部っぽい表現」「余計な根拠表示」を regex 置換で直す設計は、別パターンが出るたびに保守が増える。セキュリティ、エスケープ、プロトコル整形は別物だが、人間向け自然文の品質問題は LLM の入出力設計で直す。
- **失敗を無言で成功扱いしない。** 0 件適用、noop、needs_clarification、unsupported、partial apply を UI と履歴に正しく出す。対象は LLM 生成の status / payload 契約。副作用処理（例: 課金記録などの二次的な記録処理）が本文の成否と独立して no-throw になっている設計は、その独立性が意図されたものであれば違反として指摘しない。
- **SDK capacity を先取りで制限しない。** `maxOutputTokens` 等は業務要件がない限り設定せず model default に任せる。設定するならプロジェクト内の LLM 設定ファイル 1 箇所に正本を集約し、コメントで根拠を明記する。

## 手順

1. **対象 LLM フローを 1 行で特定**
   - 例: 「チャット指示を差分オブジェクトに変換し、生成結果に反映する」
2. **入出力境界を棚卸し**
   - LLM に渡す input、LLM から受け取る output、サーバーで補完する値、DB に保存する値を分ける。
   - field ごとに「この field の生成に必要な context か」を確認する。別 field のための trace 情報や内部 id が混ざっていれば、prompt を分けるか context formatter を分ける。
3. **アンチパターンを検出**
   - checklist の該当項目 ID（例: 1-H1）+ 項目の要約を必ず明記する。
4. **修正方針を出す**
   - 優先順位は「LLM 入力削減」「field 別 context 分離」「出力契約の変更」「後処理の責務分離」「UI 状態表現」の順に見る。
5. **必要なら実装修正**
   - 既存 lifecycle / usecase 境界を尊重し、LLM schema と永続化 schema を混ぜない。

## 後処理ブラックリストの扱い

LLM 出力に対して「この表現が出たら消す / 言い換える」という後処理を見つけたら、まず目的を分類する。

- **適切になり得るもの**: HTML/SVG/CSV/Markdown エスケープ、ファイル名 sanitize、セキュリティ上の秘匿、プロトコル上必須の正規化、構造化 ID の範囲外参照の破棄。
- **原則不適切なもの**: 人間向け自然文から、内部 ID、sourceRefs、行番号、enum、JSON key、余計な根拠表記、説明過多な文言を regex で削る/置換する処理。

後者は「LLM が悪い出力をした後に直す」のではなく、次を優先する。

- その field に不要な情報を input から外す。
- trace / sourceRefs が必要な生成と、人間向け本文生成を別 prompt / 別 context formatter / 別 output field に分ける。
- 人間向け回答には、ID 付き編集用 JSON ではなく ID なしの回答用 view を渡す。
- LLM が持つべき output contract を肯定形で書く。「何を消すか」ではなく「この field は何を表すか」を明確にする。

例:

- NG: `issuesText` に `[D1/P1/L93-L95]` が出るので保存前 regex で消す。
- OK: `issuesText` は人間向け課題本文なので、資料本文だけを渡す。sourceRefs / page / line は別の構造化生成だけに渡す。

## 出力形式

```md
## LLM Design Check — <対象>

### 結論
- pass / changes-requested / block
- High 1 件以上 = block、Medium のみ = changes-requested、指摘なし = pass
- 1行理由

### High
- [<checklist項目ID> <要約>] `<file:line>`: <問題>
  - なぜ問題か:
  - 推奨修正:

### Medium
- ...

### 入出力境界
- LLM input に残すもの:
- LLM input から外すもの:
- LLM output に出させるもの:
- サーバー側で補完するもの:
- DB / レビュー履歴に保存するもの:

### 推奨 output contract
- <schema / JSON 例 / 状態遷移>
```

## 全リポジトリスキャンモード

このスキルは手動起動専用（ui-check / test-check と違い、antipattern スキャン用 CI からは呼ばれない想定）。引数なしで呼ばれた場合、または「全コードベース」「LLM 利用箇所の棚卸し」を対象とする指示の場合は、以下を中心にスキャンする。

- `generateObject`, `generateText`, `streamObject`, `streamText`
- `z.object`, `z.discriminatedUnion` と LLM schema の組み合わせ
- `prompt`, `system`, `messages`, `history`
- レビュー履歴・適用済み差分・解釈済み JSON を保存する型
- 生成物・ドラフト・確定日時などのライフサイクル状態

推奨入口:

```sh
rg "generate(Object|Text)|stream(Object|Text)|createLLMModel|model:" <src-dir>
rg "prompt:|system:|messages:|history" <src-dir>
rg "reviewMemory|appliedChangeJson|interpretedJson|committedAt|Generation" <src-dir>
```

## やってはいけないこと

- LLM 出力が大きいという理由だけで、低レベル差分に逃げる
- DB schema と LLM output schema を同一視する
- UUID / timestamp / organizationId / generationId / sourceRefs を LLM に生成させる
- 「保存時に落とす」だけで LLM の出力設計を直したことにする
- UX 品質目的の後処理ブラックリストを増やし続ける
- field に不要な trace 情報を渡しておきながら、prompt だけで「書くな」と制御しようとする
- `edits=[]` を成功扱いして、ユーザーに「反映された」ように見せる
- prompt と Zod schema の要求を矛盾させる
- レビュー履歴に人間の生コメントだけを保存し、LLM が解釈した規則・強度・適用差分を残さない
