/// ============================================================
/// APP SETTINGS — Global Configuration Singleton
/// ============================================================
///
/// Stores and manages application-wide settings such as
/// alert preferences and sensitivity levels.
/// ============================================================

class AppSettings {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // ---- Alert Toggles ----
  bool soundAlerts = true;
  bool vibrationAlerts = true;
  bool darkMode = false;
  bool autoStart = false;

  // ---- Detection Parameters ----
  String sensitivity = 'Medium'; // Low, Medium, High

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
}
