# Frontend Foundation (Flutter)

This document explains the root of the mobile application and how it manages global state.

---

### File 1: main.dart
**Location:** `lib/main.dart`

**Purpose:** The starting point of the mobile app. It sets up the theme (colors) and decides which screen to show first.

**Key Concept:** **Widget Tree**. Everything in Flutter is a "Widget". This file builds the base of that tree.

**Important Code:**
- `runApp(...)`: Starts the Flutter engine.
- `MaterialApp`: Sets the "look and feel" (Theme).
- `home: LoginPage()`: Sets the first screen the user sees.

**Connected Previous Module:** None (App start).
**Connected Next Module:** `login_page.dart` or `home_page.dart`.

**Data Flow:** It initializes the **AppSettings** and then launches the UI.

**Why It Is Important:** If this file is gone, the app cannot launch on Android or iOS.

**Simple Explanation:** It's like the ignition switch of a car. It starts the engine and turns on the dashboard.

---

### File 2: app_settings.dart
**Location:** `lib/services/app_settings.dart`

**Purpose:** A "Global Memory" for the app. It remembers things like: Is the user logged in? Is Dark Mode on? What is the Backend IP address?

**Key Concept:** **ChangeNotifier / Singleton**. It's a single object that stays alive as long as the app is open. When a setting changes, it "notifies" the UI to update.

**Important Code:**
- `serverIp`: The IP address of your laptop/server.
- `currentUser`: Stores the info of the person currently using the app.
- `notifyListeners()`: Tells the UI "Hey, something changed! Redraw yourself!"

**Connected Previous Module:** `main.dart` (Initializes it).
**Connected Next Module:** All screens (They read data from here).

**Data Flow:** 
1. UI changes a setting (e.g., Toggle Dark Mode).
2. **AppSettings** updates its variable.
3. **AppSettings** triggers a "Notify".
4. UI detects the notify and changes color.

**Why It Is Important:** Without this, the app would "forget" who you are every time you switched screens.

**Simple Explanation:** It's like the app's "Short-term Memory".

---

### File 3: user_model.dart
**Location:** `lib/models/user_model.dart`

**Purpose:** A blueprint for what "User Information" looks like in the app.

**Key Concept:** **Serialization**. It converts raw text (JSON) from the backend into a clean Flutter object with names like `.name` and `.email`.

**Important Code:**
- `UserModel(...)`: The class definition.
- `fromJson(...)`: The "Translator" that turns backend data into Flutter data.

**Connected Previous Module:** `api_service.dart`.
**Connected Next Module:** `profile_page.dart`, `home_page.dart`.

**Data Flow:** Backend (JSON) → **UserModel** → Flutter UI.

**Why It Is Important:** It makes the code organized. Instead of saying `data['user']['user_name']`, we just say `user.name`.

**Simple Explanation:** It's like a form template. When info comes from the cloud, we fill out this form so the app knows where every piece of data belongs.
