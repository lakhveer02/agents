from openai import OpenAI
from app.core.config import settings
import os

client = OpenAI(api_key=settings.OPENAI_API_KEY)

async def transcribe_audio(file_path: str):
    with open(file_path, "rb") as audio_file:
        transcript = client.audio.transcriptions.create(
            model="whisper-1", 
            file=audio_file
        )
    return transcript.text

async def text_to_speech(text: str, output_path: str):
    response = client.audio.speech.create(
        model="tts-1",
        voice="alloy",
        input=text
    )
    response.stream_to_file(output_path)
    return output_path
