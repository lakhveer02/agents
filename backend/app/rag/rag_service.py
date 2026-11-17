import os
import httpx
from bs4 import BeautifulSoup
from PyPDF2 import PdfReader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from app.services.embedding_service import get_embedding
from app.core.vector_store import document_index
from app.schemas import schemas
from typing import List

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=100
)

async def process_pdf(file_path: str, user_id: int):
    reader = PdfReader(file_path)
    text = ""
    for page in reader.pages:
        text += page.extract_text()
    
    chunks = text_splitter.split_text(text)
    for i, chunk in enumerate(chunks):
        embedding = get_embedding(chunk)
        document_index.upsert(
            vectors=[(f"user_{user_id}_pdf_{os.path.basename(file_path)}_{i}", embedding, {"text": chunk, "user_id": user_id, "source": file_path})]
        )
    return {"status": "success", "chunks": len(chunks)}

async def process_url(url: str, user_id: int):
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        soup = BeautifulSoup(response.text, 'html.parser')
        text = soup.get_text()
    
    chunks = text_splitter.split_text(text)
    for i, chunk in enumerate(chunks):
        embedding = get_embedding(chunk)
        document_index.upsert(
            vectors=[(f"user_{user_id}_url_{url}_{i}", embedding, {"text": chunk, "user_id": user_id, "source": url})]
        )
    return {"status": "success", "chunks": len(chunks)}

def query_rag(query: str, user_id: int, top_k: int = 3):
    query_embedding = get_embedding(query)
    results = document_index.query(
        vector=query_embedding,
        top_k=top_k,
        filter={"user_id": user_id},
        include_metadata=True
    )
    
    contexts = [res['metadata']['text'] for res in results['matches']]
    sources = [res['metadata']['source'] for res in results['matches']]
    return contexts, sources
