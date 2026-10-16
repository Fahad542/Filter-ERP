import 'package:flutter/material.dart';
import '../../../utils/toast_service.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/google_places_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../l10n/app_localizations.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

// ---------------------------------------------------------------------------
// BranchManagementViewModel
//
// Re-translation on locale switch
// ────────────────────────────────
// The VM observes [SettingsViewModel]. When the locale changes
// [_onLocaleChanged] clears the translation cache and re-translates every
// branch name / location that was already fetched, without touching the
// network. The View rebuilds automatically via notifyListeners.
//
// ⚠️  BRANCH MODEL ADDITIONS REQUIRED
// ────────────────────────────────────
// Add these fields to the Branch class in workshop_owner_models.dart:
//   String? branchCode
//   String? phone
//   String? email
//   String? vatId
//   String? crNumber
//   String? contactPerson
//   int?    employeeCount
//   String? adminName
//   String? adminEmail
// Update copyWith(), fromJson(), toJson() accordingly.
// ---------------------------------------------------------------------------

// ── Access Permission model ───────────────────────────────────────────────────

class BranchAccessPermission {
  final String branchId;
  final String branchCode;
  final String branchName;
  final String city;
  final List<String> permittedSections;
  final String? adminName;
  final String? adminEmail;

  const BranchAccessPermission({
    required this.branchId,
    required this.branchCode,
    required this.branchName,
    required this.city,
    required this.permittedSections,
    this.adminName,
    this.adminEmail,
  });
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class BranchManagementViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository    ownerRepository;
  final SessionService     sessionService;
  final OwnerDataService   ownerDataService;
  final SettingsViewModel  settingsViewModel;
  final GooglePlacesService googlePlacesService =
  GooglePlacesService('AIzaSyDfxcDdlq5IDIHjpRQKeAHepYIFaSYvVMQ');

  // ── Branch form controllers ────────────────────────────────────────────────

  final TextEditingController branchNameController    = TextEditingController();
  final TextEditingController branchCodeController    = TextEditingController();
  final TextEditingController phoneController         = TextEditingController();
  final TextEditingController emailController         = TextEditingController();
  final TextEditingController addressController       = TextEditingController();
  final TextEditingController gpsLatController        = TextEditingController();
  final TextEditingController gpsLngController        = TextEditingController();
  final TextEditingController vatIdController         = TextEditingController();
  final TextEditingController crNumberController      = TextEditingController();
  final TextEditingController egsSerialController     = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();

  // ── Access form controllers ────────────────────────────────────────────────

  final TextEditingController accessAdminNameController  = TextEditingController();
  final TextEditingController accessAdminEmailController = TextEditingController();

  /// Branch selected inside the Grant Access dialog.
  Branch? _selectedAccessBranch;
  Branch? get selectedAccessBranch => _selectedAccessBranch;

  void setSelectedAccessBranch(Branch? b) {
    _selectedAccessBranch = b;
    notifyListeners();
  }

  // ── State ─────────────────────────────────────────────────────────────────

  bool _isActive = true;
  bool get isActive => _isActive;

  void toggleStatus(bool value) {
    _isActive = value;
    notifyListeners();
  }

  String? _editingBranchId;
  bool get isEditing => _editingBranchId != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading || ownerDataService.isLoadingBranches;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  bool _isAccessLoading = false;
  bool get isAccessLoading => _isAccessLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Access permissions state ───────────────────────────────────────────────

  List<BranchAccessPermission> _accessPermissions = [];
  List<BranchAccessPermission> get accessPermissions => _accessPermissions;

  /// Currently selected sections for the access form.
  final Set<String> selectedSections = {};

  static const List<String> availableSections = [
    'pos',
    'employees',
    'approvals',
    'reports',
    'departments',
    'suppliers',
  ];

  void toggleSection(String section) {
    if (selectedSections.contains(section)) {
      selectedSections.remove(section);
    } else {
      selectedSections.add(section);
    }
    notifyListeners();
  }

  void clearAccessForm() {
    accessAdminNameController.clear();
    accessAdminEmailController.clear();
    _selectedAccessBranch = null;
    selectedSections.clear();
    notifyListeners();
  }

  /// Cache of translated branches keyed by branch id.
  final Map<String, Branch> _translatedBranchCache = {};

  List<Branch> get branches {
    final raw = _searchQuery.isEmpty
        ? ownerDataService.branches
        : ownerDataService.branches.where((b) =>
    b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.location.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return raw.map((b) => _translatedBranchCache[b.id] ?? b).toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Constructor / lifecycle ───────────────────────────────────────────────

  BranchManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    required this.settingsViewModel,
  }) {
    ownerDataService.addListener(notifyListeners);
    settingsViewModel.addListener(_onLocaleChanged);
    Future.microtask(() => _init());
  }

  String _lastLocale = '';

  Future<void> _init() async {
    _lastLocale = settingsViewModel.locale.languageCode;
    if (branches.isEmpty) {
      await fetchBranches();
    }
    await fetchAccessPermissions();
  }

  // ── Locale change handler ─────────────────────────────────────────────────

  void _onLocaleChanged() {
    final newLocale = settingsViewModel.locale.languageCode;
    if (newLocale == _lastLocale) return;
    _lastLocale = newLocale;
    AppTranslationService.clearCache();
    _translatedBranchCache.clear();
    _retranslateBranches();
  }

  Future<void> _retranslateBranches() async {
    final raw = ownerDataService.branches;
    if (raw.isEmpty) return;
    await _translateBranches(raw);
    notifyListeners();
  }

  // ── Fetch & translate ─────────────────────────────────────────────────────

  Future<void> fetchBranches({bool silent = false}) async {
    await ownerDataService.fetchBranches(silent: silent);
    await _translateBranches(ownerDataService.branches);
    notifyListeners();
  }

  Future<void> _translateBranches(List<Branch> raw) async {
    final translated = await Future.wait(raw.map(_translateBranch));
    for (final b in translated) {
      _translatedBranchCache[b.id] = b;
    }
  }

  Future<Branch> _translateBranch(Branch branch) async {
    final name     = await tBranch(branch.name);
    final location = await tBranch(branch.location);
    return branch.copyWith(
      translatedName:     name,
      translatedLocation: location,
    );
  }

  // ── Access Permissions ────────────────────────────────────────────────────

  /// Fetches access permissions from the API.
  /// TODO: Wire up to ownerRepository.fetchAccessPermissions() when endpoint is ready.
  Future<void> fetchAccessPermissions({bool silent = false}) async {
    if (!silent) {
      _isAccessLoading = true;
      notifyListeners();
    }
    try {
      // Replace with real API call:
      // final token = await sessionService.getToken(role: 'owner');
      // _accessPermissions = await ownerRepository.fetchAccessPermissions(token!);
      _accessPermissions = [
        const BranchAccessPermission(
          branchId:         'b2',
          branchCode:       'b2',
          branchName:       'Main Branch',
          city:             'Riyadh',
          permittedSections: ['pos', 'employees', 'approvals', 'reports'],
          adminName:        'Ahmad Al-Rashid',
          adminEmail:       'ahmad@filtercars.com',
        ),
        const BranchAccessPermission(
          branchId:         'b3',
          branchCode:       'b3',
          branchName:       'North Branch',
          city:             'Jeddah',
          permittedSections: ['pos', 'departments', 'suppliers'],
          adminName:        'Mohammed Hassan',
          adminEmail:       'mohammed@filtercars.com',
        ),
      ];
    } catch (_) {
      _accessPermissions = [];
    } finally {
      _isAccessLoading = false;
      notifyListeners();
    }
  }

  /// Submits an access grant (create or update) for a branch.
  /// TODO: Connect to the real API endpoint.
  Future<void> submitAccessForm(
      BuildContext context, {
        required String branchId,
      }) async {
    final l10n = AppLocalizations.of(context)!;

    if (accessAdminEmailController.text.trim().isEmpty ||
        accessAdminNameController.text.trim().isEmpty) {
      ToastService.showError(context, l10n.branchFormValidationError);
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final effectiveBranchId = branchId.isNotEmpty
          ? branchId
          : (_selectedAccessBranch?.id ?? '');

      // TODO: replace with actual API call
      // await ownerRepository.setAccessPermission(token, {
      //   'branchId':          effectiveBranchId,
      //   'adminName':         accessAdminNameController.text.trim(),
      //   'adminEmail':        accessAdminEmailController.text.trim(),
      //   'permittedSections': selectedSections.toList(),
      // });

      await Future.delayed(const Duration(milliseconds: 300)); // remove when wired up

      if (context.mounted) {
        clearAccessForm();
        Navigator.pop(context);
        ToastService.showSuccess(context, l10n.branchCreateSuccess);
        await fetchAccessPermissions(silent: true);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, l10n.branchSaveError);
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── Google Places ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAddressSuggestions(String input) async {
    return googlePlacesService.getSuggestions(input);
  }

  Future<void> setSelectedAddress(String description, String placeId) async {
    addressController.text = description;
    final location = await googlePlacesService.getPlaceDetails(placeId);
    if (location != null) {
      gpsLatController.text = location['lat'].toString();
      gpsLngController.text = location['lng'].toString();
    }
    notifyListeners();
  }

  // ── Branch form helpers ───────────────────────────────────────────────────

  void clearForm() {
    branchNameController.clear();
    branchCodeController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    gpsLatController.clear();
    gpsLngController.clear();
    vatIdController.clear();
    crNumberController.clear();
    egsSerialController.clear();
    contactPersonController.clear();
    _isActive        = true;
    _editingBranchId = null;
    notifyListeners();
  }

  void setEditBranch(Branch? b) {
    if (b == null) {
      clearForm();
    } else {
      _editingBranchId             = b.id;
      branchNameController.text    = b.name;
      branchCodeController.text    = b.branchCode ?? '';
      phoneController.text         = b.phone ?? '';
      emailController.text         = b.email ?? '';
      addressController.text       = b.location;
      gpsLatController.text        = b.gpsLat?.toString() ?? '';
      gpsLngController.text        = b.gpsLng?.toString() ?? '';
      vatIdController.text         = b.vatId ?? '';
      crNumberController.text      = b.crNumber ?? '';
      egsSerialController.text     = b.egsSerial ?? '';
      contactPersonController.text = b.contactPerson ?? '';
      _isActive                    = b.status.toLowerCase() == 'active';
    }
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> submitBranchForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (branchNameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      ToastService.showError(context, l10n.branchFormValidationError);
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        'name':          branchNameController.text.trim(),
        'branchCode':    branchCodeController.text.trim(),
        'phone':         phoneController.text.trim(),
        'email':         emailController.text.trim(),
        'address':       addressController.text.trim(),
        'gpsLat':        double.tryParse(gpsLatController.text.trim()),
        'gpsLng':        double.tryParse(gpsLngController.text.trim()),
        'vatId':         vatIdController.text.trim(),
        'crNumber':      crNumberController.text.trim(),
        'egsSerial':     egsSerialController.text.trim(),
        'contactPerson': contactPersonController.text.trim(),
        'isActive':      _isActive,
      };

      if (_editingBranchId == null) {
        await ownerRepository.createBranch(data, token);
        if (context.mounted) {
          ToastService.showSuccess(context, l10n.branchCreateSuccess);
        }
      } else {
        await ownerRepository.updateBranch(token, _editingBranchId!, data);
        if (context.mounted) {
          ToastService.showSuccess(context, l10n.branchUpdateSuccess);
        }
      }

      if (context.mounted) {
        clearForm();
        Navigator.pop(context);
        await fetchBranches(silent: true);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, l10n.branchSaveError);
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBranch(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      final response = await ownerRepository.deleteBranch(token, id);

      final successMessage =
      (response is Map<String, dynamic> &&
          response['message'] != null &&
          response['message'].toString().trim().isNotEmpty)
          ? response['message'].toString()
          : l10n.branchDeleteSuccess;

      await fetchBranches(silent: false);
      if (context.mounted) {
        ToastService.showSuccess(context, successMessage);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, l10n.branchDeleteError);
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    ownerDataService.removeListener(notifyListeners);
    settingsViewModel.removeListener(_onLocaleChanged);
    branchNameController.dispose();
    branchCodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    gpsLatController.dispose();
    gpsLngController.dispose();
    vatIdController.dispose();
    crNumberController.dispose();
    egsSerialController.dispose();
    contactPersonController.dispose();
    accessAdminNameController.dispose();
    accessAdminEmailController.dispose();
    super.dispose();
  }
}