#!/bin/bash
# STEMIDI — Setup all environments
# Versions exactes testées et validées
# Usage: bash setup.sh

# set -e



#THIS ONE IS OK

rm -rf .env-midi

header "ENV-STMIDI"




if [ -d ".env-midi" ]; then
    warn ".env-midi already exists — delete it to reinstall"
else

    python3.11  -m venv .env-midi
    source .env-midi/bin/activate

    # pip install --quiet --upgrade pip

    info "basic-pitch 0.4.0 (no-deps + manual deps)..."

    pip install "tensorflow>=2.4.1,<2.15.1"
    # pip install --quiet "basic-pitch==0.4.0" --no-deps
    pip install basic-pitch==0.4.0 --no-deps
    pip install --quiet \
        librosa \
        mir-eval \
        pretty-midi \
        "resampy==0.4.2" \
        scikit-learn \
        scipy \
        typing-extensions \
        onnxruntime

    info "piano-transcription-inference..."
    pip install --quiet piano-transcription-inference

#     # verify
#     $PYTHON -c "
# import basic_pitch
# import piano_transcription_inference
# import onnxruntime as ort
# print('OK:', ort.__version__)
# " || err ".env-midi verification failed"

#     deactivate 2>/dev/null || true
#     ok ".env-midi ready"
fi



source .env-midi/bin/activate

SOURCE_FOLDER="tests/out/stems"
DEST_FOLDER="/home/alex/Desktop/stemidi/files/out/midi"

# mkdir -p "$DEST_FOLDER"

for f in "$SOURCE_FOLDER"/*.wav; do
  base=$(basename "$f" .wav)

  echo "Processing $base ..."

  tmp_dir=$(mktemp -d)

  .env-midi/bin/basic-pitch "$tmp_dir" "$f"

  mv "$tmp_dir"/*.mid "$DEST_FOLDER/$base.mid"

  rm -rf "$tmp_dir"
done