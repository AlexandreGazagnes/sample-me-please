#!/bin/bash
# Sample-Me-Please — Utils environment setup
# Creates .venv-utils with dependencies for utils/scraper.py
# Usage: bash setup/09-setup-utils.sh

set -e

GRN="\033[92m"; YLW="\033[93m"; RED="\033[91m"; CYN="\033[96m"; BLD="\033[1m"; RST="\033[0m"
ok()     { echo -e "  ${GRN}✓${RST} $1"; }
info()   { echo -e "  ${CYN}→${RST} $1"; }
warn()   { echo -e "  ${YLW}⚠${RST}  $1"; }
err()    { echo -e "  ${RED}✗${RST} $1"; exit 1; }
header() { echo -e "\n${BLD}────────────────────────────────────────${RST}\n${BLD}  $1${RST}\n${BLD}────────────────────────────────────────${RST}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# ── Python check ─────────────────────────────────────────────────────────────

header "Checking Python"

PYTHON=$(which python3 2>/dev/null) || err "python3 not found"
PY_VERSION=$($PYTHON --version 2>&1)
info "Using $PYTHON ($PY_VERSION)"

# ── Create venv ───────────────────────────────────────────────────────────────

header "Creating .venv-utils"

if [ -d ".venv-utils" ]; then
  warn ".venv-utils already exists — delete it to reinstall"
else
  $PYTHON -m venv .venv-utils
  ok ".venv-utils created"
fi

source .venv-utils/bin/activate

info "Upgrading pip..."
pip install --quiet --upgrade pip

info "Installing dependencies..."
pip install --quiet requests beautifulsoup4

# ── Verify ────────────────────────────────────────────────────────────────────

header "Verifying"

python3 -c "
import requests, bs4
print('  requests:         ' + requests.__version__)
print('  beautifulsoup4:   ' + bs4.__version__)
" || err ".venv-utils verification failed"

ok ".venv-utils ready"

# ── Smoke test ────────────────────────────────────────────────────────────────

header "Smoke test — scraper.py imports"

python3 -c "
import sys
sys.path.insert(0, '.')
import importlib.util, pathlib

spec = importlib.util.spec_from_file_location('scraper', 'utils/scraper.py')
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Test slugify helper
assert mod.slugify(\"Don't Stop Me Now\") == 'dontstopmeno', f'slugify failed: {mod.slugify(\"Don\\'t Stop Me Now\")}'
assert mod.slugify('James Brown') == 'jamesbrown'
assert mod.clean('  Hello   World  ') == 'Hello World'
print('  slugify: ok')
print('  clean:   ok')
" || err "Smoke test failed"

ok "Smoke test passed"

deactivate

echo ""
echo -e "${BLD}Run the scraper with:${RST}"
echo "  .venv-utils/bin/python3 utils/scraper.py"
echo "  .venv-utils/bin/python3 utils/scraper.py --json data/lyrics.json"
