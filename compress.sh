#!/usr/bin/env bash
# Compress all originals in two pipelines:
#
# Static images (JPG/PNG → WebP):
#   cwebp -q N -metadata icc -mt -exact -m 6 input -o output
#
# Animated GIFs → WebM (VP9):
#   ffmpeg -i input -c:v libvpx-vp9 -crf 30 -b:v 0 -an output
#
# Flags (cwebp):
#   -q N          Quality level (0-100)
#   -metadata icc Preserve ICC color profile
#   -mt           Multi-threaded encoding
#   -exact        Preserve RGB values in transparent areas
#   -m 6          Best compression method (slowest encode, smallest output)
#
# Flags (ffmpeg VP9):
#   -c:v libvpx-vp9  VP9 video codec
#   -crf 30          Constant rate factor (quality)
#   -b:v 0           Let CRF fully control quality
#   -an              No audio track

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORIGINALS="$SCRIPT_DIR/originals"

QUALITIES=(60 70 80)

for q in "${QUALITIES[@]}"; do
  mkdir -p "$SCRIPT_DIR/webp-q${q}"
done
mkdir -p "$SCRIPT_DIR/webm"

static_count=0
gif_count=0

for src in "$ORIGINALS"/*; do
  [ -f "$src" ] || continue
  basename="$(basename "$src")"
  stem="${basename%.*}"
  ext="${basename##*.}"

  case "$ext" in
    gif)
      # Animated GIF → WebM (VP9)
      out="$SCRIPT_DIR/webm/${stem}.webm"
      echo "  webm: $basename -> ${stem}.webm"
      ffmpeg -y -i "$src" -c:v libvpx-vp9 -crf 30 -b:v 0 -an "$out" 2>/dev/null
      gif_count=$((gif_count + 1))
      ;;
    *)
      # Static image → WebP at three quality levels
      for q in "${QUALITIES[@]}"; do
        OUTDIR="$SCRIPT_DIR/webp-q${q}"
        out="$OUTDIR/${stem}.webp"
        echo "  q${q}: $basename -> ${stem}.webp"
        cwebp -q "$q" -metadata icc -mt -exact -m 6 "$src" -o "$out" 2>/dev/null
      done
      static_count=$((static_count + 1))
      ;;
  esac
done

echo ""
echo "Done: $static_count static images (WebP q60/q70/q80), $gif_count GIFs (WebM VP9)"
echo ""

# Print size summary
for q in "${QUALITIES[@]}"; do
  OUTDIR="$SCRIPT_DIR/webp-q${q}"
  size=$(du -sh "$OUTDIR" | cut -f1)
  echo "  webp-q${q}: $size"
done

if [ -d "$SCRIPT_DIR/webm" ] && [ "$(ls -A "$SCRIPT_DIR/webm" 2>/dev/null)" ]; then
  webm_size=$(du -sh "$SCRIPT_DIR/webm" | cut -f1)
  echo "  webm:    $webm_size"
fi

orig_size=$(du -sh "$ORIGINALS" | cut -f1)
echo "  originals: $orig_size"
