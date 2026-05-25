/// ============================================================
/// API SERVICE — HTTP Communication with Backend
/// ============================================================
/// Handles all REST API calls to the FastAPI backend for:
///   - User authentication (login, register)
///   - Profile management (get, update)
///   - Drive history (save session, get sessions)
/// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'app_settings.dart';

class ApiService {
  // ── Singleton Pattern ──
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AppSettings _settings = AppSettings();

  /// Base URL for API calls (uses same IP/port as WebSocket)
  String get _baseUrl => 'http://${_settings.serverIp}:${_settings.serverPort}';

  // ════════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ════════════════════════════════════════════════════════════

  /// Register a new user account.
  /// Returns the created UserModel on success, throws on failure.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      _settings.currentUser = user;
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  /// Login with email and password.
  /// Returns the UserModel on success, throws on failure.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      _settings.currentUser = user;
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  // ════════════════════════════════════════════════════════════
  // PROFILE MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Fetch user profile from the backend.
  Future<UserModel> getProfile(String userId) async {
    final url = Uri.parse('$_baseUrl/api/user/profile/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  /// Update user profile in the backend.
  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String email,
    String phone = '',
    String vehicleNumber = '',
    String emergencyContact = '',
  }) async {
    final url = Uri.parse('$_baseUrl/api/user/profile/$userId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'vehicleNumber': vehicleNumber,
        'emergencyContact': emergencyContact,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      _settings.currentUser = user;
      return user;
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // ════════════════════════════════════════════════════════════
  // DRIVE HISTORY
  // ════════════════════════════════════════════════════════════

  /// Save a driving session to the backend.
  Future<void> saveSession({
    required String userId,
    required String startTime,
    required String endTime,
    required int durationSeconds,
    required double maxDrowsinessPercentage,
    required int totalBlinks,
    required int drowsyEvents,
    required String status,
  }) async {
    final url = Uri.parse('$_baseUrl/api/history/save');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'start_time': startTime,
          'end_time': endTime,
          'duration_seconds': durationSeconds,
          'max_drowsiness_percentage': maxDrowsinessPercentage,
          'total_blinks': totalBlinks,
          'drowsy_events': drowsyEvents,
          'status': status,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to save session: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Fetch all driving sessions for a user.
  Future<List<Map<String, dynamic>>> getSessions(String userId) async {
    final url = Uri.parse('$_baseUrl/api/history/sessions/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['sessions']);
    } else {
      throw Exception('Failed to fetch sessions');
    }
  }
}
