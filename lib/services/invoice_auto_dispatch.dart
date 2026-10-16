import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/create_invoice_model.dart';
import '../utils/toast_service.dart';
import 'backend_whatsapp_invoice_dispatch.dart';
import 'invoice_print_prefetch.dart';
import 'network_thermal_printer.dart';
import 'thermal_print_isolate_pipeline.dart';
import 'thermal_printer_settings.dart';

/// Cashier "Generate Invoice" auto-dispatch.
///
/// When the cashier taps **Generate Invoice** we no longer surface the digital
/// invoice popup. Instead we fire **thermal print** + **WhatsApp delivery**
/// concurrently in the background and immediately return control to the UI so
/// the cashier can keep working. All status feedback is surfaced through the
/// global [ToastService.scaffoldMessengerKey] so it follows the user across
/// route changes (e.g. when we navigate back to the Orders Hub).
///
/// ### Isolate boundaries (strict)
///
/// **Main isolate (Flutter binding + plugins):**
///   * `Printing.raster` (PDF → raw RGBA).
///   * `CapabilityProfile.load` (asset bundle).
///   * `rootBundle` asset loading (logo, Noto Arabic fonts).
///   * TCP socket send to the thermal printer.
///   * WhatsApp HTTP POST (backend builds + sends the A4 PDF).
///
/// **Background isolates (pure Dart only):**
///   * PDF document assembly via `package:pdf` (preloaded fonts/logo bytes
///     are sent in as plain `Uint8List`s).
///   * Image processing (`package:image` threshold/dither/resize/crop) +
///     ESC/POS byte assembly (`package:esc_pos_utils_plus` `Generator`).
///
/// ### Why this matters
///
/// `Printing.raster`, `CapabilityProfile.load`, `rootBundle`, and any
/// `MethodChannel` all require a `ServicesBinding` to be initialised. A
/// background isolate spawned via `Isolate.run` has no binding, so any of
/// those calls there will throw `'_binaryMessenger != null || BindingBase
/// .debugBindingType() != null'`. The pipeline below **never** does that.
final class InvoiceAutoDispatch {
  InvoiceAutoDispatch._();

  /// Begin dispatching [invoice] to the thermal printer and WhatsApp in
  /// parallel. Returns immediately — work continues in the background and any
  /// success / failure messages are surfaced as root toasts.
  static void dispatch({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecksFallback,
  }) {
    // Let the current frame paint (Navigator.pop / Orders Hub redraw) before
    // we start spawning isolates or talking to the printer.
    _afterCurrentFrame(() {
      InvoicePrintPrefetch.start(
        invoice: invoice,
        paymentMethodText: paymentMethodText,
        maintenanceChecksFallback: maintenanceChecksFallback,
      );

      unawaited(
        _dispatchThermalPrint(
          invoice: invoice,
          paymentMethodText: paymentMethodText,
          maintenanceChecksFallback: maintenanceChecksFallback,
        ),
      );

      unawaited(
        _dispatchWhatsApp(
          invoice: invoice,
          paymentMethodText: paymentMethodText,
          maintenanceChecksFallback: maintenanceChecksFallback,
        ),
      );
    });
  }

  /// Re-print an existing invoice to the thermal printer **without** firing a
  /// new WhatsApp send. Used by "Print Invoice" buttons in customer history.
  static void dispatchPrintOnly({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecksFallback,
  }) {
    _afterCurrentFrame(() {
      InvoicePrintPrefetch.start(
        invoice: invoice,
        paymentMethodText: paymentMethodText,
        maintenanceChecksFallback: maintenanceChecksFallback,
      );
      unawaited(
        _dispatchThermalPrint(
          invoice: invoice,
          paymentMethodText: paymentMethodText,
          maintenanceChecksFallback: maintenanceChecksFallback,
        ),
      );
    });
  }

  /// Defers [run] until the current frame finishes painting.
  static void _afterCurrentFrame(VoidCallback run) {
    WidgetsBinding.instance.endOfFrame.then((_) => scheduleMicrotask(run));
  }

  static Future<void> _dispatchThermalPrint({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecksFallback,
  }) async {
    try {
      final bytes = await _resolvePrintBytes(
        invoice: invoice,
        paymentMethodText: paymentMethodText,
        maintenanceChecksFallback: maintenanceChecksFallback,
      );
      final cfg = await ThermalPrinterSettings.load();
      await sendEscPosBytesToTcpPrinter(
        host: cfg.host,
        port: cfg.port,
        bytes: bytes,
      );
      _rootToastSuccess('Receipt sent to printer.');
    } catch (e) {
      _rootToastError('Print failed: $e');
    }
  }

  /// Resolve the ESC/POS payload to send to the printer.
  ///
  /// Fast path: a prefetch was started by [InvoicePrintPrefetch.start] when
  /// the invoice id became known. We just await its cached future.
  ///
  /// Cold path: defensive fallback. Re-runs the full PDF → raster → encode
  /// pipeline from scratch. Internally this still respects the isolate
  /// boundaries described in the class doc — see
  /// [prepareInvoiceEscPosBytesOffUi].
  static Future<List<int>> _resolvePrintBytes({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecksFallback,
  }) async {
    final sw = kDebugMode ? (Stopwatch()..start()) : null;

    final pendingEscPos = InvoicePrintPrefetch.escPosFutureFor(invoice.id);
    if (pendingEscPos != null) {
      try {
        final bytes = await pendingEscPos;
        InvoicePrintPrefetch.discard(invoice.id);
        if (sw != null) {
          debugPrint(
            '[Thermal] print bytes ready via prefetch in '
            '${sw.elapsedMilliseconds}ms (${bytes.length} bytes).',
          );
        }
        return bytes;
      } catch (_) {
        InvoicePrintPrefetch.discard(invoice.id);
        // Fall through to a fresh cold build.
      }
    }

    // Reuse a prefetched PDF when available so we skip the heaviest step.
    Uint8List? prefetchedPdf;
    final pendingPdf = InvoicePrintPrefetch.pdfFutureFor(invoice.id);
    if (pendingPdf != null) {
      try {
        prefetchedPdf = await pendingPdf;
      } catch (_) {
        prefetchedPdf = null;
      }
      InvoicePrintPrefetch.discard(invoice.id);
    }

    final bytes = await prepareInvoiceEscPosBytesOffUi(
      invoice: invoice,
      paymentMethodText: paymentMethodText,
      maintenanceChecksFallback: maintenanceChecksFallback,
      prefetchedPdfBytes: prefetchedPdf,
    );
    if (sw != null) {
      debugPrint(
        '[Thermal] print bytes ready via cold build in '
        '${sw.elapsedMilliseconds}ms (${bytes.length} bytes).',
      );
    }
    return bytes;
  }

  static Future<void> _dispatchWhatsApp({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecksFallback,
  }) async {
    try {
      // Backend handles the A4 PDF + Bevatel HTTP. Returns ~instantly (202).
      await BackendWhatsAppInvoiceDispatch.send(
        invoice: invoice,
        paymentMethodText: paymentMethodText,
        maintenanceChecks: maintenanceChecksFallback,
      );
      _rootToastSuccess('Invoice queued for WhatsApp.');
    } catch (e) {
      _rootToastError('WhatsApp send failed: $e');
    }
  }

  static void _rootToastSuccess(String message) {
    final ctx = ToastService.scaffoldMessengerKey.currentContext;
    if (ctx is BuildContext && ctx.mounted) {
      ToastService.showSuccess(ctx, message);
    }
  }

  static void _rootToastError(String message) {
    final ctx = ToastService.scaffoldMessengerKey.currentContext;
    if (ctx is BuildContext && ctx.mounted) {
      ToastService.showError(ctx, message);
    }
  }
}
