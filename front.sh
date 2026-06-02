#!/bin/bash
set -e

cd "$(dirname "$0")"

[ -d ".env-front" ] || { echo ".env-front not found — run: bash setup/08-setup-front.sh"; exit 1; }
source .env-front/bin/activate

export FRONT_HOST=${FRONT_HOST:-0.0.0.0}
export FRONT_PORT=${FRONT_PORT:-8000}
export BACK_URL=${BACK_URL:-http://localhost:8001}

echo "STEMIDI frontend → http://$FRONT_HOST:$FRONT_PORT"
echo "Backend URL injected: $BACK_URL"
uvicorn front:app --host "$FRONT_HOST" --port "$FRONT_PORT" --reload
