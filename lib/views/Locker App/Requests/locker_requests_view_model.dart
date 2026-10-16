import 'dart:async';
import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';
import 'locker_requests_list_view.dart'; // for LockerListFilterMode

// ── State ─────────────────────────────────────────────────────────────────────

enum LockerRequestsState { idle, loading, loadingMore, success, error }

/// State for the officer list inside the quick-assign bottom sheet on the list screen.
enum ListOfficersState { idle, loading, success, error }

/// State for the assign API call — per-officer spinner, doesn't block the list.
enum ListAssignState { idle, assigning, success, error }

// ── Status filter options (API values stay English; labels via l10n) ───────────

/// The 'all' tab sends no status param; the rest map 1-to-1 with the API.
List<({String label, String? value})> _statusFilters(AppLocalizations l10n) => [
  (label: l10n.lockerFilterAll, value: null),
  (label: l10n.lockerFilterPending, value: 'pending'),
  (label: l10n.lockerFilterAssigned, value: 'assigned'),
  (label: l10n.lockerFilterCollected, value: 'collected'),
  (label: l10n.lockerFilterCompleted, value: 'completed'),
];

List<({String label, String? value})> _assignPendingFilters(
        AppLocalizations l10n) =>
    [
      (label: l10n.lockerFilterPending, value: 'pending'),
    ];

List<({String label, String? value})> _collectorStatusFilters(
        AppLocalizations l10n) =>
    [
      (label: l10n.lockerFilterAll, value: null),
      (label: l10n.lockerFilterPending, value: 'pending'),
      (label: l10n.lockerFilterAssigned, value: 'assigned'),
      (label: l10n.lockerFilterCollected, value: 'collected'),
    ];

// ── Role helpers ──────────────────────────────────────────────────────────────

String? _cleanString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

String? _stringFromMap(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final text = _cleanString(map[key]);
    if (text != null) return text;
  }
  return null;
}

String? _normaliseView(String? value) {
  switch (value?.toLowerCase().trim()) {
    case 'supervisor':
      return 'supervisor';
    case 'collector':
      return 'collector';
    default:
      return null;
  }
}

bool _isSupervisorRole({String? userType, String? lockerPortalRole}) {
  switch (lockerPortalRole?.toLowerCase()) {
    case 'supervisor':
      return true;
    case 'collector':
      return false;
  }

  switch (userType?.toLowerCase()) {
    case 'workshop_owner':
    case 'workshop_supervisor':
    case 'supervisor':
    case 'manager':
      return true;
    default:
      return false;
  }
}

String? _lockerRoleFromUser(Object? user) {
  if (user == null) return null;
  final dynamic dynamicUser = user;

  try {
    final text = _cleanString(dynamicUser.lockerPortalRole);
    if (text != null) return text;
  } catch (_) {}

  try {
    final json = dynamicUser.toJson();
    if (json is Map<String, dynamic>) {
      return _stringFromMap(json, const [
        'lockerPortalRole',
        'locker_portal_role',
        'lockerRole',
        'locker_role',
        'role',
      ]);
    }
    if (json is Map) {
      return _stringFromMap(Map<String, dynamic>.from(json), const [
        'lockerPortalRole',
        'locker_portal_role',
        'lockerRole',
        'locker_role',
        'role',
      ]);
    }
  } catch (_) {}

  return null;
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LockerRequestsViewModel extends ChangeNotifier {
  // ── Dependencies ────────────────────────────────────────────────────────────
  final LockerRepository _repository;
  final SessionService _sessionService;

  /// Controls which pre-set filter mode the list opens with.
  final LockerListFilterMode filterMode;

  /// Dashboard can explicitly open this list as supervisor or collector.
  /// This is important because a supervisor can use both tabs.
  final String? initialView;

  LockerRequestsViewModel({
    LockerRepository? repository,
    SessionService? sessionService,
    this.filterMode = LockerListFilterMode.normal,
    this.initialView,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ──────────────────────────────────────────────────────────────────
  String? _token;
  String? _userType;
  String? _lockerPortalRole;
  String? _userId;
  String _currentView = 'collector';
  AppLocalizations? _l10n;

  /// When true, _loadPage filters results client-side to only items where
  /// assignedOfficerId matches _userId. Used for collected/myPending modes
  /// so the supervisor API endpoint is called (to get that user's own requests)
  /// but only their requests are shown.
  bool _filterByCurrentUser = false;

  // ── Role exposure ─────────────────────────────────────────────────────────
  String? get userId => _userId;
  String get currentView => _currentView;

  /// This is the screen mode, not only the account role.
  /// Supervisor account may open this same screen in collector mode too.
  bool get isSupervisor => _currentView == 'supervisor';
  bool get isCollector => _currentView == 'collector';

  bool get _loggedInUserIsSupervisor => _isSupervisorRole(
    userType: _userType,
    lockerPortalRole: _lockerPortalRole,
  );

  /// True for the "Pending Requests" entry points (default `normal` mode,
  /// `myPending`, `assignPending`) — these now always show pending only,
  /// with the date/branch/cashier/amount filter bar instead of the status
  /// dropdown. `collected` / `allCollected` ("View All" from Recent
  /// Collections) are left untouched — that's a collected-history view,
  /// not the pending work queue, so it keeps the old search + status
  /// dropdown behaviour.
  bool get isPendingOnlyMode =>
      filterMode != LockerListFilterMode.collected &&
          filterMode != LockerListFilterMode.allCollected;

  /// Sum of `lockedCashAmount` across the currently **loaded** requests.
  /// Accurate when every matching result fits on one page (typical for a
  /// pending-only queue); if there are more pages than loaded, this only
  /// reflects what's been fetched so far — the API has no server-side sum.
  double get totalExpected =>
      _requests.fold(0.0, (sum, r) => sum + r.lockedCashAmount);

  /// Returns the correct filter list for the current role and filterMode.
  /// Labels are localized; [value] strings remain English API status codes.
  List<({String label, String? value})> activeFilters(AppLocalizations l10n) {
    if (filterMode == LockerListFilterMode.assignPending) {
      return _assignPendingFilters(l10n);
    }
    // allCollected = supervisor viewing all collected — full supervisor filters.
    if (filterMode == LockerListFilterMode.allCollected) {
      return _statusFilters(l10n);
    }
    // Collector-scoped: either genuinely in collector view, or supervisor
    // viewing their own requests (filterByCurrentUser), or explicit modes.
    if (isCollector ||
        _filterByCurrentUser ||
        filterMode == LockerListFilterMode.collected ||
        filterMode == LockerListFilterMode.myPending) {
      return _collectorStatusFilters(l10n);
    }
    return _statusFilters(l10n);
  }

  // ── Pagination ───────────────────────────────────────────────────────────────
  static const int _pageSize = 20;
  int _currentPage = 1;
  int _totalItems = 0;
  bool _hasMore = false;

  int get totalItems => _totalItems;
  bool get hasMore => _hasMore;

  // ── Data ─────────────────────────────────────────────────────────────────────
  final List<LockerRequest> _requests = [];
  List<LockerRequest> get requests => List.unmodifiable(_requests);

  // ── Filters ──────────────────────────────────────────────────────────────────
  String? _selectedStatus;
  String _searchQuery = '';
  Timer? _debounce;
  Timer? _amountDebounce;

  String? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  // ── Advanced filters (pending-only screen) ────────────────────────────────
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _branchId;
  String? _cashierId;
  double? _minExpected;
  double? _maxExpected;

  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  String? get branchId => _branchId;
  String? get cashierId => _cashierId;
  double? get minExpected => _minExpected;
  double? get maxExpected => _maxExpected;

  bool get hasActiveFilters =>
      _fromDate != null ||
          _toDate != null ||
          _branchId != null ||
          _cashierId != null ||
          _minExpected != null ||
          _maxExpected != null;

  List<LockerBranch> _branches = [];
  List<LockerBranch> get branches => List.unmodifiable(_branches);

  // ── Typed cashier list (uses `userId` as the filter key) ─────────────────
  List<LockerCashierModel> _cashiers = [];
  List<LockerCashierModel> get cashiers => List.unmodifiable(_cashiers);

  // ── Officer assign state (for the quick-assign sheet on list screen) ──────
  ListOfficersState _officersState = ListOfficersState.idle;
  String? _officersError;
  List<LockerOfficer> _officers = [];

  ListOfficersState get officersState => _officersState;
  String? get officersError => _officersError;
  List<LockerOfficer> get officers => List.unmodifiable(_officers);
  bool get isOfficersLoading => _officersState == ListOfficersState.loading;

  ListAssignState _assignState = ListAssignState.idle;
  String? _assignError;
  String? _assigningOfficerId;

  ListAssignState get assignState => _assignState;
  String? get assignError => _assignError;
  String? get assigningOfficerId => _assigningOfficerId;
  bool get isAssigning => _assignState == ListAssignState.assigning;

  // ── UI State ─────────────────────────────────────────────────────────────────
  LockerRequestsState _state = LockerRequestsState.idle;
  String? _errorMessage;

  LockerRequestsState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == LockerRequestsState.loading;
  bool get isLoadingMore => _state == LockerRequestsState.loadingMore;
  bool get hasError => _state == LockerRequestsState.error;
  bool get isSuccess => _state == LockerRequestsState.success;

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<void> init(AppLocalizations l10n) async {
    _l10n = l10n;
    _state = LockerRequestsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _token = await _sessionService.getToken(role: 'locker');
      final user = await _sessionService.getUser(role: 'locker');
      final rawUserMap = await _sessionService.getUserDataMap(role: 'locker');

      _userType = user?.userType ??
          _stringFromMap(rawUserMap, const ['userType', 'user_type', 'type']);
      _lockerPortalRole = _lockerRoleFromUser(user) ??
          await _sessionService.getLockerPortalRole(role: 'locker') ??
          _stringFromMap(rawUserMap, const [
            'lockerPortalRole',
            'locker_portal_role',
            'lockerRole',
            'locker_role',
            'role',
          ]);
      _userId = user?.id ??
          _stringFromMap(rawUserMap, const ['id', 'userId', 'user_id']);

      if (_token == null) {
        _setError(l10n.lockerSessionExpired);
        return;
      }

      final requestedView = _normaliseView(initialView);
      if (filterMode == LockerListFilterMode.assignPending) {
        // Assign Officers shortcut is supervisor-only.
        _currentView = _loggedInUserIsSupervisor ? 'supervisor' : 'collector';
      } else if (requestedView == 'supervisor' && _loggedInUserIsSupervisor) {
        _currentView = 'supervisor';
      } else if (requestedView == 'collector') {
        _currentView = 'collector';
      } else {
        _currentView = _loggedInUserIsSupervisor ? 'supervisor' : 'collector';
      }

      // myPending / collected modes show "this user's own requests".
      //
      // - Logged-in COLLECTOR: call the collector endpoint directly
      //   (view=collector) — the API itself already scopes results to the
      //   logged-in collector, so no client-side filter is needed.
      // - Logged-in SUPERVISOR viewing their own requests in these modes:
      //   there's no "collector view" for a supervisor account, so keep
      //   calling the supervisor endpoint and filter client-side to just
      //   their own assigned requests, same as before.
      if (filterMode == LockerListFilterMode.collected ||
          filterMode == LockerListFilterMode.myPending) {
        if (_loggedInUserIsSupervisor) {
          _currentView = 'supervisor';
          _filterByCurrentUser = true;
        } else {
          _currentView = 'collector';
          _filterByCurrentUser = false;
        }
      }

      // allCollected = supervisor "View All" from Recent Collections —
      // supervisor endpoint, NO user filter, all requests visible.
      if (filterMode == LockerListFilterMode.allCollected) {
        _currentView = 'supervisor';
        _filterByCurrentUser = false;
      }

      debugLog(
        '[LockerRequestsVM] Session loaded — '
            'userType=$_userType lockerPortalRole=$_lockerPortalRole '
            'loggedSupervisor=$_loggedInUserIsSupervisor view=$_currentView '
            'filterMode=$filterMode filterByCurrentUser=$_filterByCurrentUser',
      );

      // Set initial status filter based on mode and screen view.
      if (isPendingOnlyMode) {
        // normal / myPending / assignPending — this screen is now always
        // the pending work queue, regardless of role.
        _selectedStatus = 'pending';
      } else if (filterMode == LockerListFilterMode.collected) {
        // "View All" from Recent Collections (collector tab) — own collected.
        _selectedStatus = 'collected';
      } else if (filterMode == LockerListFilterMode.allCollected) {
        // "View All" from Recent Collections (supervisor tab) — all collected.
        _selectedStatus = 'collected';
      }
    } catch (e) {
      _setError('${l10n.lockerFailedLoadSession} ${_friendly(e)}');
      return;
    }

    if (isPendingOnlyMode) {
      await Future.wait([
        _loadFilterOptions(),
        _loadPage(1, replace: true),
      ]);
    } else {
      await _loadPage(1, replace: true);
    }
  }

  Future<void> setStatus(String? status) async {
    if (status == _selectedStatus) return;
    _selectedStatus = status;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query == _searchQuery) return;
      _searchQuery = query;
      await _loadPage(1, replace: true);
    });
  }

  Future<void> setFromDate(DateTime? date) async {
    _fromDate = date;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  Future<void> setToDate(DateTime? date) async {
    _toDate = date;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  Future<void> setBranch(String? branchId) async {
    _branchId = branchId;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  Future<void> setCashier(String? cashierId) async {
    _cashierId = cashierId;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  /// Debounced like search — avoids firing a request per keystroke.
  void setMinExpected(double? value) {
    _amountDebounce?.cancel();
    _amountDebounce = Timer(const Duration(milliseconds: 500), () async {
      _minExpected = value;
      await _loadPage(1, replace: true);
    });
  }

  /// Debounced like search — avoids firing a request per keystroke.
  void setMaxExpected(double? value) {
    _amountDebounce?.cancel();
    _amountDebounce = Timer(const Duration(milliseconds: 500), () async {
      _maxExpected = value;
      await _loadPage(1, replace: true);
    });
  }

  Future<void> clearAdvancedFilters() async {
    _fromDate = null;
    _toDate = null;
    _branchId = null;
    _cashierId = null;
    _minExpected = null;
    _maxExpected = null;
    notifyListeners();
    await _loadPage(1, replace: true);
  }

  Future<void> refresh() => _loadPage(1, replace: true);

  Future<void> loadMore() async {
    if (_state == LockerRequestsState.loadingMore || !_hasMore) return;
    await _loadPage(_currentPage + 1, replace: false);
  }

  // ── Officer assignment (quick-assign sheet on the list screen) ────────────

  /// Loads field officers lazily — called when the quick-assign bottom sheet
  /// is about to open from a request card. Skips the network call if
  /// officers are already cached.
  Future<void> loadOfficersIfNeeded() async {
    if (_officersState == ListOfficersState.success && _officers.isNotEmpty) {
      return;
    }
    await _fetchOfficers();
  }

  /// Assigns [officerId] to [requestId] from the list's quick-assign sheet.
  /// On success, reloads the current page so the (now-assigned) request
  /// drops out of the pending queue.
  Future<bool> assignOfficer({
    required String requestId,
    required String officerId,
  }) async {
    final l10n = _l10n;
    if (_token == null) {
      _setAssignError(l10n?.lockerNotAuthenticated ?? 'Not authenticated.');
      return false;
    }

    _assigningOfficerId = officerId;
    _assignState = ListAssignState.assigning;
    _assignError = null;
    notifyListeners();

    try {
      await _repository.assignOfficer(
        token: _token!,
        requestId: requestId,
        officerUserId: officerId,
      );

      _assignState = ListAssignState.success;
      _assigningOfficerId = null;
      notifyListeners();

      debugLog(
          '[LockerRequestsVM] Assigned officer $officerId to request $requestId');

      // Do NOT reload here — the View calls vm.refresh() after closing
      // the sheet, so the list reloads cleanly once the sheet is gone.
      return true;
    } on UnauthorisedException {
      _setAssignError(l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setAssignError(
          l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setAssignError(_friendly(e));
    } catch (e, st) {
      _setAssignError(l10n?.lockerAssignmentFailed ?? 'Assignment failed.');
      debugLog('[LockerRequestsVM] Unexpected assign error: $e\n$st');
    }

    _assigningOfficerId = null;
    return false;
  }

  void resetAssignState() {
    _assignState = ListAssignState.idle;
    _assignError = null;
    _assigningOfficerId = null;
    notifyListeners();
  }

  Future<void> _fetchOfficers() async {
    _officersState = ListOfficersState.loading;
    _officersError = null;
    notifyListeners();

    try {
      _officers = await _repository.getFieldOfficers(token: _token!);
      _officersState = ListOfficersState.success;
      _officersError = null;
      notifyListeners();

      debugLog(
          '[LockerRequestsVM] Officers loaded — count=${_officers.length}');
    } on UnauthorisedException {
      _officersState = ListOfficersState.error;
      _officersError = _l10n?.lockerSessionExpired ?? 'Session expired.';
      notifyListeners();
    } on BadRequestException catch (e) {
      _officersState = ListOfficersState.error;
      _officersError =
          _l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}';
      notifyListeners();
    } on FetchDataException catch (e) {
      _officersState = ListOfficersState.error;
      _officersError = _friendly(e);
      notifyListeners();
    } catch (e, st) {
      _officersState = ListOfficersState.error;
      _officersError =
          _l10n?.lockerCouldNotLoadOfficers ?? 'Could not load officers.';
      notifyListeners();
      debugLog('[LockerRequestsVM] Unexpected officers error: $e\n$st');
    }
  }

  void _setAssignError(String msg) {
    _assignState = ListAssignState.error;
    _assignError = msg;
    notifyListeners();
    debugLog('[LockerRequestsVM] Assign error: $msg');
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  /// Loads the Branch / Cashier dropdown options. Best-effort — if it fails,
  /// the dropdowns just show "All" only, doesn't block the request list.
  Future<void> _loadFilterOptions() async {
    if (_token == null) return;
    try {
      // Fetch branches and cashiers concurrently for speed.
      final results = await Future.wait([
        _repository.getBranches(token: _token!),
        _repository.getCashiers(token: _token!),
      ]);
      _branches = results[0] as List<LockerBranch>;
      _cashiers = results[1] as List<LockerCashierModel>;
      notifyListeners();
      debugLog(
        '[LockerRequestsVM] Filter options loaded — '
            'branches=${_branches.length} cashiers=${_cashiers.length}',
      );
    } catch (e) {
      // Non-fatal: filters just stay empty ("All" option still shown).
      debugLog('[LockerRequestsVM] Could not load filter options: $e');
    }
  }

  Future<void> _loadPage(int page, {required bool replace}) async {
    if (replace) {
      _state = LockerRequestsState.loading;
    } else {
      _state = LockerRequestsState.loadingMore;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final page_ = await _repository.getCollectionRequests(
        token: _token!,
        view: _currentView,
        status: _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: page,
        limit: _pageSize,
        fromDate: _fromDate,
        toDate: _toDate,
        branchId: _branchId,
        cashierId: _cashierId,
        minExpected: _minExpected,
        maxExpected: _maxExpected,
      );

      // Client-side filter: for collected/myPending modes keep only requests
      // assigned to the logged-in user. The API always runs as supervisor so
      // all requests come back; we narrow here.
      final items = (_filterByCurrentUser && _userId != null)
          ? page_.items.where((r) => r.assignedOfficerId == _userId).toList()
          : page_.items;

      if (replace) {
        _requests
          ..clear()
          ..addAll(items);
      } else {
        _requests.addAll(items);
      }

      _currentPage = page;
      _totalItems = page_.total;
      _hasMore = _requests.length < page_.total;

      _state = LockerRequestsState.success;
      _errorMessage = null;
      notifyListeners();

      debugLog(
        '[LockerRequestsVM] page=$page total=${page_.total} '
            'loaded=${_requests.length} hasMore=$_hasMore',
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
      debugLog('[LockerRequestsVM] Unexpected: $e\n$st');
    }
  }

  void _setError(String msg) {
    _state = LockerRequestsState.error;
    _errorMessage = msg;
    notifyListeners();
    debugLog('[LockerRequestsVM] Error: $msg');
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
    _amountDebounce?.cancel();
    super.dispose();
  }
}