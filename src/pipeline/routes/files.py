"""GET /jobs/{job_id}/status|files|download-all and /dl/{path} — file access."""
import io
import zipfile
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse, FileResponse

from config import ROOT
from jobs import read_status

router = APIRouter()


def _resolve(path_str: str) -> Path:
    p = Path(path_str)
    return p if p.is_absolute() else ROOT / p


def _get_job_or_404(job_id: str) -> dict:
    try:
        return read_status(job_id)
    except FileNotFoundError:
        raise HTTPException(404, "Job not found")


@router.get("/jobs/{job_id}/status")
async def status(job_id: str):
    return _get_job_or_404(job_id)


@router.get("/jobs/{job_id}/files")
async def list_files(job_id: str):
    st = _get_job_or_404(job_id)
    output_path = st.get("output_path")
    if not output_path:
        return {"files": []}

    output = _resolve(output_path)
    files = []
    for f in sorted(output.rglob("*")):
        if f.is_file() and f.name != "status.json":
            rel = f.relative_to(ROOT)
            files.append({
                "name":  f.name,
                "path":  str(rel),
                "size":  f.stat().st_size,
                "group": "/".join(rel.parts[3:-1]) or "output",
            })
    return {"files": files}


@router.get("/jobs/{job_id}/download-all")
async def download_all(job_id: str):
    st = _get_job_or_404(job_id)
    output_path = st.get("output_path")
    if not output_path:
        raise HTTPException(400, "Job not complete")

    output = _resolve(output_path)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in sorted(output.rglob("*")):
            if f.is_file() and f.name != "status.json":
                zf.write(f, f.relative_to(output))
    buf.seek(0)

    return StreamingResponse(
        iter([buf.read()]),
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{output.name}.zip"'},
    )


@router.get("/dl/{path:path}")
async def download(path: str):
    full = (ROOT / path).resolve()
    if not full.exists() or not str(full).startswith(str(ROOT.resolve())):
        raise HTTPException(404)
    return FileResponse(full, filename=full.name)
