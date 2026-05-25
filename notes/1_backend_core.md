# Backend Foundation

This document explains the core setup of the DrowsiGuard backend, including the main entry point, database connection, and global configurations.

---

### File 1: main.py
**Location:** `backend/main.py`

**Purpose:** This is the "brain" or the entry point of the entire backend. It starts the server and manages the real-time communication with the mobile app.

**Key Concept:** **WebSocket**. Unlike normal web requests where you ask and get an answer, a WebSocket is like a phone call that stays open. The app sends camera frames constantly, and the backend sends back "Alert" or "Awake" instantly.

**Important Code:**
- `app = FastAPI()`: Creates the web server.
- `@app.websocket("/ws")`: The specific "phone line" for real-time detection.
- `face_mesh.process(rgb_frame)`: Uses AI to find the face in the image.

**Connected Previous Module:** None (This starts the backend).
**Connected Next Module:** `drowsiness_logic.py` (Sends landmarks for processing).

**Data Flow:** 
1. Receives **Base64 Image** from Flutter.
2. Decodes it into a **CV2 Image**.
3. Uses **MediaPipe** to find face landmarks (dots on the face).
4. Sends landmarks to the Logic engine.
5. Sends the result (Drowsy/Awake) back to Flutter as **JSON**.

**Why It Is Important:** Without this, the backend won't start, and the mobile app won't have anything to talk to.

**Simple Explanation:** It's like a receptionist who takes your photo, hands it to a specialist (the logic engine), and then tells you what the specialist said.

---

### File 2: database.py
**Location:** `backend/config/database.py`

**Purpose:** Manages the connection to **MongoDB Atlas** (a cloud database) to store user accounts and driving history.

**Key Concept:** **Cloud Persistence**. It ensures that even if you turn off the app, your profile and past driving sessions are safe in the cloud.

**Important Code:**
- `MongoClient(MONGO_URI)`: Connects to the database using a secret key.
- `users_collection`: The specific "folder" for user data.
- `sessions_collection`: The "folder" for driving history.

**Connected Previous Module:** None (Initialization).
**Connected Next Module:** `auth.py`, `user.py`, `history.py` (Provides them access to data).

**Data Flow:** 
1. Takes **Connection String**.
2. Establishes a link to the cloud.
3. Provides "handles" so other files can Save/Load data.

**Why It Is Important:** If this is removed, you can't login, sign up, or see your past drives.

**Simple Explanation:** It's like a filing cabinet in the clouds where we keep all the records.

---

### File 3: constants.py
**Location:** `backend/config/constants.py`

**Purpose:** Holds all the "rules" and "numbers" for detection in one place.

**Key Concept:** **Centralized Configuration**. Instead of searching through thousands of lines of code to change how sensitive the alarm is, you change it here.

**Important Code:**
- `EAR_THRESHOLD = 0.21`: The number that decides if eyes are closed.
- `DROWSY_MIN_CLOSED_FRAMES = 4`: How many frames eyes must stay closed to trigger an alarm.
- `SLIDING_WINDOW_SIZE = 15`: How much recent history to look at.

**Connected Previous Module:** None.
**Connected Next Module:** `drowsiness_logic.py`, `main.py`.

**Data Flow:** It provides fixed values to the logic engine to use during calculations.

**Why It Is Important:** It makes the system "tunable". If the alarm is too sensitive, you just change one number here.

**Simple Explanation:** It's like a "Settings" page for the AI, where we decide what counts as "tired".
