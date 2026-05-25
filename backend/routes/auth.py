# ==============================================================
# AUTH ROUTES — User Registration & Login
# ==============================================================
# Handles user authentication with MongoDB.
# Passwords are hashed using the bcrypt library directly.
# ==============================================================

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import bcrypt
import logging

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from config.database import users_collection

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# ── Helper Functions for Password Hashing ──

def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    # Convert password to bytes
    pwd_bytes = password.encode('utf-8')
    # Generate salt and hash
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    # Return as string for database storage
    return hashed.decode('utf-8')

def verify_password(password: str, hashed_password: str) -> bool:
    """Verify a password against a hash."""
    try:
        return bcrypt.checkpw(
            password.encode('utf-8'), 
            hashed_password.encode('utf-8')
        )
    except Exception:
        return False


# ── Request Models ──

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    phone: str = ""


class LoginRequest(BaseModel):
    email: str
    password: str


# ── Endpoints ──

@router.post("/register")
def register(req: RegisterRequest):
    """Register a new user account."""
    if users_collection is None:
        raise HTTPException(503, "Database not available")

    # Check if email already exists
    existing = users_collection.find_one({"email": req.email.lower().strip()})
    if existing:
        raise HTTPException(400, "Email already registered")

    # Create user document
    user_doc = {
        "name": req.name.strip(),
        "email": req.email.lower().strip(),
        "password": hash_password(req.password),
        "phone": req.phone.strip(),
        "vehicleNumber": "",
        "emergencyContact": "",
        "profileImageUrl": "",
    }

    result = users_collection.insert_one(user_doc)
    logger.info(f"New user registered: {req.email}")

    return {
        "message": "Registration successful",
        "user": {
            "_id": str(result.inserted_id),
            "name": user_doc["name"],
            "email": user_doc["email"],
            "phone": user_doc["phone"],
            "vehicleNumber": "",
            "emergencyContact": "",
            "profileImageUrl": "",
        }
    }


@router.post("/login")
def login(req: LoginRequest):
    """Authenticate user with email and password."""
    if users_collection is None:
        raise HTTPException(503, "Database not available")

    # Find user by email
    user = users_collection.find_one({"email": req.email.lower().strip()})
    if not user:
        raise HTTPException(401, "Invalid email or password")

    # Verify password
    if not verify_password(req.password, user["password"]):
        raise HTTPException(401, "Invalid email or password")

    logger.info(f"User logged in: {req.email}")

    return {
        "message": "Login successful",
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
