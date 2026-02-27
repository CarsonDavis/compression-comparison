#!/usr/bin/env bash
# Compress all originals to WebP at three quality levels
# Uses cwebp flags from CarsonDavis.github.io pipeline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORIGINALS="$SCRIPT_DIR/originals"

QUALITIES=(60 70 80)

for q in "${QUALITIES[@]}"; do
  OUTDIR="$SCRIPT_DIR/webp-q${q}"
  mkdir -p "$OUTDIR"
done

total=0
converted=0

for src in "$ORIGINALS"/*; do
  [ -f "$src" ] || continue
  basename="$(basename "$src")"
  stem="${basename%.*}"
  total=$((total + 1))

  for q in "${QUALITIES[@]}"; do
    OUTDIR="$SCRIPT_DIR/webp-q${q}"
    out="$OUTDIR/${stem}.webp"
    echo "  q${q}: $(basename "$src") -> ${stem}.webp"
    cwebp -q "$q" -metadata icc -mt -exact -m 6 "$src" -o "$out" 2>/dev/null
  done

  converted=$((converted + 1))
done

echo ""
echo "Done: converted $converted / $total images at qualities ${QUALITIES[*]}"
echo ""

# Print size summary
for q in "${QUALITIES[@]}"; do
  OUTDIR="$SCRIPT_DIR/webp-q${q}"
  size=$(du -sh "$OUTDIR" | cut -f1)
  echo "  webp-q${q}: $size"
done

orig_size=$(du -sh "$ORIGINALS" | cut -f1)
echo "  originals: $orig_size"
