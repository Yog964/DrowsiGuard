import os
import sys

from pymongo import MongoClient

MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    print("ERROR: MONGO_URI environment variable is not set.")
    print('PowerShell example: $env:MONGO_URI="mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority"')
    sys.exit(1)

try:
    print("Attempting to connect to MongoDB...")
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    print("SUCCESS: Connection successful!")
except Exception as e:
    print(f"ERROR: Connection failed: {e}")
    sys.exit(1)
