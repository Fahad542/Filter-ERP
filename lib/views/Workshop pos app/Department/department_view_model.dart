import 'package:flutter/material.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../models/department_model.dart';
import '../../../services/catalog_sync_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../More Tab/settings_view_model.dart';

class DepartmentViewModel extends ChangeNotifier with TranslatableMixin {
  final PosRepository _departmentRepository;
  final SessionService _sessionService;
  final CatalogSyncService _catalogSync;

  DepartmentViewModel({
    required PosRepository departmentRepository,
    required SessionService sessionService,
    required CatalogSyncService catalogSync,
    SettingsViewModel? settingsViewModel,
  })  : _departmentRepository = departmentRepository,
        _sessionService = sessionService,
        _catalogSync = catalogSync {
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

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing || _catalogSync.isSyncing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Department> _departments = [];
  List<Department> get departments => _departments;

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;
  final Set<int> _selectedIndices = {};
  Set<int> get selectedIndices => Set.unmodifiable(_selectedIndices);
  List<Department> get selectedDepartments => _selectedIndices
      .where((i) => i >= 0 && i < _departments.length)
      .map((i) => _departments[i])
      .toList();

  void setSelectedIndex(int? index) {
    _selectedIndex = index;
    _selectedIndices.clear();
    if (index != null) _selectedIndices.add(index);
    notifyListeners();
  }

  void toggleSelectedIndex(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    _selectedIndex = _selectedIndices.isEmpty ? null : _selectedIndices.first;
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

  /// SQLite only — use [syncCatalogFromApi] after login or from drawer Sync data.
  Future<void> fetchDepartments() async {
    _selectedIndex = null;
    _selectedIndices.clear();
    _setLoading(true);
    _setErrorMessage(null);

    try {
      _departments = await _catalogSync.loadDepartmentsLocal();
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<CatalogSyncResult> syncCatalogFromApi() async {
    _isSyncing = true;
    _setErrorMessage(null);
    notifyListeners();
    try {
      final result = await _catalogSync.syncAll();
      if (result.success) {
        _departments = await _catalogSync.loadDepartmentsLocal();
      } else {
        _setErrorMessage(result.message);
      }
      return result;
    } catch (e) {
      _setErrorMessage(e.toString());
      return CatalogSyncResult(success: false, message: e.toString());
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
