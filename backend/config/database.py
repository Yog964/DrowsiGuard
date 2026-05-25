# ==============================================================
# DATABASE - MongoDB Atlas Connection
# ==============================================================
# Connects to MongoDB Atlas using pymongo and provides collection
# handles for users and drive sessions.
# ==============================================================

import logging
import os

from pymongo import MongoClient

logger = logging.getLogger(__name__)

# MongoDB Atlas connection string.
# PowerShell:
#   $env:MONGO_URI="mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority"
MONGO_URI = os.getenv("MONGO_URI")

# Database name
DB_NAME = "drowsiguard"

# Create MongoDB client
try:
    if not MONGO_URI:
        raise ValueError("MONGO_URI environment variable is not set")

    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    logger.info("Connected to MongoDB Atlas successfully!")
except Exception as e:
    logger.error(f"Failed to connect to MongoDB: {e}")
    client = None

# Get database reference
db = client[DB_NAME] if client else None

# Collection references
users_collection = db["users"] if db is not None else None
sessions_collection = db["drive_sessions"] if db is not None else None
