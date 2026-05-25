/// ============================================================
/// HOME PAGE (Dashboard)
/// ============================================================
/// Main dashboard screen with a 2x2 grid of feature cards.
/// Acts as the central hub for navigating to all app features.
///
/// Grid Options:
///   1. Start Detection  → DetectionScreen
///   2. Drive History     → DriveHistoryPage
///   3. Profile           → ProfilePage
///   4. Settings          → SettingsPage
/// ============================================================

import 'package:flutter/material.dart';
import '../widgets/home_option_card.dart';
import '../services/websocket_service.dart';
import '../services/app_settings.dart';
import 'detection_screen.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'drive_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WebSocketService _wsService = WebSocketService();
  final AppSettings _settings = AppSettings();
  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _status = _wsService.status;

    // Auto-start detection if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_settings.autoStart) {
        _navigateToDetection();
      }
    });
  }

  void _navigateToDetection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DetectionScreen(),
      ),
    );
    // Refresh status when returning
    if (mounted) setState(() {});
  }

  void _refreshStatus() {
    if (mounted) {
      setState(() {
        _status = _wsService.status;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Refresh status from service
    _status = _wsService.status;
    final bool isReady = _status == ConnectionStatus.connected;

    // Get current user name
    final userName = _settings.currentUser?.name ?? 'User';

    return Scaffold(
      // ---- App Background ----
      backgroundColor: const Color(0xFFF4F6F9),

      // ---- App Bar ----
      appBar: AppBar(
        title: const Text(
          'DrowsiGuard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notification bell icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),

      // ---- Body ----
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Welcome Section ----
            const Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF636E72),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$userName 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),

            // ---- Dashboard Title ----
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Grid of Feature Cards ----
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2 columns
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  // Card 1: Start Detection
                  HomeOptionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Start\nDetection',
                    color: const Color(0xFF6C5CE7),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DetectionScreen(),
                        ),
                      );
                      // Refresh status when returning
                      if (mounted) setState(() {});
                    },
                  ),

                  // Card 2: Drive History
                  HomeOptionCard(
                    icon: Icons.history_rounded,
                    title: 'Drive\nHistory',
                    color: const Color(0xFF00B894),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriveHistoryPage(),
                      ),
                    ),
                  ),

                  // Card 3: Profile
                  HomeOptionCard(
                    icon: Icons.person_rounded,
                    title: 'My\nProfile',
                    color: const Color(0xFF0984E3),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    ),
                  ),

                  // Card 4: Settings
                  HomeOptionCard(
                    icon: Icons.settings_rounded,
                    title: 'App\nSettings',
                    color: const Color(0xFFE17055),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
