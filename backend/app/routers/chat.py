from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core import database
from app.routers.auth import get_current_user
from app.models import models
from app.schemas import schemas
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatCreateRequest(BaseModel):
    title: str
    chat_type: str  # rag, voice, persona, agent, commerce


class MessageCreateRequest(BaseModel):
    chat_id: int
    content: str
    role: str  # user or assistant
    metadata_json: Optional[dict] = None


@router.post("/create", response_model=schemas.Chat)
async def create_chat(
    req: ChatCreateRequest,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new chat session"""
    chat = models.Chat(
        title=req.title,
        chat_type=req.chat_type,
        user_id=current_user.id
    )
    db.add(chat)
    db.commit()
    db.refresh(chat)
    return chat


@router.get("/list", response_model=List[schemas.Chat])
async def list_chats(
    chat_type: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """List all user chats, optionally filtered by type"""
    query = db.query(models.Chat).filter(models.Chat.user_id == current_user.id)
    
    if chat_type:
        query = query.filter(models.Chat.chat_type == chat_type)
    
    chats = query.order_by(models.Chat.created_at.desc()).limit(limit).all()
    return chats


@router.get("/history/{chat_id}", response_model=schemas.Chat)
async def get_chat_history(
    chat_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get full chat history including all messages"""
    chat = db.query(models.Chat).filter(
        models.Chat.id == chat_id,
        models.Chat.user_id == current_user.id
    ).first()
    
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    return chat


@router.post("/message", response_model=schemas.Message)
async def add_message(
    req: MessageCreateRequest,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Add a message to a chat"""
    # Verify chat belongs to user
    chat = db.query(models.Chat).filter(
        models.Chat.id == req.chat_id,
        models.Chat.user_id == current_user.id
    ).first()
    
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    message = models.Message(
        chat_id=req.chat_id,
        content=req.content,
        role=req.role,
        metadata_json=req.metadata_json
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


@router.delete("/delete/{chat_id}")
async def delete_chat(
    chat_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Delete a chat and all its messages"""
    chat = db.query(models.Chat).filter(
        models.Chat.id == chat_id,
        models.Chat.user_id == current_user.id
    ).first()
    
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Delete all messages first
    db.query(models.Message).filter(models.Message.chat_id == chat_id).delete()
    
    # Delete chat
    db.delete(chat)
    db.commit()
    
    return {"message": "Chat deleted successfully", "chat_id": chat_id}


@router.get("/recent")
async def get_recent_activity(
    limit: int = 10,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get recent chat activity across all types"""
    # Get recent messages with chat info
    recent_messages = db.query(models.Message).join(models.Chat).filter(
        models.Chat.user_id == current_user.id
    ).order_by(
        models.Message.created_at.desc()
    ).limit(limit).all()
    
    activity = []
    for msg in recent_messages:
        activity.append({
            "chat_id": msg.chat_id,
            "chat_title": msg.chat.title,
            "chat_type": msg.chat.chat_type,
            "message": msg.content[:100] + "..." if len(msg.content) > 100 else msg.content,
            "role": msg.role,
            "timestamp": msg.created_at.isoformat()
        })
    
    return {"recent_activity": activity}


@router.get("/stats")
async def get_chat_stats(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get user's chat statistics"""
    total_chats = db.query(models.Chat).filter(
        models.Chat.user_id == current_user.id
    ).count()
    
    # Count by type
    rag_chats = db.query(models.Chat).filter(
        models.Chat.user_id == current_user.id,
        models.Chat.chat_type == "rag"
    ).count()
    
    persona_chats = db.query(models.Chat).filter(
        models.Chat.user_id == current_user.id,
        models.Chat.chat_type == "persona"
    ).count()
    
    agent_chats = db.query(models.Chat).filter(
        models.Chat.user_id == current_user.id,
        models.Chat.chat_type == "agent"
    ).count()
    
    voice_chats = db.query(models.Chat).filter(
        models.Chat.user_id == current_user.id,
        models.Chat.chat_type == "voice"
    ).count()
    
    total_messages = db.query(models.Message).join(models.Chat).filter(
        models.Chat.user_id == current_user.id
    ).count()
    
    return {
        "total_chats": total_chats,
        "total_messages": total_messages,
        "by_type": {
            "rag": rag_chats,
            "persona": persona_chats,
            "agent": agent_chats,
            "voice": voice_chats
        }
    }
