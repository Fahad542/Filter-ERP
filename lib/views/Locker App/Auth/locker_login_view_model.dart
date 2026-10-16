import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/network/base_api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';

class LockerLoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;
  String? _errorMessage;

  /// 'supervisor' or 'collector' — resolved right after a successful login
  /// so the view knows which dashboard to push. Null until [login] succeeds.
  String? _resolvedView;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get resolvedView => _resolvedView;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Returns true on success, false on failure.
  Future<bool> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    _setError(null);
    _setLoading(true);

    final l10n = AppLocalizations.of(context);

    try {
      final authResponse = await _authRepository.lockerLogin(email, password);

      if (authResponse.success == false) {
        _setError(
          authResponse.message ??
              (l10n?.lockerLoginFailed ?? 'Login failed. Please try again.'),
        );
        return false;
      }

      final token = authResponse.token?.trim();
      if (token == null || token.isEmpty) {
        _setError(l10n?.lockerLoginFailed ?? 'Login failed. Please try again.');
        return false;
      }

      final user = authResponse.user;
      final userType = user?.userType?.trim().toLowerCase();
      final lockerRole = user?.lockerPortalRole?.trim().toLowerCase();
      final isLockerUser = userType == 'workshop_user' &&
          (lockerRole == 'supervisor' || lockerRole == 'collector');
      if (!isLockerUser) {
        _setError(
          l10n?.lockerLoginNoAccess ??
              'This account does not have locker portal access. '
                  'Ask your workshop admin to create a locker user.',
        );
        return false;
      }

      await _sessionService.saveSession(authResponse, role: 'locker');
      await _sessionService.saveLastPortal('locker');
      _resolvedView = await _resolveLockerView();
      return true;
    } on BadRequestException catch (e) {
      _setError(e.toString().replaceFirst('Invalid Request: ', ''));
      return false;
    } on UnauthorisedException catch (e) {
      final raw = e.toString().replaceFirst('Unauthorised: ', '');
      // Never surface workshopLogin's "Invalid user type" on the locker form.
      if (raw.toLowerCase().contains('invalid user type')) {
        _setError(
          l10n?.lockerLoginNoAccess ??
              'This account does not have locker portal access. '
                  'Ask your workshop admin to create a locker user.',
        );
      } else {
        _setError(raw);
      }
      return false;
    } on FetchDataException catch (e) {
      _setError(e.toString().replaceFirst('Error During Communication: ', ''));
      return false;
    } catch (e) {
      _setError(
        l10n?.lockerLoginUnexpected ??
            'An unexpected error occurred. Please try again.',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Role resolution ────────────────────────────────────────────────────────
  //
  // Same rule used by the dashboards' ViewModels:
  // Locker users are saved as `userType = workshop_user`, while their real
  // locker access is decided by `lockerPortalRole = supervisor | collector`.
  // So always prefer lockerPortalRole over userType. Reads the just-saved
  // session (SessionService + raw SharedPreferences + JWT fallback) so it
  // works the same way regardless of what shape the User model exposes.

  Future<String> _resolveLockerView() async {
    final token = await _sessionService.getToken(role: 'locker');
    final user = await _sessionService.getUser(role: 'locker');
    final rawUserMap = await _readRawUserMap('locker');
    final tokenPayload = _decodeJwtPayload(token);

    final lockerPortalRole = _extractLockerPortalRoleFromUser(user) ??
        _extractLockerPortalRoleFromMap(rawUserMap) ??
        _extractLockerPortalRoleFromMap(tokenPayload);

    final userType = user?.userType ??
        _stringFromMap(rawUserMap, const ['userType', 'user_type', 'type']) ??
        _stringFromMap(tokenPayload, const ['userType', 'user_type', 'type']);

    return _resolveView(userType: userType, lockerPortalRole: lockerPortalRole);
  }
}

// ── Top-level helpers (same logic as LockerSupervisorDashboardViewModel /
//    LockerCollectorDashboardViewModel — kept local to avoid touching
//    SessionService) ───────────────────────────────────────────────────────

String _resolveView({String? userType, String? lockerPortalRole}) {
  switch (lockerPortalRole?.toLowerCase()) {
    case 'supervisor':
      return 'supervisor';
    case 'collector':
      return 'collector';
  }

  switch (userType?.toLowerCase()) {
    case 'workshop_supervisor':
    case 'supervisor':
    case 'manager':
      return 'supervisor';
    case 'workshop_collector':
    case 'collection_officer':
    case 'collector':
      return 'collector';
    default:
      debugPrint(
        '[LockerLoginVM] Unknown locker role/userType '
            '"$lockerPortalRole" / "$userType" — defaulting to collector.',
      );
      return 'collector';
  }
}

String? _normaliseRoleValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

String? _stringFromMap(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key];
    final text = _normaliseRoleValue(value);
    if (text != null) return text;
  }
  return null;
}

String? _extractLockerPortalRoleFromMap(Map<String, dynamic>? map) {
  return _stringFromMap(map, const [
    'lockerPortalRole',
    'locker_portal_role',
    'lockerRole',
    'locker_role',
    'role',
  ]);
}

/// Reads raw stored session JSON directly, so this ViewModel does NOT require
/// SessionService changes.
Future<Map<String, dynamic>?> _readRawUserMap(String role) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${role}_user_data');
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (e) {
    debugPrint('[LockerLoginVM] Could not read raw user map: $e');
  }
  return null;
}

/// Decodes JWT payload without verifying it, only to read already-issued claims
/// such as lockerPortalRole/userType when the User model dropped those fields.
Map<String, dynamic>? _decodeJwtPayload(String? token) {
  if (token == null || token.trim().isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (e) {
    debugPrint('[LockerLoginVM] Could not decode token payload: $e');
  }
  return null;
}

String? _extractLockerPortalRoleFromUser(Object? user) {
  if (user == null) return null;

  if (user is Map) {
    return _extractLockerPortalRoleFromMap(Map<String, dynamic>.from(user));
  }

  final dynamic dynamicUser = user;

  try {
    final role = _normaliseRoleValue(dynamicUser.lockerPortalRole);
    if (role != null) return role;
  } catch (_) {}

  try {
    final role = _normaliseRoleValue(dynamicUser.locker_portal_role);
    if (role != null) return role;
  } catch (_) {}

  try {
    final role = _normaliseRoleValue(dynamicUser.lockerRole);
    if (role != null) return role;
  } catch (_) {}

  try {
    final json = dynamicUser.toJson();
    if (json is Map) {
      return _extractLockerPortalRoleFromMap(Map<String, dynamic>.from(json));
    }
  } catch (_) {}

  try {
    final json = dynamicUser.toMap();
    if (json is Map) {
      return _extractLockerPortalRoleFromMap(Map<String, dynamic>.from(json));
    }
  } catch (_) {}

  return null;
}