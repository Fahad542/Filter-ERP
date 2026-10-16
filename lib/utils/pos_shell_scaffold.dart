import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lets nested tab bodies (which use their own [Scaffold]) open the shell drawer.
///
/// Each [PosShell] registers its own [GlobalKey] while mounted so we never attach
/// one key to two widgets during navigation (e.g. [Navigator.pushAndRemoveUntil]).
class PosShellScaffoldRegistry {
  static GlobalKey<ScaffoldState>? _activeKey;
  static ValueNotifier<bool>? _ordersSideMenuOpen;

  static void attach(GlobalKey<ScaffoldState> key) {
    _activeKey = key;
  }

  static void detach(GlobalKey<ScaffoldState> key) {
    if (_activeKey == key) _activeKey = null;
  }

  /// Orders Hub: toggle the same side rail as other tabs (not the drawer).
  static void attachOrdersSideMenu(ValueNotifier<bool> open) {
    _ordersSideMenuOpen = open;
  }

  static void detachOrdersSideMenu(ValueNotifier<bool> open) {
    if (_ordersSideMenuOpen == open) _ordersSideMenuOpen = null;
  }

  static final ValueNotifier<bool> _fallbackOrdersMenuOpen =
      ValueNotifier<bool>(false);

  static ValueListenable<bool> get ordersSideMenuOpen =>
      _ordersSideMenuOpen ?? _fallbackOrdersMenuOpen;

  static bool get isOrdersSideMenuOpen => _ordersSideMenuOpen?.value ?? false;

  static void toggleOrdersSideMenu() {
    final n = _ordersSideMenuOpen;
    if (n == null) return;
    n.value = !n.value;
  }

  static void closeOrdersSideMenu() {
    final n = _ordersSideMenuOpen;
    if (n == null || !n.value) return;
    n.value = false;
  }

  static void openDrawer() {
    _activeKey?.currentState?.openDrawer();
  }
}
