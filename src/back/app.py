from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes.upload   import router as upload_router
from routes.jobs     import router as jobs_router
from routes.feedback import router as feedback_router

app = FastAPI(title="Sample-Me-Please — Web API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(upload_router)
app.include_router(jobs_router)
app.include_router(feedback_router)
