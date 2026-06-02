#!/bin/bash
# Sample-Me-Please — Setup all environments
# Versions exactes testées et validées
# Usage: bash setup.sh


set -e

if [ -d ".env-lyrics" ]; then
    echo ".env-lyrics already exists — delete it to reinstall"
else
    python3 -m venv .env-lyrics
    source .env-lyrics/bin/activate
    pip install --upgrade pip

    pip install faster-whisper

    python3 -c "
from faster_whisper import WhisperModel
print('faster-whisper: OK')
import torch
print('cuda:', torch.cuda.is_available())
"
    deactivate
    echo ".env-lyrics ready"
fi


# --- TEST 


set -e

INPUT="$1"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
    echo "Usage: bash extract_lyrics.sh <vocals.wav>"
    exit 1
fi

SRT_OUT="${INPUT%.wav}.srt"

source .env-lyrics/bin/activate

python3 - <<EOF
from faster_whisper import WhisperModel

model = WhisperModel("large-v3", device="cuda", compute_type="float16")
segments, info = model.transcribe(
    "$INPUT",
    beam_size=5,
    vad_filter=True,
    vad_parameters=dict(min_silence_duration_ms=500)
)

print(f"Language: {info.language} ({info.language_probability:.0%})")

def fmt(s):
    return f"{int(s//3600):02}:{int((s%3600)//60):02}:{int(s%60):02},{int((s%1)*1000):03}"

with open("$SRT_OUT", "w", encoding="utf-8") as f:
    for i, seg in enumerate(list(segments), 1):
        f.write(f"{i}\n{fmt(seg.start)} --> {fmt(seg.end)}\n{seg.text.strip()}\n\n")

print(f"Saved → $SRT_OUT")
EOF

deactivate