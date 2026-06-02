#!/bin/bash
# STEMIDI — Frontend environment setup
# Creates .env-front with FastAPI + uvicorn (serves static SPA only)
# Usage: bash setup/08-setup-front.sh  (run from project root)

set -e

GRN="\033[92m"; YLW="\033[93m"; RED="\033[91m"; CYN="\033[96m"; BLD="\033[1m"; RST="\033[0m"

ok()     { echo -e "  ${GRN}✓${RST} $1"; }
info()   { echo -e "  ${CYN}→${RST} $1"; }
warn()   { echo -e "  ${YLW}⚠${RST}  $1"; }
err()    { echo -e "  ${RED}✗${RST} $1"; exit 1; }
header() { echo -e "\n${BLD}────────────────────────────────────────${RST}\n${BLD}  $1${RST}\n${BLD}────────────────────────────────────────${RST}"; }

cd "$(dirname "$0")/.."

header "ENV-FRONT — FastAPI frontend"

PYTHON=$(which python3.12 2>/dev/null || which python3 2>/dev/null)
[ -z "$PYTHON" ] && err "Python not found"
info "Python: $($PYTHON --version)"

if [ -d ".env-front" ]; then
    warn ".env-front already exists — delete it to reinstall"
else
    info "Creating .env-front..."
    $PYTHON -m venv .env-front
    source .env-front/bin/activate

    pip install --quiet --upgrade pip

    info "Installing FastAPI + uvicorn..."
    pip install --quiet \
        "fastapi==0.115.5" \
        "uvicorn[standard]==0.32.1"

    python3 -c "
import fastapi, uvicorn
print('  fastapi:', fastapi.__version__)
print('  uvicorn:', uvicorn.__version__)
" || err ".env-front verification failed"

    deactivate
    ok ".env-front ready"
fi

echo ""
ok "Run the frontend with:"
echo -e "  ${CYN}bash front.sh${RST}"
echo ""
info "Override defaults via env vars:"
echo -e "  FRONT_HOST (default 0.0.0.0)"
echo -e "  FRONT_PORT (default 8000)"
echo -e "  BACK_URL   (default http://localhost:8001)"
