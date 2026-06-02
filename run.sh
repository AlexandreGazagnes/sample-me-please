#!/bin/bash
set -e

cd "$(dirname "$0")"

[ -d ".env-back"  ] || { echo ".env-back not found  — run: bash setup/07-setup-back.sh";  exit 1; }
[ -d ".env-front" ] || { echo ".env-front not found — run: bash setup/08-setup-front.sh"; exit 1; }

BACK_HOST=${BACK_HOST:-0.0.0.0}
BACK_PORT=${BACK_PORT:-8001}
FRONT_HOST=${FRONT_HOST:-0.0.0.0}
FRONT_PORT=${FRONT_PORT:-8000}
FRONT_ORIGIN=${FRONT_ORIGIN:-http://localhost:$FRONT_PORT}
BACK_URL=${BACK_URL:-http://localhost:$BACK_PORT}

export BACK_HOST BACK_PORT FRONT_ORIGIN
export FRONT_HOST FRONT_PORT BACK_URL

trap 'kill $(jobs -p) 2>/dev/null' EXIT INT TERM

echo "backend  → http://$BACK_HOST:$BACK_PORT"
echo "frontend → http://$FRONT_HOST:$FRONT_PORT"

.env-back/bin/uvicorn  back:app  --app-dir src/back  --host "$BACK_HOST"  --port "$BACK_PORT"  &
.env-front/bin/uvicorn front:app --app-dir src/front --host "$FRONT_HOST" --port "$FRONT_PORT" &

wait
