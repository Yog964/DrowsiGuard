/// ============================================================
/// DRIVE HISTORY PAGE — Past Driving Sessions
/// ============================================================
/// Displays a list of past driving sessions fetched from MongoDB.
/// Shows duration, drowsiness stats, blink count per session.
/// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';

class DriveHistoryPage extends StatefulWidget {
  const DriveHistoryPage({super.key});

  @override
  State<DriveHistoryPage> createState() => _DriveHistoryPageState();
}

class _DriveHistoryPageState extends State<DriveHistoryPage> {
  final ApiService _api = ApiService();
  final AppSettings _settings = AppSettings();

  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final user = _settings.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final sessions = await _api.getSessions(user.id);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load history: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Drive History'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchSessions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA6)))
          : _error.isNotEmpty
              ? _buildErrorView()
              : _sessions.isEmpty
                  ? _buildEmptyView()
                  : _buildSessionList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _error,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = '';
              });
              _fetchSessions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0984E3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 64,
                color: Color(0xFF00B894),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Drive Sessions Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your first detection session\nto see your drive history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    return RefreshIndicator(
      color: const Color(0xFF00BFA6),
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final duration = session['duration_seconds'] ?? 0;
    final maxDrowsy = (session['max_drowsiness_percentage'] ?? 0.0).toDouble();
    final blinks = session['total_blinks'] ?? 0;
    final drowsyEvents = session['drowsy_events'] ?? 0;
    final status = session['status'] ?? 'unknown';
    final startTime = session['start_time'] ?? '';

    // Format duration
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final durationStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    // Determine status color
    Color statusColor;
    IconData statusIcon;
    if (maxDrowsy > 60) {
      statusColor = const Color(0xFFD63031);
      statusIcon = Icons.warning_rounded;
    } else if (maxDrowsy > 30) {
      statusColor = const Color(0xFFE17055);
      statusIcon = Icons.remove_circle_outline;
    } else {
      statusColor = const Color(0xFF00B894);
      statusIcon = Icons.check_circle_outline;
    }

    // Parse and format start time
    String formattedDate = startTime;
    try {
      final dt = DateTime.parse(startTime);
      formattedDate =
          '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: Date + Status ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status == 'completed' ? 'Completed' : 'Interrupted',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Metrics Row ──
          Row(
            children: [
              _buildMetric(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: durationStr,
                color: const Color(0xFF6C5CE7),
              ),
              _buildMetric(
                icon: Icons.trending_up_rounded,
                label: 'Max Drowsy',
                value: '${maxDrowsy.toStringAsFixed(1)}%',
                color: statusColor,
              ),
              _buildMetric(
                icon: Icons.remove_red_eye_outlined,
                label: 'Blinks',
                value: '$blinks',
                color: const Color(0xFF0984E3),
              ),
              _buildMetric(
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                value: '$drowsyEvents',
                color: const Color(0xFFFD79A8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
