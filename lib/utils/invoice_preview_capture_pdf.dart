import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/create_invoice_model.dart';
import '../services/invoice_dialog_launcher.dart';
import '../widgets/cashier_invoice_preview.dart';

/// Captures the colourful [CashierInvoicePreview] subtree (wrapped in [RepaintBoundary])
/// exactly as rendered on screen, embeds lossless PNG in a single-page PDF for WhatsApp.
abstract final class InvoicePreviewCapturePdf {
  /// Raster → PDF sized to logical layout (~96 DPI → pt). Returns `null` if the key has
  /// no rendereable boundary (e.g. dialog not laid out yet).
  static Future<Uint8List?> repaintBoundaryKeyToPdf({
    required GlobalKey repaintBoundaryKey,
    BuildContext? context,
    double? pixelRatio,
    /// Lower resolution for WhatsApp uploads — faster capture, still sharp on phone.
    bool compactForMessaging = false,
  }) async {
    final ctxForMq = context ?? repaintBoundaryKey.currentContext;
    final devicePr = ctxForMq != null
        ? MediaQuery.maybeOf(ctxForMq)?.devicePixelRatio
        : null;
    final prRaw = pixelRatio ??
        (compactForMessaging
            ? (devicePr != null ? (devicePr * 0.82) : 2.0)
            : devicePr) ??
        (compactForMessaging ? 2.0 : 2.75);
    final pr = compactForMessaging
        ? prRaw.clamp(1.75, 2.75).toDouble()
        : prRaw.clamp(2.0, 3.25).toDouble();

    await Future<void>.delayed(
      Duration(milliseconds: compactForMessaging ? 32 : 48),
    );
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(Duration.zero);

    final ro = repaintBoundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) {
      return null;
    }

    final boundary = ro;
    if (!boundary.hasSize || boundary.size.isEmpty) {
      return null;
    }

    ui.Image? uiImg;
    try {
      uiImg = await boundary.toImage(pixelRatio: pr);
    } catch (e) {
      return null;
    }
    await Future<void>.delayed(Duration.zero);

    late final Uint8List pngBytes;
    try {
      final bd = await uiImg.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return null;
      pngBytes = bd.buffer.asUint8List();
    } catch (e) {
      return null;
    } finally {
      uiImg.dispose();
    }
    await Future<void>.delayed(Duration.zero);

    final lw = boundary.size.width;
    final lh = boundary.size.height;
    final wPt = lw * 72 / 96;
    final hPt = lh * 72 / 96;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          wPt,
          hPt,
          marginAll: 0,
        ),
        build: (_) =>
            pw.SizedBox(width: wPt, height: hPt, child: pw.Image(pw.MemoryImage(pngBytes))),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    try {
      return await doc.save();
    } catch (e) {
      return null;
    }
  }

  /// Renders [CashierInvoicePreview] off-screen (same digital UI) and returns PDF bytes.
  static Future<Uint8List?> cashierInvoiceToPdf({
    required BuildContext context,
    required Invoice invoice,
    String? paymentMethodText,
    List<bool>? maintenanceChecksFallback,
    bool compactMobile = false,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final captureKey = GlobalKey();
    final payText =
        paymentMethodText ?? invoiceDialogPaymentMethodText(invoice);
    final width = compactMobile
        ? MediaQuery.sizeOf(context).width.clamp(320.0, 420.0)
        : 720.0;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                type: MaterialType.transparency,
                child: OverflowBox(
                  maxWidth: width,
                  maxHeight: double.infinity,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: RepaintBoundary(
                      key: captureKey,
                      child: CashierInvoicePreview(
                        invoice: invoice,
                        paymentMethodText: payText,
                        maintenanceChecksFallback: maintenanceChecksFallback,
                        compactMobile: compactMobile,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await WidgetsBinding.instance.endOfFrame;
      return await repaintBoundaryKeyToPdf(
        repaintBoundaryKey: captureKey,
        context: context,
        compactForMessaging: false,
      );
    } finally {
      entry.remove();
    }
  }
}
