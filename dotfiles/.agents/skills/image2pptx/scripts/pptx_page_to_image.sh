#!/usr/bin/env bash
# PPTX の指定ページを PNG にする
# Usage: pptx_page_to_image.sh <pptx_path> <page_number> <outdir> [dpi]
# 出力: <outdir>/<basename>_pageNN.png （標準出力にパス）
set -euo pipefail

PPTX="${1:?pptx path required}"
PAGE="${2:?page number required}"
OUTDIR="${3:?outdir required}"
DPI="${4:-150}"

if [ ! -f "$PPTX" ]; then
  echo "ERROR: pptx not found: $PPTX" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR="$(mktemp -d -t pptx2img-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

# まず PDF 化
PDF_PATH="$("$SCRIPT_DIR/pptx_to_pdf.sh" "$PPTX" "$TMPDIR")"

BASENAME="$(basename "${PPTX%.*}")"
PAGE_PADDED="$(printf '%02d' "$PAGE")"
OUT_PNG="$OUTDIR/${BASENAME}_page${PAGE_PADDED}.png"

# pdftocairo で指定ページのみ PNG 化
pdftocairo -png -r "$DPI" -f "$PAGE" -l "$PAGE" -singlefile "$PDF_PATH" "${OUT_PNG%.png}"

echo "$OUT_PNG"
