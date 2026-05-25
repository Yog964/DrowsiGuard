# Main UI Screens

These are the primary screens where the user spends most of their time.

---

### File 1: login_page.dart
**Location:** `lib/screens/login_page.dart`

**Purpose:** The first screen. It collects email/password and checks with the backend.

**Key Concept:** **Form Validation**. Ensuring the user doesn't leave fields empty or type an invalid email before hitting "Login".

**Important Code:**
- `TextFormField`: The input boxes.
- `_login()`: Calls `apiService.login()` and waits for the result.
- `Navigator.push(...)`: Moves the user to the Home Page if login is successful.

**Connected Previous Module:** `main.dart`.
**Connected Next Module:** `home_page.dart`.

**Data Flow:** User Input → **Validation** → **API Call** → Success → **Home Screen**.

**Why It Is Important:** It's the "Front Door". It protects user data and ensures only authorized people use the app.

**Simple Explanation:** It's the "ID Check" desk at a building.

---

### File 2: home_page.dart
**Location:** `lib/screens/home_page.dart`

**Purpose:** The main dashboard. It greets the user and shows big buttons to start detection, see history, or edit profile.

**Key Concept:** **Grid Layout / Navigation**. Organizing the app's features into an easy-to-use "Menu".

**Important Code:**
- `HomeOptionCard`: A custom widget used for the big feature buttons.
- `Drawer`: The side menu for extra options like "Logout" or "Settings".

**Connected Previous Module:** `login_page.dart`.
**Connected Next Module:** `detection_screen.dart`, `profile_page.dart`, `drive_history_page.dart`.

**Data Flow:** User Taps Button → **Navigation** to specific feature.

**Why It Is Important:** It's the "Hub". It makes the app feel professional and easy to navigate.

**Simple Explanation:** It's like the main menu of a DVD or a Video Game.

---

### File 3: detection_screen.dart
**Location:** `lib/screens/detection_screen.dart`

**Purpose:** The "Star" of the app. It shows the camera feed and real-time alerts.

**Key Concept:** **State Management (Reactive UI)**. The screen updates itself instantly whenever the backend says "Drowsy". The screen turns RED and the phone vibrates.

**Important Code:**
- `CameraPreview`: Shows the live camera feed.
- `_processFrame()`: The loop that captures a photo and sends it to the WebSocket every 200ms.
- `_updateUI(result)`: Changes the color and text on the screen based on the AI result.

**Connected Previous Module:** `home_page.dart`, `websocket_service.dart`.
**Connected Next Module:** `alert_service.dart`.

**Data Flow:** Camera → **Frame** → WebSocket → **AI Result** → **UI Update** → **Alarm (if needed)**.

**Why It Is Important:** This is the actual product. This is what saves lives by detecting drowsiness.

**Simple Explanation:** It's like a high-tech mirror that screams at you if you close your eyes.
