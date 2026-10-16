import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_localizations.dart';

import '../models/create_invoice_model.dart';
import '../utils/app_formatters.dart';
import '../utils/invoice_maintenance_checklist.dart';
import '../utils/thermal_invoice_totals.dart';
import 'thermal_invoice_pdf_ar_constants.dart';
import '../services/LocalizedApiText.dart';
import '../utils/app_arabic_font_fallbacks.dart';

const double kThermalPaperWidth = 380;

/// Arabic labels/headers on thermal receipt.
const double kThermalReceiptArabicLetterSpacing = 0.4;
const double kThermalReceiptArabicWordSpacing = 1.15;

/// Tighter spacing for catalog item Arabic names only.
const double kThermalReceiptItemArabicLetterSpacing = 0.1;
const double kThermalReceiptItemArabicWordSpacing = 0.0;

TextStyle thermalReceiptArabicText(TextStyle base) => base.copyWith(
      letterSpacing: kThermalReceiptArabicLetterSpacing,
      wordSpacing: kThermalReceiptArabicWordSpacing,
      fontFamilyFallback: appArabicFontFallbacks(),
    );

TextStyle thermalReceiptItemArabicText(TextStyle base) => base.copyWith(
      letterSpacing: kThermalReceiptItemArabicLetterSpacing,
      wordSpacing: kThermalReceiptItemArabicWordSpacing,
      fontFamilyFallback: appArabicFontFallbacks(),
    );

bool _thermalReceiptIsAr(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'ar';


String _thermalReceiptMoney(BuildContext context, double value) =>
    _thermalReceiptIsAr(context)
        ? '${value.toStringAsFixed(2)} ر.س'
        : '${value.toStringAsFixed(2)} SR';

String paymentMethodLabelAr(String method) {
  final m = method.trim().toLowerCase();
  if (m.contains('card')) return 'الدفع عن طريق البطاقة';
  if (m.contains('cash')) return 'الدفع نقدًا';
  if (m.contains('bank')) return 'تحويل بنكي';
  return method;
}

/// Full-width dotted divider (same idea as thermal PDF print).
class _ThermalDotDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;
    const r = 1.35;
    const gap = 3.2;
    var x = r;
    final y = size.height * 0.5;
    while (x <= size.width + 0.01) {
      canvas.drawCircle(Offset(x, y), r, paint);
      x += r * 2 + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _thermalLabelValueLine(
  String label,
  String value,
  TextStyle labelStyle,
  TextStyle valueStyle, {
  TextAlign textAlign = TextAlign.left,
  bool compact = false,
  bool compactBox = false,
}) {
  final line = compact ? 1.0 : null;
  final rich = Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: line == null ? labelStyle : labelStyle.copyWith(height: line),
        ),
        TextSpan(
          text: value,
          style: line == null ? valueStyle : valueStyle.copyWith(height: line),
        ),
      ],
    ),
    textAlign: textAlign,
    maxLines: compact ? 2 : 6,
    overflow: TextOverflow.visible,
    softWrap: true,
  );
  if (!compactBox) return rich;
  return SizedBox(
    height: 13,
    width: double.infinity,
    child: Align(
      alignment: textAlign == TextAlign.right
          ? Alignment.topRight
          : Alignment.topLeft,
      child: rich,
    ),
  );
}

Widget _thermalHeaderSubtitleLine(TextStyle boldStyle) {
  return SizedBox(
    height: 16,
    width: double.infinity,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Text(
          ThermalInvoicePdfLabels.documentSubtitleAr,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: thermalReceiptArabicText(
            boldStyle.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.15,
            ),
          ),
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
      ),
    ),
  );
}

/// Fixed height so [Column] does not reserve extra space under each header line.
Widget _thermalHeaderTightLine(
  String text,
  TextStyle style, {
  required double boxHeight,
  TextDirection? textDirection,
}) {
  return SizedBox(
    height: boxHeight,
    width: double.infinity,
    child: Align(
      alignment: Alignment.topCenter,
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: textDirection,
        style: textDirection == TextDirection.rtl
            ? thermalReceiptArabicText(style.copyWith(height: 1))
            : style.copyWith(height: 1),
        maxLines: 2,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    ),
  );
}

Widget _thermalMetaEnValueArFieldRow(
  String enLabel,
  String value,
  String arFieldLabel,
  TextStyle labelStyle,
  TextStyle valueStyle, {
  bool boldArabicValue = true,
}) {
  final arBold = thermalReceiptArabicText(
    valueStyle.copyWith(fontWeight: FontWeight.w800),
  );
  final valueStyleResolved =
      boldArabicValue ? arBold : valueStyle;
  return SizedBox(
    height: 13,
    width: double.infinity,
    child: Align(
      alignment: Alignment.topCenter,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$enLabel: ', style: labelStyle),
            TextSpan(
              text: value,
              style: valueStyleResolved.copyWith(height: 1.0),
            ),
            TextSpan(text: '   :   ', style: labelStyle),
            TextSpan(
              text: arFieldLabel,
              style: arBold.copyWith(height: 1.0),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 2,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    ),
  );
}

Widget thermalDashedRule() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: double.infinity,
      height: 5,
      child: CustomPaint(painter: _ThermalDotDividerPainter()),
    ),
  );
}

/// On-screen thermal-style simplified tax invoice (bilingual shell; line names follow API).
class ThermalInvoiceReceipt extends StatelessWidget {
  final Invoice invoice;
  final String paymentMethodText;

  const ThermalInvoiceReceipt({
    super.key,
    required this.invoice,
    required this.paymentMethodText,
  });

  @override
  Widget build(BuildContext context) {
    final t = computeThermalInvoiceTotals(invoice);
    final qrData = thermalInvoiceQrPayload(
      invoice,
      t.totalInvoiceAmount,
      paymentMethodText: paymentMethodText,
      vatAmount: t.vatAmount,
    );
    final issued = formatInvoiceIssuedAtDateTime(invoice.issuedAt) ??
        formatInvoiceLegalDate(invoice.invoiceDate);
    final seller = (invoice.branchName ?? '').trim();
    final vatNo = invoice.zatcaSellerVatNumber.trim();
    final addr =
        (invoice.branchAddress ?? invoice.workshopAddress ?? '').trim();
    final branchCodeLine = (invoice.branchCode ?? '').trim();

    const headEn = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      color: Color(0xFF111111),
      height: 1.0,
    );
    const headAr = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.0,
    );
    final body = TextStyle(
      fontSize: 10.5,
      height: 1.0,
      color: Colors.grey.shade900,
      fontWeight: FontWeight.w500,
    );
    final bodyBold = body.copyWith(fontWeight: FontWeight.w800);
    return Container(
      width: kThermalPaperWidth,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Center(
              child: Image.asset(
                kThermalInvoiceLogoAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 1),
          _thermalHeaderSubtitleLine(
            headAr.copyWith(color: Colors.grey.shade900),
          ),
          const SizedBox(height: 2),
          _thermalHeaderTightLine(
            ThermalInvoicePdfLabels.documentTitleAr,
            headAr.copyWith(
              color: Colors.grey.shade900,
              fontWeight: FontWeight.w600,
            ),
            boxHeight: 15,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 5),
          if (!_thermalReceiptIsAr(context))
            _thermalHeaderTightLine(
              AppLocalizations.of(context)!.posReceiptSimplifiedTaxInvoice,
              headEn.copyWith(fontWeight: FontWeight.w900),
              boxHeight: 14,
            ),
          const SizedBox(height: 6),
          _thermalHeaderTightLine(
            seller.isEmpty ? '-' : seller,
            headEn.copyWith(fontSize: 12, fontWeight: FontWeight.w900),
            boxHeight: 12,
          ),
          const SizedBox(height: 1),
          _thermalMetaEnValueArFieldRow(
            ThermalInvoicePdfLabels.addressMetaEn,
            addr.isEmpty ? '-' : addr,
            ThermalInvoicePdfLabels.addressAr,
            bodyBold,
            body,
            boldArabicValue: false,
          ),
          _thermalMetaEnValueArFieldRow(
            ThermalInvoicePdfLabels.branchLabelEn,
            branchCodeLine.isEmpty ? '-' : branchCodeLine,
            ThermalInvoicePdfLabels.branchLabelAr,
            bodyBold,
            body,
            boldArabicValue: false,
          ),
          _thermalMetaEnValueArFieldRow(
            ThermalInvoicePdfLabels.vatNumberMetaEn,
            vatNo.isEmpty ? '-' : vatNo,
            ThermalInvoicePdfLabels.vatNoAr,
            bodyBold,
            body,
          ),
          const SizedBox(height: 4),
          thermalDashedRule(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _thermalLabelValueLine(
                        'Invoice No',
                        invoice.invoiceNo,
                        bodyBold,
                        body,
                        compact: true,
                      ),
                    ),
                    Expanded(
                      child: _thermalLabelValueLine(
                        'Cashier',
                        invoice.cashierName ?? '-',
                        bodyBold,
                        body,
                        textAlign: TextAlign.right,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              _thermalLabelValueLine(
                'Date',
                issued,
                bodyBold,
                body,
                compact: true,
                compactBox: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          thermalDashedRule(),
          Padding(
            padding: const EdgeInsets.only(bottom: 0.5),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _bilingualColumnHeader(
                  ar: ThermalInvoicePdfLabels.columnItemAr,
                  en: ThermalInvoicePdfLabels.columnItemEn,
                  align: TextAlign.left,
                  bodyBold: bodyBold,
                ),
              ),
              SizedBox(
                width: 28,
                child: _bilingualColumnHeader(
                  ar: ThermalInvoicePdfLabels.columnQtyAr,
                  en: ThermalInvoicePdfLabels.columnQtyEn,
                  align: TextAlign.center,
                  bodyBold: bodyBold,
                ),
              ),
              Expanded(
                flex: 3,
                child: _bilingualColumnHeader(
                  ar: ThermalInvoicePdfLabels.columnUnitAr,
                  en: ThermalInvoicePdfLabels.columnUnitEn,
                  align: TextAlign.right,
                  bodyBold: bodyBold,
                ),
              ),
              Expanded(
                flex: 3,
                child: _bilingualColumnHeader(
                  ar: ThermalInvoicePdfLabels.columnTotalAr,
                  en: ThermalInvoicePdfLabels.columnTotalEn,
                  align: TextAlign.right,
                  bodyBold: bodyBold,
                ),
              ),
            ],
          ),
          ),
          thermalDashedRule(),
          ..._itemRows(context, body),
          thermalDashedRule(),
          _bilingualMoneyRow(
            context,
            ThermalInvoicePdfLabels.totalExclVatAr,
            ThermalInvoicePdfLabels.totalExclVatEn,
            t.grossExVatBeforeDiscount,
            body,
            bodyBold: bodyBold,
          ),
          if (t.itemDiscountsTotal > 0.001)
            _bilingualMoneyRow(
              context,
              ThermalInvoicePdfLabels.itemDiscountAr,
              ThermalInvoicePdfLabels.itemDiscountEn,
              t.itemDiscountsTotal,
              body,
              bodyBold: bodyBold,
            ),
          if (t.invoiceDiscount > 0.001)
            _bilingualMoneyRow(
              context,
              ThermalInvoicePdfLabels.invoiceDiscountAr,
              ThermalInvoicePdfLabels.invoiceDiscountEn,
              t.invoiceDiscount,
              body,
              bodyBold: bodyBold,
            ),
          if (t.promoDiscount > 0.001)
            _bilingualMoneyRow(
              context,
              ThermalInvoicePdfLabels.promoDiscountAr,
              ThermalInvoicePdfLabels.promoDiscountEn,
              t.promoDiscount,
              body,
              bodyBold: bodyBold,
            ),
          if (t.referralDiscount > 0.001)
            _bilingualMoneyRow(
              context,
              ThermalInvoicePdfLabels.referralDiscountAr,
              ThermalInvoicePdfLabels.referralDiscountEn,
              t.referralDiscount,
              body,
              bodyBold: bodyBold,
            ),
          _bilingualMoneyRow(
            context,
            ThermalInvoicePdfLabels.taxableAr,
            ThermalInvoicePdfLabels.taxableEn,
            t.totalTaxableAmount,
            body,
            bodyBold: bodyBold,
          ),
          _bilingualMoneyRow(
            context,
            ThermalInvoicePdfLabels.totalVatAr,
            ThermalInvoicePdfLabels.totalVatEn,
            t.vatAmount,
            body,
            bodyBold: bodyBold,
          ),
          thermalDashedRule(),
          _bilingualMoneyRow(
            context,
            ThermalInvoicePdfLabels.totalDueAr,
            ThermalInvoicePdfLabels.totalDueEn,
            t.totalInvoiceAmount,
            body,
            bodyBold: bodyBold,
            emphasize: true,
          ),
          thermalDashedRule(),
          ..._paymentBreakdownSection(context, bodyBold, body),
          if (invoice.odometerReading != null &&
              invoice.odometerReading! > 0) ...[
            thermalDashedRule(),
            Text(
              'Next Oil Change / Odometer: ${invoice.odometerReading}',
              style: body,
            ),
          ],
          thermalDashedRule(),
          const SizedBox(height: 4),
          // Customer details — centered on receipt width.
          Text(
            'CUSTOMER DETAILS',
            textAlign: TextAlign.center,
            style: bodyBold.copyWith(fontSize: 10.5, height: 1.0),
          ),
          ..._customerDetailRows(body, bodyBold),
          const SizedBox(height: 4),
          ..._maintenanceChecklistReceiptSection(body, bodyBold),
          if (_maintenanceChecksForReceipt() != null) thermalDashedRule(),
          const SizedBox(height: 5),
          Center(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              // Dense Phase-2 TLV needs ~160+ CSS px (same as web invoice).
              size: 168,
              gapless: true,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF000000),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF000000),
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 10),
          _thermalThankYouFooter(bodyBold),
        ],
      ),
    );
  }

  /// Thank you — English and Arabic on one centered line.
  Widget _thermalThankYouFooter(TextStyle bodyBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${ThermalInvoicePdfLabels.thankYouEn} - ',
          style: bodyBold.copyWith(fontSize: 10, height: 0.95),
        ),
        const SizedBox(width: 6),
        Text(
          ThermalInvoicePdfLabels.thankYouAr,
          textDirection: TextDirection.rtl,
          style: thermalReceiptArabicText(
            bodyBold.copyWith(fontSize: 10, height: 0.96),
          ),
        ),
      ],
    );
  }

  List<Widget> _itemRows(BuildContext context, TextStyle body) {
    final out = <Widget>[];
    accumulateInvoiceItems(invoice, (item) {
      final qty = item.qty % 1 == 0
          ? '${item.qty.toInt()}'
          : item.qty.toStringAsFixed(2);
      final unit = item.qty > 0.0001
          ? thermalR2(item.lineTotal / item.qty)
          : thermalR2(item.unitPrice);
      final total = thermalR2(item.lineTotal);
      final catalogArRaw = (item.productNameArabic ?? '').trim();
      final arLines = thermalItemArabicNameLines(catalogArRaw);
      final hasArLines = arLines.isNotEmpty;
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 0.35),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasArLines) _itemArabicNameBlock(arLines, body),
                    if (hasArLines) const SizedBox(height: 1),
                    LocalizedApiText(
                      item.productName,
                      uppercase: !_thermalReceiptIsAr(context),
                      style: body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        height: 0.9,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  qty,
                  style: body.copyWith(fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  unit.toStringAsFixed(2),
                  style: body.copyWith(fontWeight: FontWeight.w400),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _thermalReceiptMoney(context, total),
                  style: body.copyWith(fontWeight: FontWeight.w400),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    });
    return out;
  }

  Widget _itemArabicNameBlock(List<String> lines, TextStyle body) {
    if (lines.isEmpty) return const SizedBox.shrink();

    const arLineHeight = 0.44;
    final style = thermalReceiptItemArabicText(
      body.copyWith(
        fontSize: 9.2,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
        height: arLineHeight,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
    final strut = StrutStyle(
      fontSize: style.fontSize,
      height: arLineHeight,
      leading: 0,
      forceStrutHeight: true,
    );

    return Text(
      lines.join('\n'),
      textDirection: TextDirection.rtl,
      style: style,
      strutStyle: strut,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  List<Widget> _paymentBreakdownSection(
    BuildContext context,
    TextStyle bodyBold,
    TextStyle body,
  ) {
    final t = computeThermalInvoiceTotals(invoice);
    final breakdown = thermalInvoicePaymentBreakdown(
      invoice,
      fallbackTotal: t.totalInvoiceAmount,
    );
    if (breakdown.isEmpty) {
      return [
        _receiptBilingualArAboveEnTight(
          ar: ThermalInvoicePdfLabels.paymentDetailsAr,
          arabicStyle: thermalReceiptArabicText(
            bodyBold.copyWith(fontSize: 9.5, height: 0.96),
          ),
          englishChild: Text(
            '${ThermalInvoicePdfLabels.paymentDetailsEn}: -',
            style: bodyBold.copyWith(fontSize: 9.5, height: 0.95),
          ),
        ),
      ];
    }

    final lineStyle = bodyBold.copyWith(fontSize: 9.5, height: 0.95);
    return [
      _receiptBilingualArAboveEnTight(
        ar: ThermalInvoicePdfLabels.paymentDetailsAr,
        arabicStyle: thermalReceiptArabicText(
          bodyBold.copyWith(fontSize: 9.5, height: 0.96),
        ),
        englishChild: Text(
          '${ThermalInvoicePdfLabels.paymentDetailsEn}:',
          style: lineStyle,
        ),
      ),
      for (final line in breakdown)
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  line.method,
                  style: lineStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _thermalReceiptMoney(context, line.amount),
                style: lineStyle,
              ),
            ],
          ),
        ),
    ];
  }

  Widget _receiptBilingualArAboveEnTight({
    required String ar,
    required Widget englishChild,
    required TextStyle arabicStyle,
    int arabicMaxLines = 2,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ar,
          textAlign: TextAlign.left,
          textDirection: TextDirection.rtl,
          style: thermalReceiptArabicText(
            arabicStyle.copyWith(height: 0.96),
          ),
          maxLines: arabicMaxLines,
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
        Transform.translate(
          offset: const Offset(0, -2.5),
          child: englishChild,
        ),
      ],
    );
  }

  /// Bilingual summary row: Arabic line on top, English label + amount below.
  Widget _bilingualMoneyRow(
    BuildContext context,
    String ar,
    String en,
    double value,
    TextStyle style, {
    bool emphasize = false,
    required TextStyle bodyBold,
  }) {
    final vStr = _thermalReceiptMoney(context, value);
    final arabicStyle = thermalReceiptArabicText(
      bodyBold.copyWith(fontSize: 9.5, height: 0.96),
    );
    final labelStyle = bodyBold.copyWith(
      fontSize: 9.5,
      height: 0.95,
      fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
    );
    final amountStyle = emphasize
        ? style.copyWith(
            fontSize: 9.5,
            height: 0.95,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0D47A1),
          )
        : style.copyWith(
            fontSize: 9.5,
            height: 0.95,
            fontWeight: FontWeight.w800,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ar,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.rtl,
                          style: arabicStyle,
                  maxLines: 3,
                  softWrap: true,
                ),
                Transform.translate(
                  offset: const Offset(0, -2.5),
                  child: Text('$en:', style: labelStyle),
                ),
              ],
            ),
          ),
          Text(vStr, style: amountStyle),
        ],
      ),
    );
  }

  /// Item-table column header: Arabic stacked above English label.
  Widget _bilingualColumnHeader({
    required String ar,
    required String en,
    required TextAlign align,
    required TextStyle bodyBold,
  }) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ar,
          textAlign: align,
          textDirection: TextDirection.rtl,
          style: thermalReceiptArabicText(
            bodyBold.copyWith(fontSize: 9, height: 0.92),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -3.5),
          child: Text(
            en,
            style: bodyBold.copyWith(height: 0.9),
            textAlign: align,
          ),
        ),
      ],
    );
  }

  /// Customer details lines — English-only labels in two columns.
  List<Widget> _customerDetailRows(TextStyle body, TextStyle bodyBold) {
    final rows = <_KeyValue>[];

    void add(String label, String value) {
      final v = value.trim();
      if (v.isEmpty || v == '-') return;
      rows.add(_KeyValue(label, v));
    }

    add('Name', invoice.customerName);
    add('Mobile', invoice.customerMobile ?? '');
    add(
      'Customer type',
      invoice.thermalDisplayedCustomerType,
    );
    if (invoice.vehicleMake.trim().isNotEmpty) {
      add('Make', invoice.vehicleMake);
    }
    if (invoice.vehicleModel.trim().isNotEmpty) {
      add('Model', invoice.vehicleModel);
    }
    if (invoice.vehicleYear.trim().isNotEmpty) {
      add('Year', invoice.vehicleYear);
    }
    if (invoice.plateNo.trim().isNotEmpty) {
      add('Plate', invoice.plateNo);
    }
    if (invoice.vehicleVin.trim().isNotEmpty) {
      add('VIN', invoice.vehicleVin);
    }
    if (invoice.odometerReading != null && invoice.odometerReading! > 0) {
      add('Odometer', '${invoice.odometerReading}');
    }
    if ((invoice.customerTaxId ?? '').trim().isNotEmpty) {
      add('Tax ID', invoice.customerTaxId!);
    }

    final widgets = <Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      final left = rows[i];
      final right = i + 1 < rows.length ? rows[i + 1] : null;
      widgets.add(
        SizedBox(
          height: 11,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _thermalLabelValueLine(
                  left.label,
                  left.value,
                  bodyBold,
                  body,
                  compact: true,
                ),
              ),
              if (right != null)
                Expanded(
                  child: _thermalLabelValueLine(
                    right.label,
                    right.value,
                    bodyBold,
                    body,
                    compact: true,
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  /// English line, then Arabic pulled up slightly under it.
  Widget _maintenanceChecklistLabel(
    String en,
    String ar,
    TextStyle body,
    TextStyle bodyBold,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          en,
          style: bodyBold.copyWith(fontSize: 9.5, height: 1.0),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Transform.translate(
          offset: const Offset(0, -3.25),
          child: Text(
            ar,
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            style: thermalReceiptArabicText(
              body.copyWith(
                fontSize: 8.5,
                height: 1.02,
                color: Colors.grey.shade700,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<bool>? _maintenanceChecksForReceipt() =>
      InvoiceMaintenanceChecklist.checksForReceipt(invoice);

  List<Widget> _maintenanceChecklistReceiptSection(
    TextStyle body,
    TextStyle bodyBold,
  ) {
    final checks = _maintenanceChecksForReceipt();
    if (checks == null) return const [];

    return [
      thermalDashedRule(),
      const SizedBox(height: 4),
      Text(
        ThermalInvoicePdfLabels.maintenanceSectionEn,
        textAlign: TextAlign.center,
        style: bodyBold.copyWith(fontSize: 10.5, height: 1.0),
      ),
      const SizedBox(height: 7),
      ..._maintenanceChecklistGrid(body, bodyBold, checks),
      const SizedBox(height: 4),
    ];
  }

  /// Two-column grid — only checked rows (thermal / PDF).
  List<Widget> _maintenanceChecklistGrid(
    TextStyle body,
    TextStyle bodyBold,
    List<bool> checks,
  ) {
    final indices = InvoiceMaintenanceChecklist.checkedRowIndices(checks);

    final tiles = <Widget>[];
    for (final i in indices) {
      final row = InvoiceMaintenanceChecklist.rows[i];
      tiles.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '☑',
              style: bodyBold.copyWith(fontSize: 11, height: 1.0),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: _maintenanceChecklistLabel(
                row.en,
                row.ar,
                body,
                bodyBold,
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[i]),
              if (i + 1 < tiles.length)
                Expanded(child: tiles[i + 1])
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _KeyValue {
  final String label;
  final String value;
  const _KeyValue(this.label, this.value);
}
