import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:printing/printing.dart';

import '../models/create_invoice_model.dart';
import '../models/store_closing_model.dart';
import '../utils/thermal_raster_preprocess.dart';
import '../widgets/thermal_invoice_pdf.dart';
import '../widgets/thermal_store_closing_pdf.dart';
import 'thermal_esc_pos_encode.dart';
import 'thermal_esc_pos_profile_warmup.dart';
import 'thermal_pdf_raster_isolate.dart';

export '../utils/thermal_raster_preprocess.dart'
    show
        kThermalPdfRasterDpi,
        kThermalPdfRasterPrintWidthPx,
        kThermalPdfRasterStripMaxHeightPx;

/// Yield so the UI isolate can paint frames (avoids Android ANR during raster).
Future<void> _yieldUiThread({int milliseconds = 16}) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

Future<void> _scheduleUiFrame() {
  final completer = Completer<void>();
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    if (!completer.isCompleted) completer.complete();
  });
  return completer.future;
}

/// Convert a thermal-roll PDF into a complete ESC/POS byte stream.
///
/// Architecture (strict separation, no plugin misuse):
///
/// ### MAIN isolate (Flutter binding + plugins required)
///   1. [warmThermalEscPosCapabilityProfile] — loads `CapabilityProfile`
///      via `rootBundle`. Idempotent and cached.
///   2. [Printing.raster] — only the `printing` plugin can reach the
///      platform PDF renderer. Native rendering runs on the platform's
///      thread pool; on the Dart side we just await the stream and yield
///      between pages so the framework can paint.
///   3. `raster.toPng()` — engine-side PNG encode of each page. Returns
///      a `Future<Uint8List>` and the heavy lifting is on the engine's
///      worker thread; the main isolate just awaits.
///
/// ### BACKGROUND isolate (pure Dart only)
///   4. [encodePngPagesToEscPosOffUi] — `package:image` PNG decode +
///      threshold/dither/resize/strip crop, then
///      `package:esc_pos_utils_plus` `Generator` builds the final byte
///      stream. No plugins, no `rootBundle`, no `MethodChannel`, no
///      `BackgroundIsolateBinaryMessenger`.
///
/// If the worker isolate fails for any reason, we fall back to the same
/// pure-Dart encode on the main isolate so the cashier never loses the
/// receipt.
Future<List<int>> buildEscPosBytesFromPdfRaster(Uint8List pdfBytes) async {
  final swTotal = kDebugMode ? (Stopwatch()..start()) : null;

  // [MAIN] Load the capability profile (cached; first-call only hits the
  // asset bundle). Kicked off in parallel with raster.
  final profileFuture = warmThermalEscPosCapabilityProfile();

  // [MAIN] PDF → PNG pages. The engine's `decodeImageFromPixels` +
  // `Image.toByteData(PNG)` run on engine worker threads, so awaiting them
  // doesn't block frame rendering. We yield between pages anyway as a
  // belt-and-suspenders measure on slow tablets.
  final swRaster = kDebugMode ? (Stopwatch()..start()) : null;
  final pngPages = <Uint8List>[];
  await _yieldUiThread(milliseconds: 24);
  await for (final r in Printing.raster(
    pdfBytes,
    dpi: kThermalPdfRasterDpi,
  )) {
    pngPages.add(await r.toPng());
    await _yieldUiThread();
    await _scheduleUiFrame();
  }
  if (swRaster != null) {
    debugPrint(
      '[Thermal] PDF→PNG raster (main) ${swRaster.elapsedMilliseconds}ms, '
      '${pngPages.length} page(s).',
    );
  }
  if (pngPages.isEmpty) {
    throw StateError(
      'Thermal PDF could not be rasterized (0 pages). '
      'Confirm the printing plugin supports raster on this platform.',
    );
  }

  final profile = await profileFuture;

  // [BG] Heavy image processing + ESC/POS Generator encoding on a worker
  // isolate. Main-isolate fallback only fires if the worker throws.
  List<int> bytes;
  try {
    bytes = await encodePngPagesToEscPosOffUi(pngPages, profile);
  } catch (err, st) {
    if (kDebugMode) {
      debugPrint(
        '[Thermal] off-UI encode failed: $err\n$st\n'
        '→ falling back to main-isolate encode.',
      );
    }
    await _yieldUiThread();
    bytes = encodeEscPosBytesFromPngPagesSync(pngPages, profile);
  }

  if (swTotal != null) {
    debugPrint(
      '[Thermal] PDF→ESC/POS total ${swTotal.elapsedMilliseconds}ms '
      '(${bytes.length} bytes).',
    );
  }
  return bytes;
}

/// Invoice thermal PDF → ESC/POS (synchronous PDF build on main isolate; the
/// preferred path goes through `prepareInvoiceEscPosBytesOffUi` which builds
/// the PDF on a worker isolate first).
Future<List<int>> buildInvoiceEscPosBytesFromThermalPdfRaster({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) async {
  await _yieldUiThread(milliseconds: 8);
  final pdfBytes = await buildThermalInvoicePdfBytes(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
  await _yieldUiThread(milliseconds: 24);
  return buildEscPosBytesFromPdfRaster(pdfBytes);
}

/// Store closing thermal PDF → ESC/POS (same raster pipeline as invoices).
Future<List<int>> buildStoreClosingEscPosBytesFromThermalPdfRaster({
  required StoreClosingReport report,
  String? closingId,
}) async {
  final pdfBytes = await buildThermalStoreClosingPdfBytes(
    report: report,
    closingId: closingId,
  );
  return buildEscPosBytesFromPdfRaster(pdfBytes);
}
