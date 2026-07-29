#!/usr/bin/env bash
# PPTX → PDF（全ページ）
# Usage: pptx_to_pdf.sh <pptx_path> <outdir>
set -euo pipefail

PPTX="${1:?pptx path required}"
OUTDIR="${2:?outdir required}"

if [ ! -f "$PPTX" ]; then
  echo "ERROR: pptx not found: $PPTX" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

# 一時ユーザープロファイルでロック競合を回避
PROFILE_DIR="$(mktemp -d -t lo-profile-XXXXXX)"
trap 'rm -rf "$PROFILE_DIR"' EXIT

soffice --headless \
  -env:UserInstallation="file://$PROFILE_DIR" \
  --convert-to pdf \
  --outdir "$OUTDIR" \
  "$PPTX" >/dev/null

BASENAME="$(basename "${PPTX%.*}").pdf"
echo "$OUTDIR/$BASENAME"
