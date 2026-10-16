import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── State enum ────────────────────────────────────────────────────────────────

enum CollectionHistoryState { idle, loading, loadingMore, success, error }

// ── Sort options ──────────────────────────────────────────────────────────────

enum CollectionHistorySortField { date, expected, received, difference }

enum CollectionHistorySortOrder { asc, desc }

// ── Quick match-status filter (chip row) ─────────────────────────────────────

enum CollectionMatchFilter { all, matched, short, over, pending }

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Drives the standalone "Collections History" screen.
///
/// Uses the existing `GET /locker/financial/history` endpoint (via
/// [LockerRepository.getCollectionHistory]) — the same data source as
/// `locker_reports_view.dart`'s History tab — but also surfaces the
/// response's `summary` block for the Expected / Received / Differences
/// KPI cards.
class LockerCollectionHistoryViewModel extends ChangeNotifier {
  final LockerRepository _repository;
  final SessionService _sessionService;

  LockerCollectionHistoryViewModel({
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ───────────────────────────────────────────────────────────────────
  String? _token;
  AppLocalizations? _l10n;

  // ── State ─────────────────────────────────────────────────────────────────────
  CollectionHistoryState _state = CollectionHistoryState.idle;
  String? _error;
  final List<CollectionHistoryEntry> _items = [];
  CollectionHistorySummary _summary = CollectionHistorySummary.empty();

  CollectionHistoryState get state => _state;
  String? get error => _error;
  List<CollectionHistoryEntry> get items => List.unmodifiable(_items);
  CollectionHistorySummary get summary => _summary;

  bool get isLoading => _state == CollectionHistoryState.loading;
  bool get isLoadingMore => _state == CollectionHistoryState.loadingMore;
  bool get isSuccess => _state == CollectionHistoryState.success;
  bool get isError => _state == CollectionHistoryState.error;

  // ── Pagination ─────────────────────────────────────────────────────────────────
  static const int _pageSize = 20;
  int _currentPage = 1;
  int _totalItems = 0;
  bool _hasMore = false;

  int get totalItems => _totalItems;
  bool get hasMore => _hasMore;

  // ── Filters ────────────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String? _selectedBranchId;
  String? _selectedCashierId;
  DateTime? _from;
  DateTime? _to;

  String get searchQuery => _searchQuery;
  String? get selectedBranchId => _selectedBranchId;
  String? get selectedCashierId => _selectedCashierId;
  DateTime? get from => _from;
  DateTime? get to => _to;

  bool get hasActiveFilters =>
      _selectedBranchId != null ||
          _selectedCashierId != null ||
          _from != null ||
          _to != null ||
          _searchQuery.isNotEmpty ||
          _matchFilter != CollectionMatchFilter.all;

  // ── Branches ───────────────────────────────────────────────────────────────────
  List<LockerBranch> _branches = [];
  bool _branchesLoading = false;

  List<LockerBranch> get branches => List.unmodifiable(_branches);
  bool get branchesLoading => _branchesLoading;

  // ── Cashiers ───────────────────────────────────────────────────────────────────
  List<LockerCashierModel> _cashiers = [];
  bool _cashiersLoading = false;

  List<LockerCashierModel> get cashiers => List.unmodifiable(_cashiers);
  bool get cashiersLoading => _cashiersLoading;

  // ── Sorting ────────────────────────────────────────────────────────────────────
  CollectionHistorySortField _sortField = CollectionHistorySortField.date;
  CollectionHistorySortOrder _sortOrder = CollectionHistorySortOrder.desc;

  CollectionHistorySortField get sortField => _sortField;
  CollectionHistorySortOrder get sortOrder => _sortOrder;

  // ── Quick match-status filter ─────────────────────────────────────────────────
  CollectionMatchFilter _matchFilter = CollectionMatchFilter.all;
  CollectionMatchFilter get matchFilter => _matchFilter;

  /// All loaded items, filtered by the active match-status chip and sorted
  /// by the active sort field/order. Search/branch/date filters are applied
  /// server-side (see [_loadPage]); this is the final client-side pass.
  List<CollectionHistoryEntry> get visibleItems {
    var list = List<CollectionHistoryEntry>.from(_items);

    switch (_matchFilter) {
      case CollectionMatchFilter.all:
        break;
      case CollectionMatchFilter.matched:
        list = list.where((e) => e.matchStatus == 'MATCHED').toList();
        break;
      case CollectionMatchFilter.short:
        list = list.where((e) => e.matchStatus == 'SHORT').toList();
        break;
      case CollectionMatchFilter.over:
        list = list.where((e) => e.matchStatus == 'OVER').toList();
        break;
      case CollectionMatchFilter.pending:
        list = list.where((e) => e.isPendingApproval).toList();
        break;
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case CollectionHistorySortField.date:
          cmp = a.collectedAt.compareTo(b.collectedAt);
          break;
        case CollectionHistorySortField.expected:
          cmp = a.expectedAmount.compareTo(b.expectedAmount);
          break;
        case CollectionHistorySortField.received:
          cmp = a.receivedAmount.compareTo(b.receivedAmount);
          break;
        case CollectionHistorySortField.difference:
          cmp = a.difference.abs().compareTo(b.difference.abs());
          break;
      }
      return _sortOrder == CollectionHistorySortOrder.asc ? cmp : -cmp;
    });
    return list;
  }

  // ── Search debounce ────────────────────────────────────────────────────────────
  Timer? _debounce;

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Call once from initState via addPostFrameCallback.
  Future<void> init(AppLocalizations l10n) async {
    _l10n = l10n;
    try {
      _token = await _sessionService.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n.lockerSessionExpired);
        return;
      }
    } catch (e) {
      _setError('${l10n.lockerFailedLoadSession} ${_friendly(e)}');
      return;
    }

    await Future.wait([
      _loadPage(1, replace: true),
      _loadBranches(),
      _loadCashiers(),
    ]);
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query == _searchQuery) return;
      _searchQuery = query;
      await _loadPage(1, replace: true);
    });
  }

  /// Sets the selected branch by its API id and triggers a fresh server fetch.
  /// Pass `null` to clear (show all branches).
  Future<void> setSelectedBranch(String? branchId) async {
    if (_selectedBranchId == branchId) return;
    _selectedBranchId = branchId;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  Future<void> setSelectedCashier(String? cashierId) async {
    if (_selectedCashierId == cashierId) return;
    _selectedCashierId = cashierId;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (_from == from && _to == to) return;
    _from = from;
    _to = to;
    await _loadPage(1, replace: true);
  }

  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedBranchId = null;
    _selectedCashierId = null;
    _from = null;
    _to = null;
    _matchFilter = CollectionMatchFilter.all;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  /// Quick match-status chip — applied client-side over already-loaded items.
  void setMatchFilter(CollectionMatchFilter filter) {
    if (_matchFilter == filter) return;
    _matchFilter = filter;
    notifyListeners();
  }

  void toggleSort(CollectionHistorySortField field) {
    if (_sortField == field) {
      _sortOrder = _sortOrder == CollectionHistorySortOrder.asc
          ? CollectionHistorySortOrder.desc
          : CollectionHistorySortOrder.asc;
    } else {
      _sortField = field;
      _sortOrder = CollectionHistorySortOrder.desc;
    }
    notifyListeners();
  }

  Future<void> refresh() => _loadPage(1, replace: true);

  Future<void> loadMore() async {
    if (_state == CollectionHistoryState.loadingMore || !_hasMore) return;
    await _loadPage(_currentPage + 1, replace: false);
  }

  // ── Private: loading ───────────────────────────────────────────────────────────

  Future<void> _loadPage(int page, {required bool replace}) async {
    if (_token == null) return;

    _state = replace
        ? CollectionHistoryState.loading
        : CollectionHistoryState.loadingMore;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getCollectionHistory(
        token: _token!,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        branchId: _selectedBranchId,
        cashierId: _selectedCashierId,
        from: _from,
        to: _to,
        page: page,
        limit: _pageSize,
      );

      if (replace) {
        _items
          ..clear()
          ..addAll(result.items);
      } else {
        _items.addAll(result.items);
      }

      _summary = result.summary;
      _currentPage = page;
      _totalItems = result.total;
      _hasMore = _items.length < result.total;

      _state = CollectionHistoryState.success;
      _error = null;
      notifyListeners();

      debugLog(
        '[CollectionHistoryVM] page=$page total=${result.total} '
            'loaded=${_items.length} hasMore=$_hasMore',
      );
    } on UnauthorisedException {
      _setError(_l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setError(
          _l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e, st) {
      _setError(_l10n?.lockerSomethingWentWrong ?? 'Something went wrong.');
      debugLog('[CollectionHistoryVM] unexpected: $e\n$st');
    }
  }

  // ── Private: branches ──────────────────────────────────────────────────────────

  Future<void> _loadBranches() async {
    if (_token == null) return;
    _branchesLoading = true;
    notifyListeners();
    try {
      _branches = await _repository.getBranches(token: _token!);
      debugLog('[CollectionHistoryVM] Loaded ${_branches.length} branches');
    } catch (e) {
      debugLog('[CollectionHistoryVM] Failed to load branches: $e');
      // Non-fatal: dropdown just stays empty; other filters still work.
    } finally {
      _branchesLoading = false;
      notifyListeners();
    }
  }

  // ── Private: cashiers ──────────────────────────────────────────────────────────

  Future<void> _loadCashiers() async {
    if (_token == null) return;
    _cashiersLoading = true;
    notifyListeners();
    try {
      _cashiers = await _repository.getCashiers(token: _token!);
      debugLog('[CollectionHistoryVM] Loaded ${_cashiers.length} cashiers');
    } catch (e) {
      debugLog('[CollectionHistoryVM] Failed to load cashiers: $e');
    } finally {
      _cashiersLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _setError(String msg) {
    _state = CollectionHistoryState.error;
    _error = msg;
    notifyListeners();
    debugLog('[CollectionHistoryVM] error: $msg');
  }

  String _friendly(Object e) {
    final raw = e.toString();
    const prefixes = [
      'Error During Communication: ',
      'Invalid Request: ',
      'Unauthorised: ',
    ];
    for (final p in prefixes) {
      if (raw.startsWith(p)) return raw.substring(p.length);
    }
    return raw;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}