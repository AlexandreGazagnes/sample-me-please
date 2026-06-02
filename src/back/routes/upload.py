from fastapi import APIRouter, UploadFile
from proxy import proxy_post

router = APIRouter()


@router.post("/api/upload")
async def upload(file: UploadFile):
    data = await file.read()
    return await proxy_post(
        "/jobs",
        files={"file": (file.filename, data, file.content_type or "application/octet-stream")},
    )
