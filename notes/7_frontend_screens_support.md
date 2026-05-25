# Support & History Screens

These screens manage the user's records and application preferences.

---

### File 1: drive_history_page.dart
**Location:** `lib/screens/drive_history_page.dart`

**Purpose:** Displays a list of all your past driving sessions.

**Key Concept:** **ListView / FutureBuilder**. It fetches data from the internet (which takes time) and displays it as a scrolling list once it arrives.

**Important Code:**
- `apiService.getSessions(...)`: Fetches the history from MongoDB.
- `ListView.builder`: Efficiently creates a list of sessions.

**Connected Previous Module:** `home_page.dart`.
**Connected Next Module:** `api_service.dart`.

**Data Flow:** **API Request** → **JSON List** → **Map to UI Cards**.

**Why It Is Important:** It provides "Social Proof" and "Accountability". A driver can see that they've been drowsy 5 times this week and realize they need more sleep.

**Simple Explanation:** It's like your "Call History" or "Bank Statement", but for driving safety.

---

### File 2: profile_page.dart & edit_profile_page.dart
**Location:** `lib/screens/profile_page.dart` & `edit_profile_page.dart`

**Purpose:**
- **Profile Page**: Shows your current details (Name, Email, Vehicle No).
- **Edit Page**: A form to change those details.

**Key Concept:** **User Data Synchronization**. Ensuring the app and the backend database both have the same updated information.

**Important Code:**
- `apiService.updateProfile(...)`: Sends the new info to the backend.
- `appSettings.currentUser`: Updates the local memory so you don't have to re-login to see your new name.

**Connected Previous Module:** `home_page.dart`.
**Connected Next Module:** `api_service.dart`.

**Data Flow:** User Edits Form → **Update Call** → Database Saved → **Local State Updated**.

**Why It Is Important:** It makes the app feel "Personal". You aren't just a number; you are a driver with a specific vehicle.

**Simple Explanation:** It's like your "Facebook Profile" or "WhatsApp Settings".

---

### File 3: settings_page.dart
**Location:** `lib/screens/settings_page.dart`

**Purpose:** A place to configure the app, like the Backend IP address or toggling Dark Mode.

**Key Concept:** **Persistent Configuration**. Changing how the app behaves globally.

**Important Code:**
- `SwitchListTile`: Toggle switches for settings.
- `TextFormField` for IP: Allows you to connect to a different computer if the server moves.

**Connected Previous Module:** `home_page.dart`.
**Connected Next Module:** `app_settings.dart`.

**Data Flow:** UI Interaction → **Update AppSettings** → UI Refresh.

**Why It Is Important:** It makes the app flexible. You can use it in different network environments (like home vs. office).

**Simple Explanation:** It's the "Control Panel" of the app.
