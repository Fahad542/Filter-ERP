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

List<Map<String, dynamic>> softPosLineItemsFromOrder(PosOrder order) {
  final items = <Map<String, dynamic>>[];
  for (final job in order.jobs) {
    if (job.isCancelledJob) continue;
    for (final item in job.items) {
      final n = item.productName.trim();
      if (n.isEmpty) continue;
      final qty = item.qty > 0 ? item.qty : 1.0;
      // SoftPOS receipt Base Price is always VAT-exclusive.
      var unitPrice = item.unitPriceExcludingVat;
      if (unitPrice <= 0 && item.lineTotalExcludingVat > 0) {
        unitPrice = item.lineTotalExcludingVat / qty;
      }
      if (unitPrice <= 0 && item.unitPrice > 0) {
        unitPrice = item.unitPrice / 1.15;
      }
      if (unitPrice <= 0 && item.lineTotal > 0) {
        unitPrice = (item.lineTotal / 1.15) / qty;
      }
      items.add({
        'name': n,
        'qty': qty,
        'unitPrice': double.parse(unitPrice.toStringAsFixed(2)),
        'lineTotal': item.lineTotalExcludingVat > 0
            ? item.lineTotalExcludingVat
            : double.parse((unitPrice * qty).toStringAsFixed(2)),
      });
    }
  }
  return items;
}

double softPosTotalDiscountFromOrder(PosOrder order) {
  var d = (order.promoDiscountAmount ?? 0) + order.referralDiscountAmount;
  final tdv = order.totalDiscountValue ?? 0;
  final tdt = (order.totalDiscountType ?? 'amount').toLowerCase();
  if (tdv > 0 && tdt != 'percent' && tdt != 'percentage') {
    d += tdv;
  }
  for (final job in order.jobs) {
    if (job.isCancelledJob) continue;
    final before = job.amountBeforeDiscount;
    final after = job.amountAfterDiscount;
    if (before > after + 0.0001) {
      d += before - after;
    } else {
      d += job.promoDiscountAmount + job.totalDiscountValue;
    }
  }
  return (d * 100).roundToDouble() / 100;
}

double softPosVatFromOrder(PosOrder order, {required double amount}) {
  var vat = 0.0;
  for (final job in order.jobs) {
    if (job.isCancelledJob) continue;
    vat += job.vatAmount;
  }
  if (vat > 0.0001) return (vat * 100).roundToDouble() / 100;
  if (amount <= 0) return 0;
  return ((amount * 15) / 115 * 100).roundToDouble() / 100;
}


double softPosTotalBeforeDiscountFromOrder(PosOrder order) {
  var t = 0.0;
  for (final job in order.jobs) {
    if (job.isCancelledJob) continue;
    if (job.amountBeforeDiscount > 0) {
      t += job.amountBeforeDiscount;
    } else {
      t += job.totalAmount;
    }
  }
  if (t <= 0.0001 && order.subtotal > 0) t = order.subtotal;
  if (t <= 0.0001) t = order.totalAmount;
  return (t * 100).roundToDouble() / 100;
}

String? softPosCustomerTypeFromOrder(PosOrder order) {
  final kind = (order.posCustomerKind ?? '').trim();
  if (kind.isNotEmpty) {
    final lower = kind.toLowerCase();
    if (lower == 'corporate') return 'Corporate';
    if (lower == 'individual') return 'Individual';
    return kind[0].toUpperCase() + kind.substring(1);
  }
  if (order.customer?.isCustomerEmployee == true) return 'Employee';
  return null;
}

int? softPosNextOilChangeKmFromOrder(PosOrder order) {
  final odo = order.odometerReading;
  if (odo <= 0) return null;
  // SoftPOS does not have catalog km intervals here; POS can send if known.
  // Fallback: show mileage-based placeholder only when odometer set — omit next.
  return null;
}

Map<String, dynamic> softPosCustomerVehicleFieldsFromOrder(PosOrder order) {
  final c = order.customer;
  final v = order.vehicle;
  final make = (v?.make ?? '').trim();
  final model = (v?.model ?? '').trim();
  final vin = (v?.vin ?? '').trim();
  final tax = (c?.vatNumber ?? '').trim();
  final type = softPosCustomerTypeFromOrder(order);
  final plate = (v?.displayPlate ?? v?.plateNo ?? '').trim();
  return {
    if (make.isNotEmpty) 'vehicleMake': make,
    if (model.isNotEmpty) 'vehicleModel': model,
    if (vin.isNotEmpty) 'vehicleVin': vin,
    if (order.odometerReading > 0) 'mileage': order.odometerReading,
    if (type != null) 'customerType': type,
    if (tax.isNotEmpty) 'customerTaxId': tax,
    if (plate.isNotEmpty) 'plateNo': plate,
  };
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
  List<Map<String, dynamic>> lineItems = const [],
  double? totalDiscount,
  double? vatAmount,
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
  final vat = vatAmount ??
      ((softPosAmount * 15) / 115 * 100).roundToDouble() / 100;

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
        lineItems: lineItems,
        totalDiscount: totalDiscount ?? 0,
        vatAmount: vat,
      ),
    ),
  );
}
