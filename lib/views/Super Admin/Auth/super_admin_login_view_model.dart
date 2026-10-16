import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';

class SuperAdminLoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionService _sessionService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  SuperAdminLoginViewModel({
    required AuthRepository authRepository,
    required SessionService sessionService,
  })  : _authRepository = authRepository,
        _sessionService = sessionService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  Future<bool> login() async {
    if (!formKey.currentState!.validate()) return false;

    _setLoading(true);
    _setErrorMessage(null);

    try {
      final response = await _authRepository.superAdminLogin(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (response.success != true) {
        _setErrorMessage(response.message ?? 'Login failed');
        _setLoading(false);
        return false;
      }

      final userType = response.user?.userType?.trim().toLowerCase();
      if (userType != 'platform_admin' &&
          userType != 'admin' &&
          userType != 'super_admin') {
        _setErrorMessage(
          'This account does not have Super Admin portal access. Use the correct portal for your role.',
        );
        _setLoading(false);
        return false;
      }

      await _sessionService.saveSession(response, role: 'super_admin');
      
      // Verify session was saved
      final savedToken = await _sessionService.getToken(role: 'super_admin');
      _setLoading(false);
      return savedToken != null;
    } catch (e) {
      var message = e.toString();
      for (final prefix in const [
        'Unauthorised: ',
        'Invalid Request: ',
        'Error During Communication: ',
      ]) {
        if (message.startsWith(prefix)) {
          message = message.substring(prefix.length);
          break;
        }
      }
      if (message.toLowerCase().contains('invalid user type')) {
        message =
            'This account does not have Super Admin portal access. Use the correct portal for your role.';
      }
      _setErrorMessage(message);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkSession() async {
    return await _sessionService.isLoggedIn(role: 'super_admin');
  }

  void clear() {
    emailController.clear();
    passwordController.clear();
    _errorMessage = null;
    _isLoading = false;
    _obscurePassword = true;
  }
}
