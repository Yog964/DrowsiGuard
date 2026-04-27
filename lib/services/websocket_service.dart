/// ============================================================
/// WEBSOCKET SERVICE — Real-Time Backend Communication
/// ============================================================
///
/// Manages the WebSocket connection to the FastAPI drowsiness
/// detection backend. Sends camera frames and receives
/// detection results in real time.
///
/// Features:
///   - Connect/disconnect to backend WebSocket
///   - Send base64 frames as JSON messages
///   - Receive and parse detection results
///   - Expose connection status for UI
///   - Auto-cleanup on disconnect
///
/// Usage:
///   final wsService = WebSocketService();
///   wsService.connect(
///     serverUrl: 'ws://192.168.1.5:8000/ws',
///     onResult: (result) { ... },
///     onStatusChange: (status) { ... },
///   );
///   wsService.sendFrame(base64String);
///   wsService.disconnect();
/// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/detection_result_model.dart';

/// Possible connection states for the WebSocket
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketService {
  /// The active WebSocket channel (null when disconnected)
  WebSocketChannel? _channel;

  /// Current connection status
  ConnectionStatus _status = ConnectionStatus.disconnected;

  /// Getter for current connection status
  ConnectionStatus get status => _status;

  /// Whether the WebSocket is currently connected
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Callback for connection status changes
  Function(ConnectionStatus)? _onStatusChange;

  /// Connect to the backend WebSocket server.
  ///
  /// [serverUrl] is the WebSocket endpoint (e.g., 'ws://192.168.1.5:8000/ws')
  /// [onResult] is called each time a detection result is received
  /// [onStatusChange] is called when the connection state changes
  void connect({
    required String serverUrl,
    required Function(DetectionResultModel result) onResult,
    Function(ConnectionStatus status)? onStatusChange,
  }) {
    // Store the status callback
    _onStatusChange = onStatusChange;

    // Update status to connecting
    _updateStatus(ConnectionStatus.connecting);

    try {
      // Create the WebSocket channel
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      // Mark as connected once the channel is created
      _updateStatus(ConnectionStatus.connected);

      // Listen for incoming messages from the backend
      _channel!.stream.listen(
        (message) {
          // Parse the JSON response from backend
          _handleMessage(message, onResult);
        },
        onError: (error) {
          // Handle WebSocket errors
          debugPrint('WebSocket error: $error');
          _updateStatus(ConnectionStatus.error);
        },
        onDone: () {
          // Handle connection closed by server
          debugPrint('WebSocket connection closed');
          _updateStatus(ConnectionStatus.disconnected);
        },
        cancelOnError: false,
      );
    } catch (e) {
      // Handle connection failure
      debugPrint('WebSocket connection failed: $e');
      _updateStatus(ConnectionStatus.error);
    }
  }

  /// Send a captured camera frame to the backend for analysis.
  ///
  /// [base64Frame] is the base64-encoded JPEG image from the camera.
  ///
  /// The frame is wrapped in JSON format:
  ///   {"frame": "<base64_string>"}
  ///
  /// This matches the format expected by the FastAPI WebSocket endpoint.
  void sendFrame(String base64Frame) {
    if (!isConnected || _channel == null) return;

    try {
      // Wrap the frame in a JSON object matching backend's expected format
      final message = jsonEncode({'frame': base64Frame});
      _channel!.sink.add(message);
    } catch (e) {
      debugPrint('Error sending frame: $e');
    }
  }

  /// Handle an incoming message from the backend.
  ///
  /// Parses the JSON string into a DetectionResultModel
  /// and passes it to the callback for UI update.
  void _handleMessage(
    dynamic message,
    Function(DetectionResultModel) onResult,
  ) {
    try {
      // Decode the JSON string
      final Map<String, dynamic> json = jsonDecode(message as String);

      // Check if it's an error response (no face detected, etc.)
      if (json.containsKey('error') && json['error'] != null) {
        // Create a result from the error response
        final result = DetectionResultModel.fromJson(json);
        onResult(result);
        return;
      }

      // Parse into the detection result model
      final result = DetectionResultModel.fromJson(json);
      onResult(result);
    } catch (e) {
      debugPrint('Error parsing backend response: $e');
    }
  }

  /// Update the connection status and notify the listener.
  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _onStatusChange?.call(newStatus);
  }

  /// Disconnect from the WebSocket server and clean up.
  ///
  /// Always call this when leaving the detection screen.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
  }
}
