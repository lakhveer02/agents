from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from app.core import database
from app.routers.auth import get_current_user
from app.models import models
from app.rag import rag_service
from app.core.config import settings
import os
import shutil

router = APIRouter(prefix="/rag", tags=["rag"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload-pdf")
async def upload_pdf(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    file_path = os.path.join(UPLOAD_DIR, f"{current_user.id}_{file.filename}")
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    await rag_service.process_pdf(file_path, current_user.id)
    
    # Save to DB
    db_doc = models.Document(filename=file.filename, file_path=file_path, user_id=current_user.id)
    db.add(db_doc)
    db.commit()
    
    return {"message": "PDF processed and indexed"}

@router.post("/url-ingest")
async def ingest_url(
    url: str,
    current_user: models.User = Depends(get_current_user)
):
    await rag_service.process_url(url, current_user.id)
    return {"message": "URL processed and indexed"}

@router.post("/query")
async def query_rag(
    query: str,
    current_user: models.User = Depends(get_current_user)
):
    contexts, sources = rag_service.query_rag(query, current_user.id)
    return {"contexts": contexts, "sources": sources}
