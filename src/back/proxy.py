import httpx
from fastapi import HTTPException
from fastapi.responses import StreamingResponse

from config import PIPE_URL

STEP_TIMEOUT = httpx.Timeout(connect=10, read=900, write=60, pool=10)


async def proxy_post(path: str, timeout=30, **kwargs):
    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.post(f"{PIPE_URL}{path}", **kwargs)
    if resp.status_code >= 400:
        raise HTTPException(resp.status_code, resp.text)
    return resp.json()


async def proxy_get(path: str, timeout=10):
    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.get(f"{PIPE_URL}{path}")
    if resp.status_code >= 400:
        raise HTTPException(resp.status_code, resp.text)
    return resp.json()


def proxy_stream(path: str, media_type: str, headers: dict, timeout=None) -> StreamingResponse:
    async def generate():
        async with httpx.AsyncClient(timeout=timeout) as client:
            async with client.stream("GET", f"{PIPE_URL}{path}") as resp:
                if resp.status_code >= 400:
                    raise HTTPException(resp.status_code)
                async for chunk in resp.aiter_bytes():
                    yield chunk

    return StreamingResponse(generate(), media_type=media_type, headers=headers)
