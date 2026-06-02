#!/bin/bash
# Step 3 — Stem separation + sort by quality
# Usage: bash 03-stems.sh <job_id>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

JOB_ID="$1"
read_status "$JOB_ID"

STEMS_DIR="$JOB_DIR/stems"
INPUT_FILE="$JOB_DIR/${SONG_NAME}.${EXT}"

update_step "$JOB_ID" stems running
log "Step 3: extracting stems"

# Pass 1 — 6 stems (piano, guitar, other...)
.env-stems/bin/python3 -m demucs -n htdemucs_6s -d cuda \
  -o "$STEMS_DIR/6s" "$INPUT_FILE"

# Pass 2 — ft full (bass + drums, max quality)
.env-stems/bin/python3 -m demucs -n htdemucs_ft -d cuda \
  -o "$STEMS_DIR/ft" "$INPUT_FILE"

# Pass 3 — dedicated vocal separation
.env-stems/bin/python3 -m demucs -n htdemucs_ft -d cuda --two-stems=vocals \
  -o "$STEMS_DIR/ft_vocals" "$INPUT_FILE"

# Merge: replace bass & drums with higher-quality ft versions
cp "$STEMS_DIR/ft/htdemucs_ft/$SONG_NAME/bass.wav"  "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/bass.wav"
cp "$STEMS_DIR/ft/htdemucs_ft/$SONG_NAME/drums.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/drums.wav"

# Keep both "other" variants
mv "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/other.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/instrs_without_guitar_piano.wav"
cp "$STEMS_DIR/ft/htdemucs_ft/$SONG_NAME/other.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/instrs.wav"

# Use dedicated vocal-pass for cleaner separation
cp "$STEMS_DIR/ft_vocals/htdemucs_ft/$SONG_NAME/vocals.wav"    "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/vocals.wav"
cp "$STEMS_DIR/ft_vocals/htdemucs_ft/$SONG_NAME/no_vocals.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/no_vocals.wav"

# Flatten: prefix each stem with SONG_NAME
for file in "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME"/*.wav; do
  mv "$file" "$STEMS_DIR/${SONG_NAME}_$(basename "$file")"
done
rm -rf "$STEMS_DIR/6s" "$STEMS_DIR/ft" "$STEMS_DIR/ft_vocals"

log "Step 3b: sorting stems by quality"
mkdir -p "$STEMS_DIR/best_quality" "$STEMS_DIR/regular_quality"

for stem in drums bass vocals no_vocals instrs; do
  src="$STEMS_DIR/${SONG_NAME}_${stem}.wav"
  [ -f "$src" ] && mv "$src" "$STEMS_DIR/best_quality/"
done
move_files "$STEMS_DIR" "$STEMS_DIR/regular_quality" "*.wav"

update_step "$JOB_ID" stems done
log "Step 3: done"
