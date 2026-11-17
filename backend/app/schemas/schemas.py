from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class MessageBase(BaseModel):
    content: str
    role: str
    metadata_json: Optional[Any] = None

class MessageCreate(MessageBase):
    chat_id: int

class Message(MessageBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True

class ChatBase(BaseModel):
    title: str
    chat_type: str

class ChatCreate(ChatBase):
    pass

class Chat(ChatBase):
    id: int
    user_id: int
    created_at: datetime
    messages: List[Message] = []
    class Config:
        from_attributes = True
