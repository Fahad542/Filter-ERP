import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../models/department_model.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../utils/toast_service.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/google_places_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

class EmployeeManagementViewModel extends ChangeNotifier
    with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  final SettingsViewModel? settingsViewModel;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController baseSalaryController = TextEditingController();
  final TextEditingController commissionPercentController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController openingBalanceController = TextEditingController();
  final GooglePlacesService googlePlacesService = GooglePlacesService('AIzaSyDfxcDdlq5IDIHjpRQKeAHepYIFaSYvVMQ');

  double _gpsLat = 24.7136;
  double _gpsLng = 46.6753;

  bool _isLoading = false;
  bool get isLoading => _isLoading; // Separated from ownerDataService loading for cleaner UI

  bool _isActive = true;
  bool get isActive => _isActive;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  /// Tracks which employee row is currently being acted on (edit/delete),
  /// so each tile can show its own per-row loading indicator.
  String? _actionEmployeeId;
  String? get actionEmployeeId => _actionEmployeeId;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<OwnerEmployee> _employees = [];
  String? _editingEmployeeId;
  bool get isEditing => _editingEmployeeId != null;

  // ── Roles ────────────────────────────────────────────────────────────────
  List<WorkshopRole> _roles = [];
  List<WorkshopRole> get roles => _roles;

  bool _isRolesLoading = false;
  bool get isRolesLoading => _isRolesLoading;

  // ── Stats computed from the visible (branch-filtered) employee list ─────

  /// Total number of employees across all types.
  int get totalStaff => employees.length;

  /// Active technicians assigned to workshop duty (type: 'workshop' or 'both').
  int get onWorkshopDutyCount => employees
      .where(
        (e) =>
    e.role.toLowerCase() == 'technician' &&
        (e.technicianType == 'workshop' || e.technicianType == 'both') &&
        e.isActive,
  )
      .length;

  /// Active technicians available for on-call duty (type: 'oncall' or 'both').
  int get onCallCount => employees
      .where(
        (e) =>
    e.role.toLowerCase() == 'technician' &&
        (e.technicianType == 'oncall' || e.technicianType == 'both') &&
        e.isActive,
  )
      .length;

  /// Translated overlay keyed by employee id — raw [_employees] is never
  /// mutated so create/update/delete API calls keep using English values.
  final Map<String, OwnerEmployee> _translatedEmployeeCache = {};

  List<OwnerEmployee> get employees {
    final branchId = ownerDataService.selectedBranchId;
    Iterable<OwnerEmployee> list =
        _employees.map((e) => _translatedEmployeeCache[e.id] ?? e);
    if (branchId != null && branchId.isNotEmpty) {
      list = list.where((e) => e.branchId == branchId);
    }
    if (_searchQuery.isEmpty) {
      return list.toList();
    }
    final q = _searchQuery.toLowerCase();
    return list
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            (e.email?.toLowerCase().contains(q) ?? false) ||
            (e.mobile?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleStatus(bool value) {
    _isActive = value;
    notifyListeners();
  }

  List<Branch> get branches => ownerDataService.branches;
  List<Department> get departments => ownerDataService.departments;

  EmployeeManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    this.settingsViewModel,
  }) {
    ownerDataService.addListener(notifyListeners);
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
    Future.microtask(() => _init());
  }

  // ── Locale re-translation ─────────────────────────────────────────────────

  Future<void> retranslate() async {
    await _applyEmployeeTranslations();
    notifyListeners();
  }

  Future<void> _applyEmployeeTranslations() async {
    final translated =
        await Future.wait(_employees.map(_translateEmployee));
    _translatedEmployeeCache
      ..clear()
      ..addEntries(translated.map((e) => MapEntry(e.id, e)));
  }

  Future<OwnerEmployee> _translateEmployee(OwnerEmployee e) async {
    final translatedDepts = e.departmentIds.isEmpty
        ? <String>[]
        : await tAll(e.departmentIds);
    return e.copyWith(
      translatedName: await tPerson(e.name),
      translatedRole: await tUiStatus(e.role.replaceAll('_', ' ')),
      translatedBranchName:
          e.branchName != null ? await tBranch(e.branchName!) : null,
      translatedDepartmentLabels: translatedDepts,
    );
  }

  /// Re-apply client-side branch filter when this tab becomes visible.
  Future<void> syncWithSelectedBranch({bool force = false}) async {
    notifyListeners();
  }

  Future<void> _init() async {
    await Future.wait([
      fetchEmployees(),
      fetchRoles(),
    ]);
    if (branches.isEmpty || departments.isEmpty) {
      await ownerDataService.refreshAll();
    }
  }

  Future<void> fetchEmployees({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final response = await ownerRepository.getEmployees(token);
      if (response != null && response['success'] == true) {
        final raw = response['employees'] ?? response['data']?['employees'];
        if (raw is List) {
          _employees = raw
              .whereType<Map>()
              .map((e) {
                try {
                  return OwnerEmployee.fromJson(
                      Map<String, dynamic>.from(e));
                } catch (_) {
                  return null;
                }
              })
              .whereType<OwnerEmployee>()
              .toList();
        }
      }
      await _applyEmployeeTranslations();
    } catch (e) {
      debugPrint('[EmployeeVM] fetchEmployees error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoles({bool silent = false}) async {
    if (!silent) {
      _isRolesLoading = true;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');
      final response = await ownerRepository.getRoles(token);
      if (response != null && response['success'] == true) {
        _roles = (response['roles'] as List? ?? [])
            .map((json) => WorkshopRole.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
    } finally {
      _isRolesLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRole(BuildContext context, WorkshopRole role) async {
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');
      await ownerRepository.createRole(role.toJson(), token);
      await fetchRoles(silent: true);
    } catch (_) {
      if (context.mounted) ToastService.showError(context, 'Failed to create role');
    }
  }

  Future<void> updateRole(BuildContext context, String id, WorkshopRole role) async {
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');
      await ownerRepository.updateRole(token, id, role.toJson());
      await fetchRoles(silent: true);
    } catch (_) {
      if (context.mounted) ToastService.showError(context, 'Failed to update role');
    }
  }

  Future<void> deleteRole(BuildContext context, String id) async {
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');
      await ownerRepository.deleteRole(token, id);
      _roles = _roles.where((r) => r.id != id).toList();
      notifyListeners();
    } catch (_) {
      if (context.mounted) ToastService.showError(context, 'Failed to delete role');
    }
  }

  void clearForm() {
    nameController.clear();
    mobileController.clear();
    emailController.clear();
    passwordController.clear();
    departmentController.clear();
    baseSalaryController.clear();
    commissionPercentController.clear();
    addressController.clear();
    openingBalanceController.clear();
    _editingEmployeeId = null;
    _gpsLat = 24.7136;
    _gpsLng = 46.6753;
    _isActive = true;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAddressSuggestions(String input) async {
    return await googlePlacesService.getSuggestions(input);
  }

  Future<void> onAddressSelected(Map<String, dynamic> selection) async {
    final description = selection['description'] as String;
    addressController.text = description;

    final placeId = selection['place_id'] as String;
    final details = await googlePlacesService.getPlaceDetails(placeId);

    if (details != null) {
      _gpsLat = details['lat'];
      _gpsLng = details['lng'];
      notifyListeners();
    }
  }

  void setEditEmployee(OwnerEmployee? e) {
    if (e == null) {
      clearForm();
    } else {
      _editingEmployeeId = e.id;
      nameController.text = e.name;
      mobileController.text = e.mobile ?? '';
      emailController.text = e.email ?? '';
      passwordController.clear(); // Don't pre-fill password
      commissionPercentController.text = e.techCommission.toString();
      baseSalaryController.text = e.basicSalary?.toString() ?? '0';
      _isActive = e.status == 'active';
      // Note: branch and department will be handled in the UI
    }
    notifyListeners();
  }

  Future<void> submitTechnicianForm(
      BuildContext context, {
        required String? branchId,
        required String? departmentId,
        required bool isWorkshop,
        required bool isOnCall,
      }) async {
    if (nameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        (!isEditing && passwordController.text.trim().isEmpty)) {
      ToastService.showError(context, 'Please fill in all required text fields.');
      return;
    }

    if (!isWorkshop && !isOnCall) {
      ToastService.showError(context, 'Please select at least one technician type.');
      return;
    }

    if (branchId == null || branchId.isEmpty) {
      ToastService.showError(context, 'Please create a branch first to assign this employee.');
      return;
    }

    if (departmentId == null || departmentId.isEmpty) {
      ToastService.showError(context, 'Please create a department first to assign this employee.');
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      String techType = "workshop";
      if (isWorkshop && isOnCall) {
        techType = "both";
      } else if (isOnCall) {
        techType = "oncall";
      }

      final data = {
        "name": nameController.text.trim(),
        "mobile": mobileController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
        "branchId": branchId,
        "technicianType": techType,
        "commissionPercent": double.tryParse(commissionPercentController.text.trim()) ?? 0,
        "basicSalary": double.tryParse(baseSalaryController.text.trim()) ?? 0,
        "departmentIds": [departmentId],
        "isActive": _isActive,
      };

      if (passwordController.text.trim().isNotEmpty) {
        data["password"] = passwordController.text.trim();
      }

      if (_editingEmployeeId == null) {
        await ownerRepository.createTechnician(data, token);
        if (context.mounted) ToastService.showSuccess(context, 'Technician Created Successfully');
      } else {
        await ownerRepository.updateTechnician(token, _editingEmployeeId!, data);
        if (context.mounted) ToastService.showSuccess(context, 'Technician Updated Successfully');
      }

      if (context.mounted) {
        setEditEmployee(null);
        Navigator.pop(context); // Close the sheet
        await fetchEmployees(silent: true);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create technician');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitCashierForm(
      BuildContext context, {
        required String? branchId,
      }) async {
    if (nameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        (!isEditing && passwordController.text.trim().isEmpty)) {
      ToastService.showError(context, 'Please fill in all required text fields.');
      return;
    }

    if (branchId == null || branchId.isEmpty) {
      ToastService.showError(context, 'Please create a branch first to assign this cashier.');
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        "name": nameController.text.trim(),
        "mobile": mobileController.text.trim(),
        "email": emailController.text.trim(),
        "branchId": branchId,
        "isActive": _isActive,
      };

      if (passwordController.text.trim().isNotEmpty) {
        data["password"] = passwordController.text.trim();
      }

      if (_editingEmployeeId == null) {
        await ownerRepository.createCashier(data, token);
        if (context.mounted) ToastService.showSuccess(context, 'Cashier Created Successfully');
      } else {
        await ownerRepository.updateCashier(token, _editingEmployeeId!, data);
        if (context.mounted) ToastService.showSuccess(context, 'Cashier Updated Successfully');
      }

      if (context.mounted) {
        setEditEmployee(null);
        Navigator.pop(context); // Close the sheet
        await fetchEmployees(silent: true);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create cashier');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(
      BuildContext context,
      String id,
      String role,
      ) async {
    _isActionLoading = true;
    _actionEmployeeId = id;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      if (role.toLowerCase().contains('technician')) {
        await ownerRepository.deleteTechnician(token, id);
      } else {
        await ownerRepository.deleteCashier(token, id);
      }

      if (context.mounted) {
        ToastService.showSuccess(context, 'Employee Deleted Successfully');
        await fetchEmployees(silent: true);
      }
    } catch (e) {
      if (context.mounted) ToastService.showError(context, 'Failed to delete employee');
    } finally {
      _isActionLoading = false;
      _actionEmployeeId = null;
      notifyListeners();
    }
  }

  Future<void> submitSupplierForm(BuildContext context) async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ToastService.showError(context, 'Please fill in all required fields');
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "mobile": mobileController.text.trim(),
        "address": addressController.text.trim(),
        "openingBalance": double.tryParse(openingBalanceController.text.trim()) ?? 0,
        "password": passwordController.text.trim(),
        "gpsLat": _gpsLat,
        "gpsLng": _gpsLng,
        "isActive": _isActive,
      };

      await ownerRepository.createSupplier(data, token);

      if (context.mounted) {
        ToastService.showSuccess(context, 'Supplier Created Successfully');
        clearForm();
        Navigator.pop(context); // Close the sheet
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create supplier');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ownerDataService.removeListener(notifyListeners);
    unbindLocaleRetranslation();
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    departmentController.dispose();
    baseSalaryController.dispose();
    commissionPercentController.dispose();
    addressController.dispose();
    openingBalanceController.dispose();
    super.dispose();
  }
}