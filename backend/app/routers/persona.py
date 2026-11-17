from fastapi import APIRouter, Depends
from app.agents import agent_engine
from app.routers.auth import get_current_user
from app.models import models
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/persona", tags=["persona"])

class PersonaChatRequest(BaseModel):
    persona: str
    message: str
    history: List[dict] = []

@router.post("/chat")
async def persona_chat(
    req: PersonaChatRequest,
    current_user: models.User = Depends(get_current_user)
):
    response = await agent_engine.get_persona_completion(req.persona, req.message, req.history)
    return {"response": response}
