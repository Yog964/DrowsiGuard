import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// ALERT SERVICE — Sound and Vibration Management
/// ============================================================
///
/// This service handles the physical alerts (audio and haptic)
/// when drowsiness is detected. It ensures that alerts are
/// played consistently but don't overlap or cause lag.
///
/// Features:
///   - Start/Stop alarm sound (looping)
///   - Trigger vibration patterns
///   - Singleton pattern for easy access
/// ============================================================

class AlertService {
  // ── Singleton Setup ──
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  // ── State Variables ──
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;
  bool _isVibrating = false;

  // ── Configuration ──
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  
  /// Initialize the service (pre-load sound if needed)
  Future<void> initialize() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Start the drowsiness alert (Sound + Vibration)
  Future<void> startAlert() async {
    if (_isAlarmPlaying) return; // Already alerting

    _isAlarmPlaying = true;
    debugPrint('Starting Drowsiness Alert!');

    // 1. Play Alarm Sound
    if (soundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('alarm.mp3'));
      } catch (e) {
        debugPrint('Error playing alarm sound: $e');
      }
    }

    // 2. Start Vibration
    if (vibrationEnabled) {
      _startVibration();
    }
  }

  /// Stop all alerts
  Future<void> stopAlert() async {
    if (!_isAlarmPlaying) return;

    _isAlarmPlaying = false;
    _isVibrating = false;
    debugPrint('Stopping Drowsiness Alert');

    // 1. Stop Audio
    await _audioPlayer.stop();

    // 2. Stop Vibration
    await Vibration.cancel();
  }

  /// Internal helper to manage continuous vibration
  Future<void> _startVibration() async {
    _isVibrating = true;
    
    // Check if device supports vibration
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    // Vibrate in a pattern: 500ms on, 500ms off
    while (_isVibrating && _isAlarmPlaying) {
      Vibration.vibrate(duration: 500);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
