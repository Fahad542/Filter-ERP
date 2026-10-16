import 'package:flutter/material.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../models/department_model.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';

// =============================================================================
// DiscountsViewModel
// =============================================================================
//
// Backed by GET /workshop-staff/discounts.
//
// • Filters: dateFrom, dateTo, branchId (header), departmentId — all server-side.
// • Local search (invoice #) filters the already-fetched list — no extra request.
// • Per-filter-combo cache avoids redundant calls during the session.
// • Pull-to-refresh always bypasses the cache.
// • Stale-request guard (_requestId) ensures fast filter changes never let an
//   old response overwrite a newer one.

class DiscountsViewModel extends ChangeNotifier {
  final OwnerRepository _ownerRepository;
  final SessionService _sessionService;
  final OwnerDataService _ownerDataService;
  String? _lastSyncedBranchId;

  DiscountsViewModel({
    required OwnerRepository ownerRepository,
    required SessionService sessionService,
    required OwnerDataService ownerDataService,
  })  : _ownerRepository = ownerRepository,
        _sessionService = sessionService,
        _ownerDataService = ownerDataService {
    _lastSyncedBranchId = _ownerDataService.selectedBranchId;
    _lastSyncedDateGeneration = _ownerDataService.dateGeneration;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_ownerDataService.departments.isEmpty) {
      await _ownerDataService.fetchDepartments(silent: true);
      notifyListeners();
    }
    await _fetchAndFilter();
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  String? _departmentId; // null = all
  String? _invoiceSearch;
  int _lastSyncedDateGeneration = -1;

  DateTime get fromDate => _ownerDataService.filterFrom;
  DateTime get toDate => _ownerDataService.filterTo;
  String? get departmentId => _departmentId;
  /// Backward-compatible alias used by filter panel clear-check.
  String? get department => _departmentId;
  String? get invoiceSearch => _invoiceSearch;


  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Data ──────────────────────────────────────────────────────────────────
  WorkshopDiscountSummary _summary = WorkshopDiscountSummary.empty;
  List<WorkshopDiscountInvoice> _fetched = []; // raw from API
  List<WorkshopDiscountInvoice> _filtered = []; // after local search

  WorkshopDiscountSummary get summary => _summary;
  List<WorkshopDiscountInvoice> get invoices => _filtered;
  String get currency => 'SAR';

  /// Catalog departments for the filter pill (id + name).
  List<Department> get departmentOptions {
    final list = _ownerDataService.departments
        .where((d) => d.id.trim().isNotEmpty)
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  String? get departmentLabel {
    if (_departmentId == null) return null;
    for (final d in departmentOptions) {
      if (d.id == _departmentId) return d.name;
    }
    return _departmentId;
  }

  // Cache: cacheKey -> fetched items
  final Map<String, List<WorkshopDiscountInvoice>> _cache = {};
  final Map<String, WorkshopDiscountSummary> _summaryCache = {};
  int _requestId = 0;

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerDataService.selectedBranchId;
    final nextDateGen = _ownerDataService.dateGeneration;
    if (!force &&
        next == _lastSyncedBranchId &&
        nextDateGen == _lastSyncedDateGeneration &&
        _fetched.isNotEmpty) {
      return;
    }
    _lastSyncedBranchId = next;
    _lastSyncedDateGeneration = nextDateGen;
    _cache.clear();
    _summaryCache.clear();
    if (_ownerDataService.departments.isEmpty) {
      await _ownerDataService.fetchDepartments(silent: true);
    }
    await _fetchAndFilter(forceRefresh: true);
  }

  // ── Filter setters ─────────────────────────────────────────────────────────
  Future<void> applyFilterStartDate(DateTime d) async {
    _ownerDataService.setFilterFrom(d);
  }

  Future<void> applyFilterEndDate(DateTime d) async {
    _ownerDataService.setFilterTo(d);
  }

  void setDepartment(String? departmentId) {
    final next =
        (departmentId == null || departmentId.isEmpty) ? null : departmentId;
    if (_departmentId == next) return;
    _departmentId = next;
    notifyListeners();
  }

  /// Local search — client-side, no network call.
  void setInvoiceSearch(String? q) {
    final next = (q?.trim().isEmpty == true) ? null : q?.trim();
    if (_invoiceSearch == next) return;
    _invoiceSearch = next;
    _applyLocalFilter();
    notifyListeners();
  }

  /// Called when the user taps "Apply".
  Future<void> applyFilters() => _fetchAndFilter();

  void clearFilters() {
    _departmentId = null;
    _invoiceSearch = null;
    _fetchAndFilter(forceRefresh: true);
  }

  Future<void> refresh() => _fetchAndFilter(forceRefresh: true);

  // ── Date helpers ──────────────────────────────────────────────────────────
  /// Inclusive through the selected end minute (same as Reports).
  DateTime get _toDateInclusive => DateTime(
        toDate.year,
        toDate.month,
        toDate.day,
        toDate.hour,
        toDate.minute,
        59,
        999,
      );

  /// Full ISO instants so the API applies time-of-day (not calendar day only).
  String get _dateFromParam =>
      OwnerRepository.reportsRangeStartIso(fromDate);

  String get _dateToParam =>
      OwnerRepository.reportsRangeEndIso(toDate);

  String? get _branchIdParam => _ownerDataService.selectedBranchId;

  String _cacheKey() =>
      '${_branchIdParam ?? 'all'}|${_departmentId ?? 'all'}|'
      '$_dateFromParam|$_dateToParam';

  // ── Core fetch ─────────────────────────────────────────────────────────────
  Future<void> _fetchAndFilter({bool forceRefresh = false}) async {
    final key = _cacheKey();
    final myRequest = ++_requestId;

    if (!forceRefresh && _cache.containsKey(key)) {
      _fetched = _cache[key]!;
      _summary = _summaryCache[key] ?? WorkshopDiscountSummary.empty;
      _applyLocalFilter();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _sessionService.getToken(role: 'owner');
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      final response = await _ownerRepository.getDiscounts(
        token,
        dateFrom: _dateFromParam,
        dateTo: _dateToParam,
        branchId: _branchIdParam,
        departmentId: _departmentId,
        limit: 200,
        offset: 0,
      );

      if (myRequest != _requestId) return; // stale

      final items = List<WorkshopDiscountInvoice>.from(response.invoices)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _cache[key] = items;
      _summaryCache[key] = response.summary;
      _fetched = items;
      _summary = response.summary;
      _lastSyncedBranchId = _branchIdParam;
      _applyLocalFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (myRequest != _requestId) return;
      _isLoading = false;
      _error = 'Could not load discounts. Pull down to retry.';
      _fetched = [];
      _filtered = [];
      _summary = WorkshopDiscountSummary.empty;
      notifyListeners();
    }
  }

  void _applyLocalFilter() {
    final start = fromDate;
    final end = _toDateInclusive;
    Iterable<WorkshopDiscountInvoice> list = _fetched.where((i) {
      final t = i.createdAt.toLocal();
      if (t.isBefore(start)) return false;
      if (t.isAfter(end)) return false;
      return true;
    });
    if (_invoiceSearch != null && _invoiceSearch!.isNotEmpty) {
      final q = _invoiceSearch!.toLowerCase();
      list = list.where((i) =>
          i.invoiceNo.toLowerCase().contains(q) ||
          i.customerName.toLowerCase().contains(q));
    }
    _filtered = list.toList();
  }
}
