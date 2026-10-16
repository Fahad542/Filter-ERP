import 'package:flutter/material.dart';

class _ShellEntry {
  final Widget screen;
  final int sourceTab;
  const _ShellEntry(this.screen, this.sourceTab);
}

/// Controls in-shell navigation for the supplier app.
/// Screens are stacked here instead of using [Navigator.push], so the
/// [SupplierBottomBar] remains visible on every supplier screen.
class SupplierShellController extends ChangeNotifier {
  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  final List<_ShellEntry> _stack = [];

  Widget? get activeScreen => _stack.isEmpty ? null : _stack.last.screen;
  bool get hasActiveScreen => _stack.isNotEmpty;

  /// Returns the bottom-bar index that should be highlighted.
  int get effectiveTabIndex =>
      _stack.isEmpty ? _tabIndex : _stack.last.sourceTab;

  /// Switch to a main tab and clear all overlay screens.
  void switchTab(int index) {
    _tabIndex = index;
    _stack.clear();
    notifyListeners();
  }

  /// Push a new screen into the shell overlay.
  /// [sourceTab] is the bottom-bar index to highlight while this screen is shown.
  void navigateTo(Widget screen, {int sourceTab = 4}) {
    _stack.add(_ShellEntry(screen, sourceTab));
    notifyListeners();
  }

  /// Pop the top overlay screen.  Does nothing if the stack is empty.
  void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  /// Clear all overlay screens without switching the tab.
  void clearStack() {
    if (_stack.isNotEmpty) {
      _stack.clear();
      notifyListeners();
    }
  }
}
