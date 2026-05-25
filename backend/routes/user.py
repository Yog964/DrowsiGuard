# ==============================================================
# USER ROUTES — Profile Management
# ==============================================================
# Handles fetching and updating user profile data in MongoDB.
# ==============================================================

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from bson import ObjectId
import logging

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from config.database import users_collection

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/user", tags=["User"])


# ── Request Models ──

class UpdateProfileRequest(BaseModel):
    name: str
    email: str
    phone: str = ""
    vehicleNumber: str = ""
    emergencyContact: str = ""


# ── Endpoints ──

@router.get("/profile/{user_id}")
def get_profile(user_id: str):
    """Fetch user profile by ID."""
    if users_collection is None:
        raise HTTPException(503, "Database not available")

    try:
        user = users_collection.find_one({"_id": ObjectId(user_id)})
    except Exception:
        raise HTTPException(400, "Invalid user ID format")

    if not user:
        raise HTTPException(404, "User not found")

    return {
        "_id": str(user["_id"]),
        "name": user["name"],
        "email": user["email"],
        "phone": user.get("phone", ""),
        "vehicleNumber": user.get("vehicleNumber", ""),
        "emergencyContact": user.get("emergencyContact", ""),
        "profileImageUrl": user.get("profileImageUrl", ""),
    }


@router.put("/profile/{user_id}")
def update_profile(user_id: str, req: UpdateProfileRequest):
    """Update user profile fields."""
    if users_collection is None:
        raise HTTPException(503, "Database not available")

    try:
        result = users_collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {
                "name": req.name.strip(),
                "email": req.email.lower().strip(),
                "phone": req.phone.strip(),
                "vehicleNumber": req.vehicleNumber.strip(),
                "emergencyContact": req.emergencyContact.strip(),
            }}
        )
    except Exception:
        raise HTTPException(400, "Invalid user ID format")

    if result.matched_count == 0:
        raise HTTPException(404, "User not found")

    # Fetch updated user
    user = users_collection.find_one({"_id": ObjectId(user_id)})
    logger.info(f"Profile updated for user: {user_id}")

    return {
        "message": "Profile updated successfully",
        "user": {
            "_id": str(user["_id"]),
            "name": user["name"],
            "email": user["email"],
            "phone": user.get("phone", ""),
            "vehicleNumber": user.get("vehicleNumber", ""),
            "emergencyContact": user.get("emergencyContact", ""),
            "profileImageUrl": user.get("profileImageUrl", ""),
        }
    }
