---
name: image2pptx
description: 画像（理想スライド画像）をもとに PPTX を生成し、生成→レンダリング→差分確認→修正のサイクルをハーネスで反復するスキル。標準はピクセル差分駆動、オプションで構造（layout.json）先行モードも選べる。「画像からPPTX再現」「スライド画像をPPTX化」「お手本画像に寄せる」などで発火。
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(python3:*), Bash(soffice:*), Bash(pdftocairo:*), Bash(pdftoppm:*), Bash(mkdir:*), Bash(ls:*), Bash(cp:*), Bash(rm:*), Bash(.claude/skills/slide\:image2pptx/scripts/*)
argument-hint: "お手本画像のパス（複数可）と出力先ディレクトリ"
---

# image2pptx Skill

## 目的

理想スライド画像（人手で作った1枚絵 / 既存資料のスクショ等）から、編集可能な PPTX を再現する。
1発で完璧に作るのは無理なので「生成→レンダリング→差分確認→修正」をループで回し、目視で十分な近さに到達するまで詰める。

## メインフローはハーネス制御

メインセッション（あなた）は **指示出しと判断に専念** する。実装は subagent 起動とスクリプト実行に委譲：

```
[0] テーマ抽出            → subagent: agents/theme_extractor.md → theme.json
[1] PPTX 初版生成（全ページ） → subagent: agents/pptx_modifier.md（mode=initial, theme.json 必須入力）
[2] PPTX → PDF / 画像     → スクリプト: scripts/pptx_to_pdf.sh, pptx_page_to_image.sh
[2.5] ピクセル差分検出     → スクリプト: scripts/diff_pixels.py（regions.json/overlay.png 出力）
[3] 差分確認・修正案列挙   → subagent: agents/diff_reviewer.md（regions.json + theme.json をエビデンスに）
[4a] patch ガード(before)  → スクリプト: scripts/patch_guard.py before（pre_diff_ratio 計測 + .bak 保存）
[4b] PPTX 修正             → subagent: agents/pptx_modifier.md（mode=patch, theme.json 必須入力）
[4c] patch ガード(after)   → スクリプト: scripts/patch_guard.py after（post_diff_ratio 計測、悪化なら自動ロールバック）
[5] [2] に戻る            → ページごとに収束 or 上限到達まで
[6] 全ページ整合性監査     → スクリプト: scripts/audit_consistency.py（audit.json 出力）
[7] 整合性 GC             → subagent: agents/consistency_enforcer.md（theme.json 逸脱を一括補正）
[8] [6] 再実行で検証       → deviations が許容内まで
[9] 完了ゲート判定         → スクリプト: scripts/check_completion_gate.py（PASS で初めて完了報告可）
```

**ループ上限**: 1ページあたり最大 4 周。`[6][7]` の整合性 GC は最大 2 周（収束しなければユーザーに判断を仰ぐ）。

**完了の三条件（[9] 完了ゲートで機械判定）**:
1. 全ページで `diff_ratio < 0.05`（diff_pixels.py の meta.json）
2. `audit.json` の `num_deviations == 0`
3. 各ページの最新 diff Markdown に `[critical]` 残件 0

3条件すべて PASS で初めて完了報告できる。**整合性 GC の 0 deviations は必要条件であって完了条件ではない**。
完了ゲートが FAIL なら: ループ上限に達していなければ [2] に戻る、上限到達ならユーザーに判断を仰ぐ。

**patch 悪化ガード（[4a][4c]）**:
- 各 patch 周回で `pre_diff_ratio` と `post_diff_ratio` を比較
- `post > pre * 1.10`（10% 以上悪化）なら **自動ロールバックして** advisor を必ず呼ぶ
- 過去事故: diff_reviewer 幻覚で modifier がテキスト改変 → 数値や固有名詞が壊れて見た目も悪化、を機械検出するための仕組み

### なぜテーマ＋整合性 GC が必要か

ページ独立フローのままだと、各ページの subagent がヘッダー y / 背景色 / フォント / ページ番号位置を **個別に推定** するので、ページ間で 5〜20px 単位の揺らぎが発生する。通しで見ると粗い印象になる。
`theme.json` を最初に固めて全 subagent の必須入力にし、最後に `audit_consistency.py` で逸脱を機械検出 → `consistency_enforcer` が一括補正することで、ページ間の一貫性を保証する。

## ディレクトリ規約

```
<workdir>/
├── reference/         # お手本画像（input）pageNN.png
├── theme.json         # 全ページ共通仕様（[0] で確定、以降は read-only）
├── layout.json        # （オプション: 構造先行モードのみ）構造仕様。[0.5] で作成
├── pptx/              # 生成 PPTX（current.pptx を常に最新に）
├── render/            # 生成 PPTX を PDF / 画像にレンダリングした結果
│   ├── current.pdf
│   └── pageNN.png
├── diff/              # 各ループの差分メモ pageNN_iterN.md と diff_pixels.py 出力
└── audit/             # audit_consistency.py の出力（audit.json / audit_after.json）
```

## スクリプト

- `scripts/pptx_to_pdf.sh <pptx> <outdir>` — PPTX を PDF へ変換
- `scripts/pptx_page_to_image.sh <pptx> <page> <outdir>` — 指定ページを PNG 化
- `scripts/pptx_all_pages_to_image.sh <pptx> <outdir>` — 全ページ PNG 化（差分確認の初手用）
- `scripts/diff_pixels.py <reference> <current> <out_dir>` — ピクセルレベル差分検出。`overlay.png` / `regions.json` / `meta.json` を出す。**diff_reviewer の必須入力**（依存: Pillow, numpy, scipy 推奨）
- `scripts/audit_consistency.py <pptx> <theme.json> <out.json>` — PPTX 全ページが theme.json から逸脱していないか機械監査。**consistency_enforcer の必須入力**（依存: python-pptx）
- `scripts/patch_guard.py before|after <workdir> <page_no>` — patch 周回の前後で diff_ratio を比較し、悪化していたら自動ロールバック。**親が patch 周回ごとに必ず呼ぶ**（依存: Pillow, numpy）
- `scripts/check_completion_gate.py <workdir>` — 完了ゲート三条件（diff_ratio / audit / critical 残）を機械判定。**親が完了報告する直前に必ず実行し、PASS でなければ完了と言わない**

soffice はヘッドレス＋一時プロファイルで起動するためロック競合しない。

## 依存（初回セットアップ）

```bash
pip install python-pptx pillow numpy scipy
brew install --cask libreoffice    # macOS, または apt install libreoffice
brew install poppler               # pdftocairo
```

## subagent

- `agents/theme_extractor.md` — 全 reference 画像から共通テーマ (色・フォント・ヘッダー位置・余白) を抽出して `theme.json` を確定する。**最初に必ず1回**
- `agents/pptx_modifier.md` — PPTX の新規作成 / 既存修正を python-pptx で行う。`theme.json` を必須入力で受け取り、そこから外れない
- `agents/diff_reviewer.md` — お手本画像と現状画像を `regions.json` ベースで機械的に突合して修正指示リストを返す。`theme.json` 逸脱もここで起票
- `agents/consistency_enforcer.md` — 全ページ生成後の GC 役。`audit.json` を読み theme.json 逸脱を一括補正してページ間の揺らぎを矯正する
- `agents/layout_architect.md`（オプション） — 構造先行モードでのみ使用。後述

## 親（メインセッション）の作法

1. お手本画像と作業ディレクトリを確定し、ディレクトリ規約どおりに配置する
2. 各ページについて [1]→[2]→[3]→[4a]→[4b]→[4c]→[2]... を順次回す（ページ単位の独立なら [3]/[4b] の subagent を並列起動）
3. diff_reviewer の出力を **そのまま** pptx_modifier に渡す（要約して情報落とさない）
4. **patch 周回ごとに必ず `patch_guard.py before` / `after` を呼ぶ**。after で ROLLBACK が出たら advisor を必ず呼ぶ（fallthrough 禁止）
5. ループ上限到達時はユーザーに「どこで打ち止めるか」を聞く
6. **完了報告の直前に `check_completion_gate.py` を必ず実行**。PASS でなければ完了と言わない（後述「完了報告フォーマット」を参照）

### 完了報告フォーマット（必須）

完了と言うときは、以下の形式で報告する。これを書けない＝完了ゲートが PASS していない＝完了ではない。

```
## 完了ゲート判定: PASS

- diff_threshold: 0.05
- audit_deviations: 0
- pages:
  - page01: diff_ratio=0.0XX, critical=0, status=PASS
  - page02: diff_ratio=0.0XX, critical=0, status=PASS
  - page03: diff_ratio=0.0XX, critical=0, status=PASS

成果物:
- PPTX: <path>
- PDF:  <path>
```

完了ゲート FAIL のまま「完了」と書くのは過去事故と同じパターンなので絶対に禁止。FAIL の場合は次のいずれかを選ぶ:

- ループ上限未達 → ループ続行（[2] に戻る）
- ループ上限到達 → ユーザーに判断仰ぎ「現状で打ち止め」「上限緩和して継続」「方針変更」を選んでもらう

### 過去事故と再発防止の対応関係

- 事故1: ショートカット完了判定（整合性 GC 0 deviations だけで完了報告）→ `check_completion_gate.py` で機械判定、PASS フォーマット強制
- 事故2: diff_reviewer 幻覚（reference にない要素の追加・数値改変を modifier に流した）→ diff_reviewer.md「起票スコープ」、pptx_modifier.md「テキスト改変ガード」、`patch_guard.py` の悪化検出 + 自動ロールバック

### 親は実装しない（厳守）

親はオーケストレーターであって実装者ではない。次は **すべて subagent に委譲する**：

- python-pptx での PPTX 生成・編集
- お手本画像 / 現状画像の詳細観察（HEX抽出・要素分解）
- diff の起票

親が直接やるのは:

- パス管理 / ディレクトリ作成 / スクリプト実行（pptx_to_pdf.sh, pptx_page_to_image.sh 等）
- subagent 起動（initial / patch / diff_reviewer）
- subagent から受け取ったファイルパスを次の subagent に渡す
- 収束判定とユーザー報告

「面倒だから自分で書く」「subagent dispatch ができないから代行する」は禁止。dispatch 不能環境ではループを止め「subagent dispatch 不可。スキル適用不可」とユーザーに報告する。

## subagent 起動プロトコル

各 subagent はコンテキスト独立で動かす。親は会話履歴を渡さず、ファイルパスとパラメータのみで通信する。

### 起動時の prompt 雛形

```
あなたは <pptx_modifier|diff_reviewer> として動く subagent です。

## 指示書
次のファイルを Read で全文読み、その手順に従って動作する:
- /<absolute path>/skills/image2pptx/agents/<pptx_modifier.md|diff_reviewer.md>

## 入力
- pptx_path: <絶対パス>
- page_number: <1始まり>
- reference_image_path: <絶対パス>
（mode=patch なら追加で）
- current_image_path: <絶対パス>
- diff_path: <絶対パス>
- iteration: <整数>
（diff_reviewer なら追加で）
- output_diff_path: <絶対パス>
- previous_diff_path: <任意、絶対パス>

## モード
mode=<initial|patch>

## 制約
- 指示書に書かれていない手順を勝手に増やさない
- 出力は指示書のフォーマットに従う
- 標準出力にはファイルパスのみ返す（要約レポートは別途、本文に）
```

- subagent_type は `general-purpose`（python-pptx・Bash・Read・Write が必要）
- 親の会話履歴は渡さない（prompt 内の入力以外で文脈を持たせない）
- subagent 出力は **ファイルパス**（pptx_path / output_diff_path）で受け取り、内容は親が読まずに次の subagent に渡す

## オプション: 構造先行モード（layout.json）

標準フローはピクセル差分の局所 patch で収束させる。ページ数が多い・カード/グリッド/カラムなど構造が複雑・局所 patch を繰り返しても構造の歪みが収束しない、という場合は **構造先行モード** に切り替える。

### 考え方

pixel diff だけで patch すると、赤く出た場所を個別 shape の移動・拡大縮小で直す局所最適になりやすい。実際のスライドは、ヘッダー、body grid、左右カラム、カード、表、注釈、ページ番号といった **構造** で成立している。
`layout.json` は Figma Auto Layout / CSS flex の概念を PPTX 生成前に持ち込むための内部 DSL。PowerPoint には Auto Layout がないため、`pptx_modifier` が `layout.json` の frame/component/constraints を EMU 座標へ解決して `python-pptx` の shape にコンパイルする。ピクセル差分は主制御ではなく、構造 spec の誤りや例外を検出する検証手段として使う。

修正は次の順に行う:
1. `layout.json` の frame / gap / padding / component token を直す（構造差分）
2. その構造から該当ページを再生成する
3. 残った leaf/cosmetic 差分だけ PPTX の shape を patch する

### フローへの追加

```
[0.5] 構造抽出            → subagent: agents/layout_architect.md → layout.json（frame/component/auto_layout/content）
[3] 差分確認・構造分類     → diff_reviewer が差分を structural / leaf / cosmetic に分類（theme.json / layout.json 逸脱も起票）
[3.5] 構造修正             → subagent: agents/layout_architect.md（structural 差分のみ、layout.json を更新して該当ページ再生成）
[4b] PPTX 局所修正         → pptx_modifier（mode=patch）。leaf/cosmetic 差分のみ、layout.json も必須入力に追加
```

`layout_architect.md` は Codex 版由来の subagent 指示書（`agents/layout_architect.md`）を流用する。Claude Agent ツールでも同じ指示書をそのまま `general-purpose` subagent に渡して起動できる。

### 並列性の制約（構造先行モード）

ページ単位で並列にしてよいのは、PPTX / layout.json に書き込まない read-only 工程（主に diff_reviewer）だけ。初版生成・構造修正・patch・整合性 GC は **直列**。`current.pptx` または `layout.json` へ同時書き込みしてはいけない。

### Codex 版を使う場合

Codex CLI / Codex App 上でこのスキルを動かす場合は、subagent 起動を Codex の内蔵 subagent spawn（`config.toml` の `multiagent_v2`）、Codex MCP server + Agents SDK、または `codex exec` のサブプロセス起動のいずれかに置き換える。詳細な起動プロトコルとモデル割り当て（`theme_extractor` / `layout_architect` / `consistency_enforcer` / `pptx_modifier` / `diff_reviewer` それぞれに推奨モデルを割り当てる `agents/openai.yaml`）は Codex 版の指示書を直接参照する。

### ありがちな失敗パターン（構造先行モード特有）

- **theme.json をスキップ**: 各ページが個別に背景色やヘッダーを推定 → ページ間で揺らぎ。`[0]` を必ず先に
- **layout.json をスキップ**: 画像差分の局所 patch だけで詰める → 構造が壊れ、ページ間の再現性が落ちる。`[0.5]` を必ず先に
- **構造差分を shape patch で直す**: body grid / column gap / card padding の問題を個別 shape 移動で直す → 収束が遅くなる。structural は layout.json を直す
- **要約して subagent に渡す**: 親が diff を要約 → 情報落ちで pptx_modifier が誤った修正をする。**ファイルパス渡し** を厳守
