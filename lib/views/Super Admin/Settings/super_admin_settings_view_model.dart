import 'package:flutter/material.dart';

class SuperAdminSettingsViewModel extends ChangeNotifier {
  // Profile Data
  String adminName = 'Fahad Y.';
  String adminEmail = 'admin@filters.com';
  String adminPhone = '+966 50 123 4567';
  
  // App Settings
  bool isDarkMode = false;
  bool pushNotifications = true;
  bool emailAlerts = true;
  String selectedLanguage = 'English';

  void updateProfile(String name, String email, String phone) {
    adminName = name;
    adminEmail = email;
    adminPhone = phone;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void togglePushNotifications(bool value) {
    pushNotifications = value;
    notifyListeners();
  }

  void toggleEmailAlerts(bool value) {
    emailAlerts = value;
    notifyListeners();
  }

  void changeLanguage(String lang) {
    selectedLanguage = lang;
    notifyListeners();
  }
}
