import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response_model.dart';
import '../utils/api_logger.dart';
import '../views/Locker App/Collector/locker_collector_dashboard_view.dart';
import '../views/Locker App/Supervisor/locker_supervisor_dashboard_view.dart';

class SessionService {
  static bool _loggedTokenForRole = false;

  Future<void> saveSession(AuthResponse authResponse, {String role = 'cashier'}) async {
    final prefs = await SharedPreferences.getInstance();
    if (authResponse.token != null) {
      await prefs.setString('${role}_auth_token', authResponse.token!);
      ApiLogger.authToken(role, authResponse.token!);
    }
    if (authResponse.user != null) {
      final userData = jsonEncode(authResponse.user!.toJson());
      await prefs.setString('${role}_user_data', userData);
    }
  }

  Future<String?> getToken({String role = 'cashier'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('${role}_auth_token');
    if (token != null &&
        kDebugMode &&
        role == 'cashier' &&
        !_loggedTokenForRole) {
      _loggedTokenForRole = true;
      ApiLogger.authToken(role, token);
    }
    return token;
  }

  Future<User?> getUser({String role = 'cashier'}) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('${role}_user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> clearSession({String role = 'cashier'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${role}_auth_token');
    await prefs.remove('${role}_user_data');
    if (role == 'cashier') _loggedTokenForRole = false;
  }

  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    const roles = <String>[
      'cashier',
      'owner',
      'tech',
      'locker',
      'supplier',
      'admin',
      'super_admin',
      'super-admin',
    ];

    for (final role in roles) {
      await prefs.remove('${role}_auth_token');
      await prefs.remove('${role}_user_data');
    }
    await prefs.remove('last_portal');
  }

  Future<bool> isLoggedIn({String role = 'cashier'}) async {
    final token = await getToken(role: role);
    return token != null;
  }

  Future<void> saveLastPortal(String portal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_portal', portal);
  }

  Future<String?> getLastPortal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_portal');
  }

  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pos_user_email', email);
    await prefs.setString('pos_user_password', password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('pos_user_email');
    final password = prefs.getString('pos_user_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // ── Locale helpers ─────────────────────────────────────────────────────────

  /// Persists the app locale ('en' or 'ar') so translation services
  /// can read it without needing a BuildContext.
  static Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', languageCode);
  }

  /// Returns the persisted locale language code, defaulting to 'en'.
  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_locale') ?? 'ar';
  }

  Future<Map<String, dynamic>?> getUserDataMap({String role = 'cashier'}) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('${role}_user_data');
    if (userData == null || userData.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(userData);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<String?> getLockerPortalRole({String role = 'locker'}) async {
    final userMap = await getUserDataMap(role: role);
    if (userMap == null) return null;

    return _cleanString(
      userMap['lockerPortalRole'] ??
          userMap['locker_portal_role'] ??
          userMap['lockerRole'] ??
          userMap['locker_role'] ??
          userMap['role'],
    );
  }

  String? _cleanString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  Future<Widget> lockerDashboardForLoggedInUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('locker_user_data');

      if (rawJson != null && rawJson.isNotEmpty) {
        final map = jsonDecode(rawJson);
        if (map is Map) {
          final data = Map<String, dynamic>.from(map);

          // 1. Prefer lockerPortalRole / locker_portal_role / lockerRole / locker_role
          for (final key in const [
            'lockerPortalRole',
            'locker_portal_role',
            'lockerRole',
            'locker_role',
          ]) {
            final v = data[key]?.toString().trim().toLowerCase();
            if (v == 'supervisor') return const LockerSupervisorDashboardView();
            if (v == 'collector') return const LockerCollectorDashboardView();
          }

          // 2. Fall back to userType
          final userType = (data['userType'] ?? data['user_type'] ?? data['type'])
              ?.toString()
              .trim()
              .toLowerCase();
          if (userType != null) {
            if (['supervisor', 'manager', 'workshop_owner', 'workshop_supervisor']
                .contains(userType)) {
              return const LockerSupervisorDashboardView();
            }
            if (['collector', 'workshop_collector', 'collection_officer']
                .contains(userType)) {
              return const LockerCollectorDashboardView();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[MenuView] Could not resolve locker role from prefs: $e');
    }

    // Safe default — collector is the least-privileged role
    return const LockerCollectorDashboardView();
  }


}