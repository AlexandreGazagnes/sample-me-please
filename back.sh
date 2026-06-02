#!/bin/bash
set -e

cd "$(dirname "$0")"

[ -d ".env-back" ] || { echo ".env-back not found — run: bash setup/07-setup-back.sh"; exit 1; }
source .env-back/bin/activate

export BACK_HOST=${BACK_HOST:-0.0.0.0}
export BACK_PORT=${BACK_PORT:-8001}
export FRONT_ORIGIN=${FRONT_ORIGIN:-http://localhost:8000}

echo "STEMIDI backend → http://$BACK_HOST:$BACK_PORT"
echo "Accepting requests from: $FRONT_ORIGIN"
uvicorn back:app --host "$BACK_HOST" --port "$BACK_PORT" --reload
