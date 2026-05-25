/// ============================================================
/// APP SETTINGS — Global Configuration Singleton
/// ============================================================
///
/// Stores and manages application-wide settings such as
/// alert preferences, sensitivity levels, and the currently
/// logged-in user.
/// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // ---- Alert Toggles ----
  bool soundAlerts = true;
  bool vibrationAlerts = true;
  bool darkMode = false;
  bool autoStart = false;

  // ---- Server Configuration ----
  String serverIp = '10.85.124.202';
  int serverPort = 8000;

  // ---- Detection Parameters ----
  String sensitivity = 'Medium'; // Low, Medium, High

  // ---- Currently Logged-In User ----
  UserModel? currentUser;

  /// Initialize and load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    soundAlerts = prefs.getBool('soundAlerts') ?? true;
    vibrationAlerts = prefs.getBool('vibrationAlerts') ?? true;
    darkMode = prefs.getBool('darkMode') ?? false;
    autoStart = prefs.getBool('autoStart') ?? false;
    serverIp = prefs.getString('serverIp') ?? '10.85.124.202';
    sensitivity = prefs.getString('sensitivity') ?? 'Medium';
  }

  /// Save current settings to SharedPreferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundAlerts', soundAlerts);
    await prefs.setBool('vibrationAlerts', vibrationAlerts);
    await prefs.setBool('darkMode', darkMode);
    await prefs.setBool('autoStart', autoStart);
    await prefs.setString('serverIp', serverIp);
    await prefs.setString('sensitivity', sensitivity);
    notifyListeners();
  }

  /// Map human-readable sensitivity to numeric thresholds
  double get drowsinessThreshold {
    switch (sensitivity) {
      case 'High':
        return 60.0; // More sensitive (alerts earlier)
      case 'Low':
        return 85.0; // Less sensitive (alerts later)
      case 'Medium':
      default:
        return 75.0;
    }
  }

  /// Clear user data on logout
  void logout() {
    currentUser = null;
  }
}

