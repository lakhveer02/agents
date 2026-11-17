from fastapi import APIRouter, Depends, UploadFile, File
from fastapi.responses import FileResponse
from app.voice import voice_service
from app.routers.auth import get_current_user
from app.models import models
import os
import uuid

router = APIRouter(prefix="/voice", tags=["voice"])

VOICE_DIR = "voice_cache"
os.makedirs(VOICE_DIR, exist_ok=True)

@router.post("/process")
async def process_voice(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user)
):
    temp_input = os.path.join(VOICE_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(temp_input, "wb") as buffer:
        buffer.write(await file.read())
    
    # STT
    text = await voice_service.transcribe_audio(temp_input)
    
    # Process text with LLM (simple for now)
    # response_text = ... (integrate with LLM service later)
    response_text = f"You said: {text}. How can I help you further?"
    
    # TTS
    temp_output = os.path.join(VOICE_DIR, f"resp_{uuid.uuid4()}.mp3")
    await voice_service.text_to_speech(response_text, temp_output)
    
    return {
        "user_text": text,
        "ai_text": response_text,
        "audio_url": f"/voice/play/{os.path.basename(temp_output)}"
    }

@router.get("/play/{filename}")
async def play_voice(filename: str):
    file_path = os.path.join(VOICE_DIR, filename)
    return FileResponse(file_path)
