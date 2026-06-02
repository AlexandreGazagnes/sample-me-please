"""POST /jobs — receive file, quality check, create job, init workspace."""

import secrets
import shutil
import subprocess
from pathlib import Path

from fastapi import APIRouter, HTTPException, UploadFile

from config import ROOT, STEPS
from jobs import write_status

router = APIRouter()


@router.post("/jobs", status_code=201)
def create_job(file: UploadFile):
    ext = Path(file.filename).suffix.lower()
    if ext not in {".mp3", ".flac", ".wav", ".aiff"}:
        raise HTTPException(400, "Unsupported format — use MP3, FLAC, WAV or AIFF")

    # vars
    song_name = Path(file.filename).stem
    ext_lower = ext.lstrip(".")

    dest = ROOT / "data" / "requests" / file.filename
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(file.file.read())

    # job id
    job_id = f"{song_name}_{secrets.token_hex(4)}"
    write_status(job_id, song_name, file.filename, ext_lower)

    # Quality check — fast ffprobe call
    result = subprocess.run(
        ["bash", str(STEPS / "00-quality.sh"), str(dest), ext_lower],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        dest.unlink(missing_ok=True)
        shutil.rmtree(ROOT / "data" / "processing" / job_id, ignore_errors=True)
        raise HTTPException(422, f"Quality check failed:\n{result.stdout.strip()}")

    # Log to jobs.csv
    subprocess.run(
        ["bash", str(STEPS / "01-job.sh"), job_id, file.filename, song_name],
        cwd=ROOT,
        check=True,
    )

    # Init workspace (mkdir + copy source file)
    subprocess.run(
        ["bash", str(STEPS / "02-workspace.sh"), job_id, str(dest)],
        cwd=ROOT,
        check=True,
    )

    return {"job_id": job_id}
