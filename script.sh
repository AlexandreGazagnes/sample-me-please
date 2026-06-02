#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────────────────

REQUESTS_DIR="data/requests"
JOBS_DIR="data/jobs"
PROCESSING_DIR="data/processing"
PROCESSED_DIR="data/processed"
REFUSED_DIR="data/refused"

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

log() { echo "[$(date +%H:%M:%S)] $*"; }

move_files() {
  local src_dir="$1" dst_dir="$2" pattern="$3"
  for f in "$src_dir"/$pattern; do
    [ -f "$f" ] && mv "$f" "$dst_dir/"
  done
}

# ──────────────────────────────────────────────────────────────────────────────
# Bootstrap — ensure root folders exist
# ──────────────────────────────────────────────────────────────────────────────

mkdir -p "$REQUESTS_DIR" "$JOBS_DIR" "$PROCESSING_DIR" "$PROCESSED_DIR" "$REFUSED_DIR"

# ──────────────────────────────────────────────────────────────────────────────
# Input
# ──────────────────────────────────────────────────────────────────────────────

if [ $# -ge 1 ]; then
  SOURCE_FILE="$1"
else
  read -rp "Source file (in requests/): " SOURCE_FILE
fi

SOURCE_PATH="$REQUESTS_DIR/$SOURCE_FILE"
EXT="${SOURCE_FILE##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
SONG_NAME="${SOURCE_FILE%.*}"

[ -f "$SOURCE_PATH" ] || { echo "ERROR: file not found: $SOURCE_PATH"; exit 1; }

# ──────────────────────────────────────────────────────────────────────────────
# Step 0 — Quality check
# ──────────────────────────────────────────────────────────────────────────────

log "Step 0: quality check"

PROBE=$(ffprobe -v quiet -print_format json -show_streams "$SOURCE_PATH")

CODEC=$(echo "$PROBE"    | python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s['codec_name'])")
BIT_RATE=$(echo "$PROBE" | python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s.get('bit_rate', 0))")
BIT_DEPTH=$(echo "$PROBE"| python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s.get('bits_per_raw_sample') or s.get('bits_per_coded_sample') or 0)")
SAMPLE_RATE=$(echo "$PROBE" | python3 -c "import sys,json; s=next(s for s in json.load(sys.stdin)['streams'] if s['codec_type']=='audio'); print(s.get('sample_rate', 0))")

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

# ──────────────────────────────────────────────────────────────────────────────
# Step 1 — Create job
# ──────────────────────────────────────────────────────────────────────────────

log "Step 1: creating job"

TOKEN=$(openssl rand -hex 4)
JOB_NAME="${SONG_NAME}_${TOKEN}"
log "  job id: $JOB_NAME"

JOBS_CSV="$JOBS_DIR/jobs.csv"
[ -f "$JOBS_CSV" ] || echo "datetime,job_name,file" > "$JOBS_CSV"
echo "$(date '+%Y-%m-%d %H:%M:%S'),$JOB_NAME,$SOURCE_FILE" >> "$JOBS_CSV"

# ──────────────────────────────────────────────────────────────────────────────
# Step 2 — Setup processing workspace
# ──────────────────────────────────────────────────────────────────────────────

log "Step 2: setting up processing workspace"

JOB_DIR="$PROCESSING_DIR/$JOB_NAME"
STEMS_DIR="$JOB_DIR/stems"
CLEAN2_DIR="$JOB_DIR/cleaned_2"
MIDI_DIR="$JOB_DIR/midi"

mkdir -p "$STEMS_DIR" "$CLEAN2_DIR" "$MIDI_DIR"
cp "$SOURCE_PATH" "$JOB_DIR/${SONG_NAME}.${EXT}"

# ──────────────────────────────────────────────────────────────────────────────
# Step 3 — Stems
# ──────────────────────────────────────────────────────────────────────────────

log "Step 3: extracting stems"
source .env-stems/bin/activate

INPUT_FILE="$JOB_DIR/${SONG_NAME}.${EXT}"

# Pass 1 — 6 stems (piano, guitar, other...)
python3 -m demucs -n htdemucs_6s -d cuda \
  -o "$STEMS_DIR/6s" \
  "$INPUT_FILE"

# Pass 2 — ft full (bass + drums, max quality)
python3 -m demucs -n htdemucs_ft -d cuda \
  -o "$STEMS_DIR/ft" \
  "$INPUT_FILE"

# Pass 3 — dedicated vocal separation
python3 -m demucs -n htdemucs_ft -d cuda --two-stems=vocals \
  -o "$STEMS_DIR/ft_vocals" \
  "$INPUT_FILE"

# Merge: replace bass & drums in 6s with higher-quality ft versions
cp "$STEMS_DIR/ft/htdemucs_ft/$SONG_NAME/bass.wav"  "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/bass.wav"
cp "$STEMS_DIR/ft/htdemucs_ft/$SONG_NAME/drums.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/drums.wav"

# Keep both "other" variants (6s = strings/brass, ft = generic)
mv "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/other.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/instrs_without_guitar_piano.wav"
cp "$STEMS_DIR/ft/htdemucs_ft/$SONG_NAME/other.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/instrs.wav"

# Use dedicated vocal-pass for cleaner separation
cp "$STEMS_DIR/ft_vocals/htdemucs_ft/$SONG_NAME/vocals.wav"    "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/vocals.wav"
cp "$STEMS_DIR/ft_vocals/htdemucs_ft/$SONG_NAME/no_vocals.wav" "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME/no_vocals.wav"

# Flatten: prefix each stem with SONG_NAME and move to stems root
for file in "$STEMS_DIR/6s/htdemucs_6s/$SONG_NAME"/*.wav; do
  mv "$file" "$STEMS_DIR/${SONG_NAME}_$(basename "$file")"
done

rm -rf "$STEMS_DIR/6s" "$STEMS_DIR/ft" "$STEMS_DIR/ft_vocals"
deactivate

# ──────────────────────────────────────────────────────────────────────────────
# Step 4 — Vocal cleaning
# ──────────────────────────────────────────────────────────────────────────────

log "Step 4: cleaning vocals"
source .env-clean-2/bin/activate

audio-separator "$STEMS_DIR/${SONG_NAME}_vocals.wav" \
  --model_filename MDX23C-8KFFT-InstVoc_HQ.ckpt \
  --output_dir "$CLEAN2_DIR/" \
  --output_format WAV \
  --single_stem Vocals

mv "$(find "$CLEAN2_DIR" -name "*.wav" | head -1)" \
   "$CLEAN2_DIR/${SONG_NAME}_vocals_clean_2.wav"

deactivate

# ──────────────────────────────────────────────────────────────────────────────
# Step 5 — MIDI conversion
# ──────────────────────────────────────────────────────────────────────────────

log "Step 5: converting stems to MIDI"
source .env-midi/bin/activate

for f in "$STEMS_DIR"/*.wav; do
  base=$(basename "$f" .wav)
  log "  converting $base"
  tmp_dir=$(mktemp -d)
  .env-midi/bin/basic-pitch "$tmp_dir" "$f"
  mv "$tmp_dir"/*.mid "$MIDI_DIR/$base.mid"
  rm -rf "$tmp_dir"
done

deactivate

# ──────────────────────────────────────────────────────────────────────────────
# Step 6 — Sort MIDI by quality
# ──────────────────────────────────────────────────────────────────────────────

log "Step 6: sorting MIDI by quality"

MIDI_BEST_DIR="$MIDI_DIR/best_quality"
MIDI_REGULAR_DIR="$MIDI_DIR/regular_quality"
mkdir -p "$MIDI_BEST_DIR" "$MIDI_REGULAR_DIR"

for stem in vocals bass drums; do
  src="$MIDI_DIR/${SONG_NAME}_${stem}.mid"
  [ -f "$src" ] && mv "$src" "$MIDI_BEST_DIR/"
done

move_files "$MIDI_DIR" "$MIDI_REGULAR_DIR" "*.mid"

# ──────────────────────────────────────────────────────────────────────────────
# Step 7 — Sort stems by quality
# ──────────────────────────────────────────────────────────────────────────────

log "Step 7: sorting stems by quality"

STEMS_BEST_DIR="$STEMS_DIR/best_quality"
STEMS_REGULAR_DIR="$STEMS_DIR/regular_quality"
mkdir -p "$STEMS_BEST_DIR" "$STEMS_REGULAR_DIR"

for stem in drums bass vocals no_vocals instrs; do
  src="$STEMS_DIR/${SONG_NAME}_${stem}.wav"
  [ -f "$src" ] && mv "$src" "$STEMS_BEST_DIR/"
done

mv "$CLEAN2_DIR/${SONG_NAME}_vocals_clean_2.wav" "$STEMS_BEST_DIR/"

move_files "$STEMS_DIR" "$STEMS_REGULAR_DIR" "*.wav"

# ──────────────────────────────────────────────────────────────────────────────
# Step 8 — Assemble processed output
# ──────────────────────────────────────────────────────────────────────────────

log "Step 8: assembling output"

OUT_DIR="$PROCESSED_DIR/$JOB_NAME"
mkdir -p \
  "$OUT_DIR/source" \
  "$OUT_DIR/stems/best_quality" \
  "$OUT_DIR/stems/regular_quality" \
  "$OUT_DIR/midi/best_quality" \
  "$OUT_DIR/midi/regular_quality"

cp "$JOB_DIR/${SONG_NAME}.${EXT}" "$OUT_DIR/source/${SONG_NAME}.${EXT}"

move_files "$STEMS_BEST_DIR"    "$OUT_DIR/stems/best_quality"    "*.wav"
move_files "$STEMS_REGULAR_DIR" "$OUT_DIR/stems/regular_quality" "*.wav"
move_files "$MIDI_BEST_DIR"     "$OUT_DIR/midi/best_quality"     "*.mid"
move_files "$MIDI_REGULAR_DIR"  "$OUT_DIR/midi/regular_quality"  "*.mid"

rm -rf "$JOB_DIR"

log "Done. Output → $OUT_DIR"
