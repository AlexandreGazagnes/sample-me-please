#!/bin/bash
# STEMIDI — Setup all environments
# Versions exactes testées et validées
# Usage: bash setup.sh


THIS ONE IS OK 

set -e

GRN="\033[92m"; YLW="\033[93m"; RED="\033[91m"; CYN="\033[96m"; BLD="\033[1m"; RST="\033[0m"

ok()     { echo -e "  ${GRN}✓${RST} $1"; }
info()   { echo -e "  ${CYN}→${RST} $1"; }
warn()   { echo -e "  ${YLW}⚠${RST}  $1"; }
err()    { echo -e "  ${RED}✗${RST} $1"; exit 1; }
header() { echo -e "\n${BLD}────────────────────────────────────────${RST}\n${BLD}  $1${RST}\n${BLD}────────────────────────────────────────${RST}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Création structure projet ────────────────────────────────────────────────
header "Project structure"

mkdir -p \
    "$SCRIPT_DIR/tests/source" \
    "$SCRIPT_DIR/tests/out/stems" \
    "$SCRIPT_DIR/tests/out/cleaned" \
    "$SCRIPT_DIR/tests/out/cleaned_1" \
    "$SCRIPT_DIR/tests/out/cleaned_2" \
    "$SCRIPT_DIR/tests/out/lyrics" \
    "$SCRIPT_DIR/tests/out/bpm-key" \
    "$SCRIPT_DIR/tests/out/chords" \
    "$SCRIPT_DIR/tests/out/midi"

ok "Folders ready:"
echo -e "
  stemidi/
  ├── setup.sh
  ├── stemmidi.py
  ├── .env-stems/
  ├── .env-clean/
  ├── .env-midi/
  └── tests/
      ├── source/    ← placez votre fichier audio ici
      └── out/
          ├── stems/
          ├── cleaned/
          └── midi/
"

# ── Check Python 3.12 ────────────────────────────────────────────────────────
header "Checking system"

PYTHON=$(which python3.12 2>/dev/null || which python3 2>/dev/null)
[ -z "$PYTHON" ] && err "Python 3.12 not found. Install with: sudo apt install python3.12"
PY_VERSION=$($PYTHON --version 2>&1)
info "Python: $PYTHON ($PY_VERSION)"

# Check nvidia-smi
nvidia-smi > /dev/null 2>&1 && ok "NVIDIA driver OK" || warn "nvidia-smi not found — GPU disabled"

# Check ffmpeg
ffmpeg -version > /dev/null 2>&1 && ok "FFmpeg OK" || {
    warn "FFmpeg not found, installing..."
    sudo apt install -y ffmpeg
}
