import os
import faiss
import numpy as np
import pickle
from typing import List, Dict, Any, Tuple

class LocalVectorStore:
    def __init__(self, name: str, dimension: int = 1536):
        self.name = name
        self.dimension = dimension
        self.index_path = f"storage/vector_indices/{name}.index"
        self.metadata_path = f"storage/vector_indices/{name}.pkl"
        
        os.makedirs("storage/vector_indices", exist_ok=True)
        
        if os.path.exists(self.index_path):
            self.index = faiss.read_index(self.index_path)
            with open(self.metadata_path, 'rb') as f:
                self.metadata = pickle.load(f)
        else:
            self.index = faiss.IndexFlatL2(dimension)
            self.metadata = [] # List of dicts matching index IDs

    def _save(self):
        faiss.write_index(self.index, self.index_path)
        with open(self.metadata_path, 'wb') as f:
            pickle.dump(self.metadata, f)

    def upsert(self, vectors: List[Tuple[str, List[float], Dict[str, Any]]]):
        # vectors format: [(id, embedding, metadata), ...]
        for vid, embedding, meta in vectors:
            # For simplicity, we just append. In a real app, we'd handle ID updates.
            # FAISS IndexFlatL2 doesn't support IDs easily, so we track them in metadata.
            vec = np.array([embedding]).astype('float32')
            self.index.add(vec)
            self.metadata.append({"id": vid, "metadata": meta})
        self._save()

    def query(self, vector: List[float], top_k: int = 5, filter: Dict[str, Any] = None, include_metadata: bool = True):
        query_vec = np.array([vector]).astype('float32')
        distances, indices = self.index.search(query_vec, top_k * 5) # Get more for filtering
        
        matches = []
        for dist, idx in zip(distances[0], indices[0]):
            if idx == -1 or idx >= len(self.metadata):
                continue
            
            item = self.metadata[idx]
            # Apply filtering
            if filter:
                match = True
                for key, value in filter.items():
                    if item['metadata'].get(key) != value:
                        match = False
                        break
                if not match:
                    continue
            
            matches.append({
                "id": item['id'],
                "score": float(dist),
                "metadata": item['metadata'] if include_metadata else None
            })
            
            if len(matches) >= top_k:
                break
                
        return {"matches": matches}

# Initialize local stores
document_index = LocalVectorStore("document-embeddings")
memory_index = LocalVectorStore("user-memory-vectors")
product_index = LocalVectorStore("product-vectors")
