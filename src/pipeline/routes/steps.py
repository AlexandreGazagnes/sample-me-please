"""POST /jobs/{job_id}/run|stems|clean|midi|assemble — pipeline step execution."""
from fastapi import APIRouter, HTTPException

from config import STEPS
from jobs import read_status, run_step

router = APIRouter(prefix="/jobs/{job_id}")

STEP_SCRIPTS = {
    "stems":    "03-stems.sh",
    "clean":    "04-clean.sh",
    "midi":     "05-midi.sh",
    "assemble": "06-assemble.sh",
}


def _require_job(job_id: str) -> None:
    try:
        read_status(job_id)
    except FileNotFoundError:
        raise HTTPException(404, "Job not found")


@router.post("/run")
async def run_pipeline(job_id: str):
    """Run all steps sequentially. Blocks until the full pipeline completes."""
    _require_job(job_id)
    for name, script in STEP_SCRIPTS.items():
        code = await run_step(job_id, str(STEPS / script))
        if code != 0:
            raise HTTPException(500, f"{name} step failed (exit {code})")
    return {"job_id": job_id, "status": "done"}


@router.post("/stems")
async def run_stems(job_id: str):
    _require_job(job_id)
    code = await run_step(job_id, str(STEPS / "03-stems.sh"))
    if code != 0: raise HTTPException(500, "Stems step failed")
    return {"job_id": job_id, "step": "stems", "status": "done"}


@router.post("/clean")
async def run_clean(job_id: str):
    _require_job(job_id)
    code = await run_step(job_id, str(STEPS / "04-clean.sh"))
    if code != 0: raise HTTPException(500, "Clean step failed")
    return {"job_id": job_id, "step": "clean", "status": "done"}


@router.post("/midi")
async def run_midi(job_id: str):
    _require_job(job_id)
    code = await run_step(job_id, str(STEPS / "05-midi.sh"))
    if code != 0: raise HTTPException(500, "MIDI step failed")
    return {"job_id": job_id, "step": "midi", "status": "done"}


@router.post("/assemble")
async def run_assemble(job_id: str):
    _require_job(job_id)
    code = await run_step(job_id, str(STEPS / "06-assemble.sh"))
    if code != 0: raise HTTPException(500, "Assemble step failed")
    return {"job_id": job_id, "step": "assemble", "status": "done"}
