import 'package:flutter/material.dart';

import '../models/pos_order_model.dart';
import '../services/session_service.dart';
import '../widgets/softpos_settings_dialog.dart';
import 'payment_intents_service.dart';
import 'softpos_access_service.dart';
import 'softpos_bridge.dart';
import 'softpos_protocol.dart';

String softPosLineSummaryFromOrder(PosOrder order) {
  final names = <String>[];
  for (final job in order.jobs) {
    if (job.isCancelledJob) continue;
    for (final item in job.items) {
      final n = item.productName.trim();
      if (n.isNotEmpty) names.add(n);
    }
  }
  if (names.isEmpty) return '${order.jobsCount} job(s)';
  if (names.length <= 3) return names.join(', ');
  return '${names.take(3).join(', ')} +${names.length - 3} more';
}

/// When SoftPOS is enabled and Tap to Pay is in [paymentSplits], shows waiting UI
/// and sends payment to the Filter SoftPOS app. Returns false to abort invoicing.
Future<bool> runSoftPosBeforeInvoice({
  required BuildContext context,
  required PosOrder order,
  required List<Map<String, dynamic>>? paymentSplits,
  String? customerNameOverride,
  String? customerMobileOverride,
  String? plateNoOverride,
}) async {
  if (!isSoftPosUiEnabled) return true;
  if (paymentSplits == null ||
      !SoftPosBridge.splitsIncludeSoftPos(paymentSplits)) {
    return true;
  }

  final softPosAmount = SoftPosBridge.softPosAmountFromSplits(paymentSplits);
  if (softPosAmount <= 0.001) return true;

  final customer = order.customer;
  final vehicle = order.vehicle;

  String? intentUuid;
  final token = await SessionService().getToken(role: 'cashier');
  if (token != null) {
    try {
      final intent = await PaymentIntentsService.createPosCardIntent(
        token: token,
        amount: softPosAmount,
        orderId: order.id,
        externalReference: order.invoiceNo ?? 'ORD-${order.id}',
      );
      intentUuid = intent.intentId;
    } on PaymentIntentException catch (e) {
      throw SoftPosBridgeException(
        'Could not create payment intent: ${e.message}',
      );
    }
  }

  return showSoftPosWaitingDialog(
    context,
    amount: softPosAmount,
    paymentFuture: SoftPosBridge.runIfNeeded(
      paymentSplits: paymentSplits,
      request: SoftPosPaymentRequest(
        requestId: SoftPosBridge.newRequestId(),
        callbackUrl: '',
        amount: softPosAmount,
        orderId: order.id,
        orderNo: order.invoiceNo ?? order.id,
        intentUuid: intentUuid,
        paymentLabel: 'Tap to Pay',
        customerName:
            (customerNameOverride ?? customer?.name ?? '').trim().isNotEmpty
                ? (customerNameOverride ?? customer?.name)?.trim()
                : null,
        customerMobile:
            (customerMobileOverride ?? customer?.mobile ?? '').trim().isNotEmpty
                ? (customerMobileOverride ?? customer?.mobile)?.trim()
                : null,
        plateNo: (plateNoOverride ?? vehicle?.plateNo ?? '').trim().isNotEmpty
            ? (plateNoOverride ?? vehicle?.plateNo)?.trim()
            : null,
        lineSummary: softPosLineSummaryFromOrder(order),
      ),
    ),
  );
}

/// SoftPOS before takeaway checkout (no sales order yet — skip payment-intent create).
Future<bool> runSoftPosBeforeTakeawayCheckout({
  required BuildContext context,
  required List<Map<String, dynamic>>? paymentSplits,
  String? customerName,
  String? customerMobile,
  String lineSummary = 'Takeaway',
}) async {
  if (!isSoftPosUiEnabled) return true;
  if (paymentSplits == null ||
      !SoftPosBridge.splitsIncludeSoftPos(paymentSplits)) {
    return true;
  }

  final softPosAmount = SoftPosBridge.softPosAmountFromSplits(paymentSplits);
  if (softPosAmount <= 0.001) return true;

  final name = (customerName ?? '').trim();
  final mobile = (customerMobile ?? '').trim();

  return showSoftPosWaitingDialog(
    context,
    amount: softPosAmount,
    paymentFuture: SoftPosBridge.runIfNeeded(
      paymentSplits: paymentSplits,
      request: SoftPosPaymentRequest(
        requestId: SoftPosBridge.newRequestId(),
        callbackUrl: '',
        amount: softPosAmount,
        orderId: 'takeaway',
        orderNo: 'TAKEAWAY',
        intentUuid: null,
        paymentLabel: 'Tap to Pay',
        customerName: name.isNotEmpty ? name : null,
        customerMobile: mobile.isNotEmpty ? mobile : null,
        plateNo: null,
        lineSummary: lineSummary,
      ),
    ),
  );
}
