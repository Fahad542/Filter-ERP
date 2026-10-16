import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

// ---------------------------------------------------------------------------
// BillingManagementViewModel
//
// Static UI labels → AppLocalizations (ARB/gen-l10n) resolved in the View.
// Dynamic API strings (customer names, status values) → translated here via
// [TranslatableMixin] before being exposed to the UI.
//
// Re-translation on locale switch
// ────────────────────────────────
// The VM observes [SettingsViewModel]. Whenever the locale changes the
// observer calls [_onLocaleChanged], which clears the translation cache and
// re-runs [fetchDashboardData] so every API string is re-translated into the
// new locale. The View's Consumer<BillingManagementViewModel> then rebuilds
// automatically.
// ---------------------------------------------------------------------------

class BillingManagementViewModel extends ChangeNotifier
    with TranslatableMixin {
  final OwnerRepository   ownerRepository;
  final SessionService    sessionService;
  final SettingsViewModel settingsViewModel;

  BillingManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.settingsViewModel,
  }) {
    // Listen for locale changes so we re-translate API data automatically.
    settingsViewModel.addListener(_onLocaleChanged);
    _init();
  }

  // ── State ─────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Raw bills as returned from the API — never mutated after fetch.
  List<MonthlyBill> _rawBills = [];

  /// Translated bills exposed to the UI.
  List<MonthlyBill> _monthlyBills = [];
  List<MonthlyBill> get monthlyBills => _monthlyBills;

  double _totalBilledMonth   = 0.0;
  double get totalBilledMonth   => _totalBilledMonth;

  double _totalReceivedMonth = 0.0;
  double get totalReceivedMonth => _totalReceivedMonth;

  double _totalOutstanding   = 0.0;
  double get totalOutstanding   => _totalOutstanding;

  double _overdueAmount      = 0.0;
  double get overdueAmount      => _overdueAmount;

  // ── Locale change handler ─────────────────────────────────────────────────

  String _lastLocale = '';

  void _onLocaleChanged() {
    final newLocale = settingsViewModel.locale.languageCode;
    if (newLocale == _lastLocale) return;
    _lastLocale = newLocale;

    // Clear the in-memory translation cache so stale translations are evicted.
    AppTranslationService.clearCache();

    // Re-translate the already-fetched raw bills for the new locale without
    // hitting the network for the summary figures (they are locale-agnostic).
    _retranslateBills();
  }

  /// Re-translates [_rawBills] into the current locale and notifies listeners.
  Future<void> _retranslateBills() async {
    if (_rawBills.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _monthlyBills = await Future.wait(_rawBills.map(_translateBill));

    _isLoading = false;
    notifyListeners();
  }

  // ── Init & fetch ──────────────────────────────────────────────────────────

  Future<void> _init() async {
    _lastLocale = settingsViewModel.locale.languageCode;
    await fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final response = await ownerRepository.getBillingDashboard(token);

      if (response != null && response['success'] == true) {
        _totalBilledMonth   = double.tryParse(response['totalBilled']?.toString()  ?? '0') ?? 0.0;
        _totalReceivedMonth = double.tryParse(response['totalReceived']?.toString() ?? '0') ?? 0.0;
        _totalOutstanding   = double.tryParse(response['outstanding']?.toString()   ?? '0') ?? 0.0;
        _overdueAmount      = double.tryParse(response['overdue']?.toString()       ?? '0') ?? 0.0;

        if (response['recentBillingActivity'] != null) {
          // Store raw bills so we can re-translate without re-fetching.
          _rawBills = (response['recentBillingActivity'] as List)
              .map((activity) => MonthlyBill.fromJson(activity))
              .toList();

          _monthlyBills = await Future.wait(_rawBills.map(_translateBill));
        }
      }
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Translation helpers ───────────────────────────────────────────────────

  /// Translates the mutable display fields of a single [MonthlyBill].
  /// Both [customerName] and [status] originate from the API.
  Future<MonthlyBill> _translateBill(MonthlyBill bill) async {
    final customerName = await tParty(bill.customerName);
    final status       = await tStatus(bill.status);
    return bill.copyWith(
      translatedCustomerName: customerName,
      translatedStatus:       status,
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    settingsViewModel.removeListener(_onLocaleChanged);
    super.dispose();
  }
}