#!/bin/bash
# Sample-Me-Please — Web app environment setup (FastAPI)
# Usage: bash setup/06-setup-web-app.sh

set -e

GRN="\033[92m"; YLW="\033[93m"; RED="\033[91m"; CYN="\033[96m"; BLD="\033[1m"; RST="\033[0m"
ok()     { echo -e "  ${GRN}✓${RST} $1"; }
info()   { echo -e "  ${CYN}→${RST} $1"; }
warn()   { echo -e "  ${YLW}⚠${RST}  $1"; }
err()    { echo -e "  ${RED}✗${RST} $1"; exit 1; }
header() { echo -e "\n${BLD}────────────────────────────────────────${RST}\n${BLD}  $1${RST}\n${BLD}────────────────────────────────────────${RST}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# ── Python check ─────────────────────────────────────────────────────────────

header "ENV-WEB — FastAPI + Uvicorn"

PYTHON=$(which python3.12 2>/dev/null || which python3 2>/dev/null)
[ -z "$PYTHON" ] && err "Python 3.12 not found. Install with: sudo apt install python3.12"
PY_VERSION=$($PYTHON --version 2>&1)
info "Using $PYTHON ($PY_VERSION)"

# ── Create venv ───────────────────────────────────────────────────────────────

if [ -d ".env-web" ]; then
    warn ".env-web already exists — delete it to reinstall"
else
    info "Creating .env-web..."
    $PYTHON -m venv .env-web
    source .env-web/bin/activate

    pip install --quiet --upgrade pip

    info "FastAPI + Uvicorn..."
    pip install --quiet \
        "fastapi==0.115.5" \
        "uvicorn[standard]==0.32.1"

    info "File upload + templating support..."
    pip install --quiet \
        "python-multipart==0.0.12" \
        "jinja2==3.1.4" \
        "aiofiles==24.1.0"

    # ── Verify ───────────────────────────────────────────────────────────────
    python3 -c "
import fastapi, uvicorn, multipart, jinja2, aiofiles
print('  fastapi:', fastapi.__version__)
print('  uvicorn:', uvicorn.__version__)
print('  jinja2:', jinja2.__version__)
" || err ".env-web verification failed"

    deactivate
    ok ".env-web ready"
fi

# ── Run instructions ──────────────────────────────────────────────────────────

header "Usage"
echo -e "
  source .env-web/bin/activate
  uvicorn app:app --reload --host 0.0.0.0 --port 8000

  → http://localhost:8000
  → http://localhost:8000/docs   (auto API docs)
"
