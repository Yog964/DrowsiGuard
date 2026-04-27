/// ============================================================
/// DETECTION SCREEN — Live Drowsiness Monitoring
/// ============================================================
///
/// Real-time detection screen that integrates:
///   - Front camera preview
///   - WebSocket communication with FastAPI backend
///   - Live display of detection results (EAR, status, %)
///   - Connection status indicator
///   - Start/Stop/Reset monitoring controls
///
/// This screen is opened from the Home Page when the user
/// taps "Start Detection".
///
/// Flow:
///   Camera → base64 frames → WebSocket → Backend → JSON result → UI
/// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/websocket_service.dart';
import '../services/alert_service.dart';
import '../services/app_settings.dart';
import '../models/detection_result_model.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ── Service Instances ──
  final CameraService _cameraService = CameraService();
  final WebSocketService _wsService = WebSocketService();
  final AlertService _alertService = AlertService();
  final AppSettings _settings = AppSettings();

  // ── Animation Controllers ──
  late AnimationController _alertController;
  late Animation<double> _pulseAnimation;

  // ── State Variables ──
  DetectionResultModel _result = DetectionResultModel.initial();
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isMonitoring = false;
  bool _isCameraReady = false;
  String _errorMessage = '';

  // ── Backend Server URL ──
  final TextEditingController _serverIpController = TextEditingController(
    text: '192.168.1.5',
  );
  final int _serverPort = 8000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize Alert Animation
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
    _alertController.dispose();
    _cameraService.dispose();
    _wsService.disconnect();
    _serverIpController.dispose();
    super.dispose();
  }

  /// Handle app lifecycle changes (pause camera when backgrounded)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopMonitoring();
    }
  }

  /// Initialize the front camera
  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera error: $e';
        });
      }
    }
  }

  /// Start monitoring: connect WebSocket + stream frames
  void _startMonitoring() {
    if (!_isCameraReady) return;

    final serverUrl =
        'ws://${_serverIpController.text.trim()}:$_serverPort/ws';

    setState(() {
      _isMonitoring = true;
      _errorMessage = '';
    });

    // Sync settings to alert service
    _alertService.soundEnabled = _settings.soundAlerts;
    _alertService.vibrationEnabled = _settings.vibrationAlerts;

    // Connect to the backend WebSocket
    _wsService.connect(
      serverUrl: serverUrl,
      onResult: (result) {
        // Update the UI with each new detection result
        if (mounted) {
          setState(() {
            _result = result;
            _handleAlertLogic(result);
          });
        }
      },
      onStatusChange: (status) {
        if (mounted) {
          setState(() => _connectionStatus = status);
        }
      },
    );

    // Start sending camera frames to backend
    _cameraService.startFrameStream(
      (base64Frame) {
        _wsService.sendFrame(base64Frame);
      },
    );
  }

  /// Check result and trigger/stop alerts
  void _handleAlertLogic(DetectionResultModel result) {
    // Trigger alert if drowsy percentage exceeds threshold or status is Drowsy
    if (result.isDrowsy || result.drowsinessPercentage > _settings.drowsinessThreshold) {
      _alertService.startAlert();
    } else {
      _alertService.stopAlert();
    }
  }

  /// Stop monitoring: stop frame stream + disconnect WebSocket
  void _stopMonitoring() {
    _cameraService.stopFrameStream();
    _wsService.disconnect();
    _alertService.stopAlert();
    if (mounted) {
      setState(() => _isMonitoring = false);
    }
  }

  /// Reset all values to initial state
  void _resetMonitoring() {
    _stopMonitoring();
    if (mounted) {
      setState(() {
        _result = DetectionResultModel.initial();
        _connectionStatus = ConnectionStatus.disconnected;
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text('Live Detection'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Connection status dot in the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getConnectionColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getConnectionColor().withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Camera Preview Area ──
            _buildCameraPreview(),

            // ── Scrollable Results + Controls ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Connection status bar
                      _buildConnectionBar(),
                      const SizedBox(height: 16),

                      // Server IP input
                      _buildServerInput(),
                      const SizedBox(height: 16),

                      // Status display (large)
                      _buildStatusCard(),
                      const SizedBox(height: 16),

                      // Metrics grid (EAR, %, Blinks, Frames)
                      _buildMetricsGrid(),
                      const SizedBox(height: 20),

                      // Control buttons
                      _buildControlButtons(),
                      const SizedBox(height: 12),

                      // Error message display
                      if (_errorMessage.isNotEmpty)
                        _buildErrorBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // UI BUILDER METHODS
  // ════════════════════════════════════════════════════════════

  /// Camera preview area at the top of the screen
  Widget _buildCameraPreview() {
    return Container(
      height: 260,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _result.isDrowsy
              ? const Color(0xFFD63031)
              : _result.status == 'Warning'
                  ? const Color(0xFFE17055)
                  : Colors.tealAccent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_result.isDrowsy
                    ? const Color(0xFFD63031)
                    : Colors.tealAccent)
                .withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
        child: _isCameraReady && _cameraService.controller != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Live camera preview
                  CameraPreview(_cameraService.controller!),

                  // ── RED PULSING OVERLAY (Alert) ──
                  if (_result.status == 'Drowsy' || _result.drowsinessPercentage > _settings.drowsinessThreshold)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(_pulseAnimation.value),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  'DROWSINESS DETECTED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // ── NO FACE DETECTED BANNER ──
                  if (_result.error != null && _result.error!.contains('No face'))
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.face_retouching_off, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No Face Detected - Please Adjust Camera',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Status overlay at top-left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isMonitoring
                                ? Icons.fiber_manual_record
                                : Icons.videocam_off,
                            color: _isMonitoring ? Colors.red : Colors.grey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isMonitoring ? 'LIVE' : 'PAUSED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // EAR value overlay at top-right
                  if (_isMonitoring)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EAR: ${_result.earDisplay}',
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                ],
              )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, color: Colors.grey, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Initializing Camera...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }

  /// Connection status bar widget
  Widget _buildConnectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getConnectionColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getConnectionColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getConnectionIcon(),
            color: _getConnectionColor(),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            _getConnectionText(),
            style: TextStyle(
              color: _getConnectionColor(),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _getConnectionColor(),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Server IP input field
  Widget _buildServerInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, color: Color(0xFF636E72), size: 22),
          const SizedBox(width: 10),
          const Text(
            'ws://',
            style: TextStyle(
              color: Color(0xFF636E72),
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _serverIpController,
              enabled: !_isMonitoring,
              decoration: const InputDecoration(
                hintText: 'Server IP Address',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ':$_serverPort/ws',
            style: const TextStyle(
              color: Color(0xFF636E72),
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Large status display card
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _result.statusColor.withOpacity(0.15),
            _result.statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _result.statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Status icon
          Icon(
            _result.statusIcon,
            size: 48,
            color: _result.statusColor,
          ),
          const SizedBox(height: 10),

          // Status text
          Text(
            _result.status,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _result.statusColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Eye state text
          Text(
            'Eye State: ${_result.state}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),

          // Drowsiness progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _result.drowsinessPercentage / 100.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _result.statusColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Drowsiness: ${_result.drowsinessDisplay}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 2x2 grid of metric cards
  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          title: 'EAR Value',
          value: _result.earDisplay,
          icon: Icons.remove_red_eye_rounded,
          color: const Color(0xFF6C5CE7),
        ),
        _buildMetricCard(
          title: 'Eye Status',
          value: _result.eyeClosed ? 'CLOSED' : 'OPEN',
          icon: _result.eyeClosed
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          color: _result.eyeClosed
              ? const Color(0xFFD63031)
              : const Color(0xFF00B894),
        ),
        _buildMetricCard(
          title: 'Blink Count',
          value: '${_result.blinkCount}',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFFFD79A8),
        ),
        _buildMetricCard(
          title: 'Closed Frames',
          value: '${_result.closedEyeFrames}',
          icon: Icons.timer_rounded,
          color: const Color(0xFFE17055),
        ),
      ],
    );
  }

  /// Single metric card widget
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Start/Stop/Reset control buttons
  Widget _buildControlButtons() {
    return Row(
      children: [
        // Start / Stop button
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isCameraReady
                  ? (_isMonitoring ? _stopMonitoring : _startMonitoring)
                  : null,
              icon: Icon(
                _isMonitoring
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_rounded,
                size: 22,
              ),
              label: Text(
                _isMonitoring ? 'STOP' : 'START MONITORING',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring
                    ? const Color(0xFFD63031)
                    : const Color(0xFF00BFA6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Reset button
        SizedBox(
          height: 50,
          width: 50,
          child: ElevatedButton(
            onPressed: _resetMonitoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF636E72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.zero,
              elevation: 2,
            ),
            child: const Icon(Icons.refresh_rounded, size: 22),
          ),
        ),
      ],
    );
  }

  /// Error banner displayed at the bottom
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // CONNECTION STATUS HELPERS
  // ════════════════════════════════════════════════════════════

  /// Get the color for the current connection status
  Color _getConnectionColor() {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return const Color(0xFF00B894);
      case ConnectionStatus.connecting:
        return const Color(0xFFFDCB6E);
      case ConnectionStatus.error:
        return const Color(0xFFD63031);
      case ConnectionStatus.disconnected:
        return const Color(0xFF636E72);
    }
  }

  /// Get the icon for the current connection status
  IconData _getConnectionIcon() {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return Icons.cloud_done_rounded;
      case ConnectionStatus.connecting:
        return Icons.cloud_sync_rounded;
      case ConnectionStatus.error:
        return Icons.cloud_off_rounded;
      case ConnectionStatus.disconnected:
        return Icons.cloud_outlined;
    }
  }

  /// Get the text label for the current connection status
  String _getConnectionText() {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return 'Connected to Backend';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Connection Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }
}
