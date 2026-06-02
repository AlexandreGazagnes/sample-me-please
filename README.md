# Sample-Me-Please

Drop an audio file, get back separated stems, cleaned vocals, and MIDI — fully automated.

---

## What it does

| Step | What happens |
|---|---|
| Quality check | Rejects low-quality files before wasting compute |
| Stem separation | Splits into vocals, bass, drums, guitar, piano, and more (3 Demucs passes) |
| Vocal cleaning | Second-pass noise removal on extracted vocals |
| MIDI conversion | Transcribes every stem to a `.mid` file |
| Output assembly | Organizes everything into a clean, human-readable folder |

Accepted formats: **MP3** (≥ 320 kbps) · **FLAC / WAV / AIFF** (≥ 16-bit)

---

## Requirements

- Linux (tested on Ubuntu 22.04+)
- Python 3.11 + Python 3.12
- `ffmpeg` / `ffprobe` — system-level (`sudo apt install ffmpeg`)
- NVIDIA GPU + CUDA 12.1 recommended (CPU fallback works but is slow)
- ~20 GB free disk space for models and virtual environments

---

## First-time setup

Run the setup scripts once, in order. Each one builds an isolated virtual environment.

```bash
bash setup/00-setup-sys.sh       # system checks + folder structure
bash setup/01-setup-stems.sh     # Demucs stem separator
bash setup/03-setup-clean_2.sh   # vocal cleaner (MDX model)
bash setup/04-setup-midi.sh      # MIDI transcription (requires Python 3.11)
bash setup/07-setup-back.sh      # FastAPI backend
bash setup/08-setup-front.sh     # FastAPI frontend
```

> `setup/05-set-up-lyrics.sh` is optional — sets up faster-whisper for lyrics transcription, not yet wired into the main pipeline.

---

## Running

### Web interface (recommended)

```bash
bash run.sh
```

Opens backend on port **8001** and frontend on port **8000**. Visit [http://localhost:8000](http://localhost:8000).

Environment overrides:

```bash
BACK_PORT=8001 FRONT_PORT=8000 BACK_URL=http://localhost:8001 bash run.sh
```

### Command line

```bash
# Pass a file path directly
./src/pipeline/script.sh data/test/mysong.mp3

# Or drop the file in data/requests/ and pass just the filename
./src/pipeline/script.sh mysong.mp3

# Interactive mode
./src/pipeline/script.sh
```

Files that fail the quality check are moved to `data/refused/` — nothing else is touched.

---

## Output structure

Each job gets a unique 8-character token in the folder name. All filenames inside are clean and human-readable.

```
data/processed/{song}_{token}/
├── source/
│   └── {song}.mp3
├── stems/
│   ├── best_quality/
│   │   ├── {song}_vocals.wav
│   │   ├── {song}_vocals_clean_2.wav
│   │   ├── {song}_bass.wav
│   │   ├── {song}_drums.wav
│   │   ├── {song}_no_vocals.wav
│   │   └── {song}_instrs.wav
│   └── regular_quality/
│       ├── {song}_guitar.wav
│       ├── {song}_piano.wav
│       └── {song}_instrs_without_guitar_piano.wav
└── midi/
    ├── best_quality/
    │   ├── {song}_vocals.mid
    │   ├── {song}_bass.mid
    │   └── {song}_drums.mid
    └── regular_quality/
        └── ...
```

---

## Project structure

```
sample-me-please/
├── run.sh                     # start everything (backend + frontend)
├── src/
│   ├── pipeline/
│   │   └── script.sh          # main pipeline — run this directly or via web
│   ├── back/
│   │   ├── back.py            # FastAPI backend (split mode)
│   │   └── app.py             # FastAPI monolith (single-server mode)
│   └── front/
│       ├── front.py           # FastAPI frontend
│       ├── static/
│       │   └── index.html     # single-page web app
│       └── templates/
│           └── index.html     # template for monolith mode
├── setup/                     # one-time environment setup scripts
├── data/
│   ├── requests/              # drop audio files here (CLI mode)
│   ├── test/                  # test fixtures — gitignored
│   ├── jobs/                  # jobs.csv — append-only job log
│   ├── processing/            # active job workspaces
│   ├── processed/             # completed job output
│   └── refused/               # files that failed the quality check
└── tests/
    └── test-pipeline.sh       # end-to-end test script
```

---

## Models

| Step | Model | Env |
|---|---|---|
| Stem separation | Demucs `htdemucs_6s` + `htdemucs_ft` | `.env-stems` |
| Vocal cleaning | `MDX23C-8KFFT-InstVoc_HQ.ckpt` | `.env-clean-2` |
| MIDI transcription | basic-pitch 0.4.0 | `.env-midi` |
| Lyrics (optional) | faster-whisper large-v3 | `.env-lyrics` |

---

## Known limitations

- Vocal cleaning runs on CPU only (GPU path not yet working)
- Lyrics transcription exists but is not wired into the pipeline
- No BPM, key, or chord detection yet

---

## License

MIT
