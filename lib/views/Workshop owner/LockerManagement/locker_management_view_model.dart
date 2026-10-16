import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';

class LockerManagementViewModel extends ChangeNotifier {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;

  // `_isLoading`  → true only for the very first fetch (no data on screen yet).
  //                 Drives the full-screen spinner.
  // `_isRefreshing` → true for every in-flight fetch, including background
  //                 refreshes that happen while stale data is still shown.
  //                 Drives a lightweight top progress bar instead of
  //                 blanking the screen — important on slow networks where
  //                 a refresh can take several seconds.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _error;
  String? get error => _error;

  DateTime? _lastUpdatedAt;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  LockerOverviewResponse? _response;
  LockerOverviewResponse? get response => _response;

  // Bumped on every fetch; lets an in-flight request detect it has been
  // superseded (e.g. user pulls to refresh again before the first call
  // returns) and avoid clobbering newer data with a stale response.
  int _requestGeneration = 0;

  LockerManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
  });

  LockerKpis get kpis => _response?.kpis ?? LockerKpis();
  List<LockerUser> get supervisors => _response?.supervisors ?? [];
  List<LockerUser> get officers => _response?.officers ?? [];
  List<LockerCollectionRequest> get recentRequests => _response?.recentRequests ?? [];
  List<LockerCollectionRecord> get recentCollections => _response?.recentCollections ?? [];
  List<LockerBankDeposit> get recentBankDeposits => _response?.recentBankDeposits ?? [];
  List<LockerPettyCash> get recentPettyCashIssues => _response?.recentPettyCashIssues ?? [];

  Future<void> fetchLockerOverview({bool forceRefresh = false}) async {
    // Avoid piling up duplicate in-flight requests (e.g. initial load +
    // an eager pull-to-refresh) — let the current one finish instead.
    if (_isRefreshing && !forceRefresh) return;

    final generation = ++_requestGeneration;
    _isRefreshing = true;
    _isLoading = _response == null; // only show the blocking spinner pre-data
    if (_response == null) _error = null; // keep last error visible alongside stale data otherwise
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (generation != _requestGeneration) return; // superseded while awaiting token

      if (token != null) {
        final result = await ownerRepository.getLockerManagementOverview(
          token,
          forceRefresh: forceRefresh,
        );
        if (generation != _requestGeneration) return; // a newer request has taken over

        if (result != null && result['success'] == true) {
          _response = LockerOverviewResponse.fromJson(result);
          _error = null;
          _lastUpdatedAt = DateTime.now();
        } else {
          _error = 'Could not load locker data';
        }
      } else {
        _error = 'Session expired. Please sign in again.';
      }
    } catch (e) {
      if (generation != _requestGeneration) return;
      // Keep any previously loaded data on screen; only surface the error.
      _error = _response == null
          ? 'Something went wrong while loading locker data'
          : 'Could not refresh — showing last loaded data';
    } finally {
      if (generation == _requestGeneration) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Pull-to-refresh / manual refresh — always bypasses the repository cache.
  Future<void> refresh() => fetchLockerOverview(forceRefresh: true);
}