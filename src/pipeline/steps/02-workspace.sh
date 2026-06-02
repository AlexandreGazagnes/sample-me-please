#!/bin/bash
# Step 2 — Setup processing workspace
# Usage: bash 02-workspace.sh <job_id> <source_path>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib.sh"

JOB_ID="$1"
SOURCE_PATH="$2"

read_status "$JOB_ID"

log "Step 2: setting up processing workspace"

JOB_DIR="$PROCESSING_DIR/$JOB_ID"
mkdir -p "$JOB_DIR/stems" "$JOB_DIR/cleaned_2" "$JOB_DIR/midi"
cp "$SOURCE_PATH" "$JOB_DIR/${SONG_NAME}.${EXT}"

update_step "$JOB_ID" workspace done
