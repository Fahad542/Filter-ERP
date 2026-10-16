import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../services/session_service.dart';

class SettingsViewModel extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Locale
    final languageCode = prefs.getString('app_locale') ?? prefs.getString(_localeKey);
    _locale = Locale(languageCode ?? 'ar');
    
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    
    _themeMode = newThemeMode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newThemeMode.index);
  }

  Future<void> updateLocale(Locale newLocale) async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Persist session locale BEFORE notifyListeners so TranslatableMixin.t() /
    // AppTranslationService (which read SessionService) see the new language
    // immediately — otherwise EN↔AR switch shows stale API strings for a beat.
    await SessionService.saveLocale(newLocale.languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
    await prefs.setString('app_locale', newLocale.languageCode);

    LocalizedApiText.clearTranslationCache();
    AppTranslationService.clearCache();

    _locale = newLocale;
    notifyListeners();
  }
}
