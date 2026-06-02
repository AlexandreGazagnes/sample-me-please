"""Job state helpers and step runner shared by all routes."""

import json
import asyncio
import subprocess
from datetime import datetime
from pathlib import Path

from config import ROOT, STEPS


def status_path(job_id: str) -> Path:
    for base in ("processing", "processed"):
        p = ROOT / "data" / base / job_id / "status.json"
        if p.exists():
            return p
    raise FileNotFoundError(job_id)


def read_status(job_id: str) -> dict:
    return json.loads(status_path(job_id).read_text())


def write_status(job_id: str, song_name: str, source_file: str, ext: str) -> None:
    processing_dir = ROOT / "data" / "processing" / job_id
    processing_dir.mkdir(parents=True, exist_ok=True)
    status = {
        "job_id": job_id,
        "song_name": song_name,
        "source_file": source_file,
        "ext": ext,
        "created_at": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
        "output_path": None,
        "steps": {
            "quality": "pending",
            "workspace": "pending",
            "stems": "pending",
            "clean": "pending",
            "midi": "pending",
            "assemble": "pending",
        },
    }
    (processing_dir / "status.json").write_text(json.dumps(status, indent=2))


async def run_step(job_id: str, script: str, extra_args: list[str] = []) -> int:
    """Run a pipeline bash step synchronously in a thread. Blocks until done."""
    loop = asyncio.get_event_loop()

    def _run():
        return subprocess.run(
            ["bash", script, job_id, *extra_args], cwd=ROOT
        ).returncode

    return await loop.run_in_executor(None, _run)
