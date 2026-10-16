import 'package:flutter/material.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../Workshop owner/Suppliers/filter_affiliated_suppliers_models.dart';


class AffiliatedSuppliersViewModel extends ChangeNotifier {
  final AffiliatedSuppliersRepository repository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  String? _lastSyncedBranchId;

  AffiliatedSuppliersViewModel({
    required this.repository,
    required this.sessionService,
    required this.ownerDataService,
  }) {
    _lastSyncedBranchId = ownerDataService.selectedBranchId;
  }

  // ───────────────────────────────────────────────────────────────────────
  // Suppliers list (FilterAffiliatedSuppliersView)
  // ───────────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadError;
  String? get loadError => _loadError;

  List<AffiliatedSupplier> _suppliers = [];
  List<AffiliatedSupplier> get suppliers => _suppliers;

  double get aggregatePayable =>
      _suppliers.fold(0, (sum, s) => sum + s.finalBalance);

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = ownerDataService.selectedBranchId;
    if (!force && next == _lastSyncedBranchId && _suppliers.isNotEmpty) {
      return;
    }
    _lastSyncedBranchId = next;
    await initData();
  }

  // GET /workshop-suppliers/affiliated?branchId=
  Future<void> initData() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final res = await repository.getAffiliatedSuppliers(
        token,
        branchId: ownerDataService.selectedBranchId,
      );
      _suppliers = res.suppliers;
      _lastSyncedBranchId = ownerDataService.selectedBranchId;
    } catch (e) {
      // Keep the screen usable if a previous successful load already has
      // data on screen — only surface a hard error when there's nothing.
      if (_suppliers.isEmpty) {
        _loadError = 'Could not load affiliated suppliers. Pull down to retry.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => initData();

  // ───────────────────────────────────────────────────────────────────────
  // Add Suppliers (AddAffiliatedSuppliersScreen)
  // ───────────────────────────────────────────────────────────────────────

  bool _isLoadingAvailable = false;
  bool get isLoadingAvailable => _isLoadingAvailable;

  String? _availableError;
  String? get availableError => _availableError;

  List<RegisteredAffiliatedSupplier> _availableSuppliers = [];
  List<RegisteredAffiliatedSupplier> get availableSuppliers =>
      _availableSuppliers;

  bool _isAddingSuppliers = false;
  bool get isAddingSuppliers => _isAddingSuppliers;

  // GET /workshop-suppliers/affiliated/available
  Future<void> loadAvailableSuppliers() async {
    // Dispose any controllers from a previous open of the Add screen before
    // replacing the list, so text controllers never leak.
    for (final s in _availableSuppliers) {
      s.dispose();
    }
    _availableSuppliers = [];
    _isLoadingAvailable = true;
    _availableError = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final res = await repository.getAvailableAffiliatedSuppliers(token);
      _availableSuppliers = res.suppliers;
    } catch (e) {
      _availableError = 'Could not load suppliers. Pull down to retry.';
    } finally {
      _isLoadingAvailable = false;
      notifyListeners();
    }
  }

  // Call when the Add Supplier screen is closed so its row controllers
  // (opening balance / date) don't leak past the screen's lifetime.
  void disposeAvailableSuppliers() {
    for (final s in _availableSuppliers) {
      s.dispose();
    }
    _availableSuppliers = [];
  }

  // POST /workshop-suppliers/affiliated
  // Returns null on success, or a message to show the user on failure.
  Future<String?> addAffiliatedSuppliers({
    required String branchId,
    required List<RegisteredAffiliatedSupplier> selected,
  }) async {
    if (selected.isEmpty) return 'Select at least one supplier.';
    if (branchId.isEmpty) return 'Select a branch first.';

    _isAddingSuppliers = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final items = selected
          .map((s) => {
        'supplierId': s.id,
        'openingBalance': s.openingBalance,
        'openingBalanceDate': s.openingBalanceDateApi,
      })
          .toList();

      final res = await repository.createAffiliatedSuppliers(
        token,
        branchId: branchId,
        items: items,
      );

      if (!res.success) return 'Failed to add suppliers.';

      // Refresh the main list so newly linked suppliers (real ids/balances
      // from the server) show up immediately.
      await initData();
      return null;
    } catch (e) {
      return 'Failed to add suppliers. Please try again.';
    } finally {
      _isAddingSuppliers = false;
      notifyListeners();
    }
  }

  // PATCH /workshop-suppliers/affiliated/{id} — optimistic toggle with rollback.
  // Returns true on success so the caller can show a toast on failure.
  Future<bool> setSupplierActive(AffiliatedSupplier supplier, bool value) async {
    final previous = supplier.isActive;
    supplier.isActive = value;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final res = await repository.toggleAffiliatedSupplierActive(
        token,
        id: supplier.id,
        isActive: value,
      );
      supplier.isActive = res.isActive;
      notifyListeners();
      return true;
    } catch (e) {
      supplier.isActive = previous;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Ledger (AffiliatedSupplierLedgerView) — keyed by supplierId so reopening
  // a different supplier's ledger doesn't show stale data from another one.
  // ───────────────────────────────────────────────────────────────────────

  bool _isLedgerLoading = false;
  bool get isLedgerLoading => _isLedgerLoading;

  String? _ledgerError;
  String? get ledgerError => _ledgerError;

  String? _ledgerSupplierId;
  List<LedgerEntry> _ledgerEntries = const [LedgerEntry.opening()];
  List<LedgerEntry> get ledgerEntries => _ledgerEntries;

  double _ledgerOpeningBalance = 0;
  double get ledgerOpeningBalance => _ledgerOpeningBalance;

  double _ledgerClosingBalance = 0;
  double get ledgerClosingBalance => _ledgerClosingBalance;

  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // GET /workshop-suppliers/affiliated/{supplierId}/ledger?from=...&to=...
  Future<void> loadLedger({
    required String supplierId,
    required DateTime from,
    required DateTime to,
  }) async {
    _ledgerSupplierId = supplierId;
    _isLedgerLoading = true;
    _ledgerError = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final res = await repository.getAffiliatedSupplierLedger(
        token,
        supplierId: supplierId,
        from: _apiDate(from),
        to: _apiDate(to),
      );

      // Guard against a stale response landing after the user already
      // navigated to a different supplier's ledger / changed dates again.
      if (_ledgerSupplierId != supplierId) return;

      _ledgerEntries = res.toDisplayEntries();
      _ledgerOpeningBalance = res.openingBalance;
      _ledgerClosingBalance = res.totals.closingBalance;
    } catch (e) {
      if (_ledgerSupplierId != supplierId) return;
      _ledgerError = 'Failed to load ledger. Pull down to retry.';
    } finally {
      if (_ledgerSupplierId == supplierId) {
        _isLedgerLoading = false;
        notifyListeners();
      }
    }
  }
}