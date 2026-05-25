/// ============================================================
/// PROFILE PAGE
/// ============================================================
/// Displays the user's profile information fetched from MongoDB.
/// Features:
///   - Displays user info from AppSettings (loaded on login)
///   - Navigate to EditProfilePage to update info
///   - Logout functionality
/// ============================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/app_settings.dart';
import '../services/api_service.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AppSettings _settings = AppSettings();
  final ApiService _api = ApiService();

  late UserModel _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Load profile from settings or fetch from API
  void _loadProfile() async {
    if (_settings.currentUser != null) {
      setState(() {
        _user = _settings.currentUser!;
        _isLoading = false;
      });

      // Also try to refresh from the backend
      try {
        final freshUser = await _api.getProfile(_user.id);
        _settings.currentUser = freshUser;
        if (mounted) {
          setState(() => _user = freshUser);
        }
      } catch (_) {
        // Use cached data if API fails
      }
    } else {
      setState(() {
        _user = UserModel.getMockUser();
        _isLoading = false;
      });
    }
  }

  /// Navigates to edit profile and updates local state on return.
  void _navigateToEditProfile() async {
    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: _user),
      ),
    );

    // If the user saved changes, update the profile
    if (updatedUser != null) {
      setState(() {
        _user = updatedUser;
        _settings.currentUser = updatedUser;
      });
    }
  }

  /// Handles user logout - navigates back to login screen.
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              // Clear user data
              _settings.logout();
              // Navigate to login and remove all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Edit profile button in app bar
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---- Profile Avatar Section ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Avatar circle with initials
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.tealAccent.withOpacity(0.2),
                    child: Text(
                      _getInitials(_user.name),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // User name
                  Text(
                    _user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // User email
                  Text(
                    _user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---- Profile Info Cards ----
            _buildInfoTile(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: _user.phone.isEmpty ? 'Not set' : _user.phone,
              color: const Color(0xFF00B894),
            ),
            _buildInfoTile(
              icon: Icons.directions_car_outlined,
              title: 'Vehicle Number',
              value: _user.vehicleNumber.isEmpty
                  ? 'Not set'
                  : _user.vehicleNumber,
              color: const Color(0xFF6C5CE7),
            ),
            _buildInfoTile(
              icon: Icons.emergency_outlined,
              title: 'Emergency Contact',
              value: _user.emergencyContact.isEmpty
                  ? 'Not set'
                  : _user.emergencyContact,
              color: const Color(0xFFFD79A8),
            ),
            const SizedBox(height: 24),

            // ---- Edit Profile Button ----
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0984E3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ---- Logout Button ----
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single profile info tile with icon, title, and value.
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          // Title and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extracts initials from a full name (e.g., "Rahul Sharma" → "RS").
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
