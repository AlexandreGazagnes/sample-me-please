import os
from pathlib import Path

PIPE_URL  = os.getenv("PIPE_URL",  "http://localhost:8002")
BACK_HOST = os.getenv("BACK_HOST", "0.0.0.0")
BACK_PORT = int(os.getenv("BACK_PORT", "8001"))

ROOT = Path(__file__).parent.parent.parent
