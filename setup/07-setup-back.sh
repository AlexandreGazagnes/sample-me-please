#!/bin/bash
# STEMIDI — Backend environment setup
# Creates .env-back with FastAPI + uvicorn + multipart support
# Usage: bash setup/07-setup-back.sh  (run from project root)

set -e

GRN="\033[92m"; YLW="\033[93m"; RED="\033[91m"; CYN="\033[96m"; BLD="\033[1m"; RST="\033[0m"

ok()     { echo -e "  ${GRN}✓${RST} $1"; }
info()   { echo -e "  ${CYN}→${RST} $1"; }
warn()   { echo -e "  ${YLW}⚠${RST}  $1"; }
err()    { echo -e "  ${RED}✗${RST} $1"; exit 1; }
header() { echo -e "\n${BLD}────────────────────────────────────────${RST}\n${BLD}  $1${RST}\n${BLD}────────────────────────────────────────${RST}"; }

cd "$(dirname "$0")/.."

header "ENV-BACK — FastAPI backend"

PYTHON=$(which python3.12 2>/dev/null || which python3 2>/dev/null)
[ -z "$PYTHON" ] && err "Python not found"
info "Python: $($PYTHON --version)"

if [ -d ".env-back" ]; then
    warn ".env-back already exists — delete it to reinstall"
else
    info "Creating .env-back..."
    $PYTHON -m venv .env-back
    source .env-back/bin/activate

    pip install --quiet --upgrade pip

    info "Installing FastAPI + uvicorn + multipart + aiofiles..."
    pip install --quiet \
        "fastapi==0.115.5" \
        "uvicorn[standard]==0.32.1" \
        "python-multipart==0.0.12" \
        "aiofiles==24.1.0"

    python3 -c "
import fastapi, uvicorn, multipart, aiofiles
print('  fastapi:', fastapi.__version__)
print('  uvicorn:', uvicorn.__version__)
print('  python-multipart:', multipart.__version__)
print('  aiofiles:', aiofiles.__version__)
" || err ".env-back verification failed"

    deactivate
    ok ".env-back ready"
fi

echo ""
ok "Run the backend with:"
echo -e "  ${CYN}bash back.sh${RST}"
echo ""
info "Override defaults via env vars:"
echo -e "  BACK_HOST   (default 0.0.0.0)"
echo -e "  BACK_PORT   (default 8001)"
echo -e "  FRONT_ORIGIN (default http://localhost:8000)"
