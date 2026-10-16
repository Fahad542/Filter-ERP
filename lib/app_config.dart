import 'dart:io';

enum AppRunEnvironment {
  sandbox,
  production,
  local,
  lan,
}

abstract final class AppConfig {
  AppConfig._();
  static const AppRunEnvironment environment = AppRunEnvironment.sandbox;
  static const String apiBaseUrlOverride = '';
  static const String urlsandbox = 'https://filterbackend-production.up.railway.app';
  static const String urlProduction = 'https://api.filtercarservices.com';
  static const String urlLocalhost = 'http://127.0.0.1:3000';

  /// `true` = Mac iOS Simulator / Android Emulator (Nest on this Mac).
  /// `false` = real phone on same Wi‑Fi → [macLanIp].
  static const bool useMacHostLoopback = true;

  /// Only used when [useMacHostLoopback] is false (physical device).
  static const String macLanIp = '192.168.1.35';

  /// Nest on this Mac (`npm run start:dev`).
  static String get urlLan {
    if (useMacHostLoopback) {
      // iOS Simulator shares Mac network → 127.0.0.1
      // Android Emulator → special host alias 10.0.2.2
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
      return urlLocalhost;
    }
    return 'http://$macLanIp:3000';
  }

 // static const String sandboxApplicationId = 'com.filter_erp.app';
  static const String sandboxApplicationId = 'com.filter.hub';
  static const String productionApplicationId = 'com.filter.hub';

  static const String sandboxDisplayName = 'Filter Hub Sandbox';
  static const String productionDisplayName = 'Filter Hub';

  static const bool isProduction = environment == AppRunEnvironment.production;
  static const bool isSandbox = environment == AppRunEnvironment.sandbox;
  static const bool isLocal = environment == AppRunEnvironment.local ||
      environment == AppRunEnvironment.lan;

  static String get environmentName => environment.name;

  static String get androidApplicationId {
    switch (environment) {
      case AppRunEnvironment.production:
        return productionApplicationId;
      case AppRunEnvironment.sandbox:
      case AppRunEnvironment.local:
      case AppRunEnvironment.lan:
        return sandboxApplicationId;
    }
  }

  static String get appDisplayName {
    switch (environment) {
      case AppRunEnvironment.production:
        return productionDisplayName;
      case AppRunEnvironment.sandbox:
      case AppRunEnvironment.local:
      case AppRunEnvironment.lan:
        return sandboxDisplayName;
    }
  }

  static String get apiBaseUrl {
    final override = apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;
    switch (environment) {
      case AppRunEnvironment.sandbox:
        return urlsandbox;
      case AppRunEnvironment.production:
        return urlProduction;
      case AppRunEnvironment.local:
      case AppRunEnvironment.lan:
        return urlLan;
    }
  }
}
