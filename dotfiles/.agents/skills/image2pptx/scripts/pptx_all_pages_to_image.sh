#!/usr/bin/env bash
# PPTX 全ページを PNG 化
# Usage: pptx_all_pages_to_image.sh <pptx_path> <outdir> [dpi]
# 出力: <outdir>/<basename>_pageNN.png 群（標準出力に各パス）
set -euo pipefail

PPTX="${1:?pptx path required}"
OUTDIR="${2:?outdir required}"
DPI="${3:-150}"

if [ ! -f "$PPTX" ]; then
  echo "ERROR: pptx not found: $PPTX" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR="$(mktemp -d -t pptx2img-all-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

PDF_PATH="$("$SCRIPT_DIR/pptx_to_pdf.sh" "$PPTX" "$TMPDIR")"

BASENAME="$(basename "${PPTX%.*}")"
PREFIX="$OUTDIR/${BASENAME}_page"

# pdftocairo の連番出力（-2桁ゼロパディング）
pdftocairo -png -r "$DPI" "$PDF_PATH" "$PREFIX"

# 出力ファイルを 2 桁ゼロパディングへ整える（pdftocairo は ページ桁数固定でないため）
# 連番リネーム
cd "$OUTDIR"
for f in "${BASENAME}_page-"*.png; do
  [ -f "$f" ] || continue
  num="${f##*-}"
  num="${num%.png}"
  padded="$(printf '%02d' "$num")"
  newname="${BASENAME}_page${padded}.png"
  mv -f "$f" "$newname"
  echo "$OUTDIR/$newname"
done
