import os
import sys
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, Response
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(ROOT / "utils"))

STATIC = Path(__file__).parent / "static"

FRONT_HOST = os.getenv("FRONT_HOST", "0.0.0.0")
FRONT_PORT  = int(os.getenv("FRONT_PORT", "8000"))
BACK_URL    = os.getenv("BACK_URL", "http://localhost:8001")

app = FastAPI()


@app.get("/config.js", response_class=Response)
async def config_js():
    return Response(
        content=f"window.BACKEND_URL = '{BACK_URL}';",
        media_type="application/javascript",
        headers={"Cache-Control": "no-store"},
    )


@app.get("/api/lyrics")
async def get_lyrics():
    try:
        from lyrics import lyrics
        return lyrics
    except Exception:
        return []


@app.get("/", response_class=HTMLResponse)
async def index():
    return (STATIC / "index.html").read_text()
