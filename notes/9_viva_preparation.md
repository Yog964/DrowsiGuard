# Viva & Cross-Question Preparation

This document prepares you for technical questioning by examiners. It covers the "Why", "How", and "What-if" of the project.

---

### 1. Critical Technical Points (Behind the Scenes)
- **Frame Rate Syncing**: The Flutter app captures at ~5 FPS. If the backend is slower, frames queue up and latency increases. If the backend is faster, it waits. We tuned the constants for exactly this 200ms rhythm.
- **Base64 Overhead**: Sending images as Base64 strings increases data size by ~33%. However, it's easier to handle in JSON than sending raw binary bytes over WebSockets.
- **CPU vs GPU**: MediaPipe is currently running on the CPU in the backend. On a server with a GPU, the frame rate could increase to 30+ FPS.

### 2. Examiner Cross-Questions (Top 5)
1. **Q: Why use a backend for detection instead of doing it entirely on the phone?**
   - *A:* AI models like MediaPipe and custom logic can be heavy on battery and CPU. Offloading to a server keeps the phone cool and allows for more complex logic (like long-term history tracking) without slowing down the UI.
2. **Q: What happens if the internet connection is slow?**
   - *A:* Since we use WebSockets, a slow connection will cause "lag" in detection. In a real-world product, we would implement a "Local Fallback" where the phone does basic detection if the server is unreachable.
3. **Q: How do you handle different lighting conditions?**
   - *A:* MediaPipe is robust but not perfect. In pitch-black darkness, detection will fail. A real-world solution would require an IR (Infrared) camera.
4. **Q: Why use both EAR (Eyes) and MAR (Mouth)?**
   - *A:* Drowsiness often starts with "micro-sleeps" (eyes closing) but yawning is a powerful early warning sign of fatigue. By using both, we get a "defense in depth" strategy—the app catches you *before* your eyes shut if you yawn repeatedly.
5. **Q: How do you differentiate speaking from yawning?**
   - *A:* We use two filters: **Magnitude** and **Duration**. Normal speech rarely exceeds MAR 0.70, so we set our threshold to `0.98`. Also, a spoken word is brief, but a yawn must last at least `0.8 seconds` (4 frames) to trigger a warning.

### 3. Why This Tech? (The Rationale)
- **FastAPI**: It is significantly faster than Flask or Django for real-time tasks like WebSockets.
- **Flutter**: Allows us to have a beautiful, "premium" looking app on both Android and iOS with one codebase.
- **MongoDB**: Since driving history can vary (some trips have 0 drowsy events, some have 100), a NoSQL database like MongoDB is more flexible than a fixed-table SQL database.

### 4. Why Not Alternatives?
- **Why not Python on Android (Kivy/BeeWare)?** Python apps on mobile are often slow and look "ugly". Flutter provides a native-feel performance.
- **Why not OpenCV Haar Cascades?** Haar cascades are old and fail easily if the head tilts. MediaPipe Face Mesh provides 468 points and is much more stable.

### 5. Trade-offs
- **Performance vs. Portability**: Offloading to the backend saves phone battery but introduces network latency.
- **Complexity vs. Accuracy**: Our 5-frame smoothing filter reduces "flicker" (accuracy) but adds a tiny delay (0.2s) in the alarm.

### 6. Limitations
- Requires an active internet connection.
- Performance drops in low-light/night driving without IR cameras.
- Only detects eye-based drowsiness (doesn't track heart rate or steering patterns yet).

### 7. Possible Improvements
- **Yawn Detection**: Fully integrated using MAR (Mouth Aspect Ratio) with tuned thresholds.
- **Auto-Start**: Feature to begin detection immediately upon entering the screen.
- **Object Detection**: Future scope to use the back camera to detect lane departures.

### 8. Real-World Challenges
- **Network Stability**: Handling WebSocket disconnections and auto-reconnecting without crashing the app.
- **Device Calibration**: Every phone camera has a different focal length; we had to tune the EAR threshold to be "universal".

### 9. Edge-Case Scenarios
- **Glasses/Sunglasses**: Standard sunglasses can block eye detection.
- **Multiple People**: If a passenger's face enters the frame, the `max_num_faces=1` setting ensures the system only focuses on the driver.
- **Looking Sideways**: If the driver looks at the side mirror, EAR might drop. We handle this using "Smoothing" so a 0.1s glance doesn't trigger the alarm.

### 10. Hidden Assumptions
- The driver's phone is mounted on the dashboard at eye level.
- The driver is not wearing dark sunglasses.
- The server is always reachable via the specified IP.

---

# End-to-End Project Explanation (Viva Version)

### 1. Complete End-to-End Flow
1. **User Auth**: Mobile app sends Login request via HTTP Post to `/api/auth/login`.
2. **Socket Setup**: Once logged in, the app opens a persistent **WebSocket** connection to `/ws`.
3. **Hardware Trigger**: The app initializes the front camera and sets a timer to capture a frame every 200ms.
4. **Transmission**: The frame is converted to Base64 and sent over the WebSocket.
5. **AI Inference**: Backend receives the frame, decodes it, and runs **MediaPipe Face Mesh**.
6. **Feature Extraction**: 20 specific landmarks (6 per eye, 8 for mouth) are extracted.
7. **Decision Logic**: Both **EAR** and **MAR** are calculated. 
   - If EAR < 0.17 for 4+ frames → **Drowsy** (Red Status + Alarm).
   - If MAR > 0.98 for 4+ frames → **Yawn Warning** (Yellow Status).
8. **Feedback**: Backend sends a JSON object back to the phone.
9. **UI/Alert**: The phone's `detection_screen` receives the JSON, updates the 2x3 metrics grid, and triggers the `alert_service` if status is Drowsy.
10. **Persistence**: When the session ends, the app sends a summary of blinks, yawns, and drowsy events to the database.

### 2. Architecture
- **Layer 1 (UI)**: Flutter Widgets (Buttons, Camera Preview).
- **Layer 2 (Services)**: Dart Services (WebSockets, API, Alerts).
- **Layer 3 (Server)**: FastAPI (Routing, Connection Management).
- **Layer 4 (Logic)**: Python AI Services (MediaPipe, EAR/MAR Math).
- **Layer 5 (Data)**: MongoDB Atlas (Cloud Storage).

### 3. Module Connection Table
| Frontend | Connector | Backend |
| :--- | :--- | :--- |
| Login Screen | HTTP (REST) | `routes/auth.py` |
| History Page | HTTP (REST) | `routes/history.py` |
| Detection Screen| WebSocket | `main.py` |
| Detection Screen| Internal | `services/camera_service.dart` |
| Detection Screen| Internal | `services/alert_service.dart` |

### 4. Data Flow (Text)
**Driver Face → [Phone Camera] → [Base64] → [WebSocket] → [FastAPI Server] → [MediaPipe AI] → [EAR/MAR Calculation] → [Status Decision] → [JSON Message] → [Phone UI] → [Alarm]**

### 5. Summary for Presentation
"DrowsiGuard is a safety-critical application designed to prevent road accidents caused by driver fatigue. Our system uses a **Hybrid Cloud Architecture**, where a lightweight Flutter mobile client handles the camera feed and immediate alerts, while a powerful FastAPI backend performs real-time eye and mouth tracking using **MediaPipe**. By implementing a multi-factor algorithm—**Eye Aspect Ratio (EAR)** for closure and **Mouth Aspect Ratio (MAR)** for yawning—we achieve high accuracy in distinguishing between natural behavior and true drowsiness. The system includes a full suite of features including user authentication, driving history, and customizable alert settings, all backed by a scalable **MongoDB** cloud database."
