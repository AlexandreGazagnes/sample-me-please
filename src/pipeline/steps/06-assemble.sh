#!/bin/bash
# Step 6 — Assemble processed output
# Usage: bash 06-assemble.sh <job_id>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

JOB_ID="$1"
read_status "$JOB_ID"

STEMS_DIR="$JOB_DIR/stems"
MIDI_DIR="$JOB_DIR/midi"

update_step "$JOB_ID" assemble running
log "Step 6: assembling output"

OUT_DIR="$PROCESSED_DIR/$JOB_ID"
mkdir -p \
  "$OUT_DIR/source" \
  "$OUT_DIR/stems/best_quality" \
  "$OUT_DIR/stems/regular_quality" \
  "$OUT_DIR/midi/best_quality" \
  "$OUT_DIR/midi/regular_quality"

cp "$JOB_DIR/${SONG_NAME}.${EXT}" "$OUT_DIR/source/${SONG_NAME}.${EXT}"

move_files "$STEMS_DIR/best_quality"    "$OUT_DIR/stems/best_quality"    "*.wav"
move_files "$STEMS_DIR/regular_quality" "$OUT_DIR/stems/regular_quality" "*.wav"
move_files "$MIDI_DIR/best_quality"     "$OUT_DIR/midi/best_quality"     "*.mid"
move_files "$MIDI_DIR/regular_quality"  "$OUT_DIR/midi/regular_quality"  "*.mid"

update_status "$JOB_ID" output_path "$OUT_DIR"
update_step   "$JOB_ID" assemble    done

cp "$JOB_DIR/status.json" "$OUT_DIR/status.json"
rm -rf "$JOB_DIR"

log "Step 6: done — output → $OUT_DIR"
