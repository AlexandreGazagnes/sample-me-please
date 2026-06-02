#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TEST_FILE="test-short.mp3"
TEST_SRC="test/source/$TEST_FILE"

GRN="\033[92m"; RED="\033[91m"; CYN="\033[96m"; BLD="\033[1m"; RST="\033[0m"
ok()     { echo -e "  ${GRN}✓${RST} $1"; }
info()   { echo -e "  ${CYN}→${RST} $1"; }
err()    { echo -e "  ${RED}✗${RST} $1"; exit 1; }
header() { echo -e "\n${BLD}────────────────────────────────────────${RST}\n${BLD}  $1${RST}\n${BLD}────────────────────────────────────────${RST}"; }

# ── Pre-clean: wipe any leftover test artifacts from data/ ───────────────────
pre_clean() {
  rm -f  "data/requests/$TEST_FILE"
  rm -f  "data/refused/$TEST_FILE"
  rm -rf data/processing/test-short_*
  rm -rf data/processed/test-short_*
  if [ -f "data/jobs/jobs.csv" ]; then
    grep -v ",$TEST_FILE$" "data/jobs/jobs.csv" > "data/jobs/jobs.csv.tmp" || true
    mv "data/jobs/jobs.csv.tmp" "data/jobs/jobs.csv"
  fi
}

# ── Post-clean: same, minus processed (already moved out) ────────────────────
post_clean() {
  rm -f  "data/requests/$TEST_FILE"
  rm -f  "data/refused/$TEST_FILE"
  rm -rf data/processing/test-short_*
  if [ -f "data/jobs/jobs.csv" ]; then
    grep -v ",$TEST_FILE$" "data/jobs/jobs.csv" > "data/jobs/jobs.csv.tmp" || true
    mv "data/jobs/jobs.csv.tmp" "data/jobs/jobs.csv"
  fi
}
trap post_clean EXIT

# ── Preflight ─────────────────────────────────────────────────────────────────
header "Preflight"
[ -f "$TEST_SRC" ] || err "Test file not found: $TEST_SRC"
ok "$TEST_SRC found"

header "Clearing previous test artifacts from data/"
pre_clean
ok "data/ clean"

# ── Inject ────────────────────────────────────────────────────────────────────
header "Injecting test file"
cp "$TEST_SRC" "data/requests/$TEST_FILE"
ok "Copied → data/requests/$TEST_FILE"

# ── Run pipeline ──────────────────────────────────────────────────────────────
header "Running pipeline"
bash script.sh "$TEST_FILE"

# ── Move results into test/ ───────────────────────────────────────────────────
header "Moving results"
JOB_DIR=$(ls -td data/processed/test-short_* 2>/dev/null | head -1 || true)
[ -n "$JOB_DIR" ] || err "No output found in data/processed/"

JOB_NAME=$(basename "$JOB_DIR")
mv "$JOB_DIR" "test/$JOB_NAME"
ok "Results → test/$JOB_NAME"

header "Done — test/$JOB_NAME"
