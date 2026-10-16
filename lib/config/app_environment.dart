import '../app_config.dart';

/// Legacy env enum — prefer [AppConfig] / [AppRunEnvironment] in [app_config.dart].
enum AppEnvironment {
  sandbox,
  production;
}

/// Thin wrapper so older call sites keep working.
///
/// **Edit switches in [lib/app_config.dart]** (next to `main.dart`), not here.
abstract class AppEnvironmentConfig {
  AppEnvironmentConfig._();

  static AppEnvironment get current => AppConfig.isProduction
      ? AppEnvironment.production
      : AppEnvironment.sandbox;

  static bool get isProduction => AppConfig.isProduction;
  static bool get isSandbox => AppConfig.isSandbox;
  static String get name => AppConfig.environmentName;

  static const String sandboxApplicationId = AppConfig.sandboxApplicationId;
  static const String productionApplicationId =
      AppConfig.productionApplicationId;

  static String get androidApplicationId => AppConfig.androidApplicationId;

  static String get appDisplayName => AppConfig.appDisplayName;
}
