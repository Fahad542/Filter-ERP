import 'package:flutter/material.dart';

import '../models/create_invoice_model.dart';
import '../utils/thermal_invoice_totals.dart';
import 'invoice_print_prefetch.dart';

/// Payment label used by thermal print + invoice dialog action bar.
String invoiceDialogPaymentMethodText(
  Invoice invoice, {
  String? requestedPaymentMethod,
}) {
  final totals = computeThermalInvoiceTotals(invoice);
  if (invoice.payments.isNotEmpty) {
    return thermalInvoicePaymentBreakdownSummary(
      invoice,
      fallbackTotal: totals.totalInvoiceAmount,
    );
  }
  return invoice.paymentMethod ?? requestedPaymentMethod ?? 'Unpaid';
}

/// Starts thermal PDF build on a background isolate (correct Arabic). Raster on Print tap.
void startInvoiceThermalPrintPrefetch({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) {
  InvoicePrintPrefetch.start(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
}

/// Opens the invoice dialog immediately; thermal PDF pre-builds in the background.
Future<void> showInvoiceDialogAfterPrintPrefetch({
  required BuildContext context,
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  bool barrierDismissible = false,
  required WidgetBuilder builder,
}) async {
  startInvoiceThermalPrintPrefetch(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
