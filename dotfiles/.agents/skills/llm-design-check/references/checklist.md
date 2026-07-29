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
  - なぜ問題か: schema 上、論理矛盾した出力（`outcome=superseded` かつ `supersededByClaimIdx=null` 等）が表現可能なままなので、LLM は確率的に必ずいつか出す。実機で生成処理全体が FAILED になってから気づく。
  - 推奨: 判別 union で不正状態を型として表現不可能にする。X の枝では B を非 null 必須に、それ以外の枝では B field 自体を持たせない。事後検証は「schema で表現できない制約」（範囲外 alias 参照・自己参照など）だけに絞る。
  - 注意: `z.discriminatedUnion` は使わず **`z.union`** で書く。zod4 の `z.toJSONSchema`（ai-sdk の変換経路）は discriminatedUnion をネスト位置に関わらず `oneOf` に変換し、OpenAI structured outputs (strict) は `oneOf` を一切受け付けない（`anyOf` のみ許可）。`z.union` なら `anyOf` になり通る。各枝に `z.literal` の判別 field を持たせれば `z.infer` の TS 型は discriminatedUnion 相当に絞り込める。
  - 注意: `z.union` を **schema のルート**に置くのも不可。OpenAI は strict 設定の有無に関わらずルートに `type: "object"` を必須とし、ルート union（anyOf ルート、type なし）はリクエスト自体が `Invalid schema ... got 'type: "None"'` で拒否される（実害: ある PR がルート直和化した結果その生成フローが全滅し、別 PR で復旧した実例がある）。`generateObject` に渡す schema のルートは必ず `z.object` にし、直和は envelope 用の wrapper 関数で 1 段ラップして response プロパティのネストに置く（例: `{ response: union }`）。

- **2-H7 LLM の逐語引用 (quote) を完全一致 (indexOf) で原文照合している**
  - 症状: LLM に原文からの逐語 quote を出させ、`text.indexOf(quote)` の完全一致で位置導出・捏造検証を行い、不一致で throw する。
  - なぜ問題か: LLM の「逐語」出力はソフト改行・NFKC 字形・markdown 装飾・句読点・助詞レベルで必ず揺れる（法律ドメイン実測で 50% 超が非逐語という報告がある）。揺れクラスを正規化で潰す対応は列挙合戦になり、例外が尽きない。
  - 推奨: 正規化キー（NFKC → whitespace 除去 → markdown 装飾除去）上の k 誤り許容 fuzzy 検索一本にする（`approx-string-match`、Hypothes.is 本番実績の Myers bit-parallel。k = quote キー長の 10%、誤り数最小 → 最先出現）。誤り 0 の完全一致は fuzzy が自然に最良候補として返すので、exact パスを別に持たない。**保存する quote は常にマッチした原文スパン**（`text.slice(start, end)`）にし、LLM の表記揺れを保存データへ持ち込まない。位置 (charRange) を LLM に自己申告させるのは論外（1-H3 と同根）。

- **2-H8 根拠付け方式（逐語 quote vs 行番号/ID 転記）をタスク性質と無関係に選んでいる**
  - 症状: 参照導線でしかない sourceRefs に逐語 quote を出させて出力トークンを浪費する。逆に、quote 自体が成果物データ（発言・主張の抽出結果）なのに ID 転記だけで済ませて原文を保存しない。
  - 判断軸は 2 つ（精度要求の高低ではない）: ① **quote が成果物データそのものか**（発言・条文を保存する）→ 逐語 + fuzzy 照合（2-H7）。**ただの参照導線か**（クリックで該当ページが開けばよい）→ 行番号/ID 転記 + 構造検証（実在・範囲内・重複排除のみ）。ID 特定は逐語スパン特定より機械的に易しく（近年の研究では Doc-F1 80-94% vs Snippet-F1 12-44% という報告がある）、「モデルは ID のみ出力、locator 解決はシステム側」が業界デファクト（主要 LLM プロバイダの公式ガイドが推奨するパターン）。② **「実在するが無関係な根拠」が業務判断を汚すか** → どちらの方式もこれを検出できない（ID 取り違えは実測数 % 程度、逐語 fuzzy も表層一致率に対し意味的含意率は大きく劣るとの報告がある）ため、方式選択でなく **後段の独立検証 call**（evidence 先行 schema + 資料再確認）で守る。
  - 参照導線の質を上げたくなったら、quote 併記（トークン増 + 逐語の低精度）ではなく **サーバー側 quote 復元**（行番号から該当テキストを機械抽出して表示。Citations API 型のパターンと同型、トークン増ゼロ）を先に検討する。
  - 前提: 引用精度の最大変数は方式でなくセグメンテーション・行番号付与の質。方式変更の前に LLM に見せる原文の切り方を疑う。

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
  - なぜ問題か: field を分けても、prompt の要求と schema の構造が食い違えば LLM は prompt に従って自由文側へはみ出す。「本文に書くな」という負の指示だけでは確率的に漏れ続ける。同一 context・同時出力でも、**prose field の隣に構造化根拠 slot がある要素は混入しない** ことが実測で確認されている — 混入の有無を分けるのは context の共有ではなく受け皿の有無。
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

- **4-H4 LLM 出力の検証違反 1 件で、修正機会なしにジョブ全体を即 FAILED にする**
  - 症状: normalize が最初の違反で汎用 `Error` を throw し、そのまま生成処理全体が落ちる。LLM には何が悪かったか伝わらず、ユーザーは全部やり直し。
  - なぜ問題か: LLM の違反は確率的に必ず起きる（違反率 1% でも呼び出し 50 回で約 4 割の資料が失敗する）。「検証の厳しさ」と「失敗の重さ」は別の問題で、前者を緩めずに後者だけ下げられる。
  - 推奨: ①違反は最初の 1 件で止めず全件収集し、違反一覧を保持する専用エラークラスで throw する ②service 層でその型だけ catch し、元プロンプト + 違反一覧 + 修正指示のフィードバック付きプロンプトで **失敗した単位（セグメント / トピック）だけ** 1 回リトライする ③リトライも失敗したら fail-fast（これはフォールバックではなく LLM への修正機会。デフォルト値で握りつぶす 4-H1 型のフォールバックとは区別し、コメントに明記する）。

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

### LLM 出力検証の 3 層（2-H6 / 2-H7 / 4-H4 の適用形）

LLM 出力を「検証して不正なら落とす」機能を新規に作るときは、この 3 層を最初から揃える。個別の正規化ルール・null チェックを後追いで足していく設計にしない。

1. **schema 層 — 不正を表現不可能にする**: 条件付き必須は判別 union（`z.union` + 各枝 `z.literal`。`z.discriminatedUnion` は OpenAI strict 非互換の `oneOf` になるため使わない）。nullable + describe「〜のときだけ必須」で済ませない（2-H6）。prompt が要求する粒度（項目単位の根拠等）には schema 側に同じ粒度の受け皿を用意する（3-H4）。
2. **照合層 — 決定論導出 + 揺れ耐性**: 位置・ID・参照はサーバー側で決定論的に導出する。原文照合が要るなら正規化キー + fuzzy 検索一本（2-H7）、alias 参照なら範囲・自己参照チェック。「LLM が正確に写す」ことを前提にした完全一致に頼らない。
3. **失敗処理層 — 全件収集 + 局所リトライ 1 回 + fail-fast**: 違反は専用エラークラスに全件集め、失敗した単位だけフィードバック付きで 1 回リトライ、それでもだめなら FAILED（4-H4）。

OpenAI structured outputs の制約に注意（strict の有無に関わらず適用されるものを含む）:

- `oneOf` は位置を問わず不可（strict 時。`anyOf` のみ許可）。zod4 の `z.toJSONSchema` は `z.discriminatedUnion` → `oneOf`、`z.union` → `anyOf` に変換するため、LLM output schema の直和は常に `z.union` で書く。
- ルートは `type: "object"` 必須（strict 設定と無関係）。ルート `z.union` は anyOf ルート（type なし）になりリクエスト自体が拒否される。直和をトップに置きたいときは envelope 用の wrapper 関数で `{ response: union }` に 1 段ラップする。schema の形の誤りは typecheck では検出できず実 API で初めて割れるため、新設・変更時はこの 2 点を必ず確認する。
