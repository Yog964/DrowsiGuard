/// ============================================================
/// DETECTION RESULT MODEL (Flutter-side)
/// ============================================================
///
/// This Dart model mirrors the Python backend's DetectionResult.
/// Used to deserialize WebSocket JSON responses into
/// strongly-typed Dart objects for the UI.
///
/// JSON Contract (sent by backend):
/// {
///   "ear": 0.21,
///   "smoothed_ear": 0.2234,
///   "eye_closed": true,
///   "state": "Drowsy",
///   "is_drowsy": true,
///   "closed_eye_frames": 42,
///   "total_frames": 60,
///   "drowsiness_percentage": 60.0,
///   "status": "Warning",
///   "blink_count": 5,
///   "mar": 0.85,
///   "smoothed_mar": 0.82,
///   "is_yawning": true,
///   "yawn_count": 2,
///   "error": null
/// }
///
/// Usage:
///   final json = jsonDecode(websocketMessage);
///   final result = DetectionResultModel.fromJson(json);
///   print(result.status);              // "Warning"
///   print(result.drowsinessPercentage); // 60.0
///   print(result.statusColor);          // Colors.orange
/// ============================================================

import 'package:flutter/material.dart';

class DetectionResultModel {
  // ── Core EAR Values ──

  /// Raw EAR value directly from MediaPipe landmark computation.
  /// Typical range: 0.0 (fully closed) to ~0.4 (wide open).
  final double ear;

  /// Smoothed EAR after moving average filter.
  /// This is the actual value used for decision-making.
  final double smoothedEar;

  // ── Eye State ──

  /// Whether the smoothed EAR is below the closure threshold.
  /// true = eyes considered closed, false = eyes open.
  final bool eyeClosed;

  /// Current state from the backend state machine.
  /// One of: "Open", "Closing", "Closed", "Drowsy", "No Face"
  final String state;

  /// Whether this specific frame is a confirmed drowsy frame.
  /// Only true during sustained eye closure (not normal blinks).
  final bool isDrowsy;

  // ── Frame Counters ──

  /// Number of consecutive frames the eyes have been closed.
  /// Resets when eyes reopen after the debounce period.
  final int closedEyeFrames;

  /// Total number of frames in the sliding analysis window.
  /// Used as the denominator for drowsiness percentage.
  final int totalFrames;

  // ── Computed Metrics ──

  /// Percentage of recent frames classified as drowsy.
  /// Range: 0.0% (fully awake) to 100.0% (fully drowsy).
  /// Formula: (drowsy_frames / total_window_frames) × 100
  final double drowsinessPercentage;

  /// Human-readable status label for UI display.
  /// One of: "Awake", "Warning", "Drowsy", "No Face Detected"
  final String status;

  // ── Informational ──

  /// Total number of normal blinks detected this session.
  /// Blinks are eye closures shorter than BLINK_MAX_FRAMES.
  final int blinkCount;

  // ── Yawn / MAR ──

  /// Raw MAR (Mouth Aspect Ratio) from mouth landmark computation.
  /// Typical range: 0.3 (closed) to 1.2+ (wide yawn).
  final double mar;

  /// Moving-average smoothed MAR used for decision making.
  final double smoothedMar;

  /// Whether a confirmed yawn is currently active (mouth open
  /// for >= YAWN_MIN_FRAMES consecutive frames).
  final bool isYawning;

  /// Total number of confirmed yawns in this session.
  final int yawnCount;

  /// Error message from backend (null when everything is fine).
  /// Possible values: "no_face_detected", "server_error", etc.
  final String? error;

  /// Constructor with named parameters.
  DetectionResultModel({
    required this.ear,
    required this.smoothedEar,
    required this.eyeClosed,
    required this.state,
    required this.isDrowsy,
    required this.closedEyeFrames,
    required this.totalFrames,
    required this.drowsinessPercentage,
    required this.status,
    required this.blinkCount,
    this.mar = 0.0,
    this.smoothedMar = 0.0,
    this.isYawning = false,
    this.yawnCount = 0,
    this.error,
  });

  /// Factory constructor to create from backend JSON response.
  ///
  /// This is the main deserialization point, called with the
  /// JSON received from the WebSocket connection.
  ///
  /// Example:
  ///   final result = DetectionResultModel.fromJson(decodedJson);
  factory DetectionResultModel.fromJson(Map<String, dynamic> json) {
    return DetectionResultModel(
      ear: (json['ear'] as num?)?.toDouble() ?? 0.0,
      smoothedEar: (json['smoothed_ear'] as num?)?.toDouble() ?? 0.0,
      eyeClosed: json['eye_closed'] as bool? ?? false,
      state: json['state'] as String? ?? 'Unknown',
      isDrowsy: json['is_drowsy'] as bool? ?? false,
      closedEyeFrames: json['closed_eye_frames'] as int? ?? 0,
      totalFrames: json['total_frames'] as int? ?? 0,
      drowsinessPercentage:
          (json['drowsiness_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Unknown',
      blinkCount: json['blink_count'] as int? ?? 0,
      mar: (json['mar'] as num?)?.toDouble() ?? 0.0,
      smoothedMar: (json['smoothed_mar'] as num?)?.toDouble() ?? 0.0,
      isYawning: json['is_yawning'] as bool? ?? false,
      yawnCount: json['yawn_count'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  /// Convert back to JSON map (useful for logging or storage).
  Map<String, dynamic> toJson() {
    return {
      'ear': ear,
      'smoothed_ear': smoothedEar,
      'eye_closed': eyeClosed,
      'state': state,
      'is_drowsy': isDrowsy,
      'closed_eye_frames': closedEyeFrames,
      'total_frames': totalFrames,
      'drowsiness_percentage': drowsinessPercentage,
      'status': status,
      'blink_count': blinkCount,
      'mar': mar,
      'smoothed_mar': smoothedMar,
      'is_yawning': isYawning,
      'yawn_count': yawnCount,
      'error': error,
    };
  }

  /// Returns a default result for when no data has been received yet.
  /// Useful for initializing state in the UI before WebSocket connects.
  factory DetectionResultModel.initial() {
    return DetectionResultModel(
      ear: 0.0,
      smoothedEar: 0.0,
      eyeClosed: false,
      state: 'Idle',
      isDrowsy: false,
      closedEyeFrames: 0,
      totalFrames: 0,
      drowsinessPercentage: 0.0,
      status: 'Waiting...',
      blinkCount: 0,
      mar: 0.0,
      smoothedMar: 0.0,
      isYawning: false,
      yawnCount: 0,
      error: null,
    );
  }

  /// Returns a result indicating no face was detected.
  /// Used when the backend sends error="no_face_detected".
  factory DetectionResultModel.noFace() {
    return DetectionResultModel(
      ear: 0.0,
      smoothedEar: 0.0,
      eyeClosed: false,
      state: 'No Face',
      isDrowsy: false,
      closedEyeFrames: 0,
      totalFrames: 0,
      drowsinessPercentage: 0.0,
      status: 'No Face Detected',
      blinkCount: 0,
      mar: 0.0,
      smoothedMar: 0.0,
      isYawning: false,
      yawnCount: 0,
      error: 'no_face_detected',
    );
  }

  // ── Helper Getters for UI ──────────────────────────────────

  /// Returns true if the backend returned an error.
  bool get hasError => error != null;

  /// Returns true if no face was found in the frame.
  bool get isNoFace => error == 'no_face_detected';

  /// Returns the appropriate color for the current status.
  ///
  /// Usage in UI:
  ///   Container(color: result.statusColor, ...)
  ///   Text(result.status, style: TextStyle(color: result.statusColor))
  Color get statusColor {
    switch (status) {
      case 'Awake':
        return const Color(0xFF00B894); // Green
      case 'Warning':
        return const Color(0xFFE17055); // Orange
      case 'Drowsy':
        return const Color(0xFFD63031); // Red
      case 'No Face Detected':
        return const Color(0xFF636E72); // Grey
      default:
        return const Color(0xFF636E72); // Grey for unknown
    }
  }

  /// Returns an icon for the current status.
  ///
  /// Usage in UI:
  ///   Icon(result.statusIcon, color: result.statusColor)
  IconData get statusIcon {
    switch (status) {
      case 'Awake':
        return Icons.check_circle_rounded;
      case 'Warning':
        return Icons.warning_amber_rounded;
      case 'Drowsy':
        return Icons.dangerous_rounded;
      case 'No Face Detected':
        return Icons.face_retouching_off;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Returns the drowsiness percentage formatted as a display string.
  String get drowsinessDisplay => '${drowsinessPercentage.toStringAsFixed(1)}%';

  /// Returns the EAR formatted as a display string. Example: "0.2847"
  String get earDisplay => ear.toStringAsFixed(4);

  /// Returns the MAR formatted as a display string. Example: "0.8312"
  String get marDisplay => mar.toStringAsFixed(4);

  /// Returns "YAWNING" or "NORMAL" for the yawn badge in the UI.
  String get yawnDisplay => isYawning ? 'YAWNING' : 'NORMAL';

  @override
  String toString() {
    return 'DetectionResult(status=$status, ear=$ear, '
        'drowsiness=$drowsinessPercentage%, blinks=$blinkCount)';
  }
}
