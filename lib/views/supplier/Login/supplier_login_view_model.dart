import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';

class SupplierLoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final SessionService _sessionService = SessionService();

  final TextEditingController mobileEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _stripPrefix(String message) {
    var text = message;
    for (final prefix in const [
      'Unauthorised: ',
      'Invalid Request: ',
      'Error During Communication: ',
    ]) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length);
        break;
      }
    }
    return text;
  }

  /// Returns true if login succeeded. Caller navigates to SupplierShell.
  Future<bool> login() async {
    final mobileEmail = mobileEmailController.text.trim();
    final password = passwordController.text;

    if (mobileEmail.isEmpty) {
      _errorMessage = 'Please enter mobile or email';
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = 'Please enter password';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final authResponse =
          await _authRepository.supplierLogin(mobileEmail, password);

      if (authResponse.success == false) {
        _errorMessage =
            authResponse.message ?? 'Invalid mobile/email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final token = authResponse.token?.trim();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userType = authResponse.user?.userType?.trim().toLowerCase();
      if (userType != 'supplier_user' && userType != 'supplier') {
        _errorMessage =
            'This account does not have supplier portal access. Use the correct portal for your role.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _sessionService.saveSession(authResponse, role: 'supplier');
      await _sessionService.saveLastPortal('supplier');
      _isLoading = false;
      notifyListeners();
      return true;
    } on UnauthorisedException catch (e) {
      _errorMessage = _stripPrefix(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    } on BadRequestException catch (e) {
      _errorMessage = _stripPrefix(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    } on FetchDataException catch (e) {
      _errorMessage = _stripPrefix(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    mobileEmailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
