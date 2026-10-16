import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/network/base_api_service.dart';
import '../data/repositories/auth_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/current_session_model.dart';
import '../utils/app_navigation.dart';
import '../utils/toast_service.dart';
import 'cashier_realtime_session_guard.dart';
import 'cashier_session_helper.dart';
import 'session_service.dart';

/// Ensures the cashier still has an open POS session (`GET /cashier/session/current`).
/// When [CurrentSessionResponse.hasOpenSession] is false, clears local session and
/// returns to [LoginView].
class CashierOpenSessionGuard {
  CashierOpenSessionGuard._();
  static final CashierOpenSessionGuard instance = CashierOpenSessionGuard._();

  final SessionService _session = SessionService();
  final AuthRepository _auth = AuthRepository();

  bool _redirecting = false;
  Future<bool>? _inFlight;

  /// Returns `true` when the shift is open; `false` after redirecting to login.
  Future<bool> ensureOpenOrSignOut({BuildContext? context}) {
    return _inFlight ??= _ensureOpenOrSignOut(context).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<bool> _ensureOpenOrSignOut(BuildContext? context) async {
    if (_redirecting) return false;

    try {
      final token = await _session.getToken(role: 'cashier');
      if (token == null || token.trim().isEmpty) {
        await _redirectToLogin();
        return false;
      }

      final raw = await BaseApiService.runWithoutUnauthorizedLogout(
        () => _auth.getCurrentSessionAuthorized(token),
      );

      final map = _responseMap(raw);
      final parsed = CurrentSessionResponse.fromJson(map);

      if (parsed.hasOpenSession) {
        return true;
      }

      if (kDebugMode) {
        debugPrint(
          '[CashierOpenSession] no open session — success=${parsed.success} '
          'hasOpenSession=${parsed.hasOpenSession}',
        );
      }
      await _redirectToLogin(sessionWasClosed: true);
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CashierOpenSession] check failed: $e\n$st');
      }
      // Network / transient errors: do not force logout.
      return true;
    }
  }

  Map<String, dynamic> _responseMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> _redirectToLogin({bool sessionWasClosed = false}) async {
    if (_redirecting) return;
    _redirecting = true;
    try {
      if (sessionWasClosed) {
        _showSessionClosedToast();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } else {
        await CashierSessionHelper.releaseServerSession(
          authRepository: _auth,
          sessionService: _session,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pos_user_email');
      await prefs.remove('pos_user_password');
      await CashierRealtimeSessionGuard.instance.disconnect();
      await _session.clearSession(role: 'cashier');

      await AppNavigation.toCashierLogin(
        context: AppNavigation.navigatorKey?.currentContext,
      );
    } finally {
      _redirecting = false;
    }
  }

  void _showSessionClosedToast() {
    final context = AppNavigation.navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    ToastService.showInfo(context, l10n.posSessionClosedLoggedOut);
  }
}
