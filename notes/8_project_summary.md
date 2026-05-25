# Project Summary & Presentation Guide

This document provides a high-level overview of the **DrowsiGuard** project, perfect for a viva, demo, or presentation.

---

## 1. Complete Project Flow
1. **Launch**: User opens the Flutter app.
2. **Auth**: User logs in or registers (verified via FastAPI + MongoDB).
3. **Dashboard**: User enters the Home Screen.
4. **Start Detection**: User taps "Start Detection".
5. **Real-time Loop**:
   - Camera captures a frame (5 times per second).
   - Frame is sent to Backend via **WebSocket**.
   - Backend (MediaPipe) finds face landmarks.
   - Backend (Custom Logic) calculates **EAR** (Eye Aspect Ratio).
   - Backend sends "Awake", "Warning", or "Drowsy" back to Phone.
6. **Alert**: If "Drowsy", phone screen turns RED and sound/vibration triggers.
7. **Finish**: User stops session. Statistics (duration, drowsy events) are saved to **MongoDB**.
8. **Review**: User checks "History" to see past driving performance.

---

## 2. Architecture Explanation
We use a **Client-Server Architecture**:
- **Client (Frontend)**: Built with **Flutter**. Handles UI, Camera hardware, Sound/Vibration, and user interaction.
- **Server (Backend)**: Built with **FastAPI (Python)**. Handles heavy AI processing (MediaPipe), math calculations (EAR), and database management.
- **Database**: **MongoDB Atlas (Cloud)**. Stores persistent data.
- **Communication**: 
  - **REST API (HTTP)** for slow tasks (Login, History).
  - **WebSocket** for fast tasks (Live detection).

---

## 3. Module Connection Table

| Module | Connects To | Purpose |
| :--- | :--- | :--- |
| **Flutter UI** | **API Service** | Requests data (Login, History) |
| **Flutter UI** | **WS Service** | Sends video frames for detection |
| **API Service** | **FastAPI Routes** | Communicates via HTTP |
| **WS Service** | **FastAPI Main** | Communicates via WebSocket |
| **FastAPI Main** | **Drowsy Logic** | Passes coordinates for math calculation |
| **FastAPI Routes**| **MongoDB** | Saves/Loads user and session data |

---

## 4. Data Flow Diagram (Text Form)
```text
[ USER FACE ] 
      ↓ (Captured by)
[ CAMERA SERVICE ]
      ↓ (Encoded to Base64)
[ WEBSOCKET SERVICE ]
      ↓ (Sent over Network)
[ BACKEND: main.py ]
      ↓ (Processed by)
[ MEDIAPIPE AI ] ─→ [ Landmarks (Dots) ]
      ↓ 
[ DROWSY LOGIC ] ─→ [ EAR Math ] ─→ [ Status: DROWSY ]
      ↓ 
[ BACKEND: main.py ]
      ↓ (JSON Response)
[ WEBSOCKET SERVICE ]
      ↓ (Trigger)
[ ALERT SERVICE ] ─→ [ SOUND & VIBRATION ]
```

---

## 5. API Request-Response Flow
- **Request**: `POST /api/auth/login` { "email": "...", "password": "..." }
- **Response**: `200 OK` { "status": "success", "user": { "name": "Sushant", ... } }

- **WebSocket**:
  - Send: `{ "frame": "base64_string..." }`
  - Receive: `{ "status": "Drowsy", "ear": 0.12, "percentage": 85.0 }`

---

## 6. Final Summary for Demo
"DrowsiGuard is a smart driver assistance system. It uses a mobile camera to monitor the driver's eyes in real-time. By calculating the **Eye Aspect Ratio (EAR)** using AI-powered face landmarks, it can distinguish between a natural blink and dangerous drowsiness. The system features a Flutter frontend for a premium user experience and a high-performance Python backend for real-time processing. All driving history is securely stored in the cloud, allowing drivers to track their safety over time. Our goal is to reduce accidents caused by fatigue using accessible mobile technology."
