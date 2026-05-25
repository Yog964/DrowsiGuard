/// ============================================================
/// SETTINGS PAGE
/// ============================================================
/// App settings screen with toggles and configuration options.
/// Uses ListTile switches and navigation tiles.
///
/// Features:
///   - Sound alerts toggle
///   - Vibration alerts toggle
///   - Dark mode toggle (UI only, not implemented)
///   - Sensitivity level selector
///   - About section
///
/// Future Scope:
///   - Persist settings using SharedPreferences
///   - Sync settings with MongoDB user profile
///   - Implement actual dark mode theme switching
/// ============================================================

import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =======================================
          // SECTION: Alert Preferences
          // =======================================
          _buildSectionHeader('Alert Preferences'),
          const SizedBox(height: 8),

          // Sound Alerts Toggle
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
          ),

          // Vibration Alerts Toggle
          _buildSwitchTile(
            icon: Icons.vibration_rounded,
            title: 'Vibration Alerts',
            subtitle: 'Vibrate phone when drowsiness detected',
            value: _settings.vibrationAlerts,
            color: const Color(0xFFFD79A8),
            onChanged: (val) {
              setState(() => _settings.vibrationAlerts = val);
              _settings.saveSettings();
            },
          ),


          const SizedBox(height: 20),

          // =======================================
          // SECTION: Detection Settings
          // =======================================
          _buildSectionHeader('Detection Settings'),
          const SizedBox(height: 8),

          // Sensitivity Level Selector
          _buildDropdownTile(
            icon: Icons.tune_rounded,
            title: 'Detection Sensitivity',
            subtitle: 'Current: ${_settings.sensitivity}',
            color: const Color(0xFF00B894),
          ),

          // Auto-start Toggle
          _buildSwitchTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Auto Start Detection',
            subtitle: 'Begin monitoring when app opens',
            value: _settings.autoStart,
            color: const Color(0xFF0984E3),
            onChanged: (val) {
              setState(() => _settings.autoStart = val);
              _settings.saveSettings();
            },
          ),

          const SizedBox(height: 20),

          // =======================================
          // SECTION: Appearance
          // =======================================
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),

          // Dark Mode Toggle
          _buildSwitchTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _settings.darkMode,
            color: const Color(0xFF2D3436),
            onChanged: (val) {
              setState(() => _settings.darkMode = val);
              _settings.saveSettings();
            },
          ),

          const SizedBox(height: 20),

          // =======================================
          // SECTION: About
          // =======================================
          _buildSectionHeader('About'),
          const SizedBox(height: 8),

          // App Version Tile
          _buildInfoTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            trailing: '1.0.0',
            color: const Color(0xFFA29BFE),
          ),

          // Developer Info Tile
          _buildInfoTile(
            icon: Icons.code_rounded,
            title: 'Developed By',
            trailing: 'EDI Group',
            color: const Color(0xFFE17055),
          ),

          const SizedBox(height: 24),

          // ---- Reset Settings Button ----
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _settings.soundAlerts = true;
                  _settings.vibrationAlerts = true;
                  _settings.darkMode = false;
                  _settings.autoStart = false;
                  _settings.sensitivity = 'Medium';
                });
                _settings.saveSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings reset to defaults'),
                    backgroundColor: Colors.orange.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt, color: Colors.orange),
              label: const Text(
                'Reset to Defaults',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================

  /// Section header text
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D3436),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Toggle switch tile with icon, title, subtitle
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF2D3436),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }

  /// Dropdown tile for sensitivity selection
  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF2D3436),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: DropdownButton<String>(
          value: _settings.sensitivity,
          underline: const SizedBox(),
          items: ['Low', 'Medium', 'High']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _settings.sensitivity = val);
              _settings.saveSettings();
            }
          },
        ),
      ),
    );
  }

  /// Simple info tile with trailing text
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String trailing,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF2D3436),
          ),
        ),
        trailing: Text(
          trailing,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
