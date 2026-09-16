---
name: image2pptx
description: 画像（理想スライド画像）をもとに PPTX を生成し、生成→レンダリング→差分確認→修正のサイクルをハーネスで反復するスキル。標準はピクセル差分駆動、オプションで構造（layout.json）先行モードも選べる。「画像からPPTX再現」「スライド画像をPPTX化」「お手本画像に寄せる」などで発火。
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(python3:*), Bash(soffice:*), Bash(pdftocairo:*), Bash(pdftoppm:*), Bash(mkdir:*), Bash(ls:*), Bash(cp:*)
argument-hint: "お手本画像のパス（複数可）と出力先ディレクトリ"
---

# image2pptx

お手本画像から編集可能なPPTXを再現する。生成・描画・比較・修正を繰り返し、内容の正確さと見た目を検証する。以下のパスはこのスキルのディレクトリを基準にする。

## 作業ディレクトリ

```text
<workdir>/
├── reference/       # pageNN.png
├── theme.json       # 共通の色・フォント・余白・配置
├── layout.json      # 構造先行モードのみ
├── pptx/current.pptx
├── render/          # current.pdf / pageNN.png
├── diff/            # pageNN_iterN.md / ピクセル差分
└── audit/           # audit.json
```

## フロー

1. お手本・出力先・ページ順を確定し、共通テーマを`theme.json`に抽出する。表紙など意図的な例外も記録する。
2. テーマを使って全ページの初版を生成する。数値・固有名詞・本文はお手本と照合する。
3. PPTXを描画し、ピクセル差分と画像の目視から修正箇所を特定する。差分で見えた形だけで内容を推測して追加しない。
4. patch前に`patch_guard.py before`、修正後に`after`を実行する。差分率が10%超悪化してロールバックされたら、原画像と修正指示を再確認して原因を直す。
5. 全ページの整合性を`audit_consistency.py`で確認し、テーマからの意図しない逸脱を修正する。修正後は描画と比較も更新する。
6. 最終成果物に対して`check_completion_gate.py`を実行し、PPTX・PDFと検証結果を報告する。

ピクセル修正は1ページ4周、整合性修正は2周を目安にする。改善が止まったら原因と残差を整理し、構造修正など有効な方法へ切り替える。品質基準の緩和や依頼範囲の変更が必要な場合に判断を求める。

## 検証

ハーネスの完了条件は全ページ`diff_ratio < 0.05`、`audit.json`の`num_deviations == 0`、最新の差分Markdownに`[critical]`残件なし。
ゲートのPASS/FAILと未解決事項を正確に報告する。ユーザーが別の品質基準を指定した場合は、その基準とハーネスの判定を区別する。FAILをPASSとして報告しない。

数値指標だけでなく、本文・数値・固有名詞、はみ出し、ページ間の整合性を目視で確認する。

## スクリプト

- `scripts/pptx_to_pdf.sh <pptx> <outdir>` — PDF化
- `scripts/pptx_page_to_image.sh <pptx> <page> <outdir>` — 指定ページのPNG化
- `scripts/pptx_all_pages_to_image.sh <pptx> <outdir>` — 全ページのPNG化
- `scripts/diff_pixels.py <reference> <current> <out_dir>` — `overlay.png / regions.json / meta.json`
- `scripts/patch_guard.py before|after <workdir> <page_no>` — 差分率の比較と悪化時の復元
- `scripts/audit_consistency.py <pptx> <theme.json> <out.json>` — テーマ逸脱の検出
- `scripts/check_completion_gate.py <workdir>` — 完了条件の判定

依存はpython-pptx、Pillow、numpy、LibreOffice、Poppler。scipyは差分検出で推奨。環境の導入済み依存を使い、不足分だけ追加する。

## 分担と入力契約

単独実行でも分担でも同じ成果物と検証を使う。複数ページの観察や独立レビューはサブエージェントに分担できる。利用できない場合は順次実施する。
**同じ`current.pptx`、`layout.json`、バックアップへの書き込みは全モードで直列にする。** 並列化するのは独立した読取工程、または別成果物へ書く工程だけ。

役割ごとの手順は必要なものを読む:

- `agents/theme_extractor.md` — お手本一式から`theme.json`
- `agents/pptx_modifier.md` — 初版生成・patch
- `agents/diff_reviewer.md` — 原画像・現画像・`regions.json`・テーマから差分起票
- `agents/consistency_enforcer.md` — `audit.json`を使う整合性修正
- `agents/layout_architect.md` — 構造先行モードの`layout.json`

分担時は指示書の絶対パス、原画像、PPTX、ページ番号、`theme.json`、作業モードを渡す。patchには現画像・差分Markdown・iteration、レビューには`regions.json`・出力先・前回差分を追加する。
返答には成果物パスと未解決事項を含める。詳細差分はファイルのまま共有し、親も採否判断に必要な箇所を確認する。利用可能なエージェント機能を使い、モデルを固定しない。

## 構造先行モード

カード・グリッド・複数カラムが複雑、または局所patchで構造の歪みが収束しない場合に使う。
テーマ抽出後に`layout.json`のframe/component/constraintsを定め、EMU座標へ解決してPPTXを生成する。

1. 差分をstructural / leaf / cosmeticに分類する。
2. structuralは`layout.json`のframe・gap・padding・共通tokenを修正して再生成する。
3. 残ったleaf/cosmetic差分だけshapeをpatchする。

このモードではmodifier・reviewerにも`layout.json`を渡す。ピクセル差分は構造仕様の誤りや例外の検証に使う。
