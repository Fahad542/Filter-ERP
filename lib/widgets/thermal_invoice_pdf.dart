import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/create_invoice_model.dart';
import '../services/locker_translation_mixin.dart';
import '../services/thermal_pdf_asset_loader.dart';
import '../utils/app_formatters.dart';
import '../utils/plate_transliterator.dart';
import '../utils/bundle_brand_logo.dart';
import '../utils/invoice_maintenance_checklist.dart';
import '../utils/thermal_invoice_totals.dart';
import '../utils/thermal_receipt_layout.dart';
import '../utils/thermal_receipt_logo_preprocess.dart';
import '../utils/thermal_safe_text.dart';
import 'thermal_invoice_pdf_ar_constants.dart';
import 'thermal_arabic_pdf_reshaper.dart';

/// Reshape Arabic for the `pdf` package (which has no HarfBuzz shaping).
/// Call this on every Arabic string before passing it to [pw.Text].
/// Do **not** set [pw.TextDirection.rtl] on reshaped strings — the reshaper
/// already reverses the glyphs for LTR layout.
String _ar(String s) => reshapeArabic(s);

bool _thermalInvoicePdfHasArabic(String s) =>
    RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(s);

/// One contiguous run of characters within a value string. [arabic] selects
/// which font to use for this run when rendering — Latin runs use the Helvetica /
/// Noto Latin font, Arabic runs use Noto Arabic + reshaping. Pure-whitespace
/// runs collapse into the previous run so a space between an English first name
/// and an Arabic surname stays attached and doesn't flip font mid-glyph.
class _ThermalTextRun {
  final String text;
  final bool arabic;
  const _ThermalTextRun(this.text, this.arabic);
}

/// True when the code point belongs to any Arabic / Arabic-related Unicode block.
bool _isArabicCodeUnit(int code) {
  // Arabic, Arabic Supplement, Arabic Extended-A, Arabic Presentation Forms-A/B.
  if (code >= 0x0600 && code <= 0x06FF) return true;
  if (code >= 0x0750 && code <= 0x077F) return true;
  if (code >= 0x08A0 && code <= 0x08FF) return true;
  if (code >= 0xFB50 && code <= 0xFDFF) return true;
  if (code >= 0xFE70 && code <= 0xFEFF) return true;
  return false;
}

/// Split a free-text value into Arabic vs Latin runs so each run can be rendered
/// with the correct PDF font. Without this, a mixed value like
/// `"Ali علي"` rendered with Noto Arabic would show boxes for the Latin
/// characters (and vice versa with Helvetica).
///
/// Whitespace and punctuation glue to the previous run to keep word boundaries
/// intact across a single line.
List<_ThermalTextRun> _splitArabicLatinRuns(String value) {
  if (value.isEmpty) return const [];
  final runs = <_ThermalTextRun>[];
  final buf = StringBuffer();
  bool? currentArabic;

  void flush() {
    if (buf.isEmpty) return;
    runs.add(_ThermalTextRun(buf.toString(), currentArabic ?? false));
    buf.clear();
  }

  for (final code in value.runes) {
    final ch = String.fromCharCode(code);
    final isArabic = _isArabicCodeUnit(code);
    final isWhitespaceOrPunct = RegExp(r'[\s\p{P}]', unicode: true).hasMatch(ch);
    if (currentArabic == null) {
      currentArabic = isArabic;
      buf.write(ch);
      continue;
    }
    if (isWhitespaceOrPunct) {
      // Glue to current run so we don't fragment over spaces/colons/commas.
      buf.write(ch);
      continue;
    }
    if (isArabic == currentArabic) {
      buf.write(ch);
    } else {
      flush();
      currentArabic = isArabic;
      buf.write(ch);
    }
  }
  flush();
  return runs;
}

/// Build a `RichText` children list for a mixed EN+AR value. [ltrStyle] is the
/// Latin / English run style; [rtlStyle] is the Arabic run style (already
/// configured with Noto Arabic). Arabic runs are reshaped via [_ar] so the PDF
/// package — which has no shaper — renders them in correct visual order.
List<pw.InlineSpan> _thermalMixedRunSpans(
  String value, {
  required pw.TextStyle ltrStyle,
  required pw.TextStyle rtlStyle,
}) {
  final runs = _splitArabicLatinRuns(value);
  if (runs.isEmpty) return const [];
  return [
    for (final r in runs)
      pw.TextSpan(
        text: r.arabic ? _ar(r.text) : r.text,
        style: r.arabic ? rtlStyle : ltrStyle,
      ),
  ];
}

/// Vector checkbox for maintenance lines (avoids Unicode ballot glyphs on some printers).
pw.Widget thermalMaintenanceCheckbox(bool checked, {double side = 9.2}) {
  return pw.SizedBox(
    width: side + 3,
    height: side + 1,
    child: pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.SizedBox(
        width: side,
        height: side,
        child: pw.CustomPaint(
          size: PdfPoint(side, side),
          painter: (PdfGraphics canvas, PdfPoint sz) {
            final w = sz.x;
            final h = sz.y;
            const inset = 0.35;
            canvas
              ..setStrokeColor(PdfColors.black)
              ..setLineWidth(0.5)
              ..drawRect(inset, inset, w - 2 * inset, h - 2 * inset)
              ..strokePath();
            if (checked) {
              final x0 = w * 0.20;
              final y0 = h * 0.48;
              final x1 = w * 0.40;
              final y1 = h * 0.22;
              final x2 = w * 0.82;
              final y2 = h * 0.58;
              canvas
                ..setStrokeColor(PdfColors.black)
                ..setLineWidth(0.75)
                ..setLineCap(PdfLineCap.round)
                ..setLineJoin(PdfLineJoin.round)
                ..moveTo(x0, y0)
                ..lineTo(x1, y1)
                ..lineTo(x2, y2)
                ..strokePath();
            }
          },
        ),
      ),
    ),
  );
}

/// Narrow roll-style PDF (~80 mm) for system print preview / AirPrint.
pw.Document buildThermalInvoicePdfDocument({
  required Invoice invoice,
  required String paymentMethodText,
  Uint8List? filterLogoPngBytes,
  required pw.Font font,
  required pw.Font fontBold,
  required pw.Font fontArabic,
  required pw.Font fontArabicBold,
  List<bool>? maintenanceChecksFallback,
  Map<String, String> dynamicArabicValues = const <String, String>{},
}) {
  final t = computeThermalInvoiceTotals(invoice);
  final qrData = thermalInvoiceQrPayload(
    invoice,
    t.totalInvoiceAmount,
    paymentMethodText: paymentMethodText,
    vatAmount: t.vatAmount,
  );
  final issued =
      formatInvoiceIssuedAtDateTime(invoice.issuedAt) ??
      formatInvoiceLegalDate(invoice.invoiceDate);
  final seller = (invoice.branchName ?? '').trim();
  final vatNo = invoice.zatcaSellerVatNumber.trim();
  final addr = (invoice.branchAddress ?? invoice.workshopAddress ?? '').trim();
  final branchCodeLine = (invoice.branchCode ?? '').trim();
  final pdfItemDiscount = thermalR2(t.itemDiscountsTotal);
  final pdfInvoiceDiscount = thermalR2(t.invoiceDiscount);
  final pdfPromoDiscount = thermalR2(t.promoDiscount);
  final pdfReferralDiscount = thermalR2(t.referralDiscount);

  final pdf = pw.Document();

  const fsMeta = 8.15;
  /// Tight line box — removes extra gap under every printed text line.
  const tightLine = 0.78;
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
  /// Extra space between Arabic glyphs/words for thermal readability.
  const kPdfThermalArabicLetterSpacing = 0.42;

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

  String pdfUserLine(String raw) => pdfStripBidiAndInvisible(raw.trim());

  String pdfMoneyEn(num amount) => '${amount.toStringAsFixed(2)} SR';

  /// Logo subtitle — Arabic bold only.
  pw.Widget pdfHeaderSubtitleLine() {
    final style = tsArabicBold().copyWith(fontSize: 10.2, height: 1.1);
    return pw.SizedBox(
      height: 13,
      width: double.infinity,
      child: pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Text(
            _ar(ThermalInvoicePdfLabels.documentSubtitleAr),
            style: style,
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  /// Fixed-height line box — [Column] still reserves full font metrics without this.
  pw.Widget pdfHeaderTightLine(
    String text,
    pw.TextStyle style, {
    required double boxHeight,
    bool reshapeArabic = false,
  }) {
    final display = reshapeArabic ? _ar(text) : text;
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

  String dynamicArabicFor(String raw) {
    final clean = pdfUserLine(raw);
    if (clean.isEmpty || clean == '-') return '';
    if (_thermalInvoicePdfHasArabic(clean)) return '';
    final direct =
        dynamicArabicValues[clean] ?? dynamicArabicValues[raw.trim()];
    final ar = pdfUserLine(direct ?? '');
    if (ar.isNotEmpty && ar.toLowerCase() != clean.toLowerCase()) return ar;
    return '';
  }

  /// Shared AR/EN spacing for headers, totals, items.
  const kPdfBilingualArSize = 7.7;
  const kPdfBilingualEnSize = 7.6;
  const kPdfBilingualArEnGap = 0.1;
  /// Nudge EN up toward AR (+Y is up in PDF canvas).
  const kPdfBilingualEnPullUp = 0.9;
  /// Tighter gap between item Arabic name and English name in the same column.
  /// Catalog Arabic item names — readable line height (multi-line via \\n).
  const kPdfItemArLineHeight = 0.42;
  /// Tighter word/glyph gap than section labels (item names only).
  const kPdfItemArabicLetterSpacing = 0.12;

  /// Tighter than totals — item table column headers only.
  const kPdfTableHeaderEnPullUp = 1.2;

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
      enSize: 7.8,
    );
  }

  pw.Widget bilingualHeaderTriple(String ar, String en) {
    return pw.Center(
      child: _pdfBilingualHeaderColumn(
        ar: ar,
        en: en,
        blockAlign: pw.Alignment.center,
        arTextAlign: pw.TextAlign.center,
        enTextAlign: pw.TextAlign.center,
        crossAlign: pw.CrossAxisAlignment.center,
        enSize: 7,
      ),
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

  pw.Widget pdfBilingualArAboveEnTight({
    required String arabic,
    required pw.Widget englishChild,
    int textArabicMaxLines = 2,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          _ar(arabic),
          style: tsArabicLabel().copyWith(
            fontSize: kPdfBilingualArSize,
            height: 0.94,
            letterSpacing: kPdfThermalArabicLetterSpacing,
          ),
          textAlign: pw.TextAlign.left,
          maxLines: textArabicMaxLines,
        ),
        pw.SizedBox(height: kPdfBilingualArEnGap),
        pw.Transform.translate(
          offset: const PdfPoint(0, kPdfBilingualEnPullUp),
          child: englishChild,
        ),
      ],
    );
  }

  /// Payment section — Arabic heading + per-method amount lines.
  pw.Widget thermalPaymentBreakdownBlock(Invoice invoice, num totalDue) {
    final breakdown = thermalInvoicePaymentBreakdown(
      invoice,
      fallbackTotal: totalDue.toDouble(),
    );
    if (breakdown.isEmpty) {
      return pdfBilingualArAboveEnTight(
        arabic: ThermalInvoicePdfLabels.paymentDetailsAr,
        englishChild: pw.Text(
          '${ThermalInvoicePdfLabels.paymentDetailsEn}: -',
          style: tsLabel().copyWith(
            fontSize: kPdfBilingualEnSize,
            height: 0.92,
          ),
        ),
      );
    }

    final lineStyle = tsLabel().copyWith(
      fontSize: kPdfBilingualEnSize,
      height: 0.92,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pdfBilingualArAboveEnTight(
          arabic: ThermalInvoicePdfLabels.paymentDetailsAr,
          englishChild: pw.Text(
            '${ThermalInvoicePdfLabels.paymentDetailsEn}:',
            style: lineStyle,
          ),
        ),
        for (final line in breakdown) ...[
          pw.SizedBox(height: 0.12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  thermalSafeText(line.method),
                  style: lineStyle,
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Text(
                pdfMoneyEn(line.amount),
                style: lineStyle,
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget arabicAboveRichLabelSized(
    String arabicLines,
    String englishLabel,
    String englishValue, {
    required double enSize,
    double arabicSize = 6.95,
  }) {
    final lbl = tsLabel().copyWith(fontSize: enSize, height: 0.92);
    final val = tsValue().copyWith(fontSize: enSize, height: 0.92);
    return pw.Row(
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
                  fontSize: arabicSize,
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
        pw.Text(englishValue, style: val, textAlign: pw.TextAlign.right),
      ],
    );
  }

  pw.Widget arabicEnglishAmountLabelSized(
    String arabicLines,
    String englishLabel,
    num amount, {
    required double enSize,
    double arabicSize = 7.6,
    bool compact = false,
    bool emphasize = false,
    int arabicMaxLines = 3,
  }) {
    if (compact) {
      final lbl = tsLabel().copyWith(
        fontSize: kPdfBilingualEnSize,
        height: 0.92,
      );
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
              pdfMoneyEn(amount),
              style: val,
              textAlign: pw.TextAlign.right,
            ),
          ],
        ),
      );
    }
    final lbl = tsLabel().copyWith(fontSize: enSize);
    final val = tsValue().copyWith(fontSize: enSize);
    final arLbl = tsArabicLabel().copyWith(fontSize: arabicSize);
    return pw.Padding(
      padding: pw.EdgeInsets.zero,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            _ar(arabicLines),
            style: arLbl,
            textAlign: pw.TextAlign.left,
            maxLines: 10,
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  englishLabel,
                  style: lbl,
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Text(
                pdfMoneyEn(amount),
                style: val,
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Header meta — English label + value on the left, Arabic field label on the right.
  /// e.g. `VAT Number: 3007902937 : الرقم الضريبي`
  /// Mixed EN+AR values (e.g. workshop / branch names) are split into per-script
  /// runs so each glyph uses the right font instead of falling back to boxes.
  pw.Widget pdfMetaEnValueArFieldRow(
    String enLabel,
    String rawValue,
    String arFieldLabel, {
    bool boldArabicValue = true,
  }) {
    final disp = pdfUserLine(rawValue);
    final v = disp.isEmpty ? '-' : disp;
    const metaLine = 0.72;
    final labelStyle = tsLabel().copyWith(
      height: metaLine,
      fontFallback: <pw.Font>[fontArabic],
    );
    final ltrValueStyle = tsValue().copyWith(
      height: metaLine,
      fontFallback: <pw.Font>[fontArabic],
    );
    final arBold = tsArabicBold().copyWith(
      height: metaLine,
      fontFallback: <pw.Font>[font],
    );
    final arRegular = tsArabicValue().copyWith(
      height: metaLine,
      fontFallback: <pw.Font>[font],
    );
    final rtlValueStyle = boldArabicValue ? arBold : arRegular;

    final children = <pw.InlineSpan>[
      pw.TextSpan(text: '$enLabel: ', style: labelStyle),
      ..._thermalMixedRunSpans(
        v,
        ltrStyle: ltrValueStyle,
        rtlStyle: rtlValueStyle,
      ),
      pw.TextSpan(text: '   :   ', style: labelStyle),
      pw.TextSpan(text: _ar(arFieldLabel), style: arBold),
    ];

    return pw.SizedBox(
      height: 9.8,
      width: double.infinity,
      child: pw.Align(
        alignment: pw.Alignment.topCenter,
        child: pw.RichText(
          textAlign: pw.TextAlign.center,
          text: pw.TextSpan(children: children),
          maxLines: 2,
        ),
      ),
    );
  }

  /// Header meta — single English label + value on one line (matches [ThermalInvoiceReceipt]).
  pw.Widget pdfMetaEnglishMetaRow(
    String enPrefix,
    String rawValue, {
    bool center = false,
    bool compact = false,
    bool compactBox = false,
  }) {
    const metaLine = 0.72;
    final disp = pdfUserLine(rawValue);
    final v = disp.isEmpty ? '-' : disp;
    final labelStyle = tsLabel().copyWith(
      height: compact ? metaLine : null,
      fontFallback: <pw.Font>[fontArabic],
    );
    final ltrValueStyle = tsValue().copyWith(
      height: compact ? metaLine : null,
      fontFallback: <pw.Font>[fontArabic],
    );
    final rtlValueStyle = tsArabicValue().copyWith(
      height: compact ? metaLine : null,
      fontFallback: <pw.Font>[font],
    );
    final align = center ? pw.TextAlign.center : pw.TextAlign.left;
    final maxLines = compact ? 2 : 6;

    final children = <pw.InlineSpan>[
      pw.TextSpan(text: enPrefix, style: labelStyle),
      ..._thermalMixedRunSpans(
        v,
        ltrStyle: ltrValueStyle,
        rtlStyle: rtlValueStyle,
      ),
    ];
    final pw.Widget inner = pw.RichText(
      text: pw.TextSpan(children: children),
      textAlign: align,
      maxLines: maxLines,
    );
    if (!compactBox) return inner;
    return pw.SizedBox(
      height: 9.8,
      width: double.infinity,
      child: pw.Align(
        alignment:
            center ? pw.Alignment.topCenter : pw.Alignment.topLeft,
        child: inner,
      ),
    );
  }

  /// Customer grid cell — `Name: value` on one line.
  ///
  /// Mixed EN+AR values (e.g. customer name "Ali علي", make "TOYOTA كامري")
  /// are split into per-language runs so each glyph uses the correct font.
  /// Previously the whole value was forced into one font, producing boxes for
  /// the other-script characters.
  pw.Widget simpleCustGridCell(
    String label,
    String value, {
    bool compact = false,
  }) {
    const lh = 0.68;
    final v = pdfUserLine(value);
    if (v.isEmpty) return pw.SizedBox();
    final prefix = '$label: ';
    final labelStyle = tsLabel().copyWith(
      fontSize: compact ? 7.55 : null,
      height: compact ? lh : null,
      fontFallback: <pw.Font>[fontArabic],
    );
    final ltrValueStyle = tsValue().copyWith(
      fontSize: compact ? 7.55 : null,
      height: compact ? lh : null,
      fontFallback: <pw.Font>[fontArabic],
    );
    final rtlValueStyle = ltrValueStyle.copyWith(
      font: fontArabic,
      fontFallback: <pw.Font>[font],
    );

    final children = <pw.InlineSpan>[
      pw.TextSpan(text: prefix, style: labelStyle),
      ..._thermalMixedRunSpans(
        v,
        ltrStyle: ltrValueStyle,
        rtlStyle: rtlValueStyle,
      ),
    ];

    final hasArabic = _thermalInvoicePdfHasArabic(v);
    final inner = pw.RichText(
      text: pw.TextSpan(children: children),
      maxLines: compact ? 2 : (hasArabic ? 4 : 3),
    );
    if (!compact) return inner;
    return pw.SizedBox(
      height: 8.25,
      width: double.infinity,
      child: pw.Align(alignment: pw.Alignment.topLeft, child: inner),
    );
  }

  /// English line, then Arabic nudged up to sit closer under it.
  pw.Widget pdfMaintenanceChecklistLabel(String en, String ar) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          en,
          style: tsLabel().copyWith(fontSize: 6.45),
          maxLines: 2,
          textAlign: pw.TextAlign.left,
        ),
        pw.Transform.translate(
          // PDF canvas: +Y is up; negative was pushing Arabic down.
          offset: const PdfPoint(0, 1.9),
          child: pw.Text(
            _ar(ar),
            style: tsArabicLabel().copyWith(fontSize: 6.85),
            maxLines: 2,
            textAlign: pw.TextAlign.left,
          ),
        ),
      ],
    );
  }

  pw.Widget plainSectionTitle(String en, {bool center = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 0.35, bottom: 0.4),
        child: pw.SizedBox(
          width: double.infinity,
          child: pw.Text(
            en,
            style: tsLabel().copyWith(fontSize: fsMeta + 0.85, height: 0.72),
            textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
          ),
        ),
      );

  /// Full-width dotted rule — breathing room above and below every section break.
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

  pw.Widget row4(pw.Widget w1, pw.Widget w2, pw.Widget w3, pw.Widget w4) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 5, child: w1),
        pw.SizedBox(width: 22, child: w2),
        pw.Expanded(flex: 3, child: w3),
        pw.Expanded(flex: 3, child: w4),
      ],
    );
  }

  pw.Widget thermalDetailGrid(
    List<pw.Widget> cells, {
    int columnsPerRow = 1,
    double rowGap = 0,
    double colGap = 5,
  }) {
    final cols = columnsPerRow.clamp(1, 12);
    final rows = <pw.Widget>[];
    for (var i = 0; i < cells.length; i += cols) {
      final end = i + cols > cells.length ? cells.length : i + cols;
      final chunk = cells.sublist(i, end);
      rows.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: rowGap),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var idx = 0; idx < chunk.length; idx++)
                pw.Expanded(
                  child: pw.Padding(
                    padding: pw.EdgeInsets.only(
                      right: idx < chunk.length - 1 ? colGap : 0,
                    ),
                    child: chunk[idx],
                  ),
                ),
              for (var j = chunk.length; j < cols; j++)
                pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  final itemQtyTotalStyle =
      pw.TextStyle(font: font, fontSize: 8.35, height: tightLine);
  final itemUnitStyle =
      pw.TextStyle(font: font, fontSize: 8.35, height: tightLine);
  final itemEnStyle =
      pw.TextStyle(font: fontBold, fontSize: 8.45, height: tightLine);
  final itemArStyle = pw.TextStyle(
    font: fontArabic,
    fontSize: 8.3,
    height: kPdfItemArLineHeight,
    letterSpacing: kPdfItemArabicLetterSpacing,
  );

  pw.Widget pdfItemArabicNameBlock(List<String> lines) {
    if (lines.isEmpty) return pw.SizedBox();
    return pw.Text(
      _ar(lines.join('\n')),
      style: itemArStyle,
      textAlign: pw.TextAlign.left,
      softWrap: true,
    );
  }

  final itemBlocks = <pw.Widget>[];
  accumulateInvoiceItems(invoice, (item) {
    final qty = item.qty % 1 == 0
        ? '${item.qty.toInt()}'
        : item.qty.toStringAsFixed(2);
    final unit = item.qty > 0.0001
        ? thermalR2(item.lineTotal / item.qty)
        : thermalR2(item.unitPrice);
    final total = thermalR2(item.lineTotal);
    final en = thermalSafeText(item.productName).toUpperCase();
    final catalogArRaw = (item.productNameArabic ?? '').trim().isNotEmpty
        ? item.productNameArabic!.trim()
        : dynamicArabicFor(item.productName);
    final arLines = thermalItemArabicNameLines(catalogArRaw);
    final hasAr = arLines.isNotEmpty;
    itemBlocks.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 0.06),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (hasAr) pdfItemArabicNameBlock(arLines),
                  if (hasAr) pw.SizedBox(height: 0.35),
                  pw.Text(
                    en,
                    style: itemEnStyle,
                    textAlign: pw.TextAlign.left,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(
              width: 22,
              child: pw.Center(child: pw.Text(qty, style: itemQtyTotalStyle)),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                pdfMoneyEn(unit),
                style: itemUnitStyle,
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                pdfMoneyEn(total),
                style: itemQtyTotalStyle,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  });

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        80 * PdfPageFormat.mm,
        double.infinity,
        marginAll: 4 * PdfPageFormat.mm,
      ),
      build: (ctx) {
        bool hasAnyText(String? s) => (s ?? '').trim().isNotEmpty;

        bool hasMeaningfulCustomerName(String name) {
          final t = name.trim();
          return t.isNotEmpty && t.toLowerCase() != 'unknown';
        }

        final customerKids = <pw.Widget>[];

        // Customer rows are English-only labels per receipt design — value can
        // still render Arabic when the data itself is Arabic.
        void addCustLine(String label, String valueTrimmed) {
          if (valueTrimmed.isEmpty) return;
          customerKids.add(
            simpleCustGridCell(label, valueTrimmed, compact: true),
          );
        }

        if (hasMeaningfulCustomerName(invoice.customerName)) {
          addCustLine('Name', invoice.customerName.trim());
        }
        if (hasAnyText(invoice.customerMobile)) {
          addCustLine('Mobile', invoice.customerMobile!.trim());
        }
        if (hasAnyText(invoice.customerTaxId)) {
          addCustLine('Tax ID', invoice.customerTaxId!.trim());
        }
        addCustLine(
          'Customer type',
          pdfUserLine(invoice.thermalDisplayedCustomerType.trim()),
        );

        final hasMake = invoice.vehicleMake.trim().isNotEmpty;
        final hasModel = invoice.vehicleModel.trim().isNotEmpty;
        if (!(hasMake || hasModel) && invoice.vehicleInfo.trim().isNotEmpty) {
          addCustLine('Vehicle', invoice.vehicleInfo.trim());
        } else {
          if (hasMake) addCustLine('Make', invoice.vehicleMake.trim());
          if (hasModel) addCustLine('Model', invoice.vehicleModel.trim());
        }

        if (hasAnyText(invoice.vehicleYear)) {
          addCustLine('Year', invoice.vehicleYear.trim());
        }
        if (invoice.plateNo.trim().isNotEmpty) {
          // Plate value is rendered as English (letters-first MoI format) only
          // — the Arabic plate transliteration line is intentionally omitted
          // to match the simplified receipt layout.
          final formatted = formatVehiclePlateLettersFirst(
            invoice.plateNo.trim(),
          );
          customerKids.add(
            simpleCustGridCell(
              'Plate',
              formatted.isEmpty ? invoice.plateNo.trim() : formatted,
              compact: true,
            ),
          );
        }
        if (hasAnyText(invoice.vehicleVin)) {
          addCustLine('VIN', invoice.vehicleVin.trim());
        }
        if (invoice.odometerReading != null && invoice.odometerReading! > 0) {
          addCustLine('Odometer', '${invoice.odometerReading}');
        }

        final chkReceipt = InvoiceMaintenanceChecklist.displayChecks(
          invoice,
          maintenanceChecksFallback,
        );
        final checklistKids = <pw.Widget>[];
        for (var i = 0; i < InvoiceMaintenanceChecklist.rows.length; i++) {
          final row = InvoiceMaintenanceChecklist.rows[i];
          final ticked = i < chkReceipt.length && chkReceipt[i];
          checklistKids.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 0.35),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 3),
                    child: thermalMaintenanceCheckbox(ticked),
                  ),
                  pw.Expanded(
                    child: pdfMaintenanceChecklistLabel(row.en, row.ar),
                  ),
                ],
              ),
            ),
          );
        }

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
                ThermalInvoicePdfLabels.documentTitleAr,
                tsArabicValue().copyWith(fontSize: 10.2, height: 1.05),
                boxHeight: 11.5,
                reshapeArabic: true,
              ),
              pw.SizedBox(height: 4.5),
              pdfHeaderTightLine(
                ThermalInvoicePdfLabels.documentTitleEn,
                tsLabel().copyWith(fontSize: 9.4),
                boxHeight: 10,
              ),
              pw.SizedBox(height: 4.5),
              pdfHeaderTightLine(
                pdfUserLine(seller.isEmpty ? '-' : seller),
                _thermalInvoicePdfHasArabic(seller)
                    ? tsArabicValue().copyWith(fontSize: 9.5, height: 1.05)
                    : tsLabel().copyWith(fontSize: 9.2),
                boxHeight: 9.5,
                reshapeArabic: _thermalInvoicePdfHasArabic(seller),
              ),
              pw.SizedBox(height: 0.75),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.addressMetaEn,
                addr.isEmpty ? '-' : addr,
                ThermalInvoicePdfLabels.addressAr,
                boldArabicValue: false,
              ),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.branchLabelEn,
                branchCodeLine.isEmpty ? '-' : branchCodeLine,
                ThermalInvoicePdfLabels.branchLabelAr,
                boldArabicValue: false,
              ),
              pdfMetaEnValueArFieldRow(
                ThermalInvoicePdfLabels.vatNumberMetaEn,
                vatNo.isEmpty ? '-' : pdfUserLine(vatNo),
                ThermalInvoicePdfLabels.vatNoAr,
              ),
              pw.SizedBox(height: 2.5),
              dashed(),
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    height: 8.5,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pdfMetaEnglishMetaRow(
                            '${ThermalInvoicePdfLabels.invoiceNoMetaEn}: ',
                            pdfUserLine(invoice.invoiceNo),
                            compact: true,
                          ),
                        ),
                        pw.Expanded(
                          child: pdfMetaEnglishMetaRow(
                            '${ThermalInvoicePdfLabels.cashierLabelEn}: ',
                            invoice.cashierName ?? '-',
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pdfMetaEnglishMetaRow(
                    '${ThermalInvoicePdfLabels.dateLabelEn}: ',
                    pdfUserLine(issued),
                    compact: true,
                    compactBox: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 2.5),
              dashed(),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 0.5),
                child: row4(
                  bilingualHeaderLeading(
                    ThermalInvoicePdfLabels.columnItemAr,
                    ThermalInvoicePdfLabels.columnItemEn,
                  ),
                  bilingualHeaderTriple(
                    ThermalInvoicePdfLabels.columnQtyAr,
                    ThermalInvoicePdfLabels.columnQtyEn,
                  ),
                  bilingualHeaderEndAligned(
                    ThermalInvoicePdfLabels.columnUnitAr,
                    ThermalInvoicePdfLabels.columnUnitEn,
                  ),
                  bilingualHeaderEndAligned(
                    ThermalInvoicePdfLabels.columnTotalAr,
                    ThermalInvoicePdfLabels.columnTotalEn,
                  ),
                ),
              ),
              dashed(),
              ...itemBlocks,
              dashed(),
              arabicEnglishAmountLabelSized(
                ThermalInvoicePdfLabels.totalExclVatAr,
                '${ThermalInvoicePdfLabels.totalExclVatEn}: ',
                t.grossExVatBeforeDiscount,
                enSize: 7.8,
                compact: true,
              ),
              if (pdfItemDiscount > 0)
                arabicEnglishAmountLabelSized(
                  ThermalInvoicePdfLabels.itemDiscountAr,
                  '${ThermalInvoicePdfLabels.itemDiscountEn}: ',
                  pdfItemDiscount,
                  enSize: 7.6,
                  compact: true,
                ),
              if (pdfInvoiceDiscount > 0)
                arabicEnglishAmountLabelSized(
                  ThermalInvoicePdfLabels.invoiceDiscountAr,
                  '${ThermalInvoicePdfLabels.invoiceDiscountEn}: ',
                  pdfInvoiceDiscount,
                  enSize: 7.6,
                  compact: true,
                ),
              if (pdfPromoDiscount > 0)
                arabicEnglishAmountLabelSized(
                  ThermalInvoicePdfLabels.promoDiscountAr,
                  '${ThermalInvoicePdfLabels.promoDiscountEn}: ',
                  pdfPromoDiscount,
                  enSize: 7.6,
                  compact: true,
                ),
              if (pdfReferralDiscount > 0)
                arabicEnglishAmountLabelSized(
                  ThermalInvoicePdfLabels.referralDiscountAr,
                  '${ThermalInvoicePdfLabels.referralDiscountEn}: ',
                  pdfReferralDiscount,
                  enSize: 7.6,
                  compact: true,
                ),
              arabicEnglishAmountLabelSized(
                ThermalInvoicePdfLabels.taxableAr,
                '${ThermalInvoicePdfLabels.taxableEn}: ',
                t.totalTaxableAmount,
                enSize: 7.6,
                compact: true,
              ),
              arabicEnglishAmountLabelSized(
                ThermalInvoicePdfLabels.totalVatAr,
                '${ThermalInvoicePdfLabels.totalVatEn}: ',
                t.vatAmount,
                enSize: 7.6,
                compact: true,
              ),
              dashed(),
              arabicEnglishAmountLabelSized(
                ThermalInvoicePdfLabels.totalDueAr,
                '${ThermalInvoicePdfLabels.totalDueEn}: ',
                t.totalInvoiceAmount,
                enSize: kPdfBilingualEnSize,
                compact: true,
                emphasize: true,
              ),
              dashed(),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 0.15, bottom: 0.15),
                child: thermalPaymentBreakdownBlock(
                  invoice,
                  t.totalInvoiceAmount,
                ),
              ),
              if (invoice.nextOilChangeKm != null) ...[
                dashed(),
                arabicAboveRichLabelSized(
                  ThermalInvoicePdfLabels.nextOilChangeAr,
                  '${ThermalInvoicePdfLabels.nextOilChangeEn}: ',
                  '${NumberFormat('#,##0', 'en_US').format(invoice.nextOilChangeKm!)} km',
                  enSize: 7.4,
                  arabicSize: kPdfBilingualArSize,
                ),
              ],
              dashed(),
              if (customerKids.isNotEmpty) ...[
                pw.SizedBox(height: 2.5),
                plainSectionTitle(
                  ThermalInvoicePdfLabels.customerDetailsSectionEn,
                  center: true,
                ),
                thermalDetailGrid(
                  customerKids,
                  columnsPerRow: 2,
                  rowGap: 0.1,
                  colGap: 4,
                ),
                pw.SizedBox(height: 2.5),
              ],
              if (checklistKids.isNotEmpty) ...[
                dashed(),
                plainSectionTitle(
                  ThermalInvoicePdfLabels.maintenanceSectionEn,
                  center: true,
                ),
                pw.SizedBox(height: 3.5),
                thermalDetailGrid(
                  checklistKids,
                  columnsPerRow: 2,
                  rowGap: 0.1,
                  colGap: 4,
                ),
              ],
              dashed(),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(
                    errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                  ),
                  data: qrData,
                  // Dense Phase-2 TLV — match web invoice scannable size.
                  width: 132,
                  height: 132,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '${ThermalInvoicePdfLabels.thankYouEn} - ',
                    style: tsValue().copyWith(fontSize: 8.1, height: 0.92),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    _ar(ThermalInvoicePdfLabels.thankYouAr),
                    style: tsArabicLabel().copyWith(
                      fontSize: 9.1,
                      height: 0.94,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf;
}

Future<Uint8List> buildThermalInvoicePdfBytes({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
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

  /// [font] / [fontArabic] = Noto Regular (Latin + Arabic).
  /// [fontBold] = Helvetica Bold for English labels only.
  pw.Font font;
  pw.Font fontBold;
  pw.Font fontArabic;
  pw.Font fontArabicBold;
  if (preloadedAssets != null) {
    // Bytes were captured on the main isolate where AssetManifest works, so
    // this branch is safe to run from a worker isolate. It also skips the
    // PdfGoogleFonts.* network fallback chain (which adds ~10–30 s of stall
    // and is the real reason Generate Invoice felt stuck previously).
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
      // Latin labels (Address:, Invoice No:, …) need ASCII glyphs — not Arabic Bold.
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

  // Dynamic API/database values cannot use the Flutter LocalizedApiText widget in
  // a pdf/widgets document. Use the same translation service behind
  // LocalizedApiText so screen preview, PDF, and Wi-Fi print all stay bilingual.
  final dynamicArabicValues = <String, String>{};

  Future<void> addDynamicArabic(String? raw) async {
    final clean = pdfStripBidiAndInvisible((raw ?? '').trim());
    if (clean.isEmpty || clean == '-' || _thermalInvoicePdfHasArabic(clean)) {
      return;
    }
    // Plates are handled by PlateTransliterator only, not by API translation.
    if (PlateTransliterator.looksLikePlate(clean)) return;
    // Pure numbers, phone numbers, dates, and IDs only need Arabic-Indic digits;
    // do not send them to dynamic API translation.
    if (!RegExp(r'[A-Za-z]').hasMatch(clean)) return;
    if (dynamicArabicValues.containsKey(clean)) return;
    try {
      final translated =
          await AppTranslationService.localizedDynamicValueForLanguage(
            clean,
            'ar',
          );
      final ar = pdfStripBidiAndInvisible(translated.trim());
      if (ar.isNotEmpty && ar.toLowerCase() != clean.toLowerCase()) {
        dynamicArabicValues[clean] = ar;
      }
    } catch (_) {
      // Printing must never fail because dynamic translation is unavailable.
    }
  }

  await Future.wait([
    addDynamicArabic(invoice.branchName),
    addDynamicArabic(invoice.branchCode),
    addDynamicArabic(invoice.branchAddress),
    addDynamicArabic(invoice.workshopAddress),
    addDynamicArabic(invoice.cashierName),
    // Do not auto-translate customer / vehicle free-text values in the PDF; keep them as entered.
    // This avoids confusing mixed output such as Arabic transliteration of customer names.
    for (final item in invoice.items) addDynamicArabic(item.productName),
    for (final dept in invoice.departments)
      for (final item in dept.items) addDynamicArabic(item.productName),
  ]);

  final doc = buildThermalInvoicePdfDocument(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    filterLogoPngBytes: logoBytes,
    font: font,
    fontBold: fontBold,
    fontArabic: fontArabic,
    fontArabicBold: fontArabicBold,
    maintenanceChecksFallback: maintenanceChecksFallback,
    dynamicArabicValues: dynamicArabicValues,
  );
  return doc.save();
}
