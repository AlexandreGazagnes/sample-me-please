#!/bin/bash
# Step 0 — Quality check
# Usage: bash 00-quality.sh <source_path> <ext_lower>
# Exit 0 = pass, exit 1 = fail (file moved to refused/)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

SOURCE_PATH="$1"
EXT_LOWER="$2"

log "Step 0: quality check"

PROBE=$(ffprobe -v quiet -print_format json -show_streams "$SOURCE_PATH")

CODEC=$(echo "$PROBE"      | python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s['codec_name'])")
BIT_RATE=$(echo "$PROBE"   | python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s.get('bit_rate', 0))")
BIT_DEPTH=$(echo "$PROBE"  | python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s.get('bits_per_raw_sample') or s.get('bits_per_coded_sample') or 0)")
SAMPLE_RATE=$(echo "$PROBE"| python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s.get('sample_rate', 0))")

echo "  codec:       $CODEC"
echo "  bit rate:    $((BIT_RATE / 1000)) kbps"
echo "  bit depth:   $BIT_DEPTH bit"
echo "  sample rate: $SAMPLE_RATE Hz"

QUALITY_OK=1

case "$EXT_LOWER" in
  mp3)
    if [ "$BIT_RATE" -lt 320000 ]; then
      echo "  FAIL: MP3 at $((BIT_RATE / 1000)) kbps — 320 kbps required"
      QUALITY_OK=0
    else
      echo "  OK: MP3 at $((BIT_RATE / 1000)) kbps"
    fi
    ;;
  flac|wav|aiff|aif)
    if [ "$BIT_DEPTH" -lt 16 ]; then
      echo "  FAIL: bit depth $BIT_DEPTH — minimum 16-bit required"
      QUALITY_OK=0
    else
      echo "  OK: ${BIT_DEPTH}-bit $EXT_LOWER"
    fi
    ;;
  *)
    echo "  WARN: unrecognised format '$EXT_LOWER' — skipping quality check"
    ;;
esac

if [ "$QUALITY_OK" -eq 0 ]; then
  mv "$SOURCE_PATH" "$REFUSED_DIR/"
  echo "ERROR: quality check failed — file moved to $REFUSED_DIR/. Aborting."
  exit 1
fi
