import 'dart:async';
import 'dart:typed_data';

import '../models/create_invoice_model.dart';
import 'invoice_thermal_pdf_raster_escpos.dart';
import 'thermal_pdf_isolate_build.dart';

/// **Two-stage thermal print prefetch** while the invoice dialog is open.
///
/// 1. PDF bytes are built on a background isolate (Arabic-aware, fast).
/// 2. Once the PDF is ready, the raster + ESC/POS pipeline starts running on
///    the UI isolate. The work is interleaved with frame yields, so the
///    dialog stays responsive while the user reads the preview.
///
/// By the time the user taps **Print**, the encoded ESC/POS byte list is
/// (almost always) ready. The dialog closes immediately, the user is taken to
/// the Orders Hub, and the background printer task only has to do a TCP send
/// — meaning Android never sees the UI thread stall long enough to show the
/// "App isn't responding / Wait — Close" ANR popup.
///
/// If the user prints before the prefetch completes, callers can simply
/// `await` [escPosFutureFor] — no work is duplicated.
final class InvoicePrintPrefetch {
  InvoicePrintPrefetch._();

  static final Map<String, _PrefetchEntry> _byInvoiceId = {};

  /// Begin prefetching a full thermal print payload for [invoice].
  ///
  /// Safe to call multiple times for the same invoice id — only the first call
  /// schedules work.
  static void start({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecksFallback,
  }) {
    final id = invoice.id.trim();
    if (id.isEmpty) return;
    if (_byInvoiceId.containsKey(id)) return;

    final pdfFuture = buildThermalInvoicePdfBytesInIsolate(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecksFallback: maintenanceChecksFallback,
    );

    // Chain: once PDF is ready, kick off raster + ESC/POS encode on the UI
    // isolate. The pipeline yields between pages so the dialog stays smooth.
    final escPosFuture = pdfFuture.then<List<int>>((pdf) async {
      return buildEscPosBytesFromPdfRaster(pdf);
    });

    _byInvoiceId[id] = _PrefetchEntry(
      pdfFuture: pdfFuture,
      escPosFuture: escPosFuture,
    );
  }

  /// Pending PDF bytes for [invoiceId], or null if no prefetch was started.
  static Future<Uint8List>? pdfFutureFor(String invoiceId) {
    final id = invoiceId.trim();
    if (id.isEmpty) return null;
    return _byInvoiceId[id]?.pdfFuture;
  }

  /// Pending ESC/POS bytes (full thermal payload, ready to push to TCP) for
  /// [invoiceId]. Awaiting this future on Print tap means **no raster runs on
  /// the UI isolate after navigation** — no ANR.
  static Future<List<int>>? escPosFutureFor(String invoiceId) {
    final id = invoiceId.trim();
    if (id.isEmpty) return null;
    return _byInvoiceId[id]?.escPosFuture;
  }

  static void discard(String invoiceId) {
    _byInvoiceId.remove(invoiceId.trim());
  }

  static void discardAll() => _byInvoiceId.clear();
}

final class _PrefetchEntry {
  _PrefetchEntry({
    required this.pdfFuture,
    required this.escPosFuture,
  });

  final Future<Uint8List> pdfFuture;

  /// Always non-null and resilient: failures during prefetch are NOT swallowed
  /// at this layer — callers must handle errors when awaiting.
  final Future<List<int>> escPosFuture;
}
