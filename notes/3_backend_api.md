# Backend API Routes

This document explains the standard web interfaces (REST API) used for non-real-time tasks like logging in or saving history.

---

### File 1: auth.py
**Location:** `backend/routes/auth.py`

**Purpose:** Handles user security—signing up new users and letting existing ones log in.

**Key Concept:** **Password Hashing**. It never saves your actual password. It saves a "scrambled" version (hash) so that even if the database is hacked, your password is safe.

**Important Code:**
- `@router.post("/register")`: Creates a new user entry in MongoDB.
- `@router.post("/login")`: Checks if the email and password match what's in the database.

**Connected Previous Module:** `database.py` (To save/find users).
**Connected Next Module:** `api_service.dart` (Sends response to Flutter).

**Data Flow:** 
1. Receives **Email/Password** from phone.
2. Checks **MongoDB**.
3. Returns **Success + User Profile** or **Error Message**.

**Why It Is Important:** It's the "Gatekeeper". Without it, anyone could use the app, and no one would have a personal profile.

**Simple Explanation:** It's like the security guard at the entrance who checks your ID before letting you in.

---

### File 2: user.py & history.py
**Location:** `backend/routes/user.py` & `backend/routes/history.py`

**Purpose:** 
- **user.py**: Lets you update your name, phone number, or vehicle details.
- **history.py**: Saves your "Driving Session" (how long you drove, how many times you were drowsy) so you can see it later.

**Key Concept:** **CRUD (Create, Read, Update, Delete)**. These are the basic operations of any data-driven app.

**Important Code:**
- `@router.put("/profile/{user_id}")`: Updates profile data.
- `@router.post("/save")`: Writes a finished driving session to the database.
- `@router.get("/sessions/{user_id}")`: Fetches all past drives for a user.

**Connected Previous Module:** `database.py`.
**Connected Next Module:** `api_service.dart` (In Flutter).

**Data Flow:** 
- **User**: Profile Data ↔ MongoDB.
- **History**: Session Stats → MongoDB.

**Why It Is Important:** This provides the "Value" of the app beyond just detection. It helps drivers track their safety over time.

**Simple Explanation:** **User.py** is like a profile editor; **History.py** is like a diary of all your trips.
