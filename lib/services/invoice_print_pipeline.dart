import 'dart:async';

import '../models/create_invoice_model.dart';
import 'thermal_print_isolate_pipeline.dart';

/// Progress phases for Print button label.
enum InvoicePrintPhase {
  preparingPdf,
  rasterizing,
  encoding,
  sending,
}

/// Thermal print bytes — runs on a background isolate (UI stays responsive).
Future<List<int>> prepareInvoiceEscPosBytes({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  void Function(InvoicePrintPhase phase)? onPhase,
}) async {
  onPhase?.call(InvoicePrintPhase.preparingPdf);
  onPhase?.call(InvoicePrintPhase.rasterizing);
  onPhase?.call(InvoicePrintPhase.encoding);
  return prepareInvoiceEscPosBytesOffUi(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
}
