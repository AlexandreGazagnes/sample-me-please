# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [dev-0.0.1] — 2026-06-02

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
- `run.sh` — one command to start backend + frontend
- `src/` layout: `src/pipeline/`, `src/back/`, `src/front/`
- Setup scripts for all virtual environments (`setup/`)
- End-to-end test script (`tests/test-pipeline.sh`)
- `data/test/` — gitignored folder for test fixtures
