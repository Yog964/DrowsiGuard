# 🧠 Detection Logic (The AI Engine)

This document explains how the system actually detects if a driver is falling asleep or yawning by combining two biological signals: **Eyes (EAR)** and **Mouth (MAR)**.

---

### File 1: drowsiness_logic.py
**Location:** `backend/services/drowsiness_logic.py`

**Purpose:** This is the heart of the system. It processes the coordinates of eyes and mouth to calculate exactly how "tired" the driver appears.

**Key Concepts:** 
1.  **EAR (Eye Aspect Ratio)**:
    - **Math**: Compares the height of the eye to its width.
    - **Tuned Threshold**: `0.17`. Below this, eyes are "closed".
    - **Logic**: If eyes stay closed for `4+ frames` (~0.8s), it triggers **Drowsy** status.
2.  **MAR (Mouth Aspect Ratio)**:
    - **Math**: Compares mouth height to width using 8 lip landmarks.
    - **Tuned Threshold**: `0.98`. Above this, mouth is "yawning".
    - **Logic**: If mouth stays open for `4+ frames` (~0.8s), it triggers a **Yawn Warning**.

**Important Components:**
- `EARCalculator` & `MARCalculator`: The pure math "rulers" that measure landmarks.
- `EyeStateTracker`: A state machine that distinguishes a quick blink from a drowsy nap.
- `YawnTracker`: A specialized state machine that ignores speaking but catches long yawns.
- `DrowsinessLogic`: The orchestrator that combines EAR + MAR into one final status.

**Data Flow:** 
1. Takes **Landmarks** (X,Y,Z coordinates).
2. Calculates **smoothed EAR and MAR** (using moving averages to stop jitter).
3. Checks if EAR is below `0.17` or MAR is above `0.98`.
4. Returns a **Combined Status**:
    - **Drowsy (Red)**: Sustained eye closure. (High Priority)
    - **Warning (Yellow)**: Active yawning. (Medium Priority)
    - **Awake (Green)**: Alert and normal.

**Simple Explanation:** It's like a supervisor watching both your eyes and your mouth. If your eyes close, he rings the alarm. If you yawn, he gives you a warning tap on the shoulder.

---

### File 2: detection_result.py
**Location:** `backend/models/detection_result.py`

**Purpose:** A standardized "template" for the data sent from the AI to the mobile app.

**Key Concept:** **JSON Synchronization**. It ensures the Flutter app and Python backend are always talking about the same things (like `yawn_count` and `mar`).

**Updated Fields:**
- `ear` & `mar`: The raw measurements.
- `is_yawning`: A simple Yes/No for the UI badge.
- `yawn_count`: Total yawns in the current session.
- `status`: The final "Awake/Warning/Drowsy" string.

**Simple Explanation:** It’s a standardized "Report Card" that the AI fills out 5 times every second.
