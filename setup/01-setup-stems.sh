#!/bin/bash
# Sample-Me-Please — Setup all environments
# Versions exactes testées et validées
# Usage: bash setup.sh

# THIS ONE IS OK 

# ── ENV-STEMS — Demucs ───────────────────────────────────────────────────────
header "ENV-STEMS — Demucs 4.0.1 + PyTorch 2.4.1 CUDA 12.1"

if [ -d ".env-stems" ]; then
    warn ".env-stems already exists — delete it to reinstall"
else
    $PYTHON -m venv .env-stems
    source .env-stems/bin/activate

    pip install --quiet --upgrade pip

    info "PyTorch 2.4.1 + CUDA 12.1..."
    pip install --quiet \
        torch==2.4.1 \
        torchaudio==2.4.1 \
        --index-url https://download.pytorch.org/whl/cu121

    info "Demucs 4.0.1..."
    pip install --quiet "demucs==4.0.1"

    # Verify
    python3 -c "
import torch, demucs
assert torch.__version__.startswith('2.4.1'), f'Wrong torch: {torch.__version__}'
print('  torch:', torch.__version__)
print('  CUDA:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('  GPU:', torch.cuda.get_device_name(0))
print('  demucs:', demucs.__version__)
" || err ".env-stems verification failed"

    deactivate
    ok ".env-stems ready"
fi


# ── test demucs ───────────────────────────────────────────────────────

deactivate
source .env-stems/bin/activate

INPUT_DIR="tests/source"
OUTPUT_DIR="tests/out/stems"
FILE_NAME="test.flac"

BASENAME=$(basename "$FILE_NAME")
BASENAME="${BASENAME%.*}"


#ALL DEPRECATED NOT GOOD MODEL 
# python3 -m demucs -n htdemucs_ft -d cuda \
#   -o "$OUTPUT_DIR" \
#   "$INPUT_DIR/$FILE_NAME"


# Pass 1 — 6 stems (piano, guitar, other...)
python3 -m demucs -n htdemucs_6s -d cuda \
  -o "$OUTPUT_DIR/6s" \
  "$INPUT_DIR/$FILE_NAME"

# Pass 2 — ft full (bass + drums qualité max)
python3 -m demucs -n htdemucs_ft -d cuda \
  -o "$OUTPUT_DIR/ft" \
  "$INPUT_DIR/$FILE_NAME"

# Pass 3 — vocals only
python3 -m demucs -n htdemucs_ft -d cuda --two-stems=vocals \
  -o "$OUTPUT_DIR/ft_vocals" \
  "$INPUT_DIR/$FILE_NAME"
 

# bass + drums ft → 6s (écrase)
cp "$OUTPUT_DIR/ft/htdemucs_ft/$BASENAME/bass.wav" \
   "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/bass.wav"
cp "$OUTPUT_DIR/ft/htdemucs_ft/$BASENAME/drums.wav" \
   "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/drums.wav"
 
# other 6s → other_ft (strings/brass)
mv "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/other.wav" \
   "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/other_6s.wav"
 
# other ft → 6s
cp "$OUTPUT_DIR/ft/htdemucs_ft/$BASENAME/other.wav" \
   "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/other_4s.wav"
 
# vocals + no_vocals ft → 6s (écrase)
cp "$OUTPUT_DIR/ft_vocals/htdemucs_ft/$BASENAME/vocals.wav" \
   "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/vocals.wav"
cp "$OUTPUT_DIR/ft_vocals/htdemucs_ft/$BASENAME/no_vocals.wav" \
   "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME/no_vocals.wav"
 
# ── Rename + flatten → OUTPUT_DIR ────────────────────────────────────────────
 
# Préfixer chaque fichier avec BASENAME et déplacer à la racine stems/
for FILE in "$OUTPUT_DIR/6s/htdemucs_6s/$BASENAME"/*.wav; do
    NAME=$(basename "$FILE")
    mv "$FILE" "$OUTPUT_DIR/${BASENAME}_${NAME}"
done
 
# ── Cleanup ──────────────────────────────────────────────────────────────────
rm -rf "$OUTPUT_DIR/6s"
rm -rf "$OUTPUT_DIR/ft"
rm -rf "$OUTPUT_DIR/ft_vocals"
 
deactivate
 
echo "Done — stems in $OUTPUT_DIR/"
ls "$OUTPUT_DIR/"

