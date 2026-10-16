import 'dart:async';
import 'dart:typed_data';

import '../models/create_invoice_model.dart';
import '../models/store_closing_model.dart';
import 'invoice_thermal_pdf_raster_escpos.dart';
import 'thermal_esc_pos_profile_warmup.dart';
import 'thermal_pdf_isolate_build.dart';

/// Invoice thermal print — **PDF layout with correct Arabic** (Noto → raster → ESC/POS).
///
/// PDF is built on a background isolate. `Printing.raster()` runs on the UI
/// isolate (the `printing` plugin's method channel is bound to the root isolate
/// and cannot be initialised on a secondary one), so the cost of raster +
/// ESC/POS encode is paid here.
///
/// To avoid blocking the user when Print is tapped, callers should prefer the
/// pre-rendered cache exposed by `InvoicePrintPrefetch.escPosFutureFor()` —
/// that runs this pipeline ahead of time, while the dialog is open, so Print
/// tap becomes a TCP send only.
Future<List<int>> prepareInvoiceEscPosBytesOffUi({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
  Uint8List? prefetchedPdfBytes,
}) async {
  unawaited(warmThermalEscPosCapabilityProfile());

  final pdfBytes = prefetchedPdfBytes ??
      await buildThermalInvoicePdfBytesInIsolate(
        invoice: invoice,
        paymentMethodText: paymentMethodText,
        maintenanceChecksFallback: maintenanceChecksFallback,
      );

  return buildEscPosBytesFromPdfRaster(pdfBytes);
}

/// Store closing thermal — same off-UI PDF + (UI-isolate) raster pipeline.
Future<List<int>> prepareStoreClosingEscPosBytesOffUi({
  required StoreClosingReport report,
  String? closingId,
  Uint8List? prefetchedPdfBytes,
}) async {
  unawaited(warmThermalEscPosCapabilityProfile());

  final pdfBytes = prefetchedPdfBytes ??
      await buildThermalStoreClosingPdfBytesInIsolate(
        report: report,
        closingId: closingId,
      );

  return buildEscPosBytesFromPdfRaster(pdfBytes);
}
