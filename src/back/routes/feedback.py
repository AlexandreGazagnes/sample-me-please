from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from config import ROOT

router = APIRouter()


class FeedbackPayload(BaseModel):
    ig: str = ""
    message: str


@router.post("/api/feedback")
async def feedback(payload: FeedbackPayload):
    msg = payload.message.strip()
    if not msg:
        raise HTTPException(400, "Message is empty")

    ig  = payload.ig.strip().lstrip("@") or "anonymous"
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    messages_dir = ROOT / "data" / "messages"
    messages_dir.mkdir(exist_ok=True)
    entry = f"[{now}]  @{ig}\n{msg}\n{'─' * 48}\n\n"
    (messages_dir / "messages.txt").open("a", encoding="utf-8").write(entry)

    return {"ok": True}
