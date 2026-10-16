import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Home Screen/pos_view_model.dart';
import '../../../models/cashier_corporate_accounts_api_model.dart';
import '../../../models/cashier_corporate_fleet_vehicle_model.dart';
import '../../../models/customer_search_model.dart';
import '../../../models/cashier_expense_models.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/toast_service.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/gcc_plate.dart' hide canonicalSaudiPlateForApi;
import '../../../utils/ksa_vehicle_catalog.dart';
import 'pos_add_customer_phone_format.dart';

export 'pos_add_customer_phone_format.dart';

/// Vehicle class for Add New Order plate rules.
enum PosAddCustomerVehicleKind { car, bike }

class AddCustomerViewModel extends ChangeNotifier with TranslatableMixin {
  final BuildContext context;

  AddCustomerViewModel(this.context) {
    _hydrateFromSavedCustomer();
    loadMakes();
    for (final c in [
      corpVehicleNumberController,
      corpMakeController,
      corpModelController,
    ]) {
      c.addListener(_onCorporateFleetIdentityFieldEdited);
    }
  }

  bool _suppressFleetSelectionClear = false;

  /// Fleet vehicle picked from corporate dropdown — lock plate/make/model/year; odometer + VIN stay editable.
  bool get isCorporateFleetVehicleSelected {
    final id = _selectedCorporateFleetVehicleId?.trim();
    return id != null && id.isNotEmpty;
  }

  /// Corporate account selected — lock contact name and mobile (prefilled from account).
  bool get isCorporateContactLocked {
    final id = _selectedCorporate?.trim();
    return id != null && id.isNotEmpty;
  }

  void _onCorporateFleetIdentityFieldEdited() {
    if (_suppressFleetSelectionClear) return;
    if (_selectedCorporateFleetVehicleId != null) {
      _selectedCorporateFleetVehicleId = null;
      notifyListeners();
    }
  }

  // Controllers for Normal Customer
  final TextEditingController nameController = TextEditingController();
  final TextEditingController vatController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  PosAddCustomerMobileDial _mobileDialCountry =
      PosAddCustomerMobileDial.saudiArabia;
  PosAddCustomerMobileDial get mobileDialCountry => _mobileDialCountry;

  bool _pickBranchEmployeeMode = false;
  List<BranchEmployee> _branchEmployeesPickList = [];
  bool _branchEmployeesPickLoading = false;
  BranchEmployee? _branchEmployeePickSelection;

  bool get pickBranchEmployeeMode => _pickBranchEmployeeMode;
  List<BranchEmployee> get branchEmployeesPickList => _branchEmployeesPickList;
  bool get branchEmployeesPickLoading => _branchEmployeesPickLoading;
  BranchEmployee? get branchEmployeePickSelection =>
      _branchEmployeePickSelection;

  bool get lockNameMobileFromBranchEmployee => _pickBranchEmployeeMode;

  void setPickBranchEmployeeMode(bool v) {
    if (_pickBranchEmployeeMode == v) return;
    _pickBranchEmployeeMode = v;
    if (!v) {
      _branchEmployeePickSelection = null;
      nameController.clear();
      mobileController.clear();
      _mobileDialCountry = PosAddCustomerMobileDial.saudiArabia;
    } else {
      loadBranchEmployeesIfNeeded();
    }
    notifyListeners();
  }

  void setBranchEmployeeSelection(BranchEmployee? e) {
    _branchEmployeePickSelection = e;
    if (e != null) {
      nameController.text = e.name;
      _applyInternationalMobileToField(e.mobile ?? '');
    }
    notifyListeners();
  }

  Future<void> loadBranchEmployeesIfNeeded() async {
    if (_branchEmployeesPickLoading || _branchEmployeesPickList.isNotEmpty) {
      return;
    }
    _branchEmployeesPickLoading = true;
    notifyListeners();
    try {
      final posVm = context.read<PosViewModel>();
      final token = await posVm.sessionService.getToken(role: 'cashier');
      if (token == null) return;
      final res = await posVm.posRepository.getCashierEmployees(token);
      if (res.success) {
        _branchEmployeesPickList = res.employees;
      }
    } catch (_) {
      _branchEmployeesPickList = [];
    } finally {
      _branchEmployeesPickLoading = false;
      notifyListeners();
    }
  }

  static String digitsOnlyPhone(String input) =>
      PosAddCustomerPhoneFormat.digitsOnly(input);

  /// E.164-style value for walk-in save (normalized national + selected dial).
  String composedInternationalMobile() {
    final local = PosAddCustomerPhoneFormat.normalizeNational(
      _mobileDialCountry,
      mobileController.text,
    );
    if (local.isEmpty) return '';
    return '+${_mobileDialCountry.dialDigits}$local';
  }

  /// Corporate billing numbers may be stored as-is (PK/UAE) — not forced to +966.
  String composedCorporateMobile() {
    final raw = mobileController.text.trim();
    final d = digitsOnlyPhone(raw);
    if (d.isEmpty) return '';
    if (raw.startsWith('+')) return '+$d';
    final saudi = PosAddCustomerPhoneFormat.normalizeNational(
      PosAddCustomerMobileDial.saudiArabia,
      raw,
    );
    if (RegExp(r'^5\d{8}$').hasMatch(saudi)) {
      return '+${PosAddCustomerMobileDial.saudiArabia.dialDigits}$saudi';
    }
    return d;
  }

  String? validateNationalMobileInput({
    required String? raw,
    required String messageEmpty,
    required String messageInvalidSaudi,
  }) {
    final digits = digitsOnlyPhone(raw ?? '');
    if (digits.isEmpty) return messageEmpty;
    if (PosAddCustomerPhoneFormat.isValidNational(
      _mobileDialCountry,
      raw ?? '',
    )) {
      return null;
    }
    return messageInvalidSaudi;
  }

  void _applyInternationalMobileToField(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      mobileController.text = '';
      return;
    }
    var d = digitsOnlyPhone(trimmed);
    if (d.startsWith('966') && d.length > 3) {
      d = d.substring(3);
    } else if (d.startsWith('92') && d.length > 2) {
      d = d.substring(2);
    }
    _mobileDialCountry = PosAddCustomerMobileDial.saudiArabia;
    mobileController.text = PosAddCustomerPhoneFormat.formatDigits(
      _mobileDialCountry,
      d,
    );
  }

  String _normalPlateCountry = GccPlateCountry.sa.code;
  String? _normalPlateEmirate = UaeEmirate.all[1].key;
  String _corpPlateCountry = GccPlateCountry.sa.code;
  String? _corpPlateEmirate = UaeEmirate.all[1].key;
  PosAddCustomerVehicleKind _normalVehicleKind = PosAddCustomerVehicleKind.car;
  PosAddCustomerVehicleKind _corpVehicleKind = PosAddCustomerVehicleKind.car;

  PosAddCustomerVehicleKind get normalVehicleKind => _normalVehicleKind;
  PosAddCustomerVehicleKind get corpVehicleKind => _corpVehicleKind;
  bool get isNormalBike => _normalVehicleKind == PosAddCustomerVehicleKind.bike;
  bool get isCorpBike => _corpVehicleKind == PosAddCustomerVehicleKind.bike;

  void setNormalVehicleKind(PosAddCustomerVehicleKind kind) {
    if (_normalVehicleKind == kind) return;
    _normalVehicleKind = kind;
    if (kind == PosAddCustomerVehicleKind.bike) {
      _normalPlateCountry = GccPlateCountry.sa.code;
      _normalPlateEmirate = null;
    }
    notifyListeners();
  }

  void setCorpVehicleKind(PosAddCustomerVehicleKind kind) {
    if (_corpVehicleKind == kind) return;
    _corpVehicleKind = kind;
    if (kind == PosAddCustomerVehicleKind.bike) {
      _corpPlateCountry = GccPlateCountry.sa.code;
      _corpPlateEmirate = null;
    }
    notifyListeners();
  }

  String get normalPlateCountry => _normalPlateCountry;
  String? get normalPlateEmirate => _normalPlateEmirate;
  String get corpPlateCountry => _corpPlateCountry;
  String? get corpPlateEmirate => _corpPlateEmirate;

  void setNormalPlateCountry(String code, {String? emirate}) {
    _normalPlateCountry = GccPlateCountry.parseOrDefault(code).code;
    _normalPlateEmirate =
        _normalPlateCountry == 'AE' ? (emirate ?? UaeEmirate.all[1].key) : null;
    notifyListeners();
  }

  void setCorpPlateCountry(String code, {String? emirate}) {
    _corpPlateCountry = GccPlateCountry.parseOrDefault(code).code;
    _corpPlateEmirate =
        _corpPlateCountry == 'AE' ? (emirate ?? UaeEmirate.all[1].key) : null;
    notifyListeners();
  }

  GccPlateRegistration parseNormalPlateRegistration() => parseGccPlate(
        vehicleNumberController.text.trim(),
        countryCode: isNormalBike ? 'SA' : _normalPlateCountry,
        emirate: isNormalBike ? null : _normalPlateEmirate,
      );

  GccPlateRegistration parseCorpPlateRegistration() => parseGccPlate(
        corpVehicleNumberController.text.trim(),
        countryCode: isCorpBike ? 'SA' : _corpPlateCountry,
        emirate: isCorpBike ? null : _corpPlateEmirate,
      );

  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController vinNumberController = TextEditingController();
  final TextEditingController makeController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController odoMeterController = TextEditingController();

  /// Model year (optional), must match [_vehicleModelYearChoices] when set.
  String? _normalVehicleYear;
  String? _corpVehicleYear;

  String? get normalVehicleYear => _normalVehicleYear;
  String? get corpVehicleYear => _corpVehicleYear;

  void setNormalVehicleYear(String? year) {
    _normalVehicleYear = year;
    notifyListeners();
  }

  void setCorpVehicleYear(String? year) {
    _corpVehicleYear = year;
    notifyListeners();
  }

  // Controllers for Corporate Customer
  final TextEditingController corpVehicleNumberController =
      TextEditingController();
  final TextEditingController corpVinNumberController = TextEditingController();
  final TextEditingController corpMakeController = TextEditingController();
  final TextEditingController corpModelController = TextEditingController();
  final TextEditingController corpOdoMeterController = TextEditingController();

  /// Selected corporate account **id** (must match [DropdownMenuItem.value] — never duplicate company names).
  String? _selectedCorporate;
  CashierCorporateAccount? _selectedCorporateData;

  String? get selectedCorporate => _selectedCorporate;
  CashierCorporateAccount? get selectedCorporateData => _selectedCorporateData;

  List<CashierCorporateFleetVehicle> _corporateFleetVehicles = [];
  bool _corporateFleetVehiclesLoading = false;
  /// `null` = manual entry; otherwise fleet vehicle id.
  String? _selectedCorporateFleetVehicleId;

  List<CashierCorporateFleetVehicle> get corporateFleetVehicles =>
      _corporateFleetVehicles;
  bool get corporateFleetVehiclesLoading => _corporateFleetVehiclesLoading;
  String? get selectedCorporateFleetVehicleId =>
      _selectedCorporateFleetVehicleId;

  /// Keeps selection valid when the API list loads or contains duplicate [CashierCorporateAccount.companyName] rows.
  void reconcileCorporateDropdownSelection(
    List<CashierCorporateAccount> accounts,
  ) {
    if (accounts.isEmpty) {
      if (_selectedCorporate != null || _selectedCorporateData != null) {
        _selectedCorporate = null;
        _selectedCorporateData = null;
        notifyListeners();
      }
      return;
    }

    final sid = _selectedCorporate;
    if (sid != null && accounts.any((c) => c.id == sid)) {
      final m = accounts.firstWhere((c) => c.id == sid);
      if (_selectedCorporateData?.id != m.id) {
        _selectedCorporateData = m;
        notifyListeners();
      }
      return;
    }

    if (sid != null && sid.isNotEmpty) {
      final byName = accounts.where((c) => c.companyName == sid).toList();
      if (byName.isNotEmpty) {
        final pick =
            (_selectedCorporateData != null &&
                accounts.any((c) => c.id == _selectedCorporateData!.id))
            ? accounts.firstWhere((c) => c.id == _selectedCorporateData!.id)
            : byName.first;
        _selectedCorporate = pick.id;
        _selectedCorporateData = pick;
        notifyListeners();
        return;
      }
    }

    if (_selectedCorporateData != null &&
        accounts.any((c) => c.id == _selectedCorporateData!.id)) {
      final m = accounts.firstWhere((c) => c.id == _selectedCorporateData!.id);
      _selectedCorporate = m.id;
      _selectedCorporateData = m;
      notifyListeners();
      return;
    }

    if (_selectedCorporate != null || _selectedCorporateData != null) {
      _selectedCorporate = null;
      _selectedCorporateData = null;
      notifyListeners();
    }
  }

  List<String> _makes = KsaVehicleCatalog.makes;
  final Map<String, List<String>> _modelsByMake = {};
  bool _isLoadingMakes = false;
  final Set<String> _loadingModelsForMakes = <String>{};

  List<String> get makes => _makes;
  bool get isLoadingMakes => _isLoadingMakes;
  List<SearchedCustomer> _vehicleHistorySuggestions = const [];
  List<SearchedCustomer> _mobileHistorySuggestions = const [];

  /// Shown when the field is focused with no / short query (same API + limit).
  List<SearchedCustomer> _historyFocusHints = const [];
  bool _historyFocusHintsLoading = false;
  bool _isSearchingVehicleHistory = false;
  bool _isSearchingMobileHistory = false;
  Timer? _vehicleHistorySearchDebounce;
  Timer? _mobileHistorySearchDebounce;
  int _vehicleHistorySearchVersion = 0;
  int _mobileHistorySearchVersion = 0;
  bool _disposed = false;

  List<SearchedCustomer> get vehicleHistorySuggestions =>
      _vehicleHistorySuggestions;
  List<SearchedCustomer> get mobileHistorySuggestions =>
      _mobileHistorySuggestions;
  List<SearchedCustomer> get historyFocusHints => _historyFocusHints;
  bool get isSearchingVehicleHistory => _isSearchingVehicleHistory;
  bool get isSearchingMobileHistory => _isSearchingMobileHistory;

  bool hasExactMake(String value) {
    return KsaVehicleCatalog.hasMake(value);
  }

  Future<void> loadMakes({bool forceRefresh = false}) async {
    if (_isLoadingMakes) return;
    if (!forceRefresh && _makes.isNotEmpty) return;
    _isLoadingMakes = true;
    notifyListeners();
    try {
      _makes = KsaVehicleCatalog.makes;
    } finally {
      _isLoadingMakes = false;
      notifyListeners();
    }
  }

  Future<void> loadModelsForMake(
    String make, {
    bool forceRefresh = false,
  }) async {
    final key = make.trim();
    if (key.isEmpty) return;
    if (!forceRefresh && _modelsByMake.containsKey(key)) return;
    if (_loadingModelsForMakes.contains(key)) return;

    _loadingModelsForMakes.add(key);
    notifyListeners();
    try {
      _modelsByMake[key] = KsaVehicleCatalog.modelsForMake(key);
    } finally {
      _loadingModelsForMakes.remove(key);
      notifyListeners();
    }
  }

  bool isLoadingModelsForMake(String make) =>
      _loadingModelsForMakes.contains(make.trim());

  List<String> makeSuggestions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _makes.take(20).toList();
    return _makes.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }

  List<String> modelSuggestions({required String make, required String query}) {
    final models = _modelsByMake[make.trim()] ?? const <String>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return models.take(20).toList();
    return models.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }

  static const String _hintLimit = '4';

  /// A few customers for empty / short query (backend requires name or phone; [limit] caps rows).
  Future<void> loadCustomerHistoryFocusHints() async {
    if (_historyFocusHints.isNotEmpty || _historyFocusHintsLoading) return;
    _historyFocusHintsLoading = true;
    try {
      final posVm = context.read<PosViewModel>();
      final token = await posVm.sessionService.getToken();
      if (token == null) return;

      List<SearchedCustomer> found = [];
      for (final params in <Map<String, String>>[
        {'phone': '5', 'limit': _hintLimit},
        {'name': 'a', 'limit': _hintLimit},
        {'name': 'ا', 'limit': _hintLimit},
      ]) {
        final response = await posVm.posRepository.searchCustomers(
          params,
          token,
        );
        if (response.customers.isNotEmpty) {
          found = response.customers.take(4).toList();
          break;
        }
      }
      _historyFocusHints = found;
    } catch (_) {
      _historyFocusHints = const [];
    } finally {
      _historyFocusHintsLoading = false;
      notifyListeners();
    }
  }

  /// Plate / partial plate search. Use `vehicleNumber` so plate digits do not
  /// accidentally match mobile numbers, and normalize UI form (`ABC - 1234`) to
  /// API form (`1234ABC`).
  Future<List<SearchedCustomer>> fetchCustomerHistoryByVehicleOptions(
    String query,
  ) async {
    final q = query.trim();
    if (q.length < 2) return historyFocusHints;

    _vehicleHistorySearchVersion++;
    _isSearchingVehicleHistory = true;
    notifyListeners();
    try {
      if (_disposed) return const [];
      final posVm = context.read<PosViewModel>();
      final token = await posVm.sessionService.getToken();
      if (_disposed || token == null) return const [];

      final normalized = canonicalGccPlateForApi(
        q,
        countryCode: _normalPlateCountry,
        emirate: _normalPlateEmirate,
      );
      var response = await posVm.posRepository.searchCustomers({
        'vehicleNumber': normalized.isNotEmpty ? normalized : q,
        'limit': '20',
      }, token);

      if (!response.success || response.customers.isEmpty) {
        response = await posVm.posRepository.searchCustomers({
          'vehicleNumber': q,
          'limit': '20',
        }, token);
      }

      final results = response.success
          ? _dedupeCustomersById(response.customers)
          : const <SearchedCustomer>[];
      _vehicleHistorySuggestions = results;
      return results;
    } catch (_) {
      _vehicleHistorySuggestions = const [];
      return const [];
    } finally {
      if (!_disposed) {
        _isSearchingVehicleHistory = false;
        notifyListeners();
      }
    }
  }

  Future<List<SearchedCustomer>> fetchCustomerHistoryByMobileOptions(
    String query,
  ) async {
    final q = digitsOnlyPhone(query);
    if (q.length < 3) return historyFocusHints;

    _mobileHistorySearchVersion++;
    _isSearchingMobileHistory = true;
    notifyListeners();
    try {
      if (_disposed) return const [];
      final posVm = context.read<PosViewModel>();
      final token = await posVm.sessionService.getToken();
      if (_disposed || token == null) return const [];

      final response = await posVm.posRepository.searchCustomers({
        'phone': q,
        'limit': '20',
      }, token);

      final results = response.success
          ? _dedupeCustomersById(response.customers)
          : const <SearchedCustomer>[];
      _mobileHistorySuggestions = results;
      return results;
    } catch (_) {
      _mobileHistorySuggestions = const [];
      return const [];
    } finally {
      if (!_disposed) {
        _isSearchingMobileHistory = false;
        notifyListeners();
      }
    }
  }

  void searchCustomerHistoryByVehicle(String query) {
    _vehicleHistorySearchDebounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      _vehicleHistorySearchVersion++;
      _isSearchingVehicleHistory = false;
      _vehicleHistorySuggestions = const [];
      notifyListeners();
      return;
    }
    final requestVersion = ++_vehicleHistorySearchVersion;
    _isSearchingVehicleHistory = true;
    notifyListeners();
    _vehicleHistorySearchDebounce = Timer(
      const Duration(milliseconds: 120),
      () async {
        try {
          if (_disposed) return;
          final posVm = context.read<PosViewModel>();
          final token = await posVm.sessionService.getToken();
          if (_disposed || requestVersion != _vehicleHistorySearchVersion) {
            return;
          }
          if (token == null) {
            _vehicleHistorySuggestions = const [];
            return;
          }
          final normalized = canonicalGccPlateForApi(
            q,
            countryCode: _normalPlateCountry,
            emirate: _normalPlateEmirate,
          );
          var response = await posVm.posRepository.searchCustomers({
            'vehicleNumber': normalized.isNotEmpty ? normalized : q,
            'limit': '20',
          }, token);
          if (_disposed || requestVersion != _vehicleHistorySearchVersion) {
            return;
          }
          if (!response.success || response.customers.isEmpty) {
            response = await posVm.posRepository.searchCustomers({
              'vehicleNumber': q,
              'limit': '20',
            }, token);
            if (_disposed || requestVersion != _vehicleHistorySearchVersion) {
              return;
            }
          }
          _vehicleHistorySuggestions = response.success
              ? _dedupeCustomersById(response.customers)
              : const [];
        } catch (_) {
          if (_disposed || requestVersion != _vehicleHistorySearchVersion) {
            return;
          }
          _vehicleHistorySuggestions = const [];
        } finally {
          if (!_disposed && requestVersion == _vehicleHistorySearchVersion) {
            _isSearchingVehicleHistory = false;
            notifyListeners();
          }
        }
      },
    );
  }

  /// National mobile field: search by phone only. This avoids vehicle plate
  /// digits and order IDs polluting mobile autocomplete results.
  void searchCustomerHistoryByMobile(String query) {
    _mobileHistorySearchDebounce?.cancel();
    final q = digitsOnlyPhone(query);
    if (q.length < 3) {
      _mobileHistorySearchVersion++;
      _isSearchingMobileHistory = false;
      _mobileHistorySuggestions = const [];
      notifyListeners();
      return;
    }
    final requestVersion = ++_mobileHistorySearchVersion;
    _isSearchingMobileHistory = true;
    notifyListeners();
    _mobileHistorySearchDebounce = Timer(
      const Duration(milliseconds: 160),
      () async {
        try {
          if (_disposed) return;
          final posVm = context.read<PosViewModel>();
          final token = await posVm.sessionService.getToken();
          if (_disposed || requestVersion != _mobileHistorySearchVersion) {
            return;
          }
          if (token == null) {
            _mobileHistorySuggestions = const [];
            return;
          }
          final response = await posVm.posRepository.searchCustomers({
            'phone': q,
            'limit': '20',
          }, token);
          if (_disposed || requestVersion != _mobileHistorySearchVersion) {
            return;
          }
          _mobileHistorySuggestions = response.success
              ? _dedupeCustomersById(response.customers)
              : const [];
        } catch (_) {
          if (_disposed || requestVersion != _mobileHistorySearchVersion) {
            return;
          }
          _mobileHistorySuggestions = const [];
        } finally {
          if (!_disposed && requestVersion == _mobileHistorySearchVersion) {
            _isSearchingMobileHistory = false;
            notifyListeners();
          }
        }
      },
    );
  }

  List<SearchedCustomer> _dedupeCustomersById(
    List<SearchedCustomer> customers,
  ) {
    final byId = <String, SearchedCustomer>{};
    for (final c in customers) {
      final id = c.id.trim();
      if (id.isEmpty) continue;
      byId.putIfAbsent(id, () => c);
    }
    return byId.values.toList();
  }

  int _customerPrefillRebuildToken = 0;
  int get customerPrefillRebuildToken => _customerPrefillRebuildToken;

  /// Vehicle from the newest order that has usable plate/make/model/vin data.
  SearchedCustomerVehicle? historyVehicleSnapshot(SearchedCustomer c) =>
      c.vehicleSnapshot;

  void prefillFromCustomer(SearchedCustomer customer) {
    final best = customer.bestOrderWithVehicle;
    final vehicle = best?.vehicle;

    nameController.text = customer.name.trim();
    final tax = (customer.taxId ?? '').trim();
    if (tax.isNotEmpty) vatController.text = tax;

    _applyInternationalMobileToField(customer.mobile);

    if ((vehicle?.resolvedPlate ?? '').trim().isNotEmpty) {
      vehicleNumberController.text = formatVehiclePlateLettersFirst(
        vehicle!.resolvedPlate.trim(),
      );
    }
    if ((vehicle?.make ?? '').trim().isNotEmpty) {
      makeController.text = vehicle!.make.trim();
      loadModelsForMake(makeController.text);
    }
    if ((vehicle?.model ?? '').trim().isNotEmpty) {
      modelController.text = vehicle!.model.trim();
    }
    if ((vehicle?.vin ?? '').trim().isNotEmpty) {
      vinNumberController.text = vehicle!.vin!.trim();
    }
    if ((best?.odometerReading ?? 0) > 0) {
      odoMeterController.text = best!.odometerReading.toString();
    }

    // Autocomplete uses its own internal TextEditingController; bump token so
    // those widgets rebuild and pick up the updated external controllers.
    _customerPrefillRebuildToken++;
    notifyListeners();
  }

  Future<void> retranslate() async {
    AppTranslationService.clearCache();
    notifyListeners();
  }

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  void _hydrateFromSavedCustomer() {
    final vm = context.read<PosViewModel>();
    nameController.text = vm.customerName;
    vatController.text = vm.vatNumber;
    _applyInternationalMobileToField(vm.mobile);
    _normalPlateCountry = vm.vehiclePlateCountry;
    _normalPlateEmirate = vm.vehiclePlateEmirate;
    vehicleNumberController.text = formatVehiclePlateLettersFirst(
      vm.vehicleNumber.trim(),
    );

    final oid = (vm.selectedOrder?.id ?? '').trim();
    final hasBillingDraft =
        oid.isNotEmpty && vm.walkInBillingSnapshotForOrder(oid) != null;
    final continuingShell = (vm.walkInDraftOrderId ?? '').trim().isNotEmpty;

    if (hasBillingDraft || continuingShell) {
      vinNumberController.text = vm.vinNumber;
      makeController.text = vm.make;
      modelController.text = vm.model;
      odoMeterController.text = vm.odometerReading > 0
          ? vm.odometerReading.toString()
          : '';
      final y = vm.vehicleYear.trim();
      _normalVehicleYear = y.isNotEmpty ? y : null;
    } else {
      vinNumberController.text = '';
      makeController.text = '';
      modelController.text = '';
      odoMeterController.text = '';
      _normalVehicleYear = null;
    }
  }

  void setCorporate(String accountId, CashierCorporateAccount? data) {
    _selectedCorporate = accountId;
    _selectedCorporateData = data;
    _selectedCorporateFleetVehicleId = null;
    _corporateFleetVehicles = [];
    _clearCorporateVehicleFieldsOnly();
    _prefillCorporateContactFields(data);
    loadCorporateFleetVehicles();
    notifyListeners();
  }

  Future<void> loadCorporateFleetVehicles() async {
    final corpId = _selectedCorporate?.trim();
    if (corpId == null || corpId.isEmpty) {
      _corporateFleetVehicles = [];
      _corporateFleetVehiclesLoading = false;
      notifyListeners();
      return;
    }
    _corporateFleetVehiclesLoading = true;
    notifyListeners();
    try {
      final posVm = context.read<PosViewModel>();
      final token = await posVm.sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posVm.posRepository.getCorporateAccountVehicles(
        token,
        corpId,
      );
      _corporateFleetVehicles = res.success ? res.vehicles : [];
      _restoreFleetSelectionFromPosVm();
    } catch (_) {
      _corporateFleetVehicles = [];
    } finally {
      _corporateFleetVehiclesLoading = false;
      notifyListeners();
    }
  }

  /// Restore corporate account + fleet pick when returning to Add Customer with saved POS state.
  void tryHydrateCorporateAccountFromPosVm(
    List<CashierCorporateAccount> accounts,
  ) {
    if (_selectedCorporate != null || accounts.isEmpty) return;
    final posVm = context.read<PosViewModel>();
    final corpId = posVm.corporateAccountId?.trim();
    if (corpId == null || corpId.isEmpty) return;
    final match = accounts.where((c) => c.id == corpId);
    if (match.isEmpty) return;
    setCorporate(corpId, match.first);
  }

  void _restoreFleetSelectionFromPosVm() {
    if (_corporateFleetVehicles.isEmpty) return;
    final posVm = context.read<PosViewModel>();
    final savedId = posVm.corporateFleetVehicleId?.trim();
    if (savedId != null && savedId.isNotEmpty) {
      final match = _corporateFleetVehicles.where((v) => v.id == savedId);
      if (match.isNotEmpty) {
        selectCorporateFleetVehicle(savedId);
        return;
      }
    }
    final plateNorm = canonicalGccPlateForApi(
      posVm.vehicleNumber,
      countryCode: _corpPlateCountry,
      emirate: _corpPlateEmirate,
    ).trim().toUpperCase();
    if (plateNorm.isEmpty) return;
    for (final v in _corporateFleetVehicles) {
      final p = canonicalGccPlateForApi(
        v.plateDisplay ?? v.plateNo,
        countryCode: _corpPlateCountry,
        emirate: _corpPlateEmirate,
      ).trim().toUpperCase();
      if (p.isNotEmpty && p == plateNorm) {
        selectCorporateFleetVehicle(v.id);
        return;
      }
    }
  }

  void selectCorporateFleetVehicle(String? vehicleId) {
    if (vehicleId == null || vehicleId.trim().isEmpty) {
      _selectedCorporateFleetVehicleId = null;
      _clearCorporateVehicleFieldsOnly();
      notifyListeners();
      return;
    }
    final match = _corporateFleetVehicles.where((v) => v.id == vehicleId);
    if (match.isEmpty) {
      _selectedCorporateFleetVehicleId = null;
      notifyListeners();
      return;
    }
    _selectedCorporateFleetVehicleId = vehicleId;
    _prefillCorporateVehicleFields(match.first);
    notifyListeners();
  }

  void _clearCorporateVehicleFieldsOnly() {
    corpVehicleNumberController.clear();
    corpVinNumberController.clear();
    corpMakeController.clear();
    corpModelController.clear();
    corpOdoMeterController.clear();
    _corpVehicleYear = null;
  }

  void _prefillCorporateVehicleFields(CashierCorporateFleetVehicle vehicle) {
    _suppressFleetSelectionClear = true;
    final plate = (vehicle.plateDisplay ?? vehicle.plateNo).trim();
    if (plate.isNotEmpty) {
      corpVehicleNumberController.text = formatVehiclePlateLettersFirst(plate);
    }
    final make = (vehicle.make ?? '').trim();
    if (make.isNotEmpty) {
      corpMakeController.text = make;
      loadModelsForMake(make);
    } else {
      corpMakeController.clear();
    }
    final model = (vehicle.model ?? '').trim();
    corpModelController.text = model;
    final vin = (vehicle.carNo ?? '').trim();
    corpVinNumberController.text = vin.toUpperCase();
    if (vehicle.year != null && vehicle.year! > 0) {
      _corpVehicleYear = vehicle.year.toString();
    } else {
      _corpVehicleYear = null;
    }
    if (vehicle.odometer > 0) {
      corpOdoMeterController.text = vehicle.odometer.toString();
    } else {
      corpOdoMeterController.clear();
    }
    _customerPrefillRebuildToken++;
    _suppressFleetSelectionClear = false;
  }

  /// Fills Customer Name / Mobile from corporate account contact (portal user + customer.mobile).
  void _prefillCorporateContactFields(CashierCorporateAccount? data) {
    if (data == null) return;

    final contactName = data.posContactName;
    if (contactName != null && contactName.isNotEmpty) {
      nameController.text = contactName;
    }

    final phone = data.posContactPhone;
    if (phone != null && phone.isNotEmpty) {
      _applyCorporatePhoneToField(phone);
      // Mobile uses Autocomplete's internal controller — rebuild to show prefilled value.
      _customerPrefillRebuildToken++;
    }
  }

  /// Corporate billing numbers may be PK/UAE/etc. — show digits without forcing KSA-only shape.
  void _applyCorporatePhoneToField(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      mobileController.text = '';
      return;
    }
    var d = digitsOnlyPhone(trimmed);
    if (d.startsWith('966') && d.length > 3) {
      d = d.substring(3);
      _mobileDialCountry = PosAddCustomerMobileDial.saudiArabia;
      mobileController.text = PosAddCustomerPhoneFormat.formatDigits(
        _mobileDialCountry,
        d,
      );
      return;
    }
    if (d.startsWith('92') && d.length > 2) {
      d = d.substring(2);
    }
    if (d.startsWith('05') && d.length >= 10) {
      _mobileDialCountry = PosAddCustomerMobileDial.saudiArabia;
      mobileController.text = PosAddCustomerPhoneFormat.formatDigits(
        _mobileDialCountry,
        d.startsWith('0') ? d.substring(1) : d,
      );
      return;
    }
    mobileController.text = trimmed.replaceAll(RegExp(r'[^\d+\s-]'), '').trim();
  }

  void saveAndProceed({
    required bool isNormal,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) {
    final vm = context.read<PosViewModel>();
    final l10n = AppLocalizations.of(context)!;

    final composedMobile =
        isNormal ? composedInternationalMobile() : composedCorporateMobile();
    const pickEmp = false;
    vm.saveCustomerAndProceed(
      isNormal: isNormal,
      name: nameController.text.trim(),
      vat: isNormal ? vatController.text.trim() : '',
      mobile: composedMobile.isNotEmpty ? composedMobile : '',
      vehicleNumber: isNormal
          ? parseNormalPlateRegistration().display
          : parseCorpPlateRegistration().display,
      vehiclePlateCountry: isNormal
          ? (isNormalBike ? 'SA' : _normalPlateCountry)
          : (isCorpBike ? 'SA' : _corpPlateCountry),
      vehiclePlateEmirate: isNormal
          ? (isNormalBike ? null : _normalPlateEmirate)
          : (isCorpBike ? null : _corpPlateEmirate),
      vinNumber: isNormal
          ? vinNumberController.text.trim().toUpperCase()
          : corpVinNumberController.text.trim().toUpperCase(),
      make: isNormal
          ? makeController.text.trim()
          : corpMakeController.text.trim(),
      model: isNormal
          ? modelController.text.trim()
          : corpModelController.text.trim(),
      odometerStr: isNormal
          ? odoMeterController.text.trim()
          : corpOdoMeterController.text.trim(),
      selectedCorporateData: _selectedCorporateData,
      onSuccess: onSuccess,
      onError: onError,
      billingCustomerIsEmployee: pickEmp,
      billingEmployeeId: pickEmp ? _branchEmployeePickSelection?.id : null,
      billingEmployeeType: pickEmp
          ? _branchEmployeePickSelection?.employeeType
          : null,
      vehicleYear: isNormal
          ? (_normalVehicleYear ?? '')
          : (_corpVehicleYear ?? ''),
      corporateFleetVehicleId: isNormal
          ? null
          : _selectedCorporateFleetVehicleId,
    );
    nameController.clear();
    mobileController.clear();
    if (isNormal) {
      vatController.clear();
      _pickBranchEmployeeMode = false;
      _branchEmployeePickSelection = null;
    }
    _normalVehicleYear = null;
    _corpVehicleYear = null;
  }

  void _resetCustomerHistoryCaches() {
    _vehicleHistorySearchDebounce?.cancel();
    _mobileHistorySearchDebounce?.cancel();
    _vehicleHistorySearchVersion++;
    _mobileHistorySearchVersion++;
    _vehicleHistorySuggestions = const [];
    _mobileHistorySuggestions = const [];
    _historyFocusHints = const [];
    _historyFocusHintsLoading = false;
    _isSearchingVehicleHistory = false;
    _isSearchingMobileHistory = false;
    _customerPrefillRebuildToken++;
  }

  /// Clears normal-customer fields, branch-employee pick, and history caches.
  void clearNormalCustomerFields() {
    nameController.clear();
    vatController.clear();
    mobileController.clear();
    vehicleNumberController.clear();
    vinNumberController.clear();
    makeController.clear();
    modelController.clear();
    odoMeterController.clear();
    _normalPlateCountry = GccPlateCountry.sa.code;
    _normalPlateEmirate = UaeEmirate.all[1].key;
    _normalVehicleKind = PosAddCustomerVehicleKind.car;
    _normalVehicleYear = null;
    _mobileDialCountry = PosAddCustomerMobileDial.saudiArabia;
    _pickBranchEmployeeMode = false;
    _branchEmployeePickSelection = null;
    _resetCustomerHistoryCaches();
    notifyListeners();
  }

  /// Clears corporate account selection, corporate vehicle fields, and history caches.
  void clearCorporateCustomerFields() {
    _selectedCorporate = null;
    _selectedCorporateData = null;
    _corporateFleetVehicles = [];
    _corporateFleetVehiclesLoading = false;
    _selectedCorporateFleetVehicleId = null;
    corpVehicleNumberController.clear();
    corpVinNumberController.clear();
    corpMakeController.clear();
    corpModelController.clear();
    corpOdoMeterController.clear();
    _corpPlateCountry = GccPlateCountry.sa.code;
    _corpPlateEmirate = UaeEmirate.all[1].key;
    _corpVehicleKind = PosAddCustomerVehicleKind.car;
    _corpVehicleYear = null;
    _resetCustomerHistoryCaches();
    notifyListeners();
  }

  void clearAllFields() {
    nameController.clear();
    vatController.clear();
    mobileController.clear();
    vehicleNumberController.clear();
    vinNumberController.clear();
    makeController.clear();
    modelController.clear();
    odoMeterController.clear();
    corpVehicleNumberController.clear();
    corpVinNumberController.clear();
    corpMakeController.clear();
    corpModelController.clear();
    corpOdoMeterController.clear();
    _selectedCorporate = null;
    _selectedCorporateData = null;
    _mobileDialCountry = PosAddCustomerMobileDial.saudiArabia;
    _pickBranchEmployeeMode = false;
    _branchEmployeePickSelection = null;
    _branchEmployeesPickList = [];
    _normalVehicleYear = null;
    _corpVehicleYear = null;
    _resetCustomerHistoryCaches();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _vehicleHistorySearchDebounce?.cancel();
    _mobileHistorySearchDebounce?.cancel();
    unbindLocaleRetranslation();
    nameController.dispose();
    vatController.dispose();
    mobileController.dispose();
    vehicleNumberController.dispose();
    vinNumberController.dispose();
    makeController.dispose();
    modelController.dispose();
    odoMeterController.dispose();
    corpVehicleNumberController.dispose();
    corpVinNumberController.dispose();
    corpMakeController.dispose();
    corpModelController.dispose();
    corpOdoMeterController.dispose();
    super.dispose();
  }
}

/// Calendar years for vehicle year dropdown (current year back 40 years).
List<String> vehicleModelYearChoices() {
  final y = DateTime.now().year;
  return List<String>.generate(41, (i) => '${y - i}');
}
