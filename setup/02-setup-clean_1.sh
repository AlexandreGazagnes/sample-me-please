#!/bin/bash
# Sample-Me-Please — Setup all environments
# Versions exactes testées et validées
# Usage: bash setup.sh

# THIS ONE FAILS

# # ── ENV-CLEAN-1 — audio-separator ──────────────────────────────────────────────
# header "ENV-CLEAN-1 — audio-separator + PyTorch 2.4.1 CUDA 12.1"


# if [ -d ".env-clean-1" ]; then
#     echo ".env-clean-1 already exists — delete it to reinstall"
# else
#     python3 -m venv .env-clean-1
#     source .env-clean-1/bin/activate
#     pip install --upgrade pip

#     echo "Installing demucs + audio-separator + onnxruntime (let them resolve freely)..."
#     pip install onnxruntime-gpu==1.19.2 audio-separator demucs

#     echo "Force-pinning torch cu121 AFTER demucs (overrides whatever it pulled)..."
#     pip install \
#         torch==2.4.1+cu121 \
#         torchaudio==2.4.1+cu121 \
#         --index-url https://download.pytorch.org/whl/cu121 \
#         --force-reinstall

#     echo "Force-pinning numpy<2 last..."
#     pip install "numpy<2" --force-reinstall

#     python3 -c "
# import torch
# import onnxruntime as ort
# print('torch cuda:', torch.cuda.is_available())
# print('torch version:', torch.__version__)
# print('onnx providers:', ort.get_available_providers())
# "
#     deactivate
#     echo ".env-clean-1 ready"
# fi



rm -rf .env-clean-1

if [ -d ".env-clean-1" ]; then
    echo "  → .env-clean-1 already exists — delete it to reinstall"
else
    echo "create .env-clean-1"
    python3 -m venv .env-clean-1
    source .env-clean-1/bin/activate
 
    pip install --quiet --upgrade pip
 
    echo "  → audio-separator + onnxruntime-gpu..."
    pip install --quiet onnxruntime-gpu==1.19.2 audio-separator
 
    echo "  → Force PyTorch 2.4.1+cu121 + torchvision 0.19.1+cu121..."
    pip install --quiet --force-reinstall \
        torch==2.4.1+cu121 \
        torchaudio==2.4.1+cu121 \
        torchvision==0.19.1+cu121 \
        --index-url https://download.pytorch.org/whl/cu121
 
    echo "  → Reinstall onnx2torch (compatible with torch 2.4.1)..."
    pip install --quiet --force-reinstall onnx2torch==1.5.15
 
    echo "  → numpy<2..."
    pip install --quiet --force-reinstall "numpy<2"
 
    echo "  → Verify..."
    python3 -c "
import torch, onnxruntime as ort, onnx2torch
from audio_separator.separator import Separator
print('  torch:', torch.__version__)
print('  CUDA:', torch.cuda.is_available())
print('  onnxruntime:', ort.__version__)
print('  onnx2torch: ok')
print('  audio-separator: ok')
" || { echo "  ✗ .env-clean-1 verification failed"; exit 1; }
 
    deactivate
    echo "  ✓ .env-clean-1 ready"
fi
 



# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# TEST  clea stem to  clean 

BASENAME="test"
STEMS_DIR="tests/out/stems"
CLEAN1_DIR="tests/out/cleaned_1"
STEMMED_FILE="$STEMS_DIR/${BASENAME}_vocals.wav"
 
source .env-clean-1/bin/activate
 
audio-separator "$STEMMED_FILE" \
  --model_filename Kim_Vocal_2.onnx \
  --output_dir "$CLEAN1_DIR/" \
  --output_format WAV \
  --single_stem Vocals
 
 
# Rename output → BASENAME_cleaned_1.wav
mv $(find "$CLEAN1_DIR" -name "*.wav" | head -1) \
   "$CLEAN1_DIR/${BASENAME}_cleaned_1.wav"
 
echo "Done → $CLEAN1_DIR/${BASENAME}_cleaned_1.wav"
 

deactivate