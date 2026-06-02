#!/bin/bash
# Sample-Me-Please — Setup all environments
# Versions exactes testées et validées
# Usage: bash setup.sh


# THIS ONE IS OK 


# ── ENV-CLEAN-2 — audio-separator ──────────────────────────────────────────────
header "ENV-CLEAN-2 — audio-separator + PyTorch 2.4.1 CUDA 12.1"


if [ -d ".env-clean-2" ]; then
    echo ".env-clean-2 already exists — delete it to reinstall"
else
    python3 -m venv .env-clean-2
    source .env-clean-2/bin/activate
    pip install --upgrade pip

    echo "Installing demucs + audio-separator + onnxruntime (let them resolve freely)..."
    pip install onnxruntime-gpu==1.19.2 audio-separator demucs

    echo "Force-pinning torch cu121 AFTER demucs (overrides whatever it pulled)..."
    pip install \
        torch==2.4.1+cu121 \
        torchaudio==2.4.1+cu121 \
        --index-url https://download.pytorch.org/whl/cu121 \
        --force-reinstall

    echo "Force-pinning numpy<2 last..."
    pip install "numpy<2" --force-reinstall

    python3 -c "
import torch
import onnxruntime as ort
print('torch cuda:', torch.cuda.is_available())
print('torch version:', torch.__version__)
print('onnx providers:', ort.get_available_providers())
"
    deactivate
    echo ".env-clean-2 ready"
fi






# ------------------------------------------



BASENAME="test"
STEMS_DIR="tests/out/stems"
CLEAN1_DIR="tests/out/cleaned_1"
CLEAN2_DIR="tests/out/cleaned_2"
STEMMED_FILE="$STEMS_DIR/${BASENAME}_vocals.wav"
CLEAN1_FILE="$CLEAN1_DIR/${BASENAME}_cleaned_1.wav"




#--------------------------------------------------------------------

# test stems --> 2
 
source .env-clean-2/bin/activate
 
audio-separator "$STEMMED_FILE" \
  --model_filename MDX23C-8KFFT-InstVoc_HQ.ckpt \
  --output_dir "$CLEAN2_DIR/" \
  --output_format WAV \
  --single_stem Vocals

 
# Rename output → BASENAME_cleaned_2.wav
mv $(find "$CLEAN2_DIR" -name "*.wav" | head -1) \
   "$CLEAN2_DIR/${BASENAME}_cleaned_2_vocals.wav"
 
echo "Done → $CLEAN2_DIR/${BASENAME}_cleaned_2_vocals.wav"
 
 
deactivate



#--------------------------------------------------------------------

# test CLEAN 1 then clean 2  2 
 
source .env-clean-2/bin/activate
 
audio-separator "$CLEAN1_FILE" \
  --model_filename MDX23C-8KFFT-InstVoc_HQ.ckpt \
  --output_dir "$CLEAN2_DIR/" \
  --output_format WAV \
  --single_stem Vocals
 
 
# Rename output → BASENAME_cleaned_2.wav
mv $(find "$CLEAN2_DIR" -name "*.wav" | head -1) \
   "$CLEAN2_DIR/${BASENAME}_cleaned_1_then_2_vocals.wav"
 
echo "Done → $CLEAN2_DIR/${BASENAME}_cleaned_2_vocals.wav"
 


deactivate