import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../More Tab/settings_view_model.dart';
import '../../../models/current_session_model.dart';

class CurrentShiftViewModel extends ChangeNotifier with TranslatableMixin {
  final AuthRepository _authRepository;
  final SessionService _sessionService;

  CurrentShiftViewModel({
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

  CurrentSession? _currentSession;
  CurrentSession? get currentSession => _currentSession;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void fetchCurrentSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final creds = await _sessionService.getCredentials();
      final token = await _sessionService.getToken();

      if (creds == null || token == null) {
        throw Exception('User credentials or token missing.');
      }

      final response = await _authRepository.getCurrentSession(
        creds['email']!,
        creds['password']!,
        token,
      );

      final sessionResponse = CurrentSessionResponse.fromJson(response);
      
      if (sessionResponse.hasOpenSession) {
        var session = sessionResponse.session;
        if (session != null && (session.cashierName.isEmpty || session.cashierName == 'N/A')) {
          final user = await _sessionService.getUser();
          if (user != null) {
            // Create a new session object with the cashier name if it's missing
            session = CurrentSession(
              posSessionId: session.posSessionId,
              branchId: session.branchId,
              branchName: session.branchName,
              branchAddress: session.branchAddress,
              cashierName: user.name ?? 'Cashier',
              openedAt: session.openedAt,
              status: session.status.isEmpty ? 'Active' : session.status,
              elapsedTime: session.elapsedTime,
            );
          }
        }
        _currentSession = session;
      } else {
        _currentSession = null;
        _errorMessage = 'No active shift found.';
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch shift details: $e';
      _currentSession = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
