from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from typing import Dict, List
import json
import asyncio
from app.core import database
from app.routers.auth import get_current_user
from app.models import models
from app.agents import agent_engine
from app.rag import rag_service
from openai import OpenAI
from app.core.config import settings

router = APIRouter()

client = OpenAI(api_key=settings.OPENAI_API_KEY)


class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def send_message(self, message: dict, client_id: str):
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_json(message)

    async def send_stream_chunk(self, chunk: str, client_id: str, metadata: dict = None):
        message = {
            "type": "message",
            "content": chunk,
            "metadata": metadata or {}
        }
        await self.send_message(message, client_id)

    async def send_complete(self, client_id: str, metadata: dict = None):
        message = {
            "type": "complete",
            "content": "",
            "metadata": metadata or {}
        }
        await self.send_message(message, client_id)

    async def send_error(self, error: str, client_id: str):
        message = {
            "type": "error",
            "content": error,
            "metadata": {}
        }
        await self.send_message(message, client_id)


manager = ConnectionManager()


@router.websocket("/ws/chat/{client_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    client_id: str,
    db: Session = Depends(database.get_db)
):
    await manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_json()
            chat_type = data.get("chat_type", "rag")
            message = data.get("message", "")
            user_id = data.get("user_id", 1)  # In production, get from auth
            history = data.get("history", [])
            
            if chat_type == "rag":
                await handle_rag_stream(message, user_id, client_id, history)
            elif chat_type == "persona":
                persona = data.get("persona", "mentor")
                await handle_persona_stream(message, persona, client_id, history)
            elif chat_type == "agent":
                context = data.get("context", "")
                await handle_agent_stream(message, context, client_id)
            elif chat_type == "voice":
                await handle_voice_stream(message, user_id, client_id)
            else:
                await manager.send_error(f"Unknown chat type: {chat_type}", client_id)
                
    except WebSocketDisconnect:
        manager.disconnect(client_id)
    except Exception as e:
        await manager.send_error(str(e), client_id)
        manager.disconnect(client_id)


async def handle_rag_stream(query: str, user_id: int, client_id: str, history: List[dict]):
    """Stream RAG responses with context"""
    try:
        # Retrieve relevant context
        contexts, sources = rag_service.query_rag(query, user_id, top_k=3)
        
        # Build context string
        context_text = "\n\n".join([f"Context {i+1}: {ctx}" for i, ctx in enumerate(contexts)])
        
        # Build messages for OpenAI
        system_prompt = f"""You are a helpful AI assistant. Answer the user's question based on the following context.
If the context doesn't contain relevant information, say so clearly.

Context:
{context_text}"""
        
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-5:])  # Include last 5 messages for context
        messages.append({"role": "user", "content": query})
        
        # Stream response
        stream = client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=messages,
            stream=True,
            temperature=0.7
        )
        
        for chunk in stream:
            if chunk.choices[0].delta.content:
                await manager.send_stream_chunk(
                    chunk.choices[0].delta.content,
                    client_id,
                    {"sources": sources}
                )
                await asyncio.sleep(0.01)  # Small delay for smooth streaming
        
        await manager.send_complete(client_id, {"sources": sources})
        
    except Exception as e:
        await manager.send_error(f"RAG error: {str(e)}", client_id)


async def handle_persona_stream(message: str, persona: str, client_id: str, history: List[dict]):
    """Stream persona chat responses"""
    try:
        system_prompt = agent_engine.PERSONA_PROMPTS.get(
            persona,
            "You are a helpful assistant."
        )
        
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(history[-10:])
        messages.append({"role": "user", "content": message})
        
        stream = client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=messages,
            stream=True,
            temperature=0.9
        )
        
        for chunk in stream:
            if chunk.choices[0].delta.content:
                await manager.send_stream_chunk(
                    chunk.choices[0].delta.content,
                    client_id,
                    {"persona": persona}
                )
                await asyncio.sleep(0.01)
        
        await manager.send_complete(client_id, {"persona": persona})
        
    except Exception as e:
        await manager.send_error(f"Persona error: {str(e)}", client_id)


async def handle_agent_stream(command: str, context: str, client_id: str):
    """Stream command agent responses with reasoning"""
    try:
        system_prompt = """You are an AI Command Agent like Cursor. You can analyze code, generate APIs, fix errors, and optimize UI.
Provide your reasoning step by step, then the final result or instructions.
Use markdown formatting for code blocks."""
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Context: {context}\n\nCommand: {command}"}
        ]
        
        stream = client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=messages,
            stream=True,
            temperature=0.5
        )
        
        for chunk in stream:
            if chunk.choices[0].delta.content:
                await manager.send_stream_chunk(
                    chunk.choices[0].delta.content,
                    client_id,
                    {"command": command}
                )
                await asyncio.sleep(0.01)
        
        await manager.send_complete(client_id, {"command": command})
        
    except Exception as e:
        await manager.send_error(f"Agent error: {str(e)}", client_id)


async def handle_voice_stream(text: str, user_id: int, client_id: str):
    """Stream voice AI responses"""
    try:
        # Get relevant context from RAG if available
        contexts, _ = rag_service.query_rag(text, user_id, top_k=2)
        context_text = "\n".join(contexts) if contexts else ""
        
        system_prompt = f"""You are a friendly voice AI assistant. Keep responses concise and conversational.
{f'Relevant information: {context_text}' if context_text else ''}"""
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": text}
        ]
        
        stream = client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=messages,
            stream=True,
            temperature=0.8,
            max_tokens=200  # Keep voice responses shorter
        )
        
        for chunk in stream:
            if chunk.choices[0].delta.content:
                await manager.send_stream_chunk(
                    chunk.choices[0].delta.content,
                    client_id,
                    {"mode": "voice"}
                )
                await asyncio.sleep(0.01)
        
        await manager.send_complete(client_id, {"mode": "voice"})
        
    except Exception as e:
        await manager.send_error(f"Voice error: {str(e)}", client_id)
