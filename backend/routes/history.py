# ==============================================================
# HISTORY ROUTES — Drive Session History
# ==============================================================
# Handles saving and retrieving driving session data from MongoDB.
# Each session records duration, drowsiness stats, and blink data.
# ==============================================================

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime
import logging

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from config.database import sessions_collection

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/history", tags=["History"])


# ── Request Models ──

class SaveSessionRequest(BaseModel):
    user_id: str
    start_time: str
    end_time: str
    duration_seconds: int
    max_drowsiness_percentage: float
    total_blinks: int
    drowsy_events: int
    status: str  # "completed" or "interrupted"


# ── Endpoints ──

@router.post("/save")
def save_session(req: SaveSessionRequest):
    """Save a completed driving session to the database."""
    if sessions_collection is None:
        raise HTTPException(503, "Database not available")

    session_doc = {
        "user_id": req.user_id,
        "start_time": req.start_time,
        "end_time": req.end_time,
        "duration_seconds": req.duration_seconds,
        "max_drowsiness_percentage": round(req.max_drowsiness_percentage, 1),
        "total_blinks": req.total_blinks,
        "drowsy_events": req.drowsy_events,
        "status": req.status,
        "created_at": datetime.utcnow().isoformat(),
    }

    result = sessions_collection.insert_one(session_doc)
    logger.info(
        f"Drive session saved for user {req.user_id}: "
        f"duration={req.duration_seconds}s, "
        f"max_drowsy={req.max_drowsiness_percentage:.1f}%"
    )

    return {
        "message": "Session saved successfully",
        "session_id": str(result.inserted_id),
    }


@router.get("/sessions/{user_id}")
def get_sessions(user_id: str):
    """Fetch all driving sessions for a user, newest first."""
    if sessions_collection is None:
        raise HTTPException(503, "Database not available")

    sessions = list(
        sessions_collection.find({"user_id": user_id})
        .sort("created_at", -1)
        .limit(50)
    )

    # Convert ObjectId to string for JSON serialization
    for s in sessions:
        s["_id"] = str(s["_id"])

    logger.info(f"Fetched {len(sessions)} sessions for user {user_id}")

    return {"sessions": sessions}


@router.delete("/sessions/{user_id}")
def clear_sessions(user_id: str):
    """Delete all driving sessions for a user."""
    if sessions_collection is None:
        raise HTTPException(503, "Database not available")

    result = sessions_collection.delete_many({"user_id": user_id})
    logger.info(f"Cleared {result.deleted_count} sessions for user {user_id}")

    return {
        "message": f"Deleted {result.deleted_count} sessions",
    }
