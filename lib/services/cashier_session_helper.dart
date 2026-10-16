import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import 'realtime_service.dart';
import 'session_service.dart';

/// Best-effort release of the cashier's single-device / shift session on the server.
class CashierSessionHelper {
  CashierSessionHelper._();

  static Future<void> releaseServerSession({
    AuthRepository? authRepository,
    SessionService? sessionService,
  }) async {
    final auth = authRepository ?? AuthRepository();
    final session = sessionService ?? SessionService();
    try {
      final token = await session.getToken(role: 'cashier');
      final creds = await session.getCredentials();
      if (token != null) {
        try {
          await auth.cashierLogout(token);
        } catch (e) {
          debugPrint('cashierLogout failed: $e');
        }
      }
      if (token != null && creds != null) {
        try {
          await auth.closeSession(
            creds['email']!,
            creds['password']!,
            token,
          );
        } catch (e) {
          debugPrint('closeSession failed: $e');
        }
      }
    } catch (e) {
      debugPrint('releaseServerSession failed: $e');
    }
    RealtimeService().disconnectSocket();
  }

  static bool isAlreadyLoggedInElsewhereMessage(String? message) {
    if (message == null || message.isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('another device') ||
        lower.contains('already logged in') ||
        lower.contains('already signed in');
  }
}
