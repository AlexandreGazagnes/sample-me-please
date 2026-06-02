#!/bin/bash
# Shared config, helpers, and status.json utilities.
# Source this file from all pipeline scripts: source "$(dirname "$0")/../lib.sh"

REQUESTS_DIR="data/requests"
JOBS_DIR="data/jobs"
PROCESSING_DIR="data/processing"
PROCESSED_DIR="data/processed"
REFUSED_DIR="data/refused"

log()        { echo "[$(date +%H:%M:%S)] $*"; }
move_files() {
  local src_dir="$1" dst_dir="$2" pattern="$3"
  for f in "$src_dir"/$pattern; do
    [ -f "$f" ] && mv "$f" "$dst_dir/"
  done
}

# Read status.json for a job and export SONG_NAME, SOURCE_FILE, EXT, JOB_DIR, OUTPUT_PATH
read_status() {
  local job_id="$1"
  local status_file="$PROCESSING_DIR/$job_id/status.json"
  [ -f "$status_file" ] || { echo "ERROR: status.json not found for $job_id"; exit 1; }
  eval "$(python3 -c "
import json, shlex
d = json.load(open('$status_file'))
print('SONG_NAME='    + shlex.quote(d['song_name']))
print('SOURCE_FILE='  + shlex.quote(d['source_file']))
print('EXT='          + shlex.quote(d['ext']))
print('JOB_DIR='      + shlex.quote('$PROCESSING_DIR/' + d['job_id']))
print('OUTPUT_PATH='  + shlex.quote(d['output_path'] or ''))
")"
}

# Write initial status.json: write_status job_id source_file song_name ext
write_status() {
  local job_id="$1" source_file="$2" song_name="$3" ext="$4"
  mkdir -p "$PROCESSING_DIR/$job_id"
  python3 -c "
import json
from datetime import datetime
d = {
  'job_id':      '$job_id',
  'song_name':   '$song_name',
  'source_file': '$source_file',
  'ext':         '$ext',
  'created_at':  datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
  'output_path': None,
  'steps': {
    'quality':   'pending',
    'workspace': 'pending',
    'stems':     'pending',
    'clean':     'pending',
    'midi':      'pending',
    'assemble':  'pending',
  }
}
json.dump(d, open('$PROCESSING_DIR/$job_id/status.json', 'w'), indent=2)
"
}

# Update a top-level key in status.json: update_status job_id key value
update_status() {
  local job_id="$1" key="$2" value="$3"
  local status_file="$PROCESSING_DIR/$job_id/status.json"
  python3 -c "
import json
f = '$status_file'
d = json.load(open(f))
d['$key'] = '$value'
json.dump(d, open(f, 'w'), indent=2)
"
}

# Update a step status inside the steps dict: update_step job_id step_name status
update_step() {
  local job_id="$1" step="$2" status="$3"
  local status_file="$PROCESSING_DIR/$job_id/status.json"
  python3 -c "
import json
f = '$status_file'
d = json.load(open(f))
d['steps']['$step'] = '$status'
json.dump(d, open(f, 'w'), indent=2)
"
}
