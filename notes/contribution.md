# Contribution Notes: Drowsiness Detection System

This document provides a detailed explanation of the core files I contributed to or worked on for the Drowsiness Detection System. It outlines the purpose, working mechanism, and key code snippets for each file.

---

## 1. `backend/config/database.py`

**Purpose:** 
Connects the FastAPI backend to the MongoDB Atlas cluster. It establishes the central database connection used for authenticating users and storing driving sessions.

**How it works:** 
The file uses `pymongo` to establish a connection with the remote MongoDB database (`drowsiguard`). It wraps the client creation in a `try-except` block, ensuring that any connection errors are gracefully logged rather than crashing the application. Finally, it exposes collections (`users_collection` and `sessions_collection`) that are imported by different API routers.

**Code Snippet:**
```python
from pymongo import MongoClient
import logging

MONGO_URI = (
    "mongodb+srv://Sushant:XAWTYBB"
    "@cluster0.nel3fd9.mongodb.net/"
    "?retryWrites=true&w=majority&appName=Cluster0"
)

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    logger.info("✅ Connected to MongoDB Atlas successfully!")
except Exception as e:
    logger.error(f"❌ Failed to connect to MongoDB: {e}")
    client = None

db = client["drowsiguard"] if client else None
users_collection = db["users"] if db is not None else None
```

---

## 2. `backend/config/constants.py`

**Purpose:** 
A centralized configuration file for tuning parameters related to the drowsiness detection algorithms.

**How it works:** 
It defines all tunable parameters (like `EAR_THRESHOLD`, `BLINK_MAX_FRAMES`, `SLIDING_WINDOW_SIZE`) in one place. The system uses these values to calculate Eye Aspect Ratio (EAR), determine whether a closure is a normal blink or a drowsy event, and map a drowsiness percentage to a UI status label (Awake, Warning, Drowsy). It also holds the MediaPipe indices required for targeting the eyes.

**Code Snippet:**
```python
# EAR value below which the eyes are considered "closed".
EAR_THRESHOLD: float = 0.21

# Number of recent raw EAR values to average (moving average).
EAR_SMOOTHING_WINDOW: int = 3

# Minimum number of consecutive closed-eye frames required
# before the system classifies it as a "drowsy event".
DROWSY_MIN_CLOSED_FRAMES: int = 4

# MediaPipe Face Mesh Landmark Indices
LEFT_EYE_INDICES: list = [362, 385, 387, 263, 373, 380]
RIGHT_EYE_INDICES: list = [33, 160, 158, 133, 153, 144]
```

---

## 3. `lib/models/user_model.dart`

**Purpose:** 
Defines the data structure for a User in the Flutter application. 

**How it works:** 
It acts as a DTO (Data Transfer Object). The model includes a `fromJson` factory constructor to safely deserialize the JSON payload returned from the backend/MongoDB into a Dart object. It also provides a `toJson` method for serialization, and a `copyWith` method for immutability when users edit their profiles.

**Code Snippet:**
```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  UserModel({required this.id, required this.name, required this.email, required this.phone});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  UserModel copyWith({String? name, String? phone}) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: this.email,
      phone: phone ?? this.phone,
    );
  }
}
```

---

## 4. `lib/screens/edit_profile_page.dart`

**Purpose:** 
The user interface for modifying profile details (Name, Email, Vehicle Number, Emergency Contact).

**How it works:** 
It uses a `StatefulWidget` to maintain form state and `TextEditingController`s to pre-fill the form with existing user data. The form validates inputs (e.g., verifying an `@` in the email) before allowing submission. Upon saving, it triggers `ApiService.updateProfile()`, displays a loading indicator to prevent multiple submissions, and shows a `SnackBar` for success or error feedback before popping back.

**Code Snippet:**
```dart
void _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSaving = true);

  try {
    final updatedUser = await _api.updateProfile(
      userId: widget.user.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Profile updated successfully!'))
      );
      Navigator.pop(context, updatedUser);
    }
  } catch (e) {
    setState(() => _isSaving = false);
    // show error snackbar
  }
}
```

---

## 5. `lib/screens/login_page.dart`

**Purpose:** 
Handles user authentication and account registration dynamically on the same screen.

**How it works:** 
It uses a boolean `_isRegisterMode` to toggle UI fields between "Login" and "Sign Up". An animation controller smoothly fades in the form elements on load. A crucial feature is the integration of a `Server IP Address` field, mapped directly to `AppSettings`, ensuring the app can dynamically route API calls to different local or remote environments without hardcoding IPs.

**Code Snippet:**
```dart
void _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  try {
    await _api.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    // Show error
  }
}
```

---

## 6. `lib/services/alert_service.dart`

**Purpose:** 
Manages the physical alerts (audio alarms and haptic feedback/vibrations) triggered when drowsiness is confirmed.

**How it works:** 
Implemented as a Singleton to ensure global state control. It checks the user preferences from `AppSettings` (whether sound or vibration is enabled) and then plays a looping `alarm.mp3` via `audioplayers` while triggering a repeating haptic pattern via the `vibration` package. `startAlert` and `stopAlert` cleanly handle overlaps, so the alarm doesn't echo if triggered multiple times quickly.

**Code Snippet:**
```dart
Future<void> startAlert() async {
  if (_isAlarmPlaying) return; // Already alerting

  _isAlarmPlaying = true;
  if (soundEnabled) {
    await _audioPlayer.play(AssetSource('alarm.mp3'));
  }
  if (vibrationEnabled) {
    _startVibration(); // Looping vibration pattern
  }
}

Future<void> stopAlert() async {
  if (!_isAlarmPlaying) return;
  _isAlarmPlaying = false;
  _isVibrating = false;
  await _audioPlayer.stop();
  await Vibration.cancel();
}
```

---

## 7. `lib/services/app_settings.dart`

**Purpose:** 
A global configuration singleton that acts as the single source of truth for the app's preferences.

**How it works:** 
Extending `ChangeNotifier`, it allows the UI to reactively rebuild when themes or settings change. It persists data (Dark Mode, Server IP, Sensitivity, Alert Toggles, Auto-start) locally on the device using `SharedPreferences`. The `drowsinessThreshold` getter smartly maps human-readable strings ('High', 'Low', 'Medium') to absolute numeric values the algorithms use.

**Code Snippet:**
```dart
class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  bool soundAlerts = true;
  bool darkMode = false;
  String serverIp = '10.85.124.202';
  String sensitivity = 'Medium'; 

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundAlerts', soundAlerts);
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('serverIp', serverIp);
    await prefs.setString('sensitivity', sensitivity);
    notifyListeners(); // Updates UI
  }
}
```

---

## 8. `lib/screens/settings_page.dart`

**Purpose:** 
The User Interface for managing application preferences and tuning detection bounds.

**How it works:** 
Displays `ListTile` switches and dropdowns directly connected to the `AppSettings` properties. When a toggle is flipped, it immediately updates the `AppSettings` instance and invokes `saveSettings()` to persist the data to storage. It also includes an option to "Reset to Defaults".

**Code Snippet:**
```dart
_buildSwitchTile(
  icon: Icons.volume_up_rounded,
  title: 'Sound Alerts',
  subtitle: 'Play alarm sound when drowsiness detected',
  value: _settings.soundAlerts,
  color: const Color(0xFF6C5CE7),
  onChanged: (val) {
    setState(() => _settings.soundAlerts = val);
    _settings.saveSettings();
  },
)
```

---

## 9. `lib/services/api_service.dart`

**Purpose:** 
A robust REST client wrapping HTTP communications with the FastAPI backend.

**How it works:** 
A Singleton that uses `http.post`, `http.get`, and `http.put` to make external requests. It dynamically pulls `serverIp` from `AppSettings` rather than hardcoding it. It is responsible for parsing backend error messages, managing endpoints for Registration, Login, Profile adjustments, and Drive History, and deserializing responses to usable Models.

**Code Snippet:**
```dart
Future<UserModel> login({required String email, required String password}) async {
  final url = Uri.parse('$_baseUrl/api/auth/login');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final user = UserModel.fromJson(data['user']);
    _settings.currentUser = user;
    return user;
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Login failed');
  }
}
```
