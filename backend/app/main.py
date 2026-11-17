from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import auth, rag, voice, persona, agent, memory, websocket, ecommerce, chat
from app.core.database import engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AI Super App API",
    description="Backend for AI Multi-Agent Flutter Super App",
    version="1.0.0"
)

# Set up CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(rag.router)
app.include_router(voice.router)
app.include_router(persona.router)
app.include_router(agent.router)
app.include_router(memory.router)
app.include_router(websocket.router)
app.include_router(ecommerce.router)
app.include_router(chat.router)

@app.get("/")
async def root():
    return {"message": "Welcome to AI Super App API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
