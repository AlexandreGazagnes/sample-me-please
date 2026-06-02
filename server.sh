#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[ -d ".env-web" ] || { echo ".env-web not found — run: bash setup/06-setup-web-app.sh"; exit 1; }

source .env-web/bin/activate
echo "Starting STEMIDI web app → http://localhost:8000"
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
