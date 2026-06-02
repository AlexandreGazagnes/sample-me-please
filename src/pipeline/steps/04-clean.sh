#!/bin/bash
# Step 4 — Vocal cleaning
# Usage: bash 04-clean.sh <job_id>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

JOB_ID="$1"
read_status "$JOB_ID"

STEMS_DIR="$JOB_DIR/stems"
CLEAN2_DIR="$JOB_DIR/cleaned_2"

update_step "$JOB_ID" clean running
log "Step 4: cleaning vocals"

.env-clean-2/bin/python3 .env-clean-2/bin/audio-separator \
  "$STEMS_DIR/best_quality/${SONG_NAME}_vocals.wav" \
  --model_filename MDX23C-8KFFT-InstVoc_HQ.ckpt \
  --output_dir "$CLEAN2_DIR/" \
  --output_format WAV \
  --single_stem Vocals

mv "$(find "$CLEAN2_DIR" -name "*.wav" | head -1)" \
   "$STEMS_DIR/best_quality/${SONG_NAME}_vocals_clean_2.wav"

update_step "$JOB_ID" clean done
log "Step 4: done"
