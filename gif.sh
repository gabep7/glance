#!/bin/bash
# Convert a QuickTime screen recording (.mov) to an optimized GIF.
# Usage: ./gif.sh recording.mov [output.gif]
#
# Workflow (more reliable than vhs for nested :terminal):
#   1. Cmd+Shift+5 → "Record Selected Portion"
#   2. Select nvim window area, hit Record
#   3. Run the demo: type :Glance, scroll, edit, toggle keymaps
#   4. Hit Stop in menu bar (file lands on Desktop)
#   5. ./gif.sh ~/Desktop/Screen\ Recording*.mov demo.gif

set -e

INPUT="${1}"
OUTPUT="${2:-demo.gif}"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "usage: $0 <recording.mov> [output.gif]"
  exit 1
fi

TMP_PALETTE="/tmp/glance_demo_palette.png"

echo "input:  $INPUT"
echo "output: $OUTPUT"
echo ""

echo "→ generating palette..."
ffmpeg -y -i "$INPUT" \
  -vf "fps=15,scale=800:-1:flags=lanczos,palettegen=stats_mode=diff" \
  "$TMP_PALETTE" 2>&1 | tail -1

echo "→ encoding gif..."
ffmpeg -y -i "$INPUT" -i "$TMP_PALETTE" \
  -lavfi "fps=15,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5" \
  "$OUTPUT" 2>&1 | tail -1

SIZE=$(du -h "$OUTPUT" | cut -f1)
echo ""
echo "done: $OUTPUT ($SIZE)"
rm -f "$TMP_PALETTE"
