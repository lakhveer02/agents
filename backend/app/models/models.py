from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Text, JSON, Float
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    chats = relationship("Chat", back_populates="owner")
    memories = relationship("Memory", back_populates="owner")
    purchases = relationship("Purchase", back_populates="owner")

class Chat(Base):
    __tablename__ = "chats"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    chat_type = Column(String) # rag, voice, persona, agent, commerce
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="chats")
    messages = relationship("Message", back_populates="chat")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    chat_id = Column(Integer, ForeignKey("chats.id"))
    content = Column(Text)
    role = Column(String) # user, assistant
    metadata_json = Column(JSON, nullable=True) # for citations, etc.
    created_at = Column(DateTime, default=datetime.utcnow)

    chat = relationship("Chat", back_populates="messages")

class Document(Base):
    __tablename__ = "documents"
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String)
    file_path = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

class Memory(Base):
    __tablename__ = "memories"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text)
    vector_id = Column(String) # Pinecone ID
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="memories")

class Purchase(Base):
    __tablename__ = "purchases"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    product_name = Column(String)
    price = Column(Float)
    purchase_date = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="purchases")

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    description = Column(Text)
    price = Column(Float)
    category = Column(String)
    vector_id = Column(String, nullable=True)  # FAISS vector ID
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class ProductRecommendation(Base):
    __tablename__ = "product_recommendations"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    score = Column(Float)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
