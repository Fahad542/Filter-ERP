import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart'
    show
    LockerDashboardData,
    LockerSupervisorStats,
    LockerTodaysCollections,
    LockerHistoryPage;
import '../../../services/locker_translation_mixin.dart';
import '../../../services/session_service.dart';

// ── View state enum ───────────────────────────────────────────────────────────

enum LockerDashboardState { idle, loading, success, error }

// ── Session-parsing helpers ─────────────────────────────────────────────────
//
// Same DB/API rule as the old combined dashboard:
// Locker users are saved as `userType = workshop_user`, while their real
// locker access is decided by `lockerPortalRole = supervisor | collector`.
// This screen is reached only after that role has already been resolved to
// 'supervisor' by the caller (login / role routing) — there's no tab here
// and no switching, so we only need these values for display (welcome
// header name + role label), not for deciding which view to show.

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
    debugPrint('[LockerSupervisorDashboardVM] Could not read raw user map: $e');
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
    debugPrint('[LockerSupervisorDashboardVM] Could not decode token payload: $e');
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

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Backs [LockerSupervisorDashboardView] only. No `activeView` / `switchView`
/// here — unlike the old combined dashboard, this screen is supervisor-only;
/// the collector screen is a completely separate file with its own VM.
class LockerSupervisorDashboardViewModel extends ChangeNotifier
    with LockerTranslationMixin {
  // ── Dependencies ────────────────────────────────────────────────────────────
  final LockerRepository _repository;
  final SessionService _sessionService;

  LockerSupervisorDashboardViewModel({
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  /// Dashboard API is always called with the supervisor view on this screen.
  static const String _view = 'supervisor';

  // ── Session / user ──────────────────────────────────────────────────────────
  String? _token;
  String? _userName;
  String? _userId;
  String? _userType;
  String? _lockerPortalRole;

  String? get userName => translatedUserName ?? _userName;
  String? get userId => _userId;
  String? get userType => _userType;
  String? get lockerPortalRole => _lockerPortalRole;

  /// Use this for UI labels because DB locker users are normal workshop_user
  /// records and the real role is stored in lockerPortalRole.
  String? get displayRole => _lockerPortalRole ?? _userType;

  /// Arabic-translated version of [_userName] (null until translation resolves).
  String? translatedUserName;

  // ── Dashboard data ──────────────────────────────────────────────────────────
  LockerDashboardData? _dashboardData;
  LockerDashboardData? get dashboardData => _dashboardData;

  LockerSupervisorStats get supervisorStats =>
      _dashboardData?.supervisor ?? LockerSupervisorStats.empty();

  LockerTodaysCollections get todaysCollections =>
      _dashboardData?.todaysCollections ?? LockerTodaysCollections.empty();

  double get monthlyCollected => _dashboardData?.monthlyCollected ?? 0.0;
  double get lockerVaultBalance => _dashboardData?.lockerVaultBalance ?? 0.0;

  // ── Recent history ──────────────────────────────────────────────────────────
  LockerHistoryPage _recentHistory = LockerHistoryPage.empty();
  bool _historyLoading = false;

  LockerHistoryPage get recentHistory => _recentHistory;
  bool get isHistoryLoading => _historyLoading;

  // ── UI state ─────────────────────────────────────────────────────────────────
  LockerDashboardState _state = LockerDashboardState.idle;
  String? _errorMessage;
  bool _isSessionLoaded = false;

  LockerDashboardState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LockerDashboardState.loading;
  bool get hasError => _state == LockerDashboardState.error;
  bool get isSuccess => _state == LockerDashboardState.success;
  bool get isSessionLoaded => _isSessionLoaded;

  AppLocalizations? _l10n;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Entry point — call once from [initState] via [addPostFrameCallback].
  Future<void> init([BuildContext? context]) async {
    _l10n = context != null ? AppLocalizations.of(context) : null;
    _setLoading();

    try {
      _token = await _sessionService.getToken(role: 'locker');
      final user = await _sessionService.getUser(role: 'locker');
      final rawUserMap = await _readRawUserMap('locker');
      final tokenPayload = _decodeJwtPayload(_token);

      if (_token == null) {
        _setError(_l10n?.lockerSessionExpired ??
            'Session expired. Please log in again.');
        return;
      }

      _userName = user?.name ??
          _stringFromMap(rawUserMap, const ['name', 'fullName', 'full_name']) ??
          _stringFromMap(tokenPayload, const ['name', 'fullName', 'full_name']) ??
          (_l10n?.lockerFallbackUser ?? 'User');

      _userId = user?.id ??
          _stringFromMap(rawUserMap, const ['id', 'userId', 'user_id', 'sub']) ??
          _stringFromMap(tokenPayload, const ['id', 'userId', 'user_id', 'sub']);

      _userType = user?.userType ??
          _stringFromMap(rawUserMap, const ['userType', 'user_type', 'type']) ??
          _stringFromMap(tokenPayload, const ['userType', 'user_type', 'type']);

      // Priority is lockerPortalRole because DB stores locker users as
      // userType=workshop_user and real locker role in locker_portal_role.
      _lockerPortalRole = _extractLockerPortalRoleFromUser(user) ??
          _extractLockerPortalRoleFromMap(rawUserMap) ??
          _extractLockerPortalRoleFromMap(tokenPayload);

      translatedUserName = await translateUserName(_userName);

      if (_lockerPortalRole != null &&
          _lockerPortalRole!.toLowerCase() != 'supervisor' &&
          _userType?.toLowerCase() != 'workshop_owner') {
        // Purely informational — this screen no longer re-decides routing,
        // login/role-routing already sent the user here as a supervisor.
        debugPrint(
          '[LockerSupervisorDashboardVM] Warning: resolved role is '
              '"$_lockerPortalRole" / "$_userType", not supervisor.',
        );
      }

      debugPrint(
        '[LockerSupervisorDashboardVM] Session loaded — '
            'user=$_userName userType=$_userType '
            'lockerPortalRole=$_lockerPortalRole',
      );

      _isSessionLoaded = true;
      notifyListeners();
    } catch (e) {
      _setError(
        '${_l10n?.lockerFailedLoadSession ?? 'Failed to load session.'} '
        '${_friendlyMessage(e)}',
      );
      return;
    }

    await _fetchDashboard();
  }

  Future<void> refresh() => _fetchDashboard();

  Future<void> logout() async {
    await _sessionService.clearSession(role: 'locker');
    await _sessionService.saveLastPortal('');
    debugPrint('[LockerSupervisorDashboardVM] Session cleared — user logged out.');
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  Future<void> _fetchDashboard() async {
    _setLoading();

    try {
      // ── Run both calls in parallel — single network round-trip pair ──────
      _historyLoading = true;
      final results = await Future.wait([
        _repository.getDashboard(view: _view, token: _token!),
        _repository.getRecentHistory(token: _token!, limit: 5),
      ]);

      _dashboardData = results[0] as LockerDashboardData;
      _recentHistory = results[1] as LockerHistoryPage;
      _historyLoading = false;

      _state = LockerDashboardState.success;
      _errorMessage = null;
      notifyListeners();
    } on UnauthorisedException {
      _historyLoading = false;
      _setError(_l10n?.lockerSessionExpired ??
          'Your session has expired. Please log in again.');
    } on BadRequestException catch (e) {
      _historyLoading = false;
      _setError(_l10n?.lockerBadRequest(_friendlyMessage(e)) ??
          'Bad request: ${_friendlyMessage(e)}');
    } on FetchDataException catch (e) {
      _historyLoading = false;
      _setError(_friendlyMessage(e));
    } catch (e, st) {
      _historyLoading = false;
      _setError(_l10n?.lockerTryAgainGeneric ??
          'Something went wrong. Please try again.');
      debugPrint('[LockerSupervisorDashboardVM] Unexpected error: $e\n$st');
    }
  }

  void _setLoading() {
    _state = LockerDashboardState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = LockerDashboardState.error;
    _errorMessage = message;
    notifyListeners();
    debugPrint('[LockerSupervisorDashboardVM] Error: $message');
  }

  String _friendlyMessage(Object e) {
    final raw = e.toString();
    const prefixes = [
      'Error During Communication: ',
      'Invalid Request: ',
      'Unauthorised: ',
    ];
    for (final p in prefixes) {
      if (raw.startsWith(p)) return raw.substring(p.length);
    }
    return raw;
  }
}
