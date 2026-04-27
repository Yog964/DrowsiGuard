/// ============================================================
/// CAMERA SERVICE — Front Camera Management
/// ============================================================
///
/// Handles camera initialization, live preview, frame capture,
/// and cleanup. Provides a clean API for the detection screen.
///
/// Features:
///   - Front camera auto-selection
///   - Live preview via CameraController
///   - Frame capture as base64-encoded JPEG
///   - Safe initialization and disposal
///
/// Usage:
///   final cameraService = CameraService();
///   await cameraService.initialize();
///   cameraService.startFrameStream((base64Frame) { ... });
///   cameraService.dispose();
/// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  /// The active camera controller (null until initialized)
  CameraController? _controller;

  /// List of available cameras on the device
  List<CameraDescription> _cameras = [];

  /// Whether the camera has been successfully initialized
  bool _isInitialized = false;

  /// Timer for periodic frame capture
  Timer? _frameTimer;

  /// Getter: whether the camera is ready for use
  bool get isInitialized => _isInitialized;

  /// Getter: the camera controller for building CameraPreview widget
  CameraController? get controller => _controller;

  /// Initialize the front-facing camera.
  ///
  /// Steps:
  ///   1. Fetch available cameras
  ///   2. Find the front camera
  ///   3. Create and initialize the controller
  ///
  /// Throws an exception if no front camera is found.
  Future<void> initialize() async {
    // Get list of available cameras
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      throw Exception('No cameras available on this device');
    }

    // Find the front camera (selfie camera)
    final frontCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first, // Fallback to first camera
    );

    // Create the controller with medium resolution for balance
    // between quality and performance
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false, // No audio needed for drowsiness detection
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize the controller
    await _controller!.initialize();
    _isInitialized = true;
  }

  /// Start capturing frames at regular intervals and pass them
  /// to the provided callback as base64-encoded strings.
  ///
  /// [onFrame] is called with each captured frame's base64 data.
  /// [intervalMs] controls how often frames are captured (default: 200ms = ~5 FPS).
  ///
  /// 5 FPS is sufficient for drowsiness detection and keeps
  /// bandwidth/CPU usage manageable on mobile devices.
  void startFrameStream(
    Function(String base64Frame) onFrame, {
    int intervalMs = 200,
  }) {
    // Don't start if camera isn't ready
    if (!_isInitialized || _controller == null) return;

    // Cancel any existing timer
    stopFrameStream();

    // Set up periodic frame capture
    _frameTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _captureAndSendFrame(onFrame),
    );
  }

  /// Stop the frame capture stream.
  void stopFrameStream() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  /// Capture a single frame, convert to base64, and pass to callback.
  ///
  /// Pipeline:
  ///   Camera → XFile → bytes → base64 string → callback
  Future<void> _captureAndSendFrame(
    Function(String base64Frame) onFrame,
  ) async {
    if (!_isInitialized || _controller == null) return;
    if (!_controller!.value.isInitialized) return;

    try {
      // Capture the current frame as a JPEG image
      final XFile imageFile = await _controller!.takePicture();

      // Read the image bytes
      final bytes = await imageFile.readAsBytes();

      // Encode to base64 for transmission over WebSocket
      final base64String = base64Encode(bytes);

      // Pass the encoded frame to the callback
      onFrame(base64String);
    } catch (e) {
      // Silently handle capture errors (camera might be busy)
      debugPrint('Frame capture error: $e');
    }
  }

  /// Safely dispose of the camera controller and release resources.
  ///
  /// Always call this when leaving the detection screen.
  void dispose() {
    stopFrameStream();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
