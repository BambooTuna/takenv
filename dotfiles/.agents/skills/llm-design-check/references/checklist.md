# LLM Design Check Checklist

## 0. 判定原則

- LLM に渡す情報は、推論に必要な業務情報だけにする。
- LLM output は「プロダクト上の操作単位」に合わせる。DB の保存単位や UI の見た目単位に引っ張られない。
- ロジックで決定できるものは LLM から分離する。
- schema は構造を安定させるために使う。LLM の判断を細切れにしすぎない。
- 保存時バリデーションは必要だが、生成品質の主戦場は prompt / input / output contract。

## 1. LLM Input のアンチパターン

### High

- **1-H1 DB 実 ID をそのまま見せる**
  - 症状: UUID / cuid / database id を prompt JSON に含め、LLM output でも同じ id を要求する。
  - なぜ問題か: token を食う。LLM が typo / 捏造しやすい。プロンプトが永続化実装に密結合する。
  - 推奨: `p1`, `f1`, `s1`, `t1` など短い alias に変換し、サーバー側で実 ID に戻す。

- **1-H2 createdAt / updatedAt / organizationId / generationId など推論不要メタデータを渡す**
  - なぜ問題か: LLM の注意を奪い、出力 contract に不要な値が混ざる。
  - 推奨: LLM input view を作り、業務判断に不要な永続化フィールドを削る。

- **1-H3 sourceRefs / evidence / provenance を LLM に再生成させる**
  - なぜ問題か: 根拠情報は既存 data から継承・マージできる場合が多い。LLM に出させると幻覚や欠落が起きる。
  - 推奨: 既存要素は既存 sourceRefs を保持。新規要素は対象 process / flow / parent からサーバー側で継承する。

- **1-H4 画面表示用 graph をそのまま prompt に入れる**
  - 症状: UI 用 labels, expanded state, counts, review flags, display-only fields が prompt に入る。
  - 推奨: `buildLLMView()` のような専用変換層を作る。

### Medium

- **1-M1 履歴をそのまま詰め込む**
  - 症状: chat history / review history を全件入れ、今回の指示と過去の反映済み指示が混ざる。
  - 推奨: 過去履歴は「現在 graph に反映済み」「復元指示がある時だけ参照」など、扱い方を明記する。長期履歴は要約済み memory にする。

- **1-M2 曖昧なユーザー発話を質問扱いにしすぎる**
  - 症状: 「〜したいな」「〜できる？」を noop / needs_clarification にしがち。
  - 推奨: 対象と変更内容が一意なら編集意図として扱うルールを明記する。

## 2. LLM Output Contract のアンチパターン

### High

- **2-H1 低レベル差分を出させすぎる**
  - 症状: `addStep`, `deleteStep`, `addTransition`, `deleteTransition` を多数出させ、transition 欠落や順序崩れが起きる。
  - なぜ問題か: LLM は局所編集の整合性を全件維持するのが苦手。1 個の抜けで壊れる。
  - 推奨: 業務上まとまりのある単位だけ全量生成する。例: `processChanges: [{ id, value }]`。

- **2-H2 全成果物 JSON を毎回出させる**
  - 症状: 変更対象が 1 単位なのに artifact 全体を LLM output にする。
  - なぜ問題か: output が大きくなり、無関係箇所が drift する。
  - 推奨: 「変更対象 aggregate の全量」だけにする。未変更 aggregate は出力しない。

- **2-H3 DB schema と LLM schema が同じ**
  - 症状: ORM の型 / repository input と同じ構造を structured output に要求する。
  - 推奨: LLM schema は最小契約。DB 保存に必要な値は adapter/usecase で補完する。

- **2-H4 status と payload の整合条件がない**
  - 症状: `status=applied` だが `edits=[]`、`noop` だが payload がある。
  - 推奨: prompt と action で `applied => payload.length > 0`, `noop/unsupported/needs_clarification => payload=[]` を保証する。

- **2-H5 人間向け自然文の品質問題を regex 置換・ブラックリスト後処理で直している**
  - 症状: 内部 ID / sourceRefs / 行番号 / enum / JSON key / 余計な根拠表記などを、LLM 出力後に regex で削る・言い換える。
  - なぜ問題か: 別パターンが出るたびに後処理が増え続け、根本の入出力設計が直らない。エスケープ / sanitize / セキュリティ上の秘匿とは目的が異なる。
  - 推奨: 不要情報を input から外す、trace 用生成と人間向け本文生成を別 prompt / 別 field に分ける、output contract を肯定形で書く。

- **2-H6 条件付き必須を nullable + 事後検証で表現している**
  - 症状: 「field A が値 X のときだけ field B が必須」を `B: z.number().nullable()` で表現し、normalize の throw で「X なのに B が null」を検出する。
  - なぜ問題か: schema 上、論理矛盾した出力（`outcome=superseded` かつ `supersededByClaimIdx=null` 等）が表現可能なままなので、生成時の違反をschemaで抑えられず、実行時の検証に依存する。
  - 推奨: 判別 union で不正状態を型として表現不可能にする。X の枝では B を非 null 必須に、それ以外の枝では B field 自体を持たせない。事後検証は「schema で表現できない制約」（範囲外 alias 参照・自己参照など）だけに絞る。
  - SDK互換性: 使用中のZod・AI SDK・provider・モデルのバージョンと、実際に送信されるJSON Schemaを確認する。`z.union`や`z.discriminatedUnion`の名前だけで互換性を決めない。
  - ルート形状や`oneOf`/`anyOf`の対応は対象APIの制約に合わせる。必要ならobject envelopeに包む。型検査だけでなく、生成schemaと代表入力で確認する。

- **2-H7 引用照合が必要な精度や表記揺れに合っていない**
  - 症状: 表記揺れだけで有効な引用を全拒否する、または曖昧一致した別の原文を自動採用する。
  - 推奨: 完全一致を基本に、必要なら正規化・fuzzy検索・再生成を検討する。許容差と曖昧時の扱いを評価データで決める。同程度の候補が複数あれば未解決として扱い、先頭一致で確定しない。
  - 保存するquoteは検証済みの原文スパンから取得する。LLMが出した位置や文字列を未検証で保存しない。

- **2-H8 根拠付け方式をタスクと無関係に選んでいる**
  - quote自体が成果物なら原文スパンを保存する。参照導線だけなら行番号/IDの実在・範囲を確認し、表示用quoteは原文から復元できる。
  - 文字列一致もIDの実在も、主張を支持する根拠かどうかまでは保証しない。業務上の影響と評価結果に応じて関連性の独立検証や人間のレビューを追加する。
  - 方式変更前に、原文の分割・参照ラベル・LLMに見せる文脈が適切か確認する。

### Medium

- **2-M1 削除 / 作成 / 更新の表現が分裂している**
  - 症状: create / update / delete が複数 op に分かれ、LLM がどれを使うか迷う。
  - 推奨: 対象単位が同じなら `[{ id:null,value }, { id,value }, { id,value:null }]` のように統一する。

- **2-M2 placeholder id ルールが複雑**
  - 症状: `$new-step`, `$new-transition` を複数 op 間で参照させる。
  - 推奨: LLM output 内でだけ一貫すればよい短い alias にし、サーバー側で placeholder / 実 ID に変換する。

- **2-M3 optional と nullable の意味が曖昧**
  - 症状: `undefined` が変更なし、`null` が削除、空文字が未設定などの扱いが prompt にない。
  - 推奨: 「省略=変更なし」「null=削除/未設定」など意味を 1 箇所に定義する。

## 3. Prompt / Schema 不一致

### High

- **3-H1 prompt が `edits` を要求し、schema は `processChanges` を要求する**
  - またはその逆。LLM がどちらを優先するか不安定になる。
  - 推奨: prompt の用語・schema 名・UI メッセージ・レビュー履歴の名前を揃える。

- **3-H2 過去の品質ルールを別用途へ流用している**
  - 症状: 抽出用 prompt の「迷ったら除外」を編集 prompt に流用し、編集指示なのに edits=[] になる。
  - 推奨: extraction / generation / refinement / classification で品質ルールを分ける。

- **3-H3 output schema の自由度が低すぎる**
  - 症状: LLM がユーザー意図を表せず unsupported / 空配列になりやすい。
  - 推奨: 高レベル操作を表せる contract に変更する。低レベル op は inline edit など決定論的経路に限定する。

- **3-H4 prompt が要求する粒度の受け皿が schema にない（本文への内部参照混入の根本原因）**
  - 症状: prompt は「各項目の根拠を [C{n}] で必ず付けよ」と **項目単位** の根拠を要求するのに、schema の根拠 field は親単位のフラット配列しかない。LLM は根拠を書く場所がないため、人間向け自由文の中に `（[C45]）` を書き込む。
  - なぜ問題か: promptの要求とschemaの受け皿が食い違うと、人間向け本文へ内部参照が混ざりやすい。fieldの追加だけで防げると仮定せず、実際の出力で確認する。
  - 推奨: prompt が要求する粒度に合わせて schema を再構造化する（例: 項目 1 件 = `{ text, basisRefIdxs }` の配列にし、text は純本文・根拠は slot へ）。表示用の連結文はサーバー側で合成する。regex で alias を削る後処理は 2-H5。

- **3-H5 in/out の分類基準を除外カテゴリの列挙だけで書き、肯定軸の定義がない**
  - 症状: 「挨拶・雑談・日程調整・進行の話は対象外」のような **除外列挙のみ** でスコープを守ろうとする。列挙に載らない亜種（確認依頼・ステータス返信依頼・整備作業など、依頼や業務行為の体裁を取った運営系のやり取り）が素通りし、成果物に混入する。
  - なぜ問題か: 除外列挙は実務のバリエーションを尽くせない（ブラックリストが保守され続ける 2-H5 と同じ構造が分類基準側で起きる）。字面が「要望」「業務行為」に一致する発話は、内容がスコープ外でも分類定義を満たしてしまう。
  - 推奨: まず **肯定軸**（この生成が扱う対象は何か。例:「このプロジェクトが無くても顧客の日常業務として存在する事柄か」）を定義し、除外列挙はその補助にする。境界の正例・負例を 2〜3 件ずつ prompt に置く（字面は運営系でも中身は顧客業務、の逆転ケースを必ず含める）。あわせて、分類器に自分の職掌外の予測（「後段で使える見込みが無ければ除外せよ」等）をさせない — 予測ベースの除外指示は正当なデータの取りこぼしを生む。

## 4. Apply / Validation のアンチパターン

### High

- **4-H1 保存時バリデーションで生成品質を代替する**
  - 症状: LLM が欠落 transition を出す問題に対し、保存時に reject するだけ。
  - 推奨: LLM output contract を変更し、理想構造を出しやすくする。validation は参照整合性など最小限にする。

- **4-H2 partial apply がレビュー履歴と UI に見えない**
  - 症状: 一部 skip したのに「反映しました」と表示する。
  - 推奨: `appliedCount`, `skippedCount`, `reason`, `status` を UI とレビュー履歴に保存する。

- **4-H3 LLM が作った差分を機械的に永続化し、人間のレビュー意図が消える**
  - 推奨: raw comment、LLM interpreted rule、適用差分、強度 (`must/should/weak`)、根拠をレビュー履歴に保存する。

- **4-H4 回復可能な生成失敗からの再開・修正手段がない**
  - 症状: 一部の検証違反で全体が失敗し、ユーザーが全工程をやり直す。
  - 推奨: 修正に必要な違反情報を収集し、安全に再実行できる単位を定める。フィードバック付き再生成が有効なら回数と費用の上限を設定する。再試行しても無効なら失敗・部分完了を明示する。
  - 即時失敗が必要な保証要件や、再試行しても改善しない失敗までリトライを強制しない。

### Medium

- **4-M1 参照整合性を全く見ない**
  - 症状: transition が存在しない step を指しても保存できる。
  - 推奨: 業務的に線が必須かは判定しないが、存在しない ID 参照は拒否する。

- **4-M2 LLM の失敗を例外だけで扱う**
  - 症状: parse failure / unsupported / needs clarification が同じ toast になる。
  - 推奨: status を UI へ返し、次に何を指定すべきかを reason に出す。

## 5. UI / UX のアンチパターン

### High

- **5-H1 ユーザーが「言ったのに変わらない」と感じる**
  - 原因: chat 指示後に draft 表示が変わらない、0 件適用を成功風に見せる。
  - 推奨: draft 生成、反映件数、反映できない理由を即時に表示する。

### Medium

- **5-M1 draft 中に再生成できてしまう**
  - 原因: review draft と再生成が競合する。
  - 推奨: draft がある間は regenerate を止め、commit / discard を先に選ばせる。

- **5-M2 inline edit と chat edit の意味が違いすぎる**
  - 推奨: inline は即 draft 更新、chat は LLM で差分オブジェクト生成後 draft 更新、どちらもレビュー履歴に積む。

## 6. SDK 呼び出し設定のアンチパターン

### High

- **6-H1 `maxOutputTokens` 等の capacity 系パラメータを業務要件なしに設定する**
  - 症状: reasoning token を消費するモデルで出力が途中打ち切りになり、structured output の parse failure として現れる。
  - 推奨: model default に任せる。設定するなら LLM 設定ファイルの 1 箇所に正本を集約し、コメントで根拠を明記する。temperature / topP 等も同様に、根拠のない先取り設定をしない。

- **6-H2 tool 制限・カテゴリ化で LLM の選択肢を先取りに狭める**
  - 症状: 呼び出せる tool を「使いそうなもの」だけに絞る、入力情報をカテゴリ・ラベルに要約してから渡す。
  - なぜ問題か: 実装側の予測が LLM の判断可能性の上限を決めてしまう。想定外の正しい選択肢を LLM から奪う。
  - 推奨: 生の情報と広い選択肢を渡す。制限するのは業務要件・セキュリティ上の理由がある時だけ。

## 7. 推奨パターン例

### 単位ごとの局所全量生成

```ts
type UnitChange = {
  id: string | null;
  value: UnitValue | null;
};
```

- `id:null, value` = 新規作成
- `id, value` = 既存の全量置換
- `id, value:null` = 既存の削除

注意:

- `id` は DB id ではなく alias。
- `value` は LLM 用の最小業務 schema。`sourceRefs`, `createdAt`, `generationId` は含めない。
- 既存 id が未知なら新規作成扱いにしない。新規作成は `id:null` のみ。
- 未変更の単位は output に含めない。

### Alias 変換

```ts
// prompt input
{ id: "p1", title: "..." }

// server map
p1 -> entity-cuid-or-uuid
```

- input token を削る。
- LLM の ID typo を減らす。
- DB 実装と prompt を分離する。

### LLM出力検証の境界（2-H6 / 2-H7 / 4-H4）

1. **schema**: 条件付き必須や状態とpayloadの対応を表現する。使用中のSDKが生成するJSON Schemaと対象APIの対応を確認する。
2. **照合**: 参照先・範囲・原文との対応を決定論的に確認する。引用の表記揺れと曖昧一致は、必要な精度に合わせて扱う。
3. **失敗処理**: 再実行できる単位、必要なエラー情報、再試行の上限、失敗時の表示を定める。

対象フローに必要な層を実装する。SDKやproviderの制約はバージョン依存として扱い、特定のschema構文や再試行回数を全フローへ固定しない。
