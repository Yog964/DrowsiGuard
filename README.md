# DrowsiGuard

DrowsiGuard is a Flutter + FastAPI driver drowsiness detection app. It uses the phone camera to capture the driver's face, sends frames to a Python backend over WebSocket, detects facial landmarks with MediaPipe, and classifies the driver's state as `Awake`, `Warning`, or `Drowsy`.

## Problem Statement

Driver fatigue is a major road-safety risk because drowsiness can reduce reaction time before the driver notices it. This project aims to provide an accessible mobile safety assistant that monitors eye closure and yawning in real time, alerts the driver when fatigue signs appear, and stores driving-session history for later review.

## What Is This Project?

This is a client-server mobile application:

- The Flutter frontend handles login, camera preview, frame capture, settings, alerts, profile screens, and drive history.
- The FastAPI backend handles authentication APIs, MongoDB storage, MediaPipe face-landmark detection, EAR/MAR calculations, and real-time WebSocket responses.
- MongoDB stores user profiles and completed drive-session summaries.

## Why Does It Exist?

DrowsiGuard exists to demonstrate how a normal mobile device can become a low-cost driver-assistance tool. Instead of requiring dedicated hardware, it combines a phone camera, real-time landmark processing, and alert feedback through sound/vibration.

## Key Features

- Real-time drowsiness detection using front-camera frames.
- MediaPipe Face Mesh processing on the backend.
- Eye Aspect Ratio (EAR) based eye-closure detection.
- Mouth Aspect Ratio (MAR) based yawn detection.
- Blink filtering to avoid treating normal blinks as drowsiness.
- Sliding-window drowsiness percentage.
- Sound and vibration alerts when drowsiness is detected.
- User registration and login.
- Profile management with phone, vehicle number, and emergency contact.
- Drive history storage with duration, max drowsiness, blink count, and drowsy events.
- Configurable backend server IP from the app.

## Screenshots

Add screenshots here after running the app:

| Login | Home | Detection | Detection Yawning |
| --- | --- | --- | --- |
| https://github.com/user-attachments/assets/4f16993e-c4ee-46c0-a4b1-e7173d4f0bdc | https://github.com/user-attachments/assets/ceec9297-a526-4a47-a118-b908cc6ec38c | https://github.com/user-attachments/assets/86b98aca-e7e0-4703-b27a-a419f8496f6e | https://github.com/user-attachments/assets/ef347c6b-10d1-4249-b8c7-c6ce4eef0b41 |

Suggested screenshot folder:

```text
screenshots/
  login.png
  home.png
  detection.png
  history.png
```

## Tech Stack

| Layer | Technologies |
| --- | --- |
| Mobile app | Flutter, Dart, Material UI |
| Camera and device APIs | `camera`, `audioplayers`, `vibration` |
| Realtime communication | WebSocket via `web_socket_channel` |
| REST communication | `http` |
| Backend API | Python, FastAPI, Uvicorn |
| Computer vision | OpenCV, MediaPipe Face Mesh, NumPy |
| Database | MongoDB Atlas via PyMongo |
| Persistence on device | `shared_preferences` |

## Project Structure

```text
Drowsiness/
  assets/
    alarm.mp3
  backend/
    config/
      constants.py
      database.py
    models/
      detection_result.py
    routes/
      auth.py
      history.py
      user.py
    services/
      drowsiness_logic.py
    main.py
    requirements.txt
    test_db.py
  lib/
    models/
    screens/
    services/
    widgets/
    main.dart
  notes/
    *.md
  test/
    widget_test.dart
  pubspec.yaml
  README.md
```

## How To Run

### Prerequisites

Install the following:

- Flutter SDK with Dart.
- Android Studio or VS Code with Flutter support.
- Python 3.10 or 3.11 recommended for the backend.
- MongoDB Atlas connection string or a MongoDB instance.
- A physical phone or emulator with camera support.

Before running the backend, set your MongoDB URI in the `MONGO_URI` environment variable. Avoid committing real database credentials to source control.

### 1. Clone The Repository

```bash
git clone <repository-url>
cd Drowsiness
```

### 2. Run The Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
$env:MONGO_URI="mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority"
pip install -r requirements.txt
python main.py
```

The backend starts on:

```text
http://0.0.0.0:8000
```

For API docs, open:

```text
http://localhost:8000/docs
```

To confirm the backend is running, open:

```text
http://localhost:8000/
```

Expected response:

```json
{"message":"DrowsiGuard Backend is running"}
```

To verify MongoDB connectivity separately:

```bash
cd backend
python test_db.py
```

If PowerShell blocks virtual environment activation, run PowerShell as your user and allow local scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 3. Run The Frontend

From the project root:

```bash
flutter pub get
flutter run
```

The Flutter app has Android camera and internet permissions configured in `android/app/src/main/AndroidManifest.xml`. In the app settings, set the backend server IP:

- Android emulator: use `10.0.2.2` for a backend running on your computer.
- Physical phone: use your computer's local network IP, for example `192.168.x.x`.
- Port: `8000`.

The current default server IP in the app is set in `lib/services/app_settings.dart`. Update it from the Settings screen, or change the default value in code if needed.

### 4. Run With Docker

This repository does not currently include a `Dockerfile` or `docker-compose.yml`. After adding Docker support for the backend, the expected flow would be:

```bash
docker build -t drowsiguard-backend ./backend
docker run --rm -p 8000:8000 drowsiguard-backend
```

For a complete Docker setup, create a backend image that installs `backend/requirements.txt` and runs:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Main Workflow

1. User opens the Flutter app.
2. User registers or logs in.
3. User starts a detection session.
4. The Flutter camera service captures a frame about every 200 ms.
5. The frame is base64 encoded and sent to the backend through `/ws`.
6. FastAPI decodes the frame and uses MediaPipe Face Mesh to extract landmarks.
7. The detection engine calculates EAR and MAR.
8. The backend returns status, drowsiness percentage, blink count, and yawn data.
9. Flutter updates the UI and triggers sound/vibration alerts when needed.
10. When the session ends, summary data is saved to MongoDB.
11. User can review sessions in Drive History.

## API Endpoints

### Root

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/` | Backend health message |

### Authentication

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Register a new user |
| `POST` | `/api/auth/login` | Login an existing user |

### User Profile

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/api/user/profile/{user_id}` | Fetch user profile |
| `PUT` | `/api/user/profile/{user_id}` | Update user profile |

### Drive History

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/history/save` | Save a completed drive session |
| `GET` | `/api/history/sessions/{user_id}` | Fetch latest sessions for a user |
| `DELETE` | `/api/history/sessions/{user_id}` | Clear sessions for a user |

### WebSocket Detection

| Protocol | Endpoint | Purpose |
| --- | --- | --- |
| `WS` | `/ws` | Send camera frames and receive detection results |

Example WebSocket request:

```json
{
  "frame": "<base64-jpeg-frame>"
}
```

Example response:

```json
{
  "ear": 0.1234,
  "smoothed_ear": 0.1456,
  "eye_closed": true,
  "state": "Drowsy",
  "is_drowsy": true,
  "drowsiness_percentage": 80.0,
  "status": "Drowsy",
  "blink_count": 4,
  "mar": 0.45,
  "smoothed_mar": 0.47,
  "is_yawning": false,
  "yawn_count": 1
}
```

## Useful Scripts

Run backend:

```bash
cd backend
python main.py
```

Run backend with Uvicorn reload:

```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Test MongoDB connection:

```bash
cd backend
python test_db.py
```

Run Flutter app:

```bash
flutter run
```

Analyze Flutter code:

```bash
flutter analyze
```

Build Android APK:

```bash
flutter build apk
```

## Testing

Run Flutter widget tests:

```bash
flutter test
```

Run the standalone backend detection-logic demo:

```bash
cd backend
python services/drowsiness_logic.py
```

The current test coverage is basic. Add more tests for:

- Auth and profile API routes.
- Drive history API routes.
- EAR/MAR threshold behavior.
- WebSocket frame validation and error handling.

## Notes

- The backend currently depends on a valid MongoDB connection for auth, profile, and history routes.
- The `/ws` detection endpoint can run without MongoDB, but login, profile, and drive history require the database.
- The camera stream is tuned to about 5 FPS to balance responsiveness, CPU usage, and network payload size.
- Detection quality depends on lighting, camera angle, face visibility, and network stability.
- Update the server IP in the app when switching between emulator, physical device, and different Wi-Fi networks.
- Do not commit database usernames, passwords, or production secrets.

## Troubleshooting

### Backend package installation fails

Make sure you are using a supported Python version and that the virtual environment is active:

```bash
python --version
.venv\Scripts\activate
pip install -r requirements.txt
```

### App cannot connect to backend

- Keep the backend running with `python main.py` or `uvicorn main:app --host 0.0.0.0 --port 8000 --reload`.
- For Android emulator, use server IP `10.0.2.2`.
- For a physical phone, use the computer's Wi-Fi/LAN IP and keep phone and computer on the same network.
- Allow Python through Windows Firewall if prompted.

### Register/login does not work

- Check that `MONGO_URI` is set in the terminal where the backend is running.
- Run `python test_db.py` inside the `backend` folder.
- Confirm your MongoDB Atlas network access allows your current IP address.

## License

No license file is currently included. Add a license such as MIT, Apache-2.0, or a private-use notice before publishing or sharing the project publicly.
