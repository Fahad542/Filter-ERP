import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';

// ---------------------------------------------------------------------------
// OwnerLoginViewModel
//
// Pure logic — no UI strings here. All user-visible strings are in the View
// (owner_login_view.dart) via AppLocalizations.
//
// errorMessage is returned from the API in whatever language the server sends.
// The View falls back to l10n.ownerLoginFailed if errorMessage is null.
// ---------------------------------------------------------------------------

class OwnerLoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionService _sessionService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  OwnerLoginViewModel({
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
      final authResponse = await _authRepository.adminLogin(
        emailController.text.trim(),
        passwordController.text,
      );

      if (authResponse.success == false) {
        _setErrorMessage(authResponse.message ?? 'Invalid email or password');
        _setLoading(false);
        return false;
      }

      final user = authResponse.user;
      final userType = user?.userType?.trim().toLowerCase();
      final staffRole = user?.workshopStaffRole?.trim().toLowerCase();
      const allowedStaff = {
        'manager',
        'supervisor',
        'team_leader',
        'workshop_manager',
      };
      final isOwner = userType == 'workshop_owner';
      final isPortalStaff =
          userType == 'workshop_user' && allowedStaff.contains(staffRole);
      if (!isOwner && !isPortalStaff) {
        _setErrorMessage(
          'This account does not have workshop portal access. '
          'Use the correct portal for your role.',
        );
        _setLoading(false);
        return false;
      }

      await _sessionService.saveSession(authResponse, role: 'owner');
      _setLoading(false);
      return true;
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
            'This account does not have workshop portal access. Use the correct portal for your role.';
      }
      _setErrorMessage(message);
      _setLoading(false);
      return false;
    }
  }

  void clear() {
    emailController.clear();
    passwordController.clear();
    _errorMessage = null;
    _isLoading = false;
    _obscurePassword = true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}