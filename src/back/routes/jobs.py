from fastapi import APIRouter
from proxy import proxy_post, proxy_get, proxy_stream, STEP_TIMEOUT

router = APIRouter(prefix="/api/jobs/{job_id}")


@router.post("/run")
async def run_pipeline(job_id: str):
    return await proxy_post(f"/jobs/{job_id}/run", timeout=STEP_TIMEOUT)


@router.post("/stems")
async def run_stems(job_id: str):
    return await proxy_post(f"/jobs/{job_id}/stems", timeout=STEP_TIMEOUT)


@router.post("/clean")
async def run_clean(job_id: str):
    return await proxy_post(f"/jobs/{job_id}/clean", timeout=STEP_TIMEOUT)


@router.post("/midi")
async def run_midi(job_id: str):
    return await proxy_post(f"/jobs/{job_id}/midi", timeout=STEP_TIMEOUT)


@router.post("/assemble")
async def run_assemble(job_id: str):
    return await proxy_post(f"/jobs/{job_id}/assemble", timeout=STEP_TIMEOUT)


@router.get("/status")
async def status(job_id: str):
    return await proxy_get(f"/jobs/{job_id}/status")


@router.get("/files")
async def list_files(job_id: str):
    return await proxy_get(f"/jobs/{job_id}/files")


@router.get("/download-all")
async def download_all(job_id: str):
    return proxy_stream(
        f"/jobs/{job_id}/download-all",
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{job_id}.zip"'},
    )


@router.get("/stream")
async def stream(job_id: str):
    return proxy_stream(
        f"/jobs/{job_id}/stream",
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
