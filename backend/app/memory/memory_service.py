from app.core.vector_store import memory_index
from app.services.embedding_service import get_embedding

def store_memory(user_id: int, content: str):
    embedding = get_embedding(content)
    memory_index.upsert(
        vectors=[(f"user_{user_id}_mem_{hash(content)}", embedding, {"text": content, "user_id": user_id})]
    )

def retrieve_memories(user_id: int, query: str, top_k: int = 5):
    query_embedding = get_embedding(query)
    results = memory_index.query(
        vector=query_embedding,
        top_k=top_k,
        filter={"user_id": user_id},
        include_metadata=True
    )
    return [res['metadata']['text'] for res in results['matches']]
