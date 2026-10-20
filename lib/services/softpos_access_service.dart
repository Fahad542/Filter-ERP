import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/pos_softpos_feature.dart';
import '../data/network/api_constants.dart';
import '../data/network/base_api_service.dart';
import '../models/pos_payment_method.dart';
import 'realtime_service.dart';
import 'session_service.dart';

/// Server-driven POS payment method gates for the cashier POS.
///
/// SoftPOS effective = compile flag ∩ platform global ∩ branch toggle.
/// Other methods = platform global ∩ branch toggle (fail-open when unloaded).
/// Updates in real time via `cashier.softpos.access.updated`.
class SoftPosAccessService extends ChangeNotifier {
  SoftPosAccessService._();
  static final SoftPosAccessService instance = SoftPosAccessService._();
  factory SoftPosAccessService() => instance;

  static const accessCodes = <String>[
    'softpos',
    'card',
    'cash',
    'bank_transfer',
    'tabby',
    'tamara',
    'monthly_billing',
  ];

  final SessionService _session = SessionService();
  final BaseApiService _api = BaseApiService();
  final RealtimeService _realtime = RealtimeService();

  final Map<String, bool> _globalByMethod = {
    for (final c in accessCodes) c: true,
  };
  final Map<String, bool> _branchByMethod = {
    for (final c in accessCodes) c: true,
  };
  bool _loaded = false;
  bool _listening = false;
  String? _branchId;

  bool get loaded => _loaded;
  bool get globalEnabled => _globalByMethod['softpos'] != false;
  bool get branchEnabled => _branchByMethod['softpos'] != false;

  /// SoftPOS UI + Tap to Pay bridge may run.
  bool get enabled =>
      kPosSoftPosFrontendEnabled &&
      _globalByMethod['softpos'] != false &&
      _branchByMethod['softpos'] != false;

  /// Whether [accessCode] is allowed on this cashier's branch.
  bool isMethodEnabled(String accessCode) {
    final code = accessCode.trim().toLowerCase();
    if (code == 'softpos') return enabled;
    if (!accessCodes.contains(code)) return true;
    return _globalByMethod[code] != false && _branchByMethod[code] != false;
  }

  /// Map Flutter [PaymentMethod] → access code (null = ungated).
  static String? accessCodeFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.tapToPay:
        return 'softpos';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.tabby:
        return 'tabby';
      case PaymentMethod.tamara:
        return 'tamara';
      case PaymentMethod.monthlyBilling:
        return 'monthly_billing';
      case PaymentMethod.wallet:
      case PaymentMethod.employees:
        return null;
    }
  }

  bool isPaymentMethodEnabled(PaymentMethod method) {
    final code = accessCodeFor(method);
    if (code == null) return true;
    return isMethodEnabled(code);
  }

  void applyPayload(Map<String, dynamic> payload) {
    final method = (payload['method'] ?? 'softpos').toString().trim().toLowerCase();
    final code = accessCodes.contains(method) ? method : 'softpos';
    final global = payload['globalEnabled'];
    final branch = payload['branchEnabled'];
    final enabledFlag = payload['enabled'];
    final eventBranchId = payload['branchId']?.toString();

    if (eventBranchId == null || eventBranchId.isEmpty) {
      if (global is bool) {
        _globalByMethod[code] = global;
      } else if (enabledFlag is bool) {
        _globalByMethod[code] = enabledFlag;
      }
      _loaded = true;
      notifyListeners();
      return;
    }

    // Only apply branchEnabled for THIS cashier's branch (or before we know it).
    final forThisBranch = _branchId == null ||
        _branchId!.isEmpty ||
        eventBranchId == _branchId;

    if (global is bool) _globalByMethod[code] = global;
    if (forThisBranch && branch is bool) {
      _branchByMethod[code] = branch;
    }
    _loaded = true;
    notifyListeners();
  }

  void _applyMethodsMap(dynamic raw) {
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final code = entry.key.toString();
      if (!accessCodes.contains(code)) continue;
      final value = entry.value;
      if (value is! Map) continue;
      final map = Map<String, dynamic>.from(value);
      if (map['globalEnabled'] is bool) {
        _globalByMethod[code] = map['globalEnabled'] as bool;
      }
      if (map['branchEnabled'] is bool) {
        _branchByMethod[code] = map['branchEnabled'] as bool;
      }
    }
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
      // Nest may return the payload at the top level or under `data`.
      var map = Map<String, dynamic>.from(raw);
      final nested = map['data'];
      if (nested is Map &&
          (map['methods'] == null || map['branchId'] == null)) {
        map = Map<String, dynamic>.from(nested);
      }
      _branchId = map['branchId']?.toString() ?? _branchId;
      _globalByMethod['softpos'] = map['globalEnabled'] != false;
      _branchByMethod['softpos'] = map['branchEnabled'] != false;
      _applyMethodsMap(map['methods']);
      _loaded = true;
      notifyListeners();
      if (kDebugMode) {
        final off = accessCodes
            .where((c) => !isMethodEnabled(c))
            .toList(growable: false);
        debugPrint(
          '[SoftPosAccess] branch=$_branchId loaded; hidden=$off',
        );
      }
    } catch (e) {
      debugPrint('[SoftPosAccess] refresh failed: $e');
      // Fail-open so SoftPOS stays usable if the endpoint is briefly down.
      if (!_loaded) {
        for (final c in accessCodes) {
          _globalByMethod[c] = true;
          _branchByMethod[c] = true;
        }
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

/// Server gate for any gated POS payment method (SoftPOS / card / cash / …).
bool isPosPaymentMethodUiEnabled(PaymentMethod method) =>
    SoftPosAccessService.instance.isPaymentMethodEnabled(method);
