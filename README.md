# SAMPLE-ME-PLEASE

**Audio analysis pipeline** — drop an MP3, FLAC, WAV, or AIFF file and get back separated stems, cleaned vocals, and MIDI transcriptions. Designed as a production-grade job pipeline with token-based job tracking and a web interface.

---

## What it does

1. **Quality check** — rejects low-quality audio before wasting compute
2. **Stem separation** — splits the track into vocals, bass, drums, guitar, piano, and more
3. **Vocal cleaning** — runs a second-pass noise removal on the extracted vocals
4. **MIDI conversion** — transcribes every stem to a `.mid` file
5. **Organized output** — assembles everything into a clean, human-readable folder structure

---

## Requirements

- Linux (tested on Ubuntu)
- Python 3.11 (for MIDI) + Python 3.10+ (for other envs)
- `ffmpeg` / `ffprobe` (system-level — via `apt`)
- NVIDIA GPU + CUDA 12.1 (recommended; CPU fallback works but is slow)
- ~20 GB disk space for models and virtual environments

---

## First-time setup

Run the setup scripts in order. Each one creates an isolated virtual environment for its component.

```bash
bash setup/00-setup-sys.sh       # system checks + folder structure
bash setup/01-setup-stems.sh     # Demucs stem separator
bash setup/03-setup-clean_2.sh   # vocal cleaner (MDX model)
bash setup/04-setup-midi.sh      # basic-pitch MIDI transcription (requires Python 3.11)
bash setup/05-set-up-lyrics.sh   # faster-whisper (optional — lyrics transcription)
bash setup/07-setup-back.sh      # FastAPI backend
bash setup/08-setup-front.sh     # FastAPI frontend
```

---

## Running the pipeline

### Command line

```bash
# Place your audio file in data/requests/ first
bash script.sh mysong.mp3

# Or run interactively (will prompt for filename)
bash script.sh
```

Accepted formats: `MP3` (≥ 320 kbps), `FLAC`, `WAV`, `AIFF` (≥ 16-bit).  
Files that don't meet the quality threshold are moved to `data/refused/` — no partial processing.

### Web interface

Start the backend and frontend in separate terminals:

```bash
# Terminal 1 — backend (port 8001)
bash back.sh

# Terminal 2 — frontend (port 8000)
bash front.sh
```

Then open [http://localhost:8000](http://localhost:8000) in your browser.

**Configuration overrides:**

```bash
# Backend
BACK_HOST=0.0.0.0 BACK_PORT=8001 FRONT_ORIGIN=http://localhost:8000 bash back.sh

# Frontend
FRONT_HOST=0.0.0.0 FRONT_PORT=8000 BACK_URL=http://localhost:8001 bash front.sh
```

---

## Output structure

Each job gets a unique 8-character token. The token appears only in the job folder name — all filenames inside stay clean and human-readable.

```
data/processed/{song_name}_{token}/
├── source/
│   └── {song_name}.mp3          ← original file, unchanged
├── stems/
│   ├── best_quality/
│   │   ├── {song_name}_vocals.wav
│   │   ├── {song_name}_vocals_clean_2.wav   ← cleaned vocals
│   │   ├── {song_name}_bass.wav
│   │   ├── {song_name}_drums.wav
│   │   ├── {song_name}_no_vocals.wav
│   │   └── {song_name}_instrs.wav
│   └── regular_quality/
│       ├── {song_name}_guitar.wav
│       ├── {song_name}_piano.wav
│       └── {song_name}_instrs_without_guitar_piano.wav
└── midi/
    ├── best_quality/
    │   ├── {song_name}_vocals.mid
    │   ├── {song_name}_bass.mid
    │   └── {song_name}_drums.mid
    └── regular_quality/
        └── ...
```

---

## Project structure

```
stemidi/
├── script.sh              # main pipeline entry point
├── back.py                # FastAPI backend
├── front.py               # FastAPI frontend (serves SPA)
├── front/static/index.html  # single-page web app
├── setup/                 # one-time environment setup scripts
├── data/
│   ├── requests/          # ← drop audio files here
│   ├── jobs/              # jobs.csv — append-only job log
│   ├── processing/        # active job workspaces
│   ├── processed/         # completed job output
│   └── refused/           # files that failed quality check
└── tests/
    ├── source/            # test input files
    └── test-pipeline.sh   # end-to-end test script
```

---

## Models used

| Step | Model | Virtual env |
|---|---|---|
| Stem separation | Demucs `htdemucs_6s`, `htdemucs_ft` | `.env-stems` |
| Vocal cleaning | `MDX23C-8KFFT-InstVoc_HQ.ckpt` | `.env-clean-2` |
| MIDI transcription | basic-pitch 0.4.0 | `.env-midi` |
| Lyrics (optional) | faster-whisper large-v3 | `.env-lyrics` |

---

## Known limitations

- Vocal cleaning runs on **CPU only** — GPU path not yet working
- Lyrics transcription is set up but not wired into the main pipeline
- Missing features: BPM detection, key detection, chord detection
- `.env-clean-1` (Kim Vocal 2 / ONNX) has setup issues and is bypassed

---

## License

MIT
