from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core import database
from app.routers.auth import get_current_user
from app.models import models
from app.memory import memory_service
from app.services.embedding_service import get_embedding
from app.core.vector_store import product_index
from pydantic import BaseModel
from typing import List, Optional
from openai import OpenAI
from app.core.config import settings

router = APIRouter(prefix="/ecommerce", tags=["ecommerce"])

client = OpenAI(api_key=settings.OPENAI_API_KEY)


class ProductCreate(BaseModel):
    name: str
    description: str
    price: float
    category: str
    image_url: Optional[str] = None


class ProductResponse(BaseModel):
    id: int
    name: str
    description: str
    price: float
    category: str
    image_url: Optional[str]
    
    class Config:
        from_attributes = True


@router.post("/products", response_model=ProductResponse)
async def create_product(
    product: ProductCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new product and index it"""
    # Create embedding for product
    product_text = f"{product.name} {product.description} {product.category}"
    embedding = get_embedding(product_text)
    
    # Create product in DB
    db_product = models.Product(
        name=product.name,
        description=product.description,
        price=product.price,
        category=product.category,
        image_url=product.image_url,
        vector_id=f"product_{product.name}_{hash(product_text)}"
    )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    
    # Index in vector store
    product_index.upsert(
        vectors=[(
            db_product.vector_id,
            embedding,
            {
                "product_id": db_product.id,
                "name": product.name,
                "category": product.category,
                "price": product.price
            }
        )]
    )
    
    return db_product


@router.get("/products", response_model=List[ProductResponse])
async def list_products(
    category: Optional[str] = None,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """List all products, optionally filtered by category"""
    query = db.query(models.Product)
    if category:
        query = query.filter(models.Product.category == category)
    products = query.all()
    return products


@router.post("/recommend")
async def get_recommendations(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    """Generate AI-powered product recommendations based on user memory"""
    try:
        # Retrieve user's shopping memories
        memories = memory_service.retrieve_memories(
            current_user.id,
            "shopping preferences style likes",
            top_k=10
        )
        
        if not memories:
            # Return popular products if no memory
            products = db.query(models.Product).limit(6).all()
            return {
                "recommendations": [
                    {
                        "id": p.id,
                        "name": p.name,
                        "price": p.price,
                        "category": p.category,
                        "image_url": p.image_url,
                        "reason": "Popular choice"
                    }
                    for p in products
                ],
                "based_on": "popularity"
            }
        
        # Use memories to find similar products
        memory_text = " ".join(memories)
        memory_embedding = get_embedding(memory_text)
        
        # Query vector store for similar products
        results = product_index.query(
            vector=memory_embedding,
            top_k=6,
            include_metadata=True
        )
        
        # Get full product details
        recommendations = []
        for match in results['matches']:
            product_id = match['metadata'].get('product_id')
            if product_id:
                product = db.query(models.Product).filter(
                    models.Product.id == product_id
                ).first()
                if product:
                    # Generate reason using AI
                    reason_prompt = f"Based on user preferences: {memory_text[:200]}, explain in one sentence why {product.name} is recommended."
                    reason_response = client.chat.completions.create(
                        model="gpt-3.5-turbo",
                        messages=[{"role": "user", "content": reason_prompt}],
                        max_tokens=50
                    )
                    reason = reason_response.choices[0].message.content
                    
                    recommendations.append({
                        "id": product.id,
                        "name": product.name,
                        "price": product.price,
                        "category": product.category,
                        "image_url": product.image_url,
                        "reason": reason,
                        "similarity_score": 1 - match['score']  # Convert distance to similarity
                    })
                    
                    # Store recommendation
                    db_rec = models.ProductRecommendation(
                        user_id=current_user.id,
                        product_id=product.id,
                        score=1 - match['score'],
                        reason=reason
                    )
                    db.add(db_rec)
        
        db.commit()
        
        return {
            "recommendations": recommendations,
            "based_on": "your preferences and history"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Recommendation error: {str(e)}")


@router.post("/search")
async def conversational_search(
    query: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    """Conversational product search using AI"""
    try:
        # Get embedding for search query
        query_embedding = get_embedding(query)
        
        # Search in product vector store
        results = product_index.query(
            vector=query_embedding,
            top_k=10,
            include_metadata=True
        )
        
        # Get products
        products = []
        for match in results['matches']:
            product_id = match['metadata'].get('product_id')
            if product_id:
                product = db.query(models.Product).filter(
                    models.Product.id == product_id
                ).first()
                if product:
                    products.append({
                        "id": product.id,
                        "name": product.name,
                        "description": product.description,
                        "price": product.price,
                        "category": product.category,
                        "image_url": product.image_url,
                        "relevance": 1 - match['score']
                    })
        
        # Generate conversational response
        product_list = "\n".join([
            f"- {p['name']}: ${p['price']} ({p['category']})"
            for p in products[:5]
        ])
        
        ai_prompt = f"""User is searching for: "{query}"
Here are the relevant products:
{product_list}

Provide a friendly, conversational response recommending 2-3 products with brief reasons."""
        
        ai_response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": ai_prompt}],
            max_tokens=200
        )
        
        return {
            "ai_response": ai_response.choices[0].message.content,
            "products": products[:5],
            "query": query
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search error: {str(e)}")


@router.get("/product/{product_id}")
async def get_product_details(
    product_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get detailed product information"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    return {
        "id": product.id,
        "name": product.name,
        "description": product.description,
        "price": product.price,
        "category": product.category,
        "image_url": product.image_url
    }


@router.post("/ask-about-product")
async def ask_about_product(
    product_id: int,
    question: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Ask AI questions about a specific product"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    prompt = f"""Product: {product.name}
Description: {product.description}
Price: ${product.price}
Category: {product.category}

User question: {question}

Provide a helpful, detailed answer about this product."""
    
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=200
    )
    
    return {
        "question": question,
        "answer": response.choices[0].message.content,
        "product": {
            "id": product.id,
            "name": product.name,
            "price": product.price
        }
    }
