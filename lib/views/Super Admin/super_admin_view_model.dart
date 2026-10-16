import 'package:flutter/material.dart';

class SuperAdminViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  String _adminName = 'Super Admin';
  String get adminName => _adminName;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void logout() {
    // Handle logout logic here or in shell
  }
}
