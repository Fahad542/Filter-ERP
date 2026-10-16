import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/catalog_local_database.dart';
import '../../../services/cashier_session_helper.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../services/cashier_realtime_session_guard.dart';
import '../../../widgets/pos_catalog_sync_app_bar_button.dart';
import '../More Tab/settings_view_model.dart';


class LoginViewModel extends ChangeNotifier with TranslatableMixin {
  final AuthRepository _authRepository;
  final SessionService _sessionService;

  LoginViewModel({
    required AuthRepository authRepository,
    required SessionService sessionService,
    SettingsViewModel? settingsViewModel,
  })  : _authRepository = authRepository,
        _sessionService = sessionService {
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel, retranslate);
    }
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    super.dispose();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool previousSessionAutoClosed = false;

  // UI State (Moved from View)
  bool _obscurePassword = true;

  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      return await _loginAttempt(email, password, releaseStaleSessionFirst: false);
    } catch (e) {
      _setErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> _loginAttempt(
    String email,
    String password, {
    required bool releaseStaleSessionFirst,
  }) async {
    if (releaseStaleSessionFirst) {
      await CashierSessionHelper.releaseServerSession(
        authRepository: _authRepository,
        sessionService: _sessionService,
      );
      await _sessionService.clearSession(role: 'cashier');
    }

    final authResponse = await _authRepository.login(email, password);

    if (authResponse.success == false) {
      final message = authResponse.message ?? 'Invalid email or password';
      if (!releaseStaleSessionFirst &&
          CashierSessionHelper.isAlreadyLoggedInElsewhereMessage(message)) {
        await CashierSessionHelper.releaseServerSession(
          authRepository: _authRepository,
          sessionService: _sessionService,
        );
        return _loginAttempt(email, password, releaseStaleSessionFirst: true);
      }
      _setErrorMessage(message);
      _setLoading(false);
      return false;
    }

    final userType = authResponse.user?.userType?.trim().toLowerCase();
    if (userType != 'cashier_user') {
      _setErrorMessage(
        'This account does not have POS portal access. Use the correct portal for your role.',
      );
      _setLoading(false);
      return false;
    }

    await _sessionService.saveSession(authResponse);
    await _sessionService.saveCredentials(email, password);

    if (authResponse.token != null) {
      try {
        final sessionResponse = await _authRepository.openSession(
          email,
          password,
          authResponse.token!,
        );
        previousSessionAutoClosed = sessionResponse is Map &&
            sessionResponse['previousSessionAutoClosed'] == true;
      } catch (e) {
        final err = e.toString();
        if (CashierSessionHelper.isAlreadyLoggedInElsewhereMessage(err) &&
            !releaseStaleSessionFirst) {
          await CashierSessionHelper.releaseServerSession(
            authRepository: _authRepository,
            sessionService: _sessionService,
          );
          await _sessionService.clearSession(role: 'cashier');
          return _loginAttempt(email, password, releaseStaleSessionFirst: true);
        }
        await _sessionService.clearSession(role: 'cashier');
        _setErrorMessage(err);
        _setLoading(false);
        return false;
      }
    }

    await CashierRealtimeSessionGuard.instance.ensureConnected();
    _setLoading(false);
    return true;
  }

  /// Call when login succeeded but the app could not open the POS shell.
  Future<void> rollbackFailedShellNavigation() async {
    await CashierSessionHelper.releaseServerSession(
      authRepository: _authRepository,
      sessionService: _sessionService,
    );
    await _sessionService.clearSession(role: 'cashier');
  }

  Future<void> logout() async {
    try {
      final creds = await _sessionService.getCredentials();
      final token = await _sessionService.getToken();
      if (creds != null && token != null) {
        await _authRepository.closeSession(creds['email']!, creds['password']!, token);
      }
    } catch (e) {
      debugPrint('Failed to close shift session: $e');
    }

    await CashierRealtimeSessionGuard.instance.disconnect();
    PosCatalogSyncButton.resetPostLoginCatalogSync();
    await _sessionService.clearSession();
    await CatalogLocalDatabase.instance.clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pos_user_email');
    await prefs.remove('pos_user_password');
    notifyListeners();
  }
}
