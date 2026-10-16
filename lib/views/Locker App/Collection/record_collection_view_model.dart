import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

// ── Role-resolution helpers ─────────────────────────────────────────────────
//
// Same approach as LockerRequestsViewModel: DB locker users are always
// saved as userType=workshop_user, with the REAL locker role stored
// separately as lockerPortalRole (supervisor | collector). We need this
// here because the picker must call the supervisor endpoint for a
// supervisor (sees every assigned request in the workshop) and the
// collector endpoint for a collector (sees only their own).

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

// ── State ─────────────────────────────────────────────────────────────────────

enum RecordCollectionState { idle, submitting, success, error }

// ── ViewModel ─────────────────────────────────────────────────────────────────

class RecordCollectionViewModel extends ChangeNotifier {
  // ── Dependencies ─────────────────────────────────────────────────────────────
  final LockerRepository _repository;
  final SessionService _sessionService;

  /// Optional — when supplied, [init] skips the picker and loads this
  /// request's detail directly (e.g. opened from that request's own detail
  /// screen). Leave null for the default entry point, where the user first
  /// picks a request from the dropdown.
  final LockerRequest? initialRequest;

  RecordCollectionViewModel({
    this.initialRequest,
    LockerRepository? repository,
    SessionService? sessionService,
  })  : _repository = repository ?? LockerRepository(),
        _sessionService = sessionService ?? SessionService();

  // ── Session ───────────────────────────────────────────────────────────────────
  String? _token;
  bool _isSupervisor = false;
  AppLocalizations? _l10n;

  /// Whether the signed-in locker user is a supervisor or a collector.
  /// False (collector) until [loadSession] resolves it — matches the
  /// LockerShell/LockerSidebar default, so the sidebar doesn't briefly
  /// flash the full supervisor item set before this loads.
  bool get isSupervisor => _isSupervisor;

  // ── Picked image ─────────────────────────────────────────────────────────────
  //
  // We keep the raw bytes (for preview) and the base64 data-URI string
  // (for the API). The image is compressed to JPEG at 70 % quality so the
  // payload stays manageable — typically 100–300 KB for a phone photo.

  Uint8List? _pickedImageBytes;
  String?    _pickedImageBase64; // "data:image/jpeg;base64,/9j/4AA…"

  Uint8List? get pickedImageBytes   => _pickedImageBytes;
  bool       get hasImage           => _pickedImageBytes != null;

  final ImagePicker _imagePicker = ImagePicker();

  // ── Picker (pending requests) state ──────────────────────────────────────────
  bool _loadingRequests = false;
  String? _requestsError;
  List<LockerRequest> _pendingRequests = const [];

  bool get loadingRequests => _loadingRequests;
  String? get requestsError => _requestsError;
  List<LockerRequest> get pendingRequests => _pendingRequests;

  // ── Selected request + detail state ──────────────────────────────────────────
  LockerRequest? _selectedRequest;
  LockerRequestDetail? _selectedDetail;
  bool _loadingDetail = false;
  String? _detailError;

  LockerRequest? get selectedRequest => _selectedRequest;
  LockerRequestDetail? get selectedDetail => _selectedDetail;
  bool get loadingDetail => _loadingDetail;
  String? get detailError => _detailError;
  bool get hasSelection => _selectedRequest != null;

  /// Expected amount for the currently-selected request, sourced from the
  /// detail endpoint (`totalSecuredAsset`) once loaded, falling back to the
  /// list-level `lockedCashAmount` while detail is still loading.
  double get expectedAmount =>
      _selectedDetail?.totalSecuredAsset ?? _selectedRequest?.lockedCashAmount ?? 0.0;

  // ── Submission state ──────────────────────────────────────────────────────────
  RecordCollectionState _state = RecordCollectionState.idle;
  String? _errorMessage;
  CollectionResult? _result;

  RecordCollectionState get state => _state;
  String? get errorMessage => _errorMessage;
  CollectionResult? get result => _result;

  bool get isSubmitting => _state == RecordCollectionState.submitting;
  bool get isSuccess    => _state == RecordCollectionState.success;
  bool get hasError     => _state == RecordCollectionState.error;

  // ── Derived helpers ───────────────────────────────────────────────────────────

  /// Difference between expected and received (signed: positive = short).
  double computeDifference(double received) => expectedAmount - received;

  // ── Init ──────────────────────────────────────────────────────────────────────

  /// Called once from the view's first frame. Loads the session token, then
  /// either jumps straight to [initialRequest]'s detail or loads the picker
  /// list of pending requests.
  Future<void> init(AppLocalizations l10n) async {
    _l10n = l10n;
    final ok = await loadSession();
    if (!ok) return;

    if (initialRequest != null) {
      await selectRequest(initialRequest!);
    } else {
      await loadPendingRequests();
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Loads the auth token lazily — call once before [submit] or any fetch.
  /// Also resolves whether the signed-in locker user is a supervisor or a
  /// collector, since the picker must call a different API view depending
  /// on that (supervisor → all assigned requests in the workshop;
  /// collector → only their own assigned requests).
  Future<bool> loadSession() async {
    final l10n = _l10n;
    try {
      _token = await _sessionService.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n?.lockerSessionExpired ?? 'Session expired.');
        return false;
      }

      final user = await _sessionService.getUser(role: 'locker');
      final rawUserMap = await _sessionService.getUserDataMap(role: 'locker');
      final userType = user?.userType ??
          _stringFromMap(rawUserMap, const ['userType', 'user_type', 'type']);
      final lockerPortalRole = _lockerRoleFromUser(user) ??
          await _sessionService.getLockerPortalRole(role: 'locker') ??
          _stringFromMap(rawUserMap, const [
            'lockerPortalRole',
            'locker_portal_role',
            'lockerRole',
            'locker_role',
            'role',
          ]);
      _isSupervisor = _isSupervisorRole(
        userType: userType,
        lockerPortalRole: lockerPortalRole,
      );

      debugLog(
        '[RecordCollectionVM] Session loaded — '
            'userType=$userType lockerPortalRole=$lockerPortalRole '
            'isSupervisor=$_isSupervisor',
      );

      return true;
    } catch (e) {
      _setError(
          '${l10n?.lockerFailedLoadSession ?? 'Failed to load session.'} ${_friendly(e)}');
      return false;
    }
  }

  /// Loads the picker list of requests that are ready to be collected.
  ///
  /// - Supervisor: GET .../collection-requests?view=supervisor&status=assigned
  ///   — every assigned request across the whole workshop, not just their own.
  /// - Collector: GET .../collection-requests?view=collector&status=assigned
  ///   — only the requests assigned to this collector.
  Future<void> loadPendingRequests() async {
    if (_token == null) {
      final ok = await loadSession();
      if (!ok) return;
    }

    _loadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      final page = await _repository.getCollectionRequests(
        token: _token!,
        view: _isSupervisor ? 'supervisor' : 'collector',
        status: 'assigned',
        page: 1,
        limit: 50,
      );
      _pendingRequests = page.items;
      _loadingRequests = false;
      notifyListeners();
    } on UnauthorisedException {
      _loadingRequests = false;
      _requestsError = _l10n?.lockerSessionExpired ?? 'Session expired.';
      notifyListeners();
    } catch (e) {
      _loadingRequests = false;
      _requestsError = _l10n?.lockerFailedLoadRequests ?? 'Failed to load requests.';
      notifyListeners();
      debugLog('[RecordCollectionVM] loadPendingRequests error: $e');
    }
  }

  /// Selects a request from the picker (or sets the initial request) and
  /// fetches its full detail — including the counter-closing breakdown —
  /// from GET /locker/collection-requests/{id}.
  Future<void> selectRequest(LockerRequest request) async {
    _selectedRequest = request;
    _selectedDetail = null;
    _detailError = null;
    _loadingDetail = true;
    notifyListeners();

    if (_token == null) {
      final ok = await loadSession();
      if (!ok) {
        _loadingDetail = false;
        _detailError = _errorMessage;
        notifyListeners();
        return;
      }
    }

    try {
      final detail = await _repository.getRequestDetail(
        token: _token!,
        requestId: request.id,
      );
      _selectedDetail = detail;
      _loadingDetail = false;
      notifyListeners();
    } on UnauthorisedException {
      _loadingDetail = false;
      _detailError = _l10n?.lockerSessionExpired ?? 'Session expired.';
      notifyListeners();
    } on BadRequestException catch (e) {
      _loadingDetail = false;
      _detailError = _friendly(e);
      notifyListeners();
    } on FetchDataException catch (e) {
      _loadingDetail = false;
      _detailError = _friendly(e);
      notifyListeners();
    } catch (e) {
      _loadingDetail = false;
      _detailError =
          _l10n?.lockerFailedLoadRequestDetails ?? 'Failed to load request details.';
      notifyListeners();
      debugLog('[RecordCollectionVM] selectRequest error: $e');
    }
  }

  /// Submits the collection record to the API.
  ///
  /// [proofUrl] is optional — if omitted (or empty), the currently picked
  /// image's base64 data-URI is used automatically so the caller doesn't
  /// have to know about the internal image state.
  ///
  /// Returns [true] on success; the caller can then read [result] for details.
  /// Returns [false] on any error; read [errorMessage] for a user-facing string.
  Future<bool> submit({
    required double receivedAmount,
    String notes = '',
    String proofUrl = '',
  }) async {
    final request = _selectedRequest;
    if (request == null) {
      _setError(_l10n?.lockerNoRequestSelected ?? 'No request selected.');
      return false;
    }

    // Use the picked image base64 string if the caller didn't supply
    // an explicit proofUrl.
    final resolvedProofUrl =
    proofUrl.isNotEmpty ? proofUrl : (_pickedImageBase64 ?? '');

    // Ensure we have a token (idempotent call).
    if (_token == null) {
      final ok = await loadSession();
      if (!ok) return false;
    }

    _state = RecordCollectionState.submitting;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    debugLog(
      '[RecordCollectionVM] Submitting — requestId=${request.id} '
          'receivedAmount=$receivedAmount',
    );

    try {
      final result = await _repository.recordCollection(
        token          : _token!,
        requestId      : request.id,
        receivedAmount : receivedAmount,
        notes          : notes,
        proofUrl       : resolvedProofUrl,
      );

      _result = result;
      _state = RecordCollectionState.success;
      _errorMessage = null;
      notifyListeners();

      debugLog(
        '[RecordCollectionVM] Success — collectionId=${result.collectionId} '
            'difference=${result.difference} status=${result.collectionStatus}',
      );

      return true;
    } on UnauthorisedException {
      _setError(_l10n?.lockerSessionExpired ?? 'Session expired.');
    } on BadRequestException catch (e) {
      _setError(_friendly(e));
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e, st) {
      _setError(_l10n?.lockerSomethingWentWrong ?? 'Something went wrong.');
      debugLog('[RecordCollectionVM] Unexpected error: $e\n$st');
    }

    return false;
  }

  /// Resets to idle — allows the user to correct and resubmit after an error.
  void resetError() {
    if (_state == RecordCollectionState.error) {
      _state = RecordCollectionState.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ── Image pick / clear ───────────────────────────────────────────────────────

  /// Opens the camera or gallery (controlled by [source]), compresses the
  /// result to JPEG 70 %, stores raw bytes for in-app preview, and builds
  /// the base64 data-URI string that will be sent to the API on submit.
  ///
  /// Uses `image_picker` (Android Photo Picker for gallery; CAMERA for capture).
  /// No broad READ_MEDIA_IMAGES / storage permission — Play policy compliant.
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        // Resize to at most 1920 × 1920 — enough for evidence photos while
        // keeping the base64 string well under typical API body-size limits.
        maxWidth: 1920,
        maxHeight: 1920,
        // 70 % JPEG quality — good visual fidelity, manageable file size.
        imageQuality: 70,
        requestFullMetadata: false,
      );

      if (file == null) return; // user cancelled

      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      _pickedImageBytes   = bytes;
      _pickedImageBase64  = 'data:image/jpeg;base64,$base64Str';
      notifyListeners();

      debugLog(
        '[RecordCollectionVM] Image picked — '
            '${(bytes.lengthInBytes / 1024).toStringAsFixed(0)} KB '
            'source=${source.name}',
      );
    } catch (e) {
      debugLog('[RecordCollectionVM] pickImage error: $e');
      // Non-fatal — the user can try again; we don't overwrite errorMessage
      // here because the submission state (_state) is unrelated.
    }
  }

  /// Removes the currently attached image so the user can pick again or
  /// submit without a photo (evidence is optional).
  void clearImage() {
    _pickedImageBytes  = null;
    _pickedImageBase64 = null;
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  void _setError(String msg) {
    _state = RecordCollectionState.error;
    _errorMessage = msg;
    notifyListeners();
    debugLog('[RecordCollectionVM] Error: $msg');
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