#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ── Bootstrap ────────────────────────────────────────────────────────────────

mkdir -p "$REQUESTS_DIR" "$JOBS_DIR" "$PROCESSING_DIR" "$PROCESSED_DIR" "$REFUSED_DIR"

# ── Input ────────────────────────────────────────────────────────────────────

if [ $# -ge 1 ]; then
  ARG="$1"
else
  read -rp "Source file (path or filename in requests/): " ARG
fi

if [ -f "$ARG" ]; then
  SOURCE_PATH="$ARG"
  SOURCE_FILE=$(basename "$ARG")
else
  SOURCE_FILE="$ARG"
  SOURCE_PATH="$REQUESTS_DIR/$SOURCE_FILE"
fi

EXT="${SOURCE_FILE##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
SONG_NAME="${SOURCE_FILE%.*}"

[ -f "$SOURCE_PATH" ] || { echo "ERROR: file not found: $SOURCE_PATH"; exit 1; }

# ── Steps ────────────────────────────────────────────────────────────────────

bash "$SCRIPT_DIR/steps/00-quality.sh" "$SOURCE_PATH" "$EXT_LOWER"

JOB_ID="${SONG_NAME}_$(openssl rand -hex 4)"
write_status "$JOB_ID" "$SOURCE_FILE" "$SONG_NAME" "$EXT_LOWER"

bash "$SCRIPT_DIR/steps/01-job.sh"       "$JOB_ID" "$SOURCE_FILE" "$SONG_NAME"
bash "$SCRIPT_DIR/steps/02-workspace.sh" "$JOB_ID" "$SOURCE_PATH"
bash "$SCRIPT_DIR/steps/03-stems.sh"     "$JOB_ID"
bash "$SCRIPT_DIR/steps/04-clean.sh"     "$JOB_ID"
bash "$SCRIPT_DIR/steps/05-midi.sh"      "$JOB_ID"
bash "$SCRIPT_DIR/steps/06-assemble.sh"  "$JOB_ID"

log "Done. Job: $JOB_ID"
