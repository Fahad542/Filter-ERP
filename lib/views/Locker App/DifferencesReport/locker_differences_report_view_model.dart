import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum DifferencesReportState { idle, loading, success, error }

// ── Type filter chip ──────────────────────────────────────────────────────────

enum DifferencesTypeFilter { all, short, over, pending }

// ── Domain models ─────────────────────────────────────────────────────────────
//
// Parsed directly from the analytics API JSON so we have zero dependency on
// LockerAnalyticsData (locker_financial_models.dart).
//
// Analytics response shape:
// {
//   "success": true,
//   "totalShort": "23450.00",
//   "totalOver": "292.50",
//   "netVariance": "-23157.50",
//   "differencesSummary": { "currency": "SAR", ... },
//   "recentVariances": [
//     { "id", "collectionId", "referenceCode", "branchName", "cashierName",
//       "cashierId", "type", "status", "amount", "difference",
//       "receivedAmount", "collectionStatus", "date", "collectedAt",
//       "officerName" }
//   ]
// }

class DifferenceVarianceEntry {
  final String id;
  final String collectionId;
  final String referenceCode;
  final String branchName;
  final String cashierName;
  final String cashierId;
  final String type;             // "short" | "over"
  final double amount;
  final double difference;
  final double receivedAmount;
  final String collectionStatus; // "approved" | "pending_approval"
  final DateTime date;
  final String officerName;

  const DifferenceVarianceEntry({
    required this.id,
    required this.collectionId,
    required this.referenceCode,
    required this.branchName,
    required this.cashierName,
    required this.cashierId,
    required this.type,
    required this.amount,
    required this.difference,
    required this.receivedAmount,
    required this.collectionStatus,
    required this.date,
    required this.officerName,
  });

  bool get isShort   => type.toLowerCase() == 'short';
  bool get isOver    => type.toLowerCase() == 'over';
  bool get isPending => collectionStatus.toLowerCase() == 'pending_approval';

  factory DifferenceVarianceEntry.fromJson(Map<String, dynamic> j) {
    return DifferenceVarianceEntry(
      id              : j['id']?.toString() ?? '',
      collectionId    : j['collectionId']?.toString() ?? j['id']?.toString() ?? '',
      referenceCode   : j['referenceCode']    as String? ?? '',
      branchName      : j['branchName']       as String? ?? '',
      cashierName     : j['cashierName']      as String? ?? '',
      cashierId       : j['cashierId']?.toString() ?? '',
      type            : j['type']             as String? ?? '',
      amount          : _d(j['amount']),
      difference      : _d(j['difference']),
      receivedAmount  : _d(j['receivedAmount']),
      collectionStatus: j['collectionStatus'] as String? ?? '',
      date            : DateTime.tryParse(j['date']        as String? ?? '')?.toLocal() ??
          DateTime.tryParse(j['collectedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      officerName     : j['officerName'] as String? ?? '',
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// Top-level KPI summary — parsed from analytics response root keys.
class DifferencesSummary {
  final double totalShort;
  final double totalOver;
  final double netVariance;
  final String currency;

  const DifferencesSummary({
    required this.totalShort,
    required this.totalOver,
    required this.netVariance,
    required this.currency,
  });

  factory DifferencesSummary.empty() => const DifferencesSummary(
    totalShort: 0, totalOver: 0, netVariance: 0, currency: 'SAR',
  );

  /// Parses from the root-level analytics JSON map.
  factory DifferencesSummary.fromJson(Map<String, dynamic> j) {
    // currency lives inside differencesSummary sub-object
    final ds = j['differencesSummary'] as Map<String, dynamic>?;
    return DifferencesSummary(
      totalShort : _d(j['totalShort']),
      totalOver  : _d(j['totalOver']),
      netVariance: _d(j['netVariance']),
      currency   : ds?['currency'] as String? ?? 'SAR',
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LockerDifferencesReportViewModel extends ChangeNotifier {
  final LockerRepository _repo;
  final SessionService   _session;

  LockerDifferencesReportViewModel({
    LockerRepository? repository,
    SessionService?   sessionService,
  })  : _repo    = repository    ?? LockerRepository(),
        _session = sessionService ?? SessionService();

  // ── Session ───────────────────────────────────────────────────────────────
  String? _token;
  AppLocalizations? _l10n;

  // ── State ─────────────────────────────────────────────────────────────────
  DifferencesReportState        _state   = DifferencesReportState.idle;
  String?                       _error;
  DifferencesSummary            _summary = DifferencesSummary.empty();
  List<DifferenceVarianceEntry> _all     = [];

  DifferencesReportState        get state   => _state;
  String?                       get error   => _error;
  DifferencesSummary            get summary => _summary;

  bool get isLoading => _state == DifferencesReportState.loading;
  bool get isSuccess => _state == DifferencesReportState.success;
  bool get isError   => _state == DifferencesReportState.error;

  // ── Filters ────────────────────────────────────────────────────────────────
  DateTime?             _from;
  DateTime?             _to;
  String?               _selectedBranchId;
  String?               _selectedCashierId;
  String                _searchQuery = '';
  DifferencesTypeFilter _typeFilter  = DifferencesTypeFilter.all;

  DateTime?             get from              => _from;
  DateTime?             get to                => _to;
  String?               get selectedBranchId  => _selectedBranchId;
  String?               get selectedCashierId => _selectedCashierId;
  String                get searchQuery       => _searchQuery;
  DifferencesTypeFilter get typeFilter        => _typeFilter;

  bool get hasActiveFilters =>
      _from != null ||
          _to != null ||
          _selectedBranchId != null ||
          _selectedCashierId != null ||
          _searchQuery.isNotEmpty ||
          _typeFilter != DifferencesTypeFilter.all;

  // ── Branches / cashiers ────────────────────────────────────────────────────
  List<LockerBranch>       _branches         = [];
  bool                     _branchesLoading  = false;
  List<LockerCashierModel> _cashiers         = [];
  bool                     _cashiersLoading  = false;

  List<LockerBranch>       get branches         => List.unmodifiable(_branches);
  bool                     get branchesLoading  => _branchesLoading;
  List<LockerCashierModel> get cashiers         => List.unmodifiable(_cashiers);
  bool                     get cashiersLoading  => _cashiersLoading;

  // ── Derived chip counts (over full unfiltered list) ────────────────────────
  int get totalCount   => _all.length;
  int get shortCount   => _all.where((e) => e.isShort).length;
  int get overCount    => _all.where((e) => e.isOver).length;
  int get pendingCount => _all.where((e) => e.isPending).length;

  // ── Client-side filtered + searched list ───────────────────────────────────
  List<DifferenceVarianceEntry> get visibleItems {
    var list = List<DifferenceVarianceEntry>.from(_all);

    // Type chip filter
    switch (_typeFilter) {
      case DifferencesTypeFilter.all:     break;
      case DifferencesTypeFilter.short:   list = list.where((e) => e.isShort).toList();   break;
      case DifferencesTypeFilter.over:    list = list.where((e) => e.isOver).toList();    break;
      case DifferencesTypeFilter.pending: list = list.where((e) => e.isPending).toList(); break;
    }

    // Branch filter (client-side backup — also sent to analytics API)
    if (_selectedBranchId != null) {
      final b = _branches.where((b) => b.id == _selectedBranchId).firstOrNull;
      if (b != null) {
        list = list
            .where((e) => e.branchName.toLowerCase() == b.name.toLowerCase())
            .toList();
      }
    }

    // Cashier filter (client-side backup — also sent as cashierUserId)
    if (_selectedCashierId != null) {
      list = list
          .where((e) => e.cashierId == _selectedCashierId)
          .toList();
    }

    // Text search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
      e.referenceCode.toLowerCase().contains(q) ||
          e.branchName.toLowerCase().contains(q)    ||
          e.cashierName.toLowerCase().contains(q)   ||
          e.officerName.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  // ── Search debounce ────────────────────────────────────────────────────────
  Timer? _debounce;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init(AppLocalizations l10n) async {
    _l10n = l10n;
    try {
      _token = await _session.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n.lockerSessionExpired);
        return;
      }
    } catch (e) {
      _setError('${l10n.lockerFailedLoadSession} ${_friendly(e)}');
      return;
    }
    await Future.wait([_load(), _loadBranches(), _loadCashiers()]);
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query == _searchQuery) return;
      _searchQuery = query;
      notifyListeners();
    });
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (_from == from && _to == to) return;
    _from = from;
    _to   = to;
    await _load();
  }

  Future<void> setSelectedBranch(String? branchId) async {
    if (_selectedBranchId == branchId) return;
    _selectedBranchId = branchId;
    notifyListeners();
    await _load();
  }

  Future<void> setSelectedCashier(String? cashierId) async {
    if (_selectedCashierId == cashierId) return;
    _selectedCashierId = cashierId;
    notifyListeners();
    await _load();
  }

  void setTypeFilter(DifferencesTypeFilter f) {
    if (_typeFilter == f) return;
    _typeFilter = f;
    notifyListeners();
  }

  Future<void> clearFilters() async {
    _from = null;
    _to   = null;
    _selectedBranchId  = null;
    _selectedCashierId = null;
    _searchQuery       = '';
    _typeFilter        = DifferencesTypeFilter.all;
    notifyListeners();
    await _load();
  }

  Future<void> refresh() => _load();

  // ── Private: data loading ─────────────────────────────────────────────────

  Future<void> _load() async {
    if (_token == null) return;
    _state = DifferencesReportState.loading;
    _error = null;
    notifyListeners();

    try {
      // Call the raw-map variant added to LockerRepository so we parse
      // analytics fields (totalShort / totalOver / netVariance /
      // recentVariances) directly — LockerAnalyticsData does not expose them.
      final json = await _repo.getFinancialAnalyticsRaw(
        token: _token!,
        from : _from,
        to   : _to,
        branchId: _selectedBranchId,
        cashierUserId: _selectedCashierId,
      );

      _summary = DifferencesSummary.fromJson(json);

      final rawList = json['recentVariances'];
      _all = (rawList is List)
          ? rawList
          .whereType<Map<String, dynamic>>()
          .map(DifferenceVarianceEntry.fromJson)
          .toList()
          : [];

      _state = DifferencesReportState.success;
      notifyListeners();
      debugLog('[DifferencesReportVM] ${_all.length} variances '
          'short=${_summary.totalShort} over=${_summary.totalOver}');
    } on UnauthorisedException {
      _setError(_l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setError(
          _l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e, st) {
      _setError(_l10n?.lockerSomethingWentWrong ?? 'Something went wrong.');
      debugLog('[DifferencesReportVM] $e\n$st');
    }
  }

  Future<void> _loadBranches() async {
    if (_token == null) return;
    _branchesLoading = true;
    notifyListeners();
    try {
      _branches = await _repo.getBranches(token: _token!);
    } catch (e) {
      debugLog('[DifferencesReportVM] branches load failed: $e');
      // Non-fatal — branch dropdown stays empty; other filters still work.
    } finally {
      _branchesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCashiers() async {
    if (_token == null) return;
    _cashiersLoading = true;
    notifyListeners();
    try {
      _cashiers = await _repo.getCashiers(token: _token!);
    } catch (e) {
      debugLog('[DifferencesReportVM] cashiers load failed: $e');
    } finally {
      _cashiersLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setError(String msg) {
    _state = DifferencesReportState.error;
    _error = msg;
    notifyListeners();
    debugLog('[DifferencesReportVM] error: $msg');
  }

  String _friendly(Object e) {
    final raw = e.toString();
    for (final p in [
      'Error During Communication: ',
      'Invalid Request: ',
      'Unauthorised: ',
    ]) {
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