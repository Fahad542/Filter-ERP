import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

enum PettyCashIssueLogState { idle, loading, success, error }

class LockerPettyCashIssueLogViewModel extends ChangeNotifier {
  final LockerRepository _repo;
  final SessionService _session;

  LockerPettyCashIssueLogViewModel({
    LockerRepository? repository,
    SessionService? session,
  })  : _repo = repository ?? LockerRepository(),
        _session = session ?? SessionService();

  String? _token;

  PettyCashIssueLogState _state = PettyCashIssueLogState.idle;
  String? _error;
  PettyCashIssueLogSummary _summary = PettyCashIssueLogSummary.empty();
  List<PettyCashIssueLogEntry> _issues = const [];

  PettyCashIssueLogState get state => _state;
  String? get error => _error;
  PettyCashIssueLogSummary get summary => _summary;
  List<PettyCashIssueLogEntry> get issues => List.unmodifiable(_issues);

  bool get isLoading => _state == PettyCashIssueLogState.loading;
  bool get isSuccess => _state == PettyCashIssueLogState.success;
  bool get isError => _state == PettyCashIssueLogState.error;

  // ── Filters (default = last 30 days, matching web) ─────────────────────────
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  String? _selectedBranchId;
  String? _selectedCashierId;

  DateTime get from => _from;
  DateTime get to => _to;
  String? get selectedBranchId => _selectedBranchId;
  String? get selectedCashierId => _selectedCashierId;

  bool get hasActiveFilters =>
      _selectedBranchId != null || _selectedCashierId != null;

  List<LockerBranch> _branches = [];
  bool _branchesLoading = false;
  List<LockerCashierModel> _cashiers = [];
  bool _cashiersLoading = false;

  List<LockerBranch> get branches => List.unmodifiable(_branches);
  bool get branchesLoading => _branchesLoading;
  List<LockerCashierModel> get cashiers => List.unmodifiable(_cashiers);
  bool get cashiersLoading => _cashiersLoading;

  AppLocalizations? _l10n(BuildContext? context) =>
      context != null ? AppLocalizations.of(context) : null;

  Future<void> init([BuildContext? context]) async {
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
    notifyListeners();

    final l10n = _l10n(context);
    try {
      _token = await _session.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n?.lockerSessionExpired ??
            'Session expired. Please log in again.');
        return;
      }
    } catch (e) {
      _setError(
        '${l10n?.lockerFailedLoadSession ?? 'Failed to load session.'} ${_friendly(e)}'
            .trim(),
      );
      return;
    }

    await Future.wait([
      _load(context),
      _loadBranches(),
      _loadCashiers(),
    ]);
  }

  Future<void> setDateRange(DateTime from, DateTime to,
      [BuildContext? context]) async {
    final nextFrom = DateTime(from.year, from.month, from.day);
    final nextTo = DateTime(to.year, to.month, to.day);
    if (_from == nextFrom && _to == nextTo) return;
    _from = nextFrom;
    _to = nextTo;
    await _load(context);
  }

  Future<void> setSelectedBranch(String? branchId,
      [BuildContext? context]) async {
    if (_selectedBranchId == branchId) return;
    _selectedBranchId = branchId;
    notifyListeners();
    await _load(context);
  }

  Future<void> setSelectedCashier(String? cashierId,
      [BuildContext? context]) async {
    if (_selectedCashierId == cashierId) return;
    _selectedCashierId = cashierId;
    notifyListeners();
    await _load(context);
  }

  Future<void> clearFilters([BuildContext? context]) async {
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
    _selectedBranchId = null;
    _selectedCashierId = null;
    notifyListeners();
    await _load(context);
  }

  Future<void> refresh([BuildContext? context]) => _load(context);

  Future<void> _load([BuildContext? context]) async {
    if (_token == null) return;
    final l10n = _l10n(context);
    _state = PettyCashIssueLogState.loading;
    _error = null;
    notifyListeners();

    try {
      final page = await _repo.getPettyCashIssues(
        token: _token!,
        from: _from,
        to: _to,
        branchId: _selectedBranchId,
        cashierId: _selectedCashierId,
        limit: 100,
      );
      _summary = page.summary;
      _issues = page.issues;
      _state = PettyCashIssueLogState.success;
      notifyListeners();
      debugLog(
        '[PettyCashIssueLogVM] ${page.issues.length} issues '
        'total=${page.summary.totalAmount}',
      );
    } on UnauthorisedException {
      _setError(l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.');
    } on BadRequestException catch (e) {
      _setError(l10n != null
          ? l10n.lockerBadRequest(_friendly(e))
          : 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e, st) {
      _setError(
          l10n?.lockerSomethingWentWrong ?? 'Something went wrong.');
      debugLog('[PettyCashIssueLogVM] $e\n$st');
    }
  }

  Future<void> _loadBranches() async {
    if (_token == null) return;
    _branchesLoading = true;
    notifyListeners();
    try {
      _branches = await _repo.getBranches(token: _token!);
    } catch (e) {
      debugLog('[PettyCashIssueLogVM] branches load failed: $e');
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
      debugLog('[PettyCashIssueLogVM] cashiers load failed: $e');
    } finally {
      _cashiersLoading = false;
      notifyListeners();
    }
  }

  void _setError(String msg) {
    _state = PettyCashIssueLogState.error;
    _error = msg;
    notifyListeners();
    debugLog('[PettyCashIssueLogVM] error: $msg');
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
}
