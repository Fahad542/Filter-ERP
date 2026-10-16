import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../views/Menu/menu_view.dart';
import '../views/Workshop pos app/Login/login_view.dart';

/// Root navigator helpers (see [navigatorKey] in [main.dart]).
class AppNavigation {
  AppNavigation._();

  static GlobalKey<NavigatorState>? navigatorKey;

  static NavigatorState? get _nav => navigatorKey?.currentState;

  /// After session expiry / force-close — keep [last_portal] so re-login returns to POS.
  static Future<void> toCashierLogin({BuildContext? context}) async {
    final session = SessionService();
    await session.clearSession(role: 'cashier');
    final nav = _navigator(context);
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  static Future<void> toPortalMenu({BuildContext? context}) async {
    final session = SessionService();
    await session.clearAllSessions();
    final nav = _navigator(context);
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MenuView()),
      (route) => false,
    );
  }

  /// Returns false if navigation could not run (caller should release server session).
  static Future<bool> toCashierShell(
    Widget shell, {
    BuildContext? context,
  }) async {
    final nav = _navigator(context);
    if (nav == null) return false;
    await nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => shell),
      (route) => false,
    );
    return true;
  }

  static NavigatorState? _navigator(BuildContext? context) {
    final root = _nav;
    if (root != null) return root;
    if (context == null || !context.mounted) return null;
    return Navigator.of(context, rootNavigator: true);
  }
}
