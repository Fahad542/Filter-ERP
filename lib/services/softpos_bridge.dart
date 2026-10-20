import 'dart:async';
import 'dart:math';

import 'realtime_service.dart';
import 'softpos_protocol.dart';
import 'softpos_settings.dart';
import 'softpos_terminals_api.dart';

class SoftPosBridgeException implements Exception {
  final String message;
  const SoftPosBridgeException(this.message);

  @override
  String toString() => message;
}

class _SoftPosActiveSession {
  final String requestId;
  final double amount;
  final Completer<SoftPosPaymentResult> completer;
  final Future<void> Function() cleanup;

  const _SoftPosActiveSession({
    required this.requestId,
    required this.amount,
    required this.completer,
    required this.cleanup,
  });
}

/// Sends card payments to SoftPOS via backend Socket.IO only (no LAN bridge).
abstract final class SoftPosBridge {
  static const _paymentTimeout = Duration(minutes: 3);
  static _SoftPosActiveSession? _active;

  /// Stops an in-flight SoftPOS payment from the POS waiting dialog.
  static Future<void> cancelActivePayment() async {
    final session = _active;
    if (session == null) return;

    try {
      await SoftPosTerminalsApi().cancelPaymentRequest(
        session.requestId,
        message: 'Cancelled from POS',
      );
    } catch (_) {
      // SoftPOS unreachable — still cancel locally below.
    }

    if (!session.completer.isCompleted) {
      session.completer.complete(
        SoftPosPaymentResult(
          requestId: session.requestId,
          status: SoftPosProtocol.statusCancelled,
          amount: session.amount,
          message: 'Cancelled from POS',
          processedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    await session.cleanup();
    if (identical(_active, session)) {
      _active = null;
    }
  }

  static String newRequestId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(999999)}';
  }

  /// True when bound SoftPOS handset reported presence recently.
  static Future<bool> isBoundDeviceOnline() async {
    try {
      final binding = await SoftPosTerminalsApi().getBinding();
      return binding?.online == true;
    } catch (_) {
      return false;
    }
  }

  /// SoftPOS is triggered only for Tap to Pay (not Card).
  static bool isSoftPosPaymentMethod(String? raw) {
    final method = (raw ?? '').toString().trim().toLowerCase();
    if (method.isEmpty) return false;
    final compact = method.replaceAll(RegExp(r'[\s_\-]'), '');
    return compact.contains('taptopay') ||
        compact == 'softpos' ||
        compact == 'nearpay' ||
        (method.contains('tap') && method.contains('pay'));
  }

  static double softPosAmountFromSplits(List<Map<String, dynamic>> splits) {
    var sum = 0.0;
    for (final s in splits) {
      if (isSoftPosPaymentMethod(s['method']?.toString())) {
        sum += (s['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return sum;
  }

  /// Deprecated name — SoftPOS follows Tap to Pay splits only.
  static double cardAmountFromSplits(List<Map<String, dynamic>> splits) =>
      softPosAmountFromSplits(splits);

  static bool splitsIncludeSoftPos(List<Map<String, dynamic>>? splits) {
    if (splits == null || splits.isEmpty) return false;
    return splits.any((s) => isSoftPosPaymentMethod(s['method']?.toString()));
  }

  /// Deprecated name — SoftPOS follows Tap to Pay splits only.
  static bool splitsIncludeCard(List<Map<String, dynamic>>? splits) =>
      splitsIncludeSoftPos(splits);

  /// Backend Socket.IO: cashier payment-request → SoftPOS handset → result event.
  static Future<SoftPosPaymentResult> requestPaymentViaSocket({
    required SoftPosPaymentRequest request,
  }) async {
    final completer = Completer<SoftPosPaymentResult>();
    Timer? timeoutTimer;
    Timer? pollTimer;
    late void Function(Map<String, dynamic>) onUpdate;
    final realtime = RealtimeService();
    final api = SoftPosTerminalsApi();

    Future<void> cleanup() async {
      timeoutTimer?.cancel();
      pollTimer?.cancel();
      realtime.off(RealtimeService.eventCashierSoftPosPaymentUpdated, onUpdate);
      if (identical(_active?.completer, completer)) {
        _active = null;
      }
    }

    onUpdate = (payload) {
      final id = payload['requestId']?.toString();
      if (id != request.requestId) return;
      final status = payload['status']?.toString() ?? '';
      if (status == 'pending') return;
      if (completer.isCompleted) return;
      completer.complete(
        SoftPosPaymentResult(
          requestId: request.requestId,
          status: status.isEmpty ? SoftPosProtocol.statusDeclined : status,
          amount: (payload['amount'] is num)
              ? (payload['amount'] as num).toDouble()
              : request.amount,
          authCode: payload['authCode']?.toString(),
          message: payload['message']?.toString(),
          processedAt: payload['updatedAt']?.toString() ??
              DateTime.now().toIso8601String(),
        ),
      );
    };

    try {
      realtime.on(RealtimeService.eventCashierSoftPosPaymentUpdated, onUpdate);

      await api.createPaymentRequest({
        'requestId': request.requestId,
        'amount': request.amount,
        'currency': request.currency,
        'orderId': request.orderId,
        if (request.orderNo != null) 'orderNo': request.orderNo,
        if (request.customerName != null) 'customerName': request.customerName,
        if (request.customerMobile != null)
          'customerMobile': request.customerMobile,
        if (request.plateNo != null) 'plateNo': request.plateNo,
        if (request.lineSummary != null) 'lineSummary': request.lineSummary,
        if (request.lineItems.isNotEmpty) 'lineItems': request.lineItems,
        if (request.totalBeforeDiscount != null)
          'totalBeforeDiscount': request.totalBeforeDiscount,
        if (request.totalDiscount != null)
          'totalDiscount': request.totalDiscount,
        if (request.vatAmount != null) 'vatAmount': request.vatAmount,
        if (request.vehicleMake != null) 'vehicleMake': request.vehicleMake,
        if (request.vehicleModel != null) 'vehicleModel': request.vehicleModel,
        if (request.vehicleVin != null) 'vehicleVin': request.vehicleVin,
        if (request.mileage != null) 'mileage': request.mileage,
        if (request.nextOilChangeKm != null)
          'nextOilChangeKm': request.nextOilChangeKm,
        if (request.customerType != null) 'customerType': request.customerType,
        if (request.customerTaxId != null)
          'customerTaxId': request.customerTaxId,
        'paymentLabel': request.paymentLabel,
        if (request.intentUuid != null && request.intentUuid!.isNotEmpty)
          'intentUuid': request.intentUuid,
      });

      _active = _SoftPosActiveSession(
        requestId: request.requestId,
        amount: request.amount,
        completer: completer,
        cleanup: cleanup,
      );

      // Fallback poll in case socket event is missed.
      pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (completer.isCompleted) return;
        try {
          final row = await api.getPaymentRequestStatus(request.requestId);
          if (row == null) return;
          final status = row['status']?.toString() ?? '';
          if (status == 'pending' || status.isEmpty) return;
          onUpdate(row);
        } catch (_) {}
      });

      timeoutTimer = Timer(_paymentTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            const SoftPosBridgeException(
              'SoftPOS payment timed out. Check the SoftPOS app.',
            ),
          );
        }
      });

      final result = await completer.future;
      await cleanup();
      return result;
    } catch (e) {
      await cleanup();
      if (e is SoftPosBridgeException) rethrow;
      throw SoftPosBridgeException(
        e is TimeoutException
            ? 'SoftPOS payment timed out. Check the SoftPOS app.'
            : 'SoftPOS backend bridge failed: $e',
      );
    }
  }

  /// Runs bridge when enabled and Tap to Pay is in [paymentSplits].
  /// Requires a bound SoftPOS device — backend socket only.
  static Future<bool> runIfNeeded({
    required List<Map<String, dynamic>>? paymentSplits,
    required SoftPosPaymentRequest request,
  }) async {
    final settings = await SoftPosSettings.load();
    if (!settings.enabled) return true;
    if (!splitsIncludeSoftPos(paymentSplits)) return true;

    final softPosAmount = softPosAmountFromSplits(paymentSplits!);
    if (softPosAmount <= 0.001) return true;

    final deviceId = (settings.deviceId ?? '').trim();
    if (deviceId.isEmpty) {
      throw const SoftPosBridgeException(
        'SoftPOS is not bound. Open SoftPOS settings and bind a terminal.',
      );
    }

    final payRequest = SoftPosPaymentRequest(
      requestId: request.requestId,
      callbackUrl: SoftPosProtocol.socketCallbackUrl,
      amount: softPosAmount,
      currency: request.currency,
      orderId: request.orderId,
      orderNo: request.orderNo,
      customerName: request.customerName,
      customerMobile: request.customerMobile,
      plateNo: request.plateNo,
      vehicleMake: request.vehicleMake,
      vehicleModel: request.vehicleModel,
      vehicleVin: request.vehicleVin,
      mileage: request.mileage,
      nextOilChangeKm: request.nextOilChangeKm,
      customerType: request.customerType,
      customerTaxId: request.customerTaxId,
      lineSummary: request.lineSummary,
      lineItems: request.lineItems,
      totalBeforeDiscount: request.totalBeforeDiscount,
      totalDiscount: request.totalDiscount,
      vatAmount: request.vatAmount,
      paymentLabel: request.paymentLabel,
      intentUuid: request.intentUuid,
    );

    // ignore: avoid_print
    print('[SoftPOS bridge] socket path deviceId=$deviceId');
    final result = await requestPaymentViaSocket(request: payRequest);
    return result.approved;
  }
}
