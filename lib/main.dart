/// ============================================================
/// MAIN.DART — App Entry Point
/// ============================================================
/// This is the root of the DrowsiGuard Flutter application.
/// It sets up the MaterialApp and launches the LoginPage.
///
/// Project: Real-Time Driver Drowsiness Detection & Alert System
///
/// Structure:
///   lib/
///   ├── main.dart                      ← YOU ARE HERE
///   ├── models/
///   │   └── user_model.dart            ← Data model
///   ├── screens/
///   │   ├── login_page.dart            ← Authentication
///   │   ├── home_page.dart             ← Dashboard
///   │   ├── profile_page.dart          ← View profile
///   │   ├── edit_profile_page.dart     ← Edit profile
///   │   ├── settings_page.dart         ← App settings
///   │   └── placeholder_page.dart      ← Coming soon pages
///   └── widgets/
///       └── home_option_card.dart       ← Reusable card widget
/// ============================================================

import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  // Entry point: Run the DrowsiGuard app
  runApp(const DrowsiGuardApp());
}

/// Root widget of the application.
/// Sets up global theme and initial route (LoginPage).
class DrowsiGuardApp extends StatelessWidget {
  const DrowsiGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ---- App Configuration ----
      title: 'DrowsiGuard',
      debugShowCheckedModeBanner: false, // Remove debug banner

      // ---- Global Theme ----
      theme: ThemeData(
        // Use Material 3 design
        useMaterial3: true,

        // Primary color scheme
        colorSchemeSeed: const Color(0xFF0F2027),

        // Default font family (uses system font)
        fontFamily: 'Roboto',

        // App bar theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),

        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Input decoration theme (for TextFormFields)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ---- Initial Screen ----
      // App starts with the Login Page
      home: const LoginPage(),
    );
  }
}
