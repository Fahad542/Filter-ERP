import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/store_closing_model.dart';
import '../services/thermal_pdf_asset_loader.dart';
import '../utils/business_timezone.dart';
import '../utils/bundle_brand_logo.dart';
import '../utils/thermal_receipt_layout.dart';
import '../utils/thermal_receipt_logo_preprocess.dart';
import '../utils/thermal_safe_text.dart';
import 'thermal_arabic_pdf_reshaper.dart';
import 'thermal_invoice_pdf_ar_constants.dart';

String _ar(String s) => reshapeArabic(s);

bool _hasArabicScript(String s) =>
    RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(s);

String _pdfUserLine(String raw) => pdfStripBidiAndInvisible(raw.trim());

String _pdfMoney(num amount) => '${amount.toStringAsFixed(2)} SR';

String _signedAmount(num amount) {
  final v = amount.toStringAsFixed(2);
  return amount >= 0 ? '+$v' : v;
}

pw.Document buildThermalStoreClosingPdfDocument({
  required StoreClosingReport report,
  String? closingId,
  Uint8List? filterLogoPngBytes,
  required pw.Font font,
  required pw.Font fontBold,
  required pw.Font fontArabic,
  required pw.Font fontArabicBold,
}) {
  final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(report.timestamp.toLocal());
  String sessionDt(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy hh:mm a')
        .format(BusinessTimezone.toWall(dt));
  }
  final branchLine = _pdfUserLine(report.branch);
  final rawWorkshop = report.workshopName.trim();
  final workshopLine = _pdfUserLine(
    rawWorkshop.isNotEmpty &&
            rawWorkshop != 'Loading...' &&
            rawWorkshop != '...'
        ? rawWorkshop
        : (branchLine.isNotEmpty && branchLine != '-'
            ? branchLine
            : 'Filter Car Services'),
  );
  final cashierLine = _pdfUserLine(report.cashierName);
  final closingIdLine = _pdfUserLine(closingId ?? report.id);
  final systemHdrEn = report.salesReturnsTotal > 0.001
      ? 'System (gross)'
      : ThermalInvoicePdfLabels.closingSystemEn;
  final diffHdrEn =
      report.salesReturnsTotal > 0.001 ? 'Diff (net)' : ThermalInvoicePdfLabels.closingDiffEn;

  const fsMeta = 8.15;
  const tightLine = 0.78;
  const kPdfThermalArabicLetterSpacing = 0.42;
  const kPdfBilingualArSize = 7.7;
  const kPdfBilingualEnSize = 7.6;
  const kPdfBilingualArEnGap = 0.1;
  const kPdfBilingualEnPullUp = 0.9;
  const kPdfTableHeaderEnPullUp = 1.2;

  pw.TextStyle tsLabel() => pw.TextStyle(
        font: fontBold,
        fontSize: fsMeta + 0.35,
        fontWeight: pw.FontWeight.bold,
        height: tightLine,
      );
  pw.TextStyle tsValue() => pw.TextStyle(
        font: font,
        fontSize: fsMeta,
        fontWeight: pw.FontWeight.normal,
        height: tightLine,
      );
  pw.TextStyle tsArabicLabel() => pw.TextStyle(
        font: fontArabic,
        fontSize: fsMeta + 0.45,
        fontWeight: pw.FontWeight.normal,
        height: 0.86,
        letterSpacing: kPdfThermalArabicLetterSpacing,
      );
  pw.TextStyle tsArabicValue() => pw.TextStyle(
        font: fontArabic,
        fontSize: fsMeta + 0.35,
        fontWeight: pw.FontWeight.normal,
        height: 0.86,
        letterSpacing: kPdfThermalArabicLetterSpacing,
      );
  pw.TextStyle tsArabicBold() => pw.TextStyle(
        font: fontArabicBold,
        fontSize: fsMeta + 0.35,
        fontWeight: pw.FontWeight.bold,
        height: 0.86,
        letterSpacing: kPdfThermalArabicLetterSpacing,
      );

  final itemQtyStyle =
      pw.TextStyle(font: font, fontSize: 8.35, height: tightLine);
  final itemEnStyle =
      pw.TextStyle(font: fontBold, fontSize: 8.45, height: tightLine);

  /// Store-closing header meta — slightly taller rows and wider EN/value/AR gaps.
  const kStoreClosingMetaRowHeight = 10.2;
  const kStoreClosingMetaLineHeight = 0.76;
  const kStoreClosingMetaMidGap = '     :     ';

  pw.Widget pdfHeaderSubtitleLine() {
    return pw.SizedBox(
      height: 13,
      width: double.infinity,
      child: pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Text(
            _ar(ThermalInvoicePdfLabels.documentSubtitleAr),
            style: tsArabicBold().copyWith(fontSize: 10.2, height: 1.1),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  pw.Widget pdfHeaderTightLine(
    String text,
    pw.TextStyle style, {
    required double boxHeight,
    bool reshapeArabicText = false,
  }) {
    final display = reshapeArabicText ? _ar(text) : text;
    return pw.SizedBox(
      height: boxHeight,
      width: double.infinity,
      child: pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Text(
          display,
          style: style.copyWith(height: 1),
          textAlign: pw.TextAlign.center,
          maxLines: 2,
          softWrap: true,
        ),
      ),
    );
  }

  pw.Widget pdfMetaEnValueArFieldRow(
    String enLabel,
    String rawValue,
    String arFieldLabel, {
    bool boldArabicValue = true,
  }) {
    final disp = _pdfUserLine(rawValue);
    final v = disp.isEmpty ? '-' : disp;
    final labelStyle = tsLabel();
    final valueStyle = tsValue();
    final arBold = tsArabicBold();
    final arRegular = tsArabicValue();
    final valueArStyle =
        !_hasArabicScript(v) ? valueStyle : (boldArabicValue ? arBold : arRegular);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 0.9),
      child: pw.SizedBox(
        height: kStoreClosingMetaRowHeight,
        width: double.infinity,
        child: pw.Align(
          alignment: pw.Alignment.topCenter,
          child: pw.RichText(
            textAlign: pw.TextAlign.center,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$enLabel: ',
                  style: labelStyle.copyWith(height: kStoreClosingMetaLineHeight),
                ),
                pw.TextSpan(
                  text: _hasArabicScript(v) ? _ar(v) : v,
                  style: valueArStyle.copyWith(height: kStoreClosingMetaLineHeight),
                ),
                pw.TextSpan(
                  text: kStoreClosingMetaMidGap,
                  style: labelStyle.copyWith(height: kStoreClosingMetaLineHeight),
                ),
                pw.TextSpan(
                  text: _ar(arFieldLabel),
                  style: arBold.copyWith(height: kStoreClosingMetaLineHeight),
                ),
              ],
            ),
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  pw.Widget pdfMetaEnglishMetaRow(
    String enPrefix,
    String rawValue, {
    bool compact = false,
    bool compactBox = false,
    bool alignRight = false,
    bool alignCenter = false,
  }) {
    final metaLine =
        alignCenter ? kStoreClosingMetaLineHeight : 0.72;
    final disp = _pdfUserLine(rawValue);
    final v = disp.isEmpty ? '-' : disp;
    final labelStyle = tsLabel().copyWith(height: compact ? metaLine : null);
    final valueStyle = tsValue().copyWith(height: compact ? metaLine : null);
    final arValStyle = tsArabicValue().copyWith(height: compact ? metaLine : null);
    final textAlign = alignCenter
        ? pw.TextAlign.center
        : alignRight
            ? pw.TextAlign.right
            : pw.TextAlign.left;
    final boxAlign = alignCenter
        ? pw.Alignment.topCenter
        : alignRight
            ? pw.Alignment.topRight
            : pw.Alignment.topLeft;

    late final pw.Widget inner;
    if (!_hasArabicScript(v)) {
      inner = pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: enPrefix, style: labelStyle),
            pw.TextSpan(text: v, style: valueStyle),
          ],
        ),
        textAlign: textAlign,
        maxLines: compact ? 2 : 6,
      );
    } else {
      inner = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: alignCenter
            ? pw.MainAxisAlignment.center
            : alignRight
                ? pw.MainAxisAlignment.end
                : pw.MainAxisAlignment.start,
        children: [
          pw.Text(enPrefix, style: labelStyle),
          pw.Flexible(
            child: pw.Text(
              _ar(v),
              style: arValStyle,
              maxLines: compact ? 2 : 4,
              softWrap: true,
              textAlign: textAlign,
            ),
          ),
        ],
      );
    }
    if (!compactBox) return inner;
    final rowHeight = alignCenter ? kStoreClosingMetaRowHeight : 9.25;
    return pw.SizedBox(
      height: rowHeight,
      width: double.infinity,
      child: pw.Align(alignment: boxAlign, child: inner),
    );
  }

  pw.Widget dashed() => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4.5, bottom: 2.5),
        child: pw.SizedBox(
          width: double.infinity,
          height: 3.5,
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint sz) {
              const dot = 0.95;
              const gap = 2.35;
              final y = (sz.y - dot) * 0.5;
              canvas.setFillColor(ThermalReceiptLayout.brandInk);
              var x = 0.0;
              while (x + dot <= sz.x + 0.01) {
                canvas.drawRect(x, y, dot, dot);
                canvas.fillPath();
                x += dot + gap;
              }
            },
          ),
        ),
      );

  pw.Widget _pdfBilingualHeaderColumn({
    required String ar,
    required String en,
    required pw.Alignment blockAlign,
    required pw.TextAlign arTextAlign,
    required pw.TextAlign enTextAlign,
    required pw.CrossAxisAlignment crossAlign,
    double enSize = 7.8,
  }) {
    return pw.Column(
      crossAxisAlignment: crossAlign,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Align(
          alignment: blockAlign,
          child: pw.Text(
            _ar(ar),
            style: tsArabicLabel().copyWith(fontSize: 8.25, height: 0.86),
            textAlign: arTextAlign,
          ),
        ),
        pw.Transform.translate(
          offset: const PdfPoint(0, kPdfTableHeaderEnPullUp),
          child: pw.Align(
            alignment: blockAlign,
            child: pw.Text(
              en,
              style: tsLabel().copyWith(fontSize: enSize, height: 0.88),
              textAlign: enTextAlign,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget bilingualHeaderLeading(String ar, String en) {
    return _pdfBilingualHeaderColumn(
      ar: ar,
      en: en,
      blockAlign: pw.Alignment.centerLeft,
      arTextAlign: pw.TextAlign.right,
      enTextAlign: pw.TextAlign.left,
      crossAlign: pw.CrossAxisAlignment.start,
    );
  }

  pw.Widget bilingualHeaderEndAligned(String ar, String en) {
    return _pdfBilingualHeaderColumn(
      ar: ar,
      en: en,
      blockAlign: pw.Alignment.centerRight,
      arTextAlign: pw.TextAlign.right,
      enTextAlign: pw.TextAlign.right,
      crossAlign: pw.CrossAxisAlignment.stretch,
      enSize: 7,
    );
  }

  pw.Widget plainSectionTitle(String en) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 0.35, bottom: 0.4),
        child: pw.SizedBox(
          width: double.infinity,
          child: pw.Text(
            en,
            style: tsLabel().copyWith(fontSize: fsMeta + 0.85, height: 0.72),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );

  pw.Widget arabicEnglishAmountLabelSized(
    String arabicLines,
    String englishLabel,
    num amount, {
    bool compact = true,
    bool emphasize = false,
  }) {
    final lbl = tsLabel().copyWith(fontSize: kPdfBilingualEnSize, height: 0.92);
    final val = (emphasize ? tsLabel() : tsValue()).copyWith(
      fontSize: kPdfBilingualEnSize,
      height: 0.92,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 0.08),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  _ar(arabicLines),
                  style: tsArabicLabel().copyWith(
                    fontSize: kPdfBilingualArSize,
                    height: 0.9,
                  ),
                  textAlign: pw.TextAlign.left,
                  maxLines: 3,
                ),
                pw.SizedBox(height: kPdfBilingualArEnGap),
                pw.Transform.translate(
                  offset: const PdfPoint(0, kPdfBilingualEnPullUp),
                  child: pw.Text(
                    englishLabel,
                    style: lbl,
                    textAlign: pw.TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            _pdfMoney(amount),
            style: val,
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  pw.Widget categoryCell(String ar, String en) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          _ar(ar),
          style: tsArabicLabel().copyWith(fontSize: 8.3, height: 0.42),
          textAlign: pw.TextAlign.left,
        ),
        pw.SizedBox(height: 0.35),
        pw.Text(
          thermalSafeText(en).toUpperCase(),
          style: itemEnStyle,
          textAlign: pw.TextAlign.left,
        ),
      ],
    );
  }

  pw.Widget dataRow(
    String catAr,
    String catEn,
    double sys,
    double phy,
    double diff, {
    bool emphasize = false,
  }) {
    final amtStyle = emphasize
        ? pw.TextStyle(font: fontBold, fontSize: 8.45, height: tightLine)
        : itemQtyStyle;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 0.06),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 5, child: categoryCell(catAr, catEn)),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              sys.toStringAsFixed(2),
              style: amtStyle,
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              phy.toStringAsFixed(2),
              style: amtStyle,
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              _signedAmount(diff),
              style: amtStyle,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget row4(pw.Widget w1, pw.Widget w2, pw.Widget w3, pw.Widget w4) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 5, child: w1),
        pw.Expanded(flex: 3, child: w2),
        pw.Expanded(flex: 3, child: w3),
        pw.Expanded(flex: 3, child: w4),
      ],
    );
  }

  List<pw.Widget> departmentSalesPdfSection() {
    if (report.departmentBreakdown.isEmpty) return [];
    return [
      plainSectionTitle(ThermalInvoicePdfLabels.departmentSalesSectionEn),
      pw.SizedBox(height: 2),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 0.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: bilingualHeaderLeading(
                ThermalInvoicePdfLabels.departmentColAr,
                ThermalInvoicePdfLabels.departmentColEn,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: bilingualHeaderEndAligned(
                ThermalInvoicePdfLabels.departmentOrdersAr,
                ThermalInvoicePdfLabels.departmentOrdersEn,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: bilingualHeaderEndAligned(
                ThermalInvoicePdfLabels.departmentRevenueAr,
                ThermalInvoicePdfLabels.departmentRevenueEn,
              ),
            ),
          ],
        ),
      ),
      dashed(),
      ...report.departmentBreakdown.map((row) {
        final name = thermalSafeText(row.departmentName);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 0.06),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  _hasArabicScript(name) ? _ar(name) : name,
                  style: itemEnStyle,
                  maxLines: 2,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  '${row.ordersCount}',
                  style: itemQtyStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  _pdfMoney(row.revenueSar),
                  style: itemQtyStyle,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
      dashed(),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 0.35),
        child: arabicEnglishAmountLabelSized(
          ThermalInvoicePdfLabels.closingTotalAr,
          '${ThermalInvoicePdfLabels.closingGrandTotalEn}: ',
          report.departmentBreakdown.fold<double>(
            0,
            (sum, r) => sum + r.revenueSar,
          ),
          emphasize: true,
        ),
      ),
      dashed(),
    ];
  }

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        80 * PdfPageFormat.mm,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      ),
      build: (ctx) {
        return pw.DefaultTextStyle(
          style: pw.TextStyle(font: font, fontSize: 7.85, height: tightLine),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (filterLogoPngBytes != null && filterLogoPngBytes.isNotEmpty)
                pw.Center(
                  child: pw.SizedBox(
                    height: 48,
                    child: pw.Image(
                      pw.MemoryImage(filterLogoPngBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              pw.SizedBox(height: 0.5),
              pdfHeaderSubtitleLine(),
              pw.SizedBox(height: 2),
              pdfHeaderTightLine(
                ThermalInvoicePdfLabels.storeClosingTitleAr,
                tsArabicValue().copyWith(fontSize: 10.2, height: 1.05),
                boxHeight: 11.5,
                reshapeArabicText: true,
              ),
              pw.SizedBox(height: 4.5),
              pdfHeaderTightLine(
                ThermalInvoicePdfLabels.storeClosingTitleEn,
                tsLabel().copyWith(fontSize: 9.4),
                boxHeight: 10,
              ),
              pw.SizedBox(height: 4.5),
              pdfHeaderTightLine(
                workshopLine,
                _hasArabicScript(workshopLine)
                    ? tsArabicValue().copyWith(fontSize: 9.5, height: 1.05)
                    : tsLabel().copyWith(fontSize: 9.2),
                boxHeight: 9.5,
                reshapeArabicText: _hasArabicScript(workshopLine),
              ),
              pw.SizedBox(height: 0.75),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.branchLabelEn,
                branchLine.isEmpty ? '-' : branchLine,
                ThermalInvoicePdfLabels.branchLabelAr,
                boldArabicValue: false,
              ),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.cashierLabelEn,
                cashierLine.isEmpty ? '-' : cashierLine,
                ThermalInvoicePdfLabels.cashierLabelAr,
                boldArabicValue: false,
              ),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.closingIdMetaEn,
                closingIdLine.isEmpty ? '-' : closingIdLine,
                ThermalInvoicePdfLabels.closingIdAr,
              ),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.dateLabelEn,
                dateStr,
                ThermalInvoicePdfLabels.dateLabelAr,
                boldArabicValue: false,
              ),
              if (report.sessionOpenedAt != null)
                pdfMetaEnValueArFieldRow(
                  ThermalInvoicePdfLabels.sessionStartEn,
                  sessionDt(report.sessionOpenedAt),
                  ThermalInvoicePdfLabels.sessionStartAr,
                  boldArabicValue: false,
                ),
              if (report.sessionClosedAt != null)
                pdfMetaEnValueArFieldRow(
                  ThermalInvoicePdfLabels.sessionEndEn,
                  sessionDt(report.sessionClosedAt),
                  ThermalInvoicePdfLabels.sessionEndAr,
                  boldArabicValue: false,
                ),
              pw.SizedBox(height: 2.2),
              dashed(),
              ...departmentSalesPdfSection(),
              plainSectionTitle(ThermalInvoicePdfLabels.storeClosingSectionEn),
              pw.SizedBox(height: 2),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 0.5),
                child: row4(
                  bilingualHeaderLeading(
                    ThermalInvoicePdfLabels.closingCategoryAr,
                    ThermalInvoicePdfLabels.closingCategoryEn,
                  ),
                  bilingualHeaderEndAligned(
                    ThermalInvoicePdfLabels.closingSystemAr,
                    systemHdrEn,
                  ),
                  bilingualHeaderEndAligned(
                    ThermalInvoicePdfLabels.closingPhysicalAr,
                    ThermalInvoicePdfLabels.closingPhysicalEn,
                  ),
                  bilingualHeaderEndAligned(
                    ThermalInvoicePdfLabels.closingDiffAr,
                    diffHdrEn,
                  ),
                ),
              ),
              dashed(),
              dataRow(
                ThermalInvoicePdfLabels.closingCashAr,
                ThermalInvoicePdfLabels.closingCashEn,
                report.systemCashGross,
                report.physicalCash,
                report.cashDiff,
              ),
              dataRow(
                ThermalInvoicePdfLabels.closingBankAr,
                ThermalInvoicePdfLabels.closingBankEn,
                report.systemBankGross,
                report.physicalBank,
                report.bankDiff,
              ),
              dataRow(
                ThermalInvoicePdfLabels.closingCorporateAr,
                ThermalInvoicePdfLabels.closingCorporateEn,
                report.systemCorporateGross,
                report.physicalCorporate,
                report.corporateDiff,
              ),
              dataRow(
                ThermalInvoicePdfLabels.closingTamaraAr,
                ThermalInvoicePdfLabels.closingTamaraEn,
                report.systemTamaraGross,
                report.physicalTamara,
                report.tamaraDiff,
              ),
              dataRow(
                ThermalInvoicePdfLabels.closingTabbyAr,
                ThermalInvoicePdfLabels.closingTabbyEn,
                report.systemTabbyGross,
                report.physicalTabby,
                report.tabbyDiff,
              ),
              dataRow(
                ThermalInvoicePdfLabels.closingOthersAr,
                ThermalInvoicePdfLabels.closingOthersEn,
                report.systemOthersGross,
                report.physicalOthers,
                report.othersDiff,
              ),
              dashed(),
              dataRow(
                ThermalInvoicePdfLabels.closingTotalAr,
                ThermalInvoicePdfLabels.closingTotalEn,
                report.systemBucketsSumGross,
                report.physicalTotal,
                report.diffBucketsSum,
                emphasize: true,
              ),
              if (report.salesReturnsTotal > 0.001) ...[
                dashed(),
                arabicEnglishAmountLabelSized(
                  ThermalInvoicePdfLabels.closingSalesReturnAr,
                  '${ThermalInvoicePdfLabels.closingSalesReturnEn}: ',
                  -report.salesReturnsTotal,
                ),
              ],
              dashed(),
              arabicEnglishAmountLabelSized(
                ThermalInvoicePdfLabels.closingGrandTotalAr,
                '${ThermalInvoicePdfLabels.closingGrandTotalEn}: ',
                report.systemSales,
                emphasize: true,
              ),
              if (report.commissionAmount > 0.001 ||
                  report.commissionPercent > 0) ...[
                dashed(),
                arabicEnglishAmountLabelSized(
                  ThermalInvoicePdfLabels.closingCommissionAr,
                  '${ThermalInvoicePdfLabels.closingCommissionEn} (${report.commissionPercent.toStringAsFixed(2)}%): ',
                  report.commissionAmount,
                  emphasize: true,
                ),
              ],
            ],
          ),
        );
      },
    ),
  );

  return pdf;
}

Future<Uint8List> buildThermalStoreClosingPdfBytes({
  required StoreClosingReport report,
  String? closingId,
  ThermalPdfAssetBytes? preloadedAssets,
}) async {
  Uint8List? logoBytes;
  if (preloadedAssets != null) {
    logoBytes = preloadedAssets.logoPng;
  } else {
    try {
      final data = await loadBrandLogoByteData();
      if (data != null) {
        final raw = data.buffer.asUint8List();
        logoBytes =
            preprocessThermalReceiptLogoPng(raw, targetMaxWidth: 230) ?? raw;
      }
    } catch (_) {
      logoBytes = null;
    }
  }

  pw.Font font;
  pw.Font fontBold;
  pw.Font fontArabic;
  pw.Font fontArabicBold;
  if (preloadedAssets != null) {
    final noto = pw.Font.ttf(preloadedAssets.notoRegular.buffer.asByteData());
    final notoBold =
        pw.Font.ttf(preloadedAssets.notoBold.buffer.asByteData());
    font = noto;
    fontArabic = noto;
    fontArabicBold = notoBold;
    fontBold = pw.Font.helveticaBold();
  } else {
    try {
      final notoBytes = await rootBundle.load(
        'assets/fonts/NotoSansArabic-Regular.ttf',
      );
      final noto = pw.Font.ttf(notoBytes);
      font = noto;
      fontArabic = noto;
      fontArabicBold = noto;
      fontBold = pw.Font.helveticaBold();
      try {
        final notoBoldBytes = await rootBundle.load(
          'assets/fonts/NotoSansArabic-Bold.ttf',
        );
        fontArabicBold = pw.Font.ttf(notoBoldBytes);
      } catch (_) {}
    } catch (_) {
      try {
        font = await PdfGoogleFonts.poppinsRegular();
        fontBold = await PdfGoogleFonts.poppinsBold();
      } catch (_) {
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
      fontArabicBold = fontBold;
      try {
        fontArabic = await PdfGoogleFonts.almaraiRegular();
      } catch (_) {
        try {
          fontArabic = await PdfGoogleFonts.cairoRegular();
        } catch (_) {
          fontArabic = font;
        }
      }
      try {
        fontArabicBold = await PdfGoogleFonts.notoSansArabicBold();
      } catch (_) {}
    }
  }

  final doc = buildThermalStoreClosingPdfDocument(
    report: report,
    closingId: closingId,
    filterLogoPngBytes: logoBytes,
    font: font,
    fontBold: fontBold,
    fontArabic: fontArabic,
    fontArabicBold: fontArabicBold,
  );
  return doc.save();
}
