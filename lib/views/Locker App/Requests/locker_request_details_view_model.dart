import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── State enums ───────────────────────────────────────────────────────────────

enum LockerDetailState { idle, loading, success, error }

enum LockerOfficersState { idle, loading, success, error }

/// Granular state for the assign operation so the UI can show a spinner
/// on the specific tile the user tapped without blocking the whole screen.
enum LockerAssignState { idle, assigning, success, error }

/// State for supervisor approve/reject variance action.
enum LockerVarianceActionState { idle, processing, success, error }

// ── Role helpers ──────────────────────────────────────────────────────────────

bool _isSupervisorLockerRole({
  String? lockerPortalRole,
  String? userType,
}) {
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

String? _cleanRole(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LockerRequestDetailsViewModel extends ChangeNotifier {
  // ── Dependencies ─────────────────────────────────────────────────────────────
  final LockerRepository _repository;
  final SessionService _sessionService;
  final String requestId;

  LockerRequestDetailsViewModel({
    required this.requestId,
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ───────────────────────────────────────────────────────────────────
  String? _token;
  String? _userType;
  String? _lockerPortalRole;
  String? _userId;
  AppLocalizations? _l10n;

  /// The logged-in user's ID — used to check self-assignment.
  String? get userId => _userId;

  /// Whether the currently logged-in user is a locker supervisor.
  ///
  /// Important: locker users normally have `userType = workshop_user`.
  /// Their real locker access is decided by `lockerPortalRole`.
  bool get isSupervisor => _isSupervisorLockerRole(
        lockerPortalRole: _lockerPortalRole,
        userType: _userType,
      );

  bool get isCollector => !isSupervisor;

  // ── Detail state ──────────────────────────────────────────────────────────────
  LockerDetailState _detailState = LockerDetailState.idle;
  String? _detailError;
  LockerRequestDetail? _detail;

  LockerDetailState get detailState => _detailState;
  String? get detailError => _detailError;
  LockerRequestDetail? get detail => _detail;

  bool get isDetailLoading => _detailState == LockerDetailState.loading;
  bool get isDetailSuccess => _detailState == LockerDetailState.success;
  bool get isDetailError => _detailState == LockerDetailState.error;

  // ── Officers state ────────────────────────────────────────────────────────────
  LockerOfficersState _officersState = LockerOfficersState.idle;
  String? _officersError;
  List<LockerOfficer> _officers = [];

  LockerOfficersState get officersState => _officersState;
  String? get officersError => _officersError;
  List<LockerOfficer> get officers => List.unmodifiable(_officers);

  bool get isOfficersLoading => _officersState == LockerOfficersState.loading;

  // ── Assign state ──────────────────────────────────────────────────────────────
  LockerAssignState _assignState = LockerAssignState.idle;
  String? _assignError;
  String? _assigningOfficerId;

  LockerAssignState get assignState => _assignState;
  String? get assignError => _assignError;
  String? get assigningOfficerId => _assigningOfficerId;

  bool get isAssigning => _assignState == LockerAssignState.assigning;

  // ── Variance approve/reject state ─────────────────────────────────────────────
  LockerVarianceActionState _varianceActionState =
      LockerVarianceActionState.idle;
  String? _varianceActionError;

  LockerVarianceActionState get varianceActionState => _varianceActionState;
  String? get varianceActionError => _varianceActionError;
  bool get isVarianceProcessing =>
      _varianceActionState == LockerVarianceActionState.processing;

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Entry point — call once from [initState] via [addPostFrameCallback].
  Future<void> init(AppLocalizations l10n) async {
    _l10n = l10n;
    try {
      _token = await _sessionService.getToken(role: 'locker');
      final user = await _sessionService.getUser(role: 'locker');
      _userType = user?.userType;
      _lockerPortalRole = await _sessionService.getLockerPortalRole(role: 'locker');
      _userId = user?.id;

      if (_token == null) {
        _setDetailError(l10n.lockerSessionExpired);
        return;
      }

      debugLog(
        '[LockerDetailVM] Session loaded — '
        'userType=$_userType lockerPortalRole=$_lockerPortalRole '
        'isSupervisor=$isSupervisor userId=$_userId',
      );
    } catch (e) {
      _setDetailError('${l10n.lockerFailedLoadSession} ${_friendly(e)}');
      return;
    }

    await _fetchDetail();
  }

  /// Pull-to-refresh on the details screen.
  Future<void> refresh() => _fetchDetail();

  /// Loads field officers lazily — called when the assign bottom sheet is about
  /// to open. Skips the network call if officers are already cached.
  Future<void> loadOfficersIfNeeded() async {
    if (_officersState == LockerOfficersState.success && _officers.isNotEmpty) {
      return;
    }
    await _fetchOfficers();
  }

  /// Assigns [officerId] to this request. Optimistically updates [_detail] on
  /// success so the UI reflects the change immediately without re-fetching.
  Future<bool> assignOfficer(String officerId) async {
    if (_token == null) {
      _setAssignError(_l10n?.lockerNotAuthenticated ?? 'Not authenticated.');
      return false;
    }

    _assigningOfficerId = officerId;
    _assignState = LockerAssignState.assigning;
    _assignError = null;
    notifyListeners();

    try {
      final returnedOfficerId = await _repository.assignOfficer(
        token: _token!,
        requestId: requestId,
        officerUserId: officerId,
      );

      final officer =
          _officers.where((o) => o.id == returnedOfficerId).firstOrNull;
      final officerName = officer?.name ?? '';

      if (_detail != null) {
        _detail = _detail!.copyWithAssignment(
          officerId: returnedOfficerId,
          officerName: officerName,
        );
      }

      _assignState = LockerAssignState.success;
      _assigningOfficerId = null;
      notifyListeners();

      debugLog(
          '[LockerDetailVM] Assigned officer $returnedOfficerId to request $requestId');
      return true;
    } on UnauthorisedException {
      _setAssignError(_l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setAssignError(_l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setAssignError(_friendly(e));
    } catch (e, st) {
      _setAssignError(_l10n?.lockerAssignmentFailed ?? 'Assignment failed.');
      debugLog('[LockerDetailVM] Unexpected assign error: $e\n$st');
    }

    _assigningOfficerId = null;
    return false;
  }

  void resetAssignState() {
    _assignState = LockerAssignState.idle;
    _assignError = null;
    _assigningOfficerId = null;
    notifyListeners();
  }

  // ── Variance approval / rejection ─────────────────────────────────────────────

  /// Approves the variance for this request's collection.
  ///
  /// The [collectionId] is the ID returned in the collection result section —
  /// i.e. [LockerRequestDetail.collection.id].
  ///
  /// Returns true on success. After success the caller should call [refresh]
  /// to reload the updated status from the server.
  Future<bool> approveVariance({
    required String collectionId,
  }) async {
    return _performVarianceAction(
      collectionId: collectionId,
      status: 'approved',
      rejectionReason: '',
    );
  }

  /// Rejects the variance for this request's collection.
  Future<bool> rejectVariance({
    required String collectionId,
    String rejectionReason = '',
  }) async {
    return _performVarianceAction(
      collectionId: collectionId,
      status: 'rejected',
      rejectionReason: rejectionReason,
    );
  }

  void resetVarianceActionState() {
    _varianceActionState = LockerVarianceActionState.idle;
    _varianceActionError = null;
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  Future<bool> _performVarianceAction({
    required String collectionId,
    required String status,
    required String rejectionReason,
  }) async {
    if (_token == null) {
      _varianceActionState = LockerVarianceActionState.error;
      _varianceActionError = _l10n?.lockerNotAuthenticated ?? 'Not authenticated.';
      notifyListeners();
      return false;
    }

    _varianceActionState = LockerVarianceActionState.processing;
    _varianceActionError = null;
    notifyListeners();

    try {
      await _repository.approveDifference(
        token: _token!,
        collectionId: collectionId,
        status: status,
        rejectionReason: rejectionReason,
      );

      _varianceActionState = LockerVarianceActionState.success;
      _varianceActionError = null;
      notifyListeners();

      debugLog(
          '[LockerDetailVM] Variance $status for collectionId=$collectionId');

      // Refresh detail so status reflects the new state.
      await _fetchDetail();
      return true;
    } on UnauthorisedException {
      _varianceActionState = LockerVarianceActionState.error;
      _varianceActionError = _l10n?.lockerSessionExpired ?? 'Session expired.';
    } on BadRequestException catch (e) {
      _varianceActionState = LockerVarianceActionState.error;
      _varianceActionError = _l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}';
    } on FetchDataException catch (e) {
      _varianceActionState = LockerVarianceActionState.error;
      _varianceActionError = _friendly(e);
    } catch (e, st) {
      _varianceActionState = LockerVarianceActionState.error;
      _varianceActionError = _l10n?.lockerOperationFailed ?? 'Operation failed.';
      debugLog('[LockerDetailVM] Unexpected variance action error: $e\n$st');
    }

    notifyListeners();
    return false;
  }

  Future<void> _fetchDetail() async {
    _detailState = LockerDetailState.loading;
    _detailError = null;
    notifyListeners();

    try {
      _detail = await _repository.getRequestDetail(
        token: _token!,
        requestId: requestId,
      );
      _detailState = LockerDetailState.success;
      _detailError = null;
      notifyListeners();

      debugLog(
          '[LockerDetailVM] Detail loaded — id=$requestId status=${_detail?.status}');
    } on UnauthorisedException {
      _setDetailError(_l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setDetailError(_l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setDetailError(_friendly(e));
    } catch (e, st) {
      _setDetailError(_l10n?.lockerSomethingWentWrong ?? 'Something went wrong.');
      debugLog('[LockerDetailVM] Unexpected detail error: $e\n$st');
    }
  }

  Future<void> _fetchOfficers() async {
    _officersState = LockerOfficersState.loading;
    _officersError = null;
    notifyListeners();

    try {
      _officers = await _repository.getFieldOfficers(token: _token!);
      _officersState = LockerOfficersState.success;
      _officersError = null;
      notifyListeners();

      debugLog('[LockerDetailVM] Officers loaded — count=${_officers.length}');
    } on UnauthorisedException {
      _officersState = LockerOfficersState.error;
      _officersError = _l10n?.lockerSessionExpired ?? 'Session expired.';
      notifyListeners();
    } on BadRequestException catch (e) {
      _officersState = LockerOfficersState.error;
      _officersError = _l10n?.lockerBadRequest(_friendly(e)) ?? 'Bad request: ${_friendly(e)}';
      notifyListeners();
    } on FetchDataException catch (e) {
      _officersState = LockerOfficersState.error;
      _officersError = _friendly(e);
      notifyListeners();
    } catch (e, st) {
      _officersState = LockerOfficersState.error;
      _officersError = _l10n?.lockerCouldNotLoadOfficers ?? 'Could not load officers.';
      notifyListeners();
      debugLog('[LockerDetailVM] Unexpected officers error: $e\n$st');
    }
  }

  void _setDetailError(String msg) {
    _detailState = LockerDetailState.error;
    _detailError = msg;
    notifyListeners();
    debugLog('[LockerDetailVM] Detail error: $msg');
  }

  void _setAssignError(String msg) {
    _assignState = LockerAssignState.error;
    _assignError = msg;
    notifyListeners();
    debugLog('[LockerDetailVM] Assign error: $msg');
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