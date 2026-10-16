import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_navigation.dart';
import 'cashier_session_helper.dart';
import 'realtime_service.dart';
import 'session_service.dart';
import 'softpos_access_service.dart';

/// Listens for `cashier.session.force-closed` and sends the cashier to login.
///
/// Registered once from [main.dart] so force-logout works on any POS screen.
class CashierRealtimeSessionGuard {
  CashierRealtimeSessionGuard._();
  static final CashierRealtimeSessionGuard instance =
      CashierRealtimeSessionGuard._();

  final RealtimeService _realtime = RealtimeService();
  final SessionService _session = SessionService();

  bool _listenerAttached = false;
  bool _handlingForceClose = false;

  /// Attach socket listener (idempotent). Safe to call from [MaterialApp.initState].
  void start() {
    if (!_listenerAttached) {
      _listenerAttached = true;
      _realtime.on(
        RealtimeService.eventCashierSessionForceClosed,
        _onSessionForceClosed,
      );
      if (kDebugMode) {
        debugPrint('[CashierRealtime] force-close listener attached');
      }
    }
    unawaited(ensureConnected());
  }

  /// Connect / reconnect when a cashier token exists; disconnect otherwise.
  Future<void> ensureConnected() async {
    if (!_listenerAttached) start();

    final token = await _session.getToken(role: 'cashier');
    if (token == null || token.isEmpty) {
      _realtime.disconnectSocket();
      return;
    }

    if (!(_realtime.isConnected && _realtime.authToken == token)) {
      _realtime.reconnect(token);
    }
    SoftPosAccessService.instance.ensureListening();
    unawaited(SoftPosAccessService.instance.refresh());
    if (kDebugMode) {
      debugPrint('[CashierRealtime] socket connected for cashier session');
    }
  }

  Future<void> disconnect() async {
    _realtime.disconnectSocket();
  }

  Future<void> _onSessionForceClosed(Map<String, dynamic> payload) async {
    if (_handlingForceClose) return;
    _handlingForceClose = true;

    if (kDebugMode) {
      debugPrint('[CashierRealtime] force-closed event: $payload');
    }

    try {
      _realtime.disconnectSocket();

      await CashierSessionHelper.releaseServerSession(sessionService: _session);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pos_user_email');
      await prefs.remove('pos_user_password');
      await _session.clearSession(role: 'cashier');

      _navigateToLogin();
    } finally {
      _handlingForceClose = false;
    }
  }

  void _navigateToLogin() {
    void go() {
      unawaited(AppNavigation.toCashierLogin());
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      go();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => go());
    }
  }
}
