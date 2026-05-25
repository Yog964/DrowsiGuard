# Frontend Services (Communication & Hardware)

These files handle the "Heavy Lifting"—talking to the server and controlling the phone's hardware.

---

### File 1: websocket_service.dart
**Location:** `lib/services/websocket_service.dart`

**Purpose:** Manages the high-speed "Live Stream" connection for drowsiness detection.

**Key Concept:** **Full-Duplex Communication**. It sends images and receives results at the same time, very fast (5 times per second).

**Important Code:**
- `connect(...)`: Opens the "line" to the backend.
- `sendFrame(base64)`: Sends a picture to the backend.
- `_handleMessage(...)`: Receives the "Drowsy/Awake" result and tells the screen.

**Connected Previous Module:** `detection_screen.dart`.
**Connected Next Module:** `backend/main.py`.

**Data Flow:** Camera Frame → **Base64 String** → WebSocket → **Backend** → JSON Result → **UI Update**.

**Why It Is Important:** This is the core of the real-time detection. Without it, the app can't do live monitoring.

**Simple Explanation:** It's like a walkie-talkie that is always "ON", constantly shouting "Here's a photo!" and hearing back "He's awake!"

---

### File 2: api_service.dart
**Location:** `lib/services/api_service.dart`

**Purpose:** Handles standard web requests (HTTP) for login, profile, and history.

**Key Concept:** **REST Client**. It uses standard `POST`, `GET`, and `PUT` methods to talk to the backend.

**Important Code:**
- `login(...)`: Sends credentials to backend.
- `saveSession(...)`: Sends the final drive stats to the database.
- `getSessions(...)`: Asks the backend for a list of all past drives.

**Connected Previous Module:** `login_page.dart`, `drive_history_page.dart`.
**Connected Next Module:** `backend/routes/*.py`.

**Data Flow:** UI Action → **HTTP Request** → Backend → **HTTP Response** → UI.

**Why It Is Important:** It's the bridge for all permanent data.

**Simple Explanation:** It's like a mail carrier. You give it a letter (data), it takes it to the server, and brings back a reply.

---

### File 3: camera_service.dart & alert_service.dart
**Location:** `lib/services/camera_service.dart` & `lib/services/alert_service.dart`

**Purpose:**
- **Camera Service**: Controls the front camera. It takes the "video" and turns it into individual pictures (frames).
- **Alert Service**: Controls the sound and vibration. It wakes up the driver if they are drowsy.

**Key Concept:** **Hardware Interfacing**. Controlling physical parts of the phone.

**Important Code:**
- `initialize()`: Turns on the camera.
- `takePicture()`: Grabs a single frame.
- `triggerAlarm()`: Plays the "Beep Beep" sound and vibrates the phone.

**Connected Previous Module:** `detection_screen.dart`.
**Connected Next Module:** Phone Hardware (Camera, Speaker, Motor).

**Data Flow:**
- **Camera**: Lens → **Byte Data** → Image String.
- **Alert**: Drowsy Status → **Sound/Vibration**.

**Why It Is Important:** One provides the "Eyes" (Camera) and the other provides the "Voice" (Alarm) of the app.

**Simple Explanation:** **Camera** is the app's eyes; **Alert** is the app's alarm clock.
