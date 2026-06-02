#!/bin/bash
# Step 5 — MIDI conversion + sort by quality
# Usage: bash 05-midi.sh <job_id>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

JOB_ID="$1"
read_status "$JOB_ID"

STEMS_DIR="$JOB_DIR/stems"
MIDI_DIR="$JOB_DIR/midi"

update_step "$JOB_ID" midi running
log "Step 5: converting stems to MIDI"

for f in "$STEMS_DIR/best_quality"/*.wav "$STEMS_DIR/regular_quality"/*.wav; do
  [ -f "$f" ] || continue
  base=$(basename "$f" .wav)
  log "  converting $base"
  tmp_dir=$(mktemp -d)
  .env-midi/bin/python3.11 .env-midi/bin/basic-pitch "$tmp_dir" "$f"
  mv "$tmp_dir"/*.mid "$MIDI_DIR/$base.mid"
  rm -rf "$tmp_dir"
done

log "Step 5b: sorting MIDI by quality"
mkdir -p "$MIDI_DIR/best_quality" "$MIDI_DIR/regular_quality"

for stem in vocals bass drums; do
  src="$MIDI_DIR/${SONG_NAME}_${stem}.mid"
  [ -f "$src" ] && mv "$src" "$MIDI_DIR/best_quality/"
done
move_files "$MIDI_DIR" "$MIDI_DIR/regular_quality" "*.mid"

update_step "$JOB_ID" midi done
log "Step 5: done"
