from fastapi import APIRouter, Depends
from app.memory import memory_service
from app.routers.auth import get_current_user
from app.models import models
from pydantic import BaseModel

router = APIRouter(prefix="/memory", tags=["memory"])

class MemoryStoreRequest(BaseModel):
    content: str

@router.post("/store")
async def store_memory(
    req: MemoryStoreRequest,
    current_user: models.User = Depends(get_current_user)
):
    memory_service.store_memory(current_user.id, req.content)
    return {"message": "Memory stored"}

@router.get("/retrieve")
async def retrieve_memories(
    query: str,
    current_user: models.User = Depends(get_current_user)
):
    memories = memory_service.retrieve_memories(current_user.id, query)
    return {"memories": memories}
