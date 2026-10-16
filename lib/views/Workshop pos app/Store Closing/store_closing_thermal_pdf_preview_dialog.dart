import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/store_closing_model.dart';
import '../../../services/store_closing_print_prefetch.dart';
import '../../../services/thermal_pdf_isolate_build.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_shimmer.dart';

/// Resolves the same thermal PDF bytes sent to the Wi‑Fi printer.
Future<Uint8List> resolveStoreClosingThermalPdfBytes({
  required StoreClosingReport report,
  String? closingId,
}) async {
  final pending = StoreClosingPrintPrefetch.pdfFutureFor(report, closingId);
  if (pending != null) {
    try {
      return await pending;
    } catch (_) {
      // Fall through to a fresh build.
    }
  }
  return buildThermalStoreClosingPdfBytesInIsolate(
    report: report,
    closingId: closingId,
  );
}

/// Full-screen dialog preview of the thermal store-closing receipt PDF.
Future<void> showStoreClosingThermalPdfPreview(
  BuildContext context, {
  required StoreClosingReport report,
  String? closingId,
}) {
  final l10n = AppLocalizations.of(context)!;
  final pdfFuture = resolveStoreClosingThermalPdfBytes(
    report: report,
    closingId: closingId,
  );

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      final maxH = MediaQuery.sizeOf(dialogCtx).height * 0.88;
      final maxW = MediaQuery.sizeOf(dialogCtx).width * 0.92;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: maxW.clamp(320, 720),
          height: maxH.clamp(400, 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.posStoreClosingPdfTitle,
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(dialogCtx).closeButtonLabel,
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: pdfFuture,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const _ThermalPdfPreviewShimmer();
                    }
                    if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.posStoreClosingPdfPreviewError,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      );
                    }
                    final bytes = snap.data!;
                    return PdfPreview(
                      build: (_) async => bytes,
                      allowPrinting: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      pdfFileName: 'store_closing_receipt.pdf',
                      scrollViewDecoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Compact receipt-shaped shimmer while thermal PDF bytes resolve.
class _ThermalPdfPreviewShimmer extends StatelessWidget {
  const _ThermalPdfPreviewShimmer();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Container(
          width: 280,
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PosShimmer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PosShimmerBox(width: 96, height: 12, radius: 6),
                const SizedBox(height: 10),
                const PosShimmerLine(width: 140, height: 10),
                const SizedBox(height: 16),
                ...List.generate(6, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < 5 ? 10 : 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: PosShimmerLine(
                            width: double.infinity,
                            height: 9,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const PosShimmerBox(width: 48, height: 9, radius: 5),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const PosShimmerBox(
                  width: double.infinity,
                  height: 1,
                  radius: 1,
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(
                      child: PosShimmerLine(width: double.infinity, height: 11),
                    ),
                    SizedBox(width: 16),
                    PosShimmerBox(width: 56, height: 11, radius: 5),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
