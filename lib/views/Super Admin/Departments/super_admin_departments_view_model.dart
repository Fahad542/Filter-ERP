import 'package:flutter/material.dart';
import '../../../models/super_admin_departments_api_model.dart';
import '../../../data/repositories/super_admin_repository.dart';
import '../../../services/session_service.dart';

class SuperAdminDepartmentsViewModel extends ChangeNotifier {
  final SuperAdminRepository _repository = SuperAdminRepository();
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;
  String? _errorMessage;
  List<SuperAdminDepartment> _departments = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SuperAdminDepartment> get departments => _departments;

  SuperAdminDepartmentsViewModel() {
    refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _sessionService.getToken(role: 'admin');
      if (token == null) throw Exception('Authentication token not found');

      final response = await _repository.getDepartments(token);
      if (response.success) {
        _departments = response.departments;
      } else {
        _errorMessage = 'Failed to load departments';
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(String error) {
    String clean = error;
    if (clean.startsWith('Exception: ')) clean = clean.substring(11);
    if (clean.startsWith('Error: ')) clean = clean.substring(7);
    return clean;
  }
}
