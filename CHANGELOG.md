# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [dev-0.0.3] — 2026-06-02 — Stable web app

### Added
- `run.sh` — single command to start backend + frontend simultaneously
- `src/` layout: source code organized under `src/pipeline/`, `src/back/`, `src/front/`
- `data/test/` — gitignored folder for test fixtures
- Pipeline now accepts a full file path in addition to a bare filename

### Changed
- CORS policy set to `allow_origins=["*"]` — fixes NetworkError on upload in all browsers
- All venv tool calls use explicit binary paths (`./env-*/bin/python3 script`) to survive project relocation
- `tests/` directory renamed from `test/`
- All `STEMIDI` branding replaced with `Sample-Me-Please`

### Removed
- `back.sh`, `front.sh`, `server.sh` — replaced by `run.sh`

---

## [dev-0.0.2] — 2026-06-02 — Refactor & structure

### Added
- `src/` directory structure for pipeline, backend, and frontend
- `script.sh` moved to `src/pipeline/script.sh`
- `back.py`, `app.py` moved to `src/back/`
- `front.py`, `static/`, `templates/` moved to `src/front/`

### Fixed
- `ROOT` / `BASE` / `STATIC` path resolution updated after file moves
- Uvicorn commands updated with `--app-dir` flag

---

## [dev-0.0.1] — 2026-06-02 — Initial release

### Added
- Audio pipeline: quality check → stem separation → vocal cleaning → MIDI conversion
- Token-based job tracking with `data/jobs/jobs.csv`
- Quality gate: MP3 ≥ 320 kbps, FLAC / WAV / AIFF ≥ 16-bit
- 3-pass Demucs stem separation (`htdemucs_6s`, `htdemucs_ft`, dedicated vocal pass)
- Vocal cleaning via `MDX23C-8KFFT-InstVoc_HQ.ckpt`
- MIDI transcription via basic-pitch 0.4.0
- Output organized into `best_quality/` and `regular_quality/` for stems and MIDI
- FastAPI backend with SSE job streaming, file download, and feedback endpoints
- Single-page web app — upload, live logs, download
- Setup scripts for all virtual environments (`setup/`)
- End-to-end test script (`tests/test-pipeline.sh`)
