from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="MB Final API")

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Sample data model
class Item(BaseModel):
    id: int
    name: str
    description: Optional[str] = None

# In-memory database
items_db = [
    {"id": 1, "name": "Item 1", "description": "First item"},
    {"id": 2, "name": "Item 2", "description": "Second item"},
]

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Get all items
@app.get("/api/items", response_model=List[Item])
async def read_items():
    return items_db

# Get item by ID
@app.get("/api/items/{item_id}", response_model=Item)
async def read_item(item_id: int):
    for item in items_db:
        if item["id"] == item_id:
            return item
    raise HTTPException(status_code=404, detail="Item not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
