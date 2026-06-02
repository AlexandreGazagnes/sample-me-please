import os
from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, FileResponse
from pydantic import BaseModel
from pathlib import Path
import asyncio
import subprocess
import uuid
import json
import io
import zipfile
from datetime import datetime

ROOT = Path(__file__).parent.parent.parent

BACK_HOST    = os.getenv("BACK_HOST",    "0.0.0.0")
BACK_PORT    = int(os.getenv("BACK_PORT", "8001"))
FRONT_ORIGIN = os.getenv("FRONT_ORIGIN", "http://localhost:8000")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=[FRONT_ORIGIN],
    allow_methods=["*"],
    allow_headers=["*"],
)

jobs: dict = {}


@app.post("/api/upload")
async def upload(file: UploadFile):
    ext = Path(file.filename).suffix.lower()
    if ext not in {".mp3", ".flac", ".wav", ".aiff"}:
        raise HTTPException(400, "Unsupported format — use MP3, FLAC, WAV or AIFF")

    dest = ROOT / "data" / "requests" / file.filename
    dest.write_bytes(await file.read())

    job_id = uuid.uuid4().hex[:8]
    jobs[job_id] = {
        "status": "processing",
        "history": [],
        "queue": asyncio.Queue(),
        "output_path": None,
    }

    asyncio.create_task(_run_pipeline(job_id, file.filename))
    return {"job_id": job_id}


async def _run_pipeline(job_id: str, filename: str):
    job = jobs[job_id]
    loop = asyncio.get_event_loop()

    def _run():
        proc = subprocess.Popen(
            ["bash", "src/pipeline/script.sh", filename],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        for line in proc.stdout:
            msg = {"type": "log", "text": line.rstrip()}
            job["history"].append(msg)
            loop.call_soon_threadsafe(job["queue"].put_nowait, msg)
        proc.wait()
        return proc.returncode

    code = await loop.run_in_executor(None, _run)

    if code == 0:
        processed = ROOT / "data" / "processed"
        dirs = sorted(processed.iterdir(), key=lambda d: d.stat().st_mtime, reverse=True) if processed.exists() else []
        job["output_path"] = str(dirs[0]) if dirs else None
        msg = {"type": "done"}
    else:
        msg = {"type": "error", "text": f"Pipeline exited with code {code}"}

    job["status"] = msg["type"]
    job["history"].append(msg)
    job["queue"].put_nowait(msg)


@app.get("/api/jobs/{job_id}/stream")
async def stream(job_id: str):
    if job_id not in jobs:
        raise HTTPException(404)

    async def generate():
        job = jobs[job_id]
        for msg in job["history"]:
            yield f"data: {json.dumps(msg)}\n\n"
        if job["status"] != "processing":
            return
        while True:
            try:
                msg = await asyncio.wait_for(job["queue"].get(), timeout=25)
                yield f"data: {json.dumps(msg)}\n\n"
                if msg["type"] in ("done", "error"):
                    break
            except asyncio.TimeoutError:
                yield 'data: {"type":"ping"}\n\n'

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@app.get("/api/jobs/{job_id}/files")
async def list_files(job_id: str):
    if job_id not in jobs:
        raise HTTPException(404)
    job = jobs[job_id]
    if job["status"] != "done" or not job["output_path"]:
        return {"files": []}

    output = Path(job["output_path"])
    files = []
    for f in sorted(output.rglob("*")):
        if f.is_file():
            rel = f.relative_to(ROOT)
            files.append({
                "name": f.name,
                "path": str(rel),
                "size": f.stat().st_size,
                "group": "/".join(rel.parts[3:-1]) or "output",
            })
    return {"files": files}


@app.get("/api/jobs/{job_id}/download-all")
async def download_all(job_id: str):
    if job_id not in jobs:
        raise HTTPException(404)
    job = jobs[job_id]
    if job["status"] != "done" or not job["output_path"]:
        raise HTTPException(400, "Job not complete")

    output = Path(job["output_path"])
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in sorted(output.rglob("*")):
            if f.is_file():
                zf.write(f, f.relative_to(output))
    buf.seek(0)

    zip_name = f"{output.name}.zip"
    return StreamingResponse(
        iter([buf.read()]),
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{zip_name}"'},
    )


@app.get("/dl/{path:path}")
async def download(path: str):
    full = (ROOT / path).resolve()
    if not full.exists() or not str(full).startswith(str(ROOT.resolve())):
        raise HTTPException(404)
    return FileResponse(full, filename=full.name)


class FeedbackPayload(BaseModel):
    ig: str = ""
    message: str


@app.post("/api/feedback")
async def feedback(payload: FeedbackPayload):
    msg = payload.message.strip()
    if not msg:
        raise HTTPException(400, "Message is empty")

    ig = payload.ig.strip().lstrip("@") or "anonymous"
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    messages_dir = ROOT / "data" / "messages"
    messages_dir.mkdir(exist_ok=True)

    entry = f"[{now}]  @{ig}\n{msg}\n{'─' * 48}\n\n"
    with open(messages_dir / "messages.txt", "a", encoding="utf-8") as f:
        f.write(entry)

    return {"ok": True}
