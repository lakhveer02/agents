from fastapi import APIRouter, Depends
from app.agents import agent_engine
from app.routers.auth import get_current_user
from app.models import models
from pydantic import BaseModel

router = APIRouter(prefix="/agent", tags=["agent"])

class CommandRequest(BaseModel):
    command: str
    context: str = ""

@router.post("/command")
async def execute_command(
    req: CommandRequest,
    current_user: models.User = Depends(get_current_user)
):
    response = await agent_engine.run_command_agent(req.command, req.context)
    return {"result": response}
