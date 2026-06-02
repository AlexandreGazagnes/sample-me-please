from fastapi import FastAPI

from routes.intake import router as intake_router
from routes.steps import router as steps_router
from routes.files import router as files_router

app = FastAPI(title="Sample-Me-Please — Pipeline API")

app.include_router(intake_router)
app.include_router(steps_router)
app.include_router(files_router)
