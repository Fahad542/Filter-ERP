import 'package:flutter/material.dart';

import '../models/pos_order_model.dart';
import '../services/session_service.dart';
import '../widgets/softpos_settings_dialog.dart';
import 'payment_intents_service.dart';
import 'softpos_access_service.dart';
import 'softpos_bridge.dart';
import 'softpos_invoice_flow.dart';
import 'softpos_protocol.dart';

class SoftPosRequestPaymentResult {
  final bool approved;
  final String? intentUuid;

  const SoftPosRequestPaymentResult({
    required this.approved,
    this.intentUuid,
  });
}

/// Collects Tap to Pay via Filter SoftPOS (legacy Request Payment path).
Future<SoftPosRequestPaymentResult> runSoftPosRequestPayment({
  required BuildContext context,
  required PosOrder order,
  required List<Map<String, dynamic>> paymentSplits,
  String? customerNameOverride,
  String? customerMobileOverride,
  String? plateNoOverride,
}) async {
  if (!isSoftPosUiEnabled) {
    return const SoftPosRequestPaymentResult(approved: true);
  }
  if (!SoftPosBridge.splitsIncludeSoftPos(paymentSplits)) {
    return const SoftPosRequestPaymentResult(approved: true);
  }

  final softPosAmount = SoftPosBridge.softPosAmountFromSplits(paymentSplits);
  if (softPosAmount <= 0.001) {
    return const SoftPosRequestPaymentResult(approved: true);
  }

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

  final approved = await showSoftPosWaitingDialog(
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
        customerName:
            (customerNameOverride ?? customer?.name ?? '').trim().isNotEmpty
                ? (customerNameOverride ?? customer?.name)?.trim()
                : null,
        customerMobile:
            (customerMobileOverride ?? customer?.mobile ?? '').trim().isNotEmpty
                ? (customerMobileOverride ?? customer?.mobile)?.trim()
                : null,
        plateNo: (plateNoOverride ?? vehicle?.displayPlate ?? vehicle?.plateNo ?? '')
                .trim()
                .isNotEmpty
            ? (plateNoOverride ?? vehicle?.displayPlate ?? vehicle?.plateNo)?.trim()
            : null,
        vehicleMake: (vehicle?.make ?? '').trim().isNotEmpty
            ? vehicle!.make.trim()
            : null,
        vehicleModel: (vehicle?.model ?? '').trim().isNotEmpty
            ? vehicle!.model.trim()
            : null,
        vehicleVin: (vehicle?.vin ?? '').trim().isNotEmpty
            ? vehicle!.vin!.trim()
            : null,
        mileage: order.odometerReading > 0 ? order.odometerReading : null,
        customerType: softPosCustomerTypeFromOrder(order),
        customerTaxId: (customer?.vatNumber ?? '').trim().isNotEmpty
            ? customer!.vatNumber.trim()
            : null,
        lineSummary: softPosLineSummaryFromOrder(order),
        lineItems: softPosLineItemsFromOrder(order),
        totalBeforeDiscount: softPosTotalBeforeDiscountFromOrder(order),
        totalDiscount: softPosTotalDiscountFromOrder(order),
        vatAmount: softPosVatFromOrder(order, amount: softPosAmount),
        paymentLabel: 'Tap to Pay',
      ),
    ),
  );

  return SoftPosRequestPaymentResult(
    approved: approved,
    intentUuid: intentUuid,
  );
}
