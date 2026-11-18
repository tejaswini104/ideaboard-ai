import os
from datetime import datetime, timezone
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg://ideaboard:ideaboard@db:5432/ideaboard")
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create the simple table automatically for local development.
    with engine.begin() as conn:
        conn.execute(text("""CREATE TABLE IF NOT EXISTS ideas (
            id SERIAL PRIMARY KEY,
            content TEXT NOT NULL CHECK (length(trim(content)) > 0),
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"""))
    yield

app = FastAPI(title="IdeaBoard API", version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000").split(","), allow_methods=["GET", "POST", "OPTIONS"], allow_headers=["*"])

class IdeaCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)

@app.get("/health")
def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except SQLAlchemyError as exc:
        raise HTTPException(status_code=503, detail="Database unavailable") from exc

@app.get("/api/ideas")
def list_ideas():
    with engine.connect() as conn:
        rows = conn.execute(text("SELECT id, content, created_at FROM ideas ORDER BY created_at DESC, id DESC")).mappings().all()
        return [{"id": r["id"], "content": r["content"], "created_at": r["created_at"].isoformat()} for r in rows]

@app.post("/api/ideas", status_code=201)
def create_idea(payload: IdeaCreate):
    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Idea cannot be blank")
    with engine.begin() as conn:
        row = conn.execute(text("INSERT INTO ideas(content) VALUES (:content) RETURNING id, content, created_at"), {"content": content}).mappings().one()
        return {"id": row["id"], "content": row["content"], "created_at": row["created_at"].isoformat()}
