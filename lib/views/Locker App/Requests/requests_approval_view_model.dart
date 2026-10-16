import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── State enums ───────────────────────────────────────────────────────────────

enum VarianceApprovalsState { idle, loading, success, error }

enum VarianceActionState { idle, processing, success, error }

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LockerVarianceApprovalsViewModel extends ChangeNotifier {
  final LockerRepository _repository;
  final SessionService _sessionService;

  LockerVarianceApprovalsViewModel({
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ───────────────────────────────────────────────────────────────
  String? _token;
  AppLocalizations? _l10n;

  // ── List state ────────────────────────────────────────────────────────────
  VarianceApprovalsState _state = VarianceApprovalsState.idle;
  String? _errorMessage;
  List<LockerVarianceApproval> _approvals = [];
  List<LockerFundRequest> _fundRequests = [];

  VarianceApprovalsState get state => _state;
  String? get errorMessage => _errorMessage;
  List<LockerVarianceApproval> get approvals => List.unmodifiable(_approvals);
  List<LockerFundRequest> get fundRequests => List.unmodifiable(_fundRequests);
  int get pendingFundCount =>
      _fundRequests.where((r) => r.isPending).length;

  bool get isLoading => _state == VarianceApprovalsState.loading;
  bool get hasError => _state == VarianceApprovalsState.error;
  bool get isSuccess => _state == VarianceApprovalsState.success;

  // ── Per-item action state ─────────────────────────────────────────────────
  VarianceActionState _actionState = VarianceActionState.idle;
  String? _actionError;

  /// The collection ID currently being processed (used for per-tile loading).
  String? _processingId;

  VarianceActionState get actionState => _actionState;
  String? get actionError => _actionError;
  String? get processingId => _processingId;
  bool get isProcessing => _actionState == VarianceActionState.processing;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> init(AppLocalizations l10n) async {
    _l10n = l10n;
    _state = VarianceApprovalsState.loading;
    _errorMessage = null;
    notifyListeners();

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

    await _fetchApprovals();
  }

  Future<void> refresh() => _fetchApprovals();

  /// Approves the collection with [collectionId].
  /// Returns true on success.
  Future<bool> approve(String collectionId) async {
    return _performAction(collectionId, 'approved', '');
  }

  /// Rejects the collection with [collectionId] with an optional reason.
  /// Returns true on success.
  Future<bool> reject(String collectionId, {String reason = ''}) async {
    return _performAction(collectionId, 'rejected', reason);
  }

  Future<bool> approveFundRequest(String requestId) async {
    return _performFundAction(requestId, approve: true);
  }

  Future<bool> rejectFundRequest(String requestId, {required String reason}) async {
    return _performFundAction(requestId, approve: false, reason: reason);
  }

  void resetActionState() {
    _actionState = VarianceActionState.idle;
    _actionError = null;
    _processingId = null;
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _fetchApprovals() async {
    _state = VarianceApprovalsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getApprovals(token: _token!),
        _repository.getPettyCashFundRequests(token: _token!, status: 'pending'),
      ]);
      _approvals = results[0] as List<LockerVarianceApproval>;
      _fundRequests = results[1] as List<LockerFundRequest>;
      _state = VarianceApprovalsState.success;
      _errorMessage = null;
      notifyListeners();
      debugLog(
        '[VarianceApprovalsVM] Loaded ${_approvals.length} variance, '
        '${_fundRequests.length} fund requests',
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
      debugLog('[VarianceApprovalsVM] Unexpected: $e\n$st');
    }
  }

  Future<bool> _performFundAction(
    String requestId, {
    required bool approve,
    String reason = '',
  }) async {
    final l10n = _l10n;
    if (_token == null) {
      _actionError = l10n?.lockerNotAuthenticated ?? 'Not authenticated.';
      _actionState = VarianceActionState.error;
      notifyListeners();
      return false;
    }

    _processingId = requestId;
    _actionState = VarianceActionState.processing;
    _actionError = null;
    notifyListeners();

    try {
      if (approve) {
        await _repository.approvePettyCashFundRequest(
          token: _token!,
          requestId: requestId,
        );
      } else {
        await _repository.rejectPettyCashFundRequest(
          token: _token!,
          requestId: requestId,
          rejectionReason: reason,
        );
      }
      _fundRequests = _fundRequests.where((r) => r.id != requestId).toList();
      _actionState = VarianceActionState.success;
      _processingId = null;
      notifyListeners();
      return true;
    } on UnauthorisedException {
      _setActionError(l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setActionError(
          l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setActionError(_friendly(e));
    } catch (e, st) {
      _setActionError(l10n?.lockerOperationFailed ?? 'Operation failed.');
      debugLog('[VarianceApprovalsVM] Fund action error: $e\n$st');
    }
    _processingId = null;
    return false;
  }

  Future<bool> _performAction(
      String collectionId, String status, String reason) async {
    final l10n = _l10n;
    if (_token == null) {
      _actionError = l10n?.lockerNotAuthenticated ?? 'Not authenticated.';
      _actionState = VarianceActionState.error;
      notifyListeners();
      return false;
    }

    _processingId = collectionId;
    _actionState = VarianceActionState.processing;
    _actionError = null;
    notifyListeners();

    try {
      await _repository.approveDifference(
        token: _token!,
        collectionId: collectionId,
        status: status,
        rejectionReason: reason,
      );

      // Remove the item from the local list immediately so the UI updates.
      _approvals =
          _approvals.where((a) => a.id != collectionId).toList();

      _actionState = VarianceActionState.success;
      _processingId = null;
      notifyListeners();

      debugLog(
          '[VarianceApprovalsVM] $status collectionId=$collectionId');
      return true;
    } on UnauthorisedException {
      _setActionError(l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setActionError(
          l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setActionError(_friendly(e));
    } catch (e, st) {
      _setActionError(l10n?.lockerOperationFailed ?? 'Operation failed.');
      debugLog('[VarianceApprovalsVM] Unexpected action error: $e\n$st');
    }

    _processingId = null;
    return false;
  }

  void _setError(String msg) {
    _state = VarianceApprovalsState.error;
    _errorMessage = msg;
    notifyListeners();
    debugLog('[VarianceApprovalsVM] Error: $msg');
  }

  void _setActionError(String msg) {
    _actionState = VarianceActionState.error;
    _actionError = msg;
    notifyListeners();
    debugLog('[VarianceApprovalsVM] Action error: $msg');
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
}