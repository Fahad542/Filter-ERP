import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/pos_softpos_feature.dart';
import '../data/network/api_constants.dart';
import '../data/network/base_api_service.dart';
import 'realtime_service.dart';
import 'session_service.dart';

/// Server-driven SoftPOS / NFC gate for the cashier POS.
///
/// Effective = compile flag ∩ platform global ∩ branch toggle.
/// Updates in real time via `cashier.softpos.access.updated`.
class SoftPosAccessService extends ChangeNotifier {
  SoftPosAccessService._();
  static final SoftPosAccessService instance = SoftPosAccessService._();
  factory SoftPosAccessService() => instance;

  final SessionService _session = SessionService();
  final BaseApiService _api = BaseApiService();
  final RealtimeService _realtime = RealtimeService();

  bool _globalEnabled = true;
  bool _branchEnabled = true;
  bool _loaded = false;
  bool _listening = false;
  String? _branchId;

  bool get loaded => _loaded;
  bool get globalEnabled => _globalEnabled;
  bool get branchEnabled => _branchEnabled;

  /// SoftPOS UI + Tap to Pay bridge may run.
  bool get enabled =>
      kPosSoftPosFrontendEnabled && _globalEnabled && _branchEnabled;

  void applyPayload(Map<String, dynamic> payload) {
    final global = payload['globalEnabled'];
    final branch = payload['branchEnabled'];
    final enabledFlag = payload['enabled'];
    final eventBranchId = payload['branchId']?.toString();

    if (eventBranchId == null || eventBranchId.isEmpty) {
      if (global is bool) {
        _globalEnabled = global;
      } else if (enabledFlag is bool) {
        _globalEnabled = enabledFlag;
      }
      _loaded = true;
      notifyListeners();
      return;
    }

    if (_branchId != null &&
        _branchId!.isNotEmpty &&
        eventBranchId != _branchId) {
      if (global is bool) {
        _globalEnabled = global;
        _loaded = true;
        notifyListeners();
      }
      return;
    }

    if (global is bool) _globalEnabled = global;
    if (branch is bool) _branchEnabled = branch;
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final token = await _session.getToken(role: 'cashier');
      if (token == null || token.isEmpty) return;
      final raw = await _api.get(
        ApiConstants.cashierSoftPosAccessEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);
      _branchId = map['branchId']?.toString() ?? _branchId;
      _globalEnabled = map['globalEnabled'] != false;
      _branchEnabled = map['branchEnabled'] != false;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[SoftPosAccess] refresh failed: $e');
      // Fail-open so SoftPOS stays usable if the endpoint is briefly down.
      if (!_loaded) {
        _globalEnabled = true;
        _branchEnabled = true;
        _loaded = true;
        notifyListeners();
      }
    }
  }

  void ensureListening() {
    if (_listening) return;
    _listening = true;
    _realtime.on(
      RealtimeService.eventCashierSoftPosAccessUpdated,
      (payload) {
        applyPayload(payload);
        unawaited(refresh());
      },
    );
    unawaited(refresh());
  }

  Future<void> start() async {
    ensureListening();
    await refresh();
  }
}

/// Compile flag ∩ server SoftPOS access.
bool get isSoftPosUiEnabled => SoftPosAccessService.instance.enabled;
