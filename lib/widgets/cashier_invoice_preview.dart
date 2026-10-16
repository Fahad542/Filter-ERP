import 'package:flutter/material.dart';
import '../utils/app_arabic_font_fallbacks.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/create_invoice_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_formatters.dart';
import '../utils/invoice_maintenance_checklist.dart';
import '../utils/thermal_invoice_totals.dart';
import '../services/locker_translation_mixin.dart';
import 'thermal_invoice_pdf_ar_constants.dart';

String _dash(String? s) {
  final v = (s ?? '').trim();
  return v.isEmpty ? '—' : v;
}

/// Seller VAT registration for the invoice header.
String _invoiceSellerVatRegistrationValue(Invoice i) => i.zatcaSellerVatNumber;

List<String> _branchRibbonSegments(Invoice i) {
  final raw = _invoiceBranchDisplayRaw(i).trim();
  if (raw.isEmpty) return const [];
  final byBullet = raw
      .split('•')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (byBullet.length >= 2) return byBullet;
  return [raw];
}

/// Prefer rich branch line for splitting (Arabic/workshop combos).
String _invoiceBranchDisplayRaw(Invoice i) {
  final b = (i.branchName ?? '').trim();
  final w = (i.workshopName ?? '').trim();
  if (b.isNotEmpty && w.isNotEmpty && b.toLowerCase() != w.toLowerCase()) {
    return '$b • $w';
  }
  if (b.isNotEmpty) return b;
  if (w.isNotEmpty) return w;
  return '';
}

String _fmtQty(double q) =>
    q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

String _sar(double v) => 'SAR ${v.toStringAsFixed(2)}';

/// Always print all 6 checklist rows on the download invoice (ticked or not).
List<bool> _maintenanceChecksForReceipt(Invoice invoice, List<bool>? fallback) =>
    InvoiceMaintenanceChecklist.displayChecks(invoice, fallback);

const _kMaintenanceChecklistColumns = 2;

/// Arabic labels and helper lines on white — same near-black as primary body text.
const Color _kInvoicePreviewArabicOnLight = AppColors.onSurfaceLight;

List<Widget> _maintenanceChecklistBlock(List<bool> checks) {
  final padded = List<bool>.from(checks);
  while (padded.length < InvoiceMaintenanceChecklist.rows.length) {
    padded.add(false);
  }

  final itemLabelEnStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10.9,
    fontWeight: FontWeight.w700,
    color: Colors.grey.shade900,
    height: 1.22,
  );
  final itemLabelArStyle = appArabicTextStyle(
    fontSize: 10.9,
    fontWeight: FontWeight.w700,
    color: Colors.grey.shade900,
    height: 1.22,
  );
  Widget checkItem(int idx) {
    final row = InvoiceMaintenanceChecklist.rows[idx];
    final ticked = padded[idx];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        row.en,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: itemLabelEnStyle,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        row.ar,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: itemLabelArStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              ticked ? '☑' : '☐',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final tableRows = <TableRow>[];
  for (var i = 0; i < InvoiceMaintenanceChecklist.rows.length; i += 2) {
    tableRows.add(
      TableRow(
        children: [
          TableCell(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCCCCCC), width: 0.75),
              ),
              child: checkItem(i),
            ),
          ),
          TableCell(
            child: i + 1 < InvoiceMaintenanceChecklist.rows.length
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFCCCCCC),
                        width: 0.75,
                      ),
                    ),
                    child: checkItem(i + 1),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  final checklistGrid = Table(
    columnWidths: {
      for (var c = 0; c < _kMaintenanceChecklistColumns; c++)
        c: const FlexColumnWidth(1),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.top,
    children: tableRows,
  );

  return [
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Color(0xFFE2E8F0),
        border: Border.all(color: Color(0xFFCCCCCC), width: 0.75),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Check list',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.grey.shade900,
            ),
          ),
          Text(
            'قائمة الفحص',
            textDirection: TextDirection.rtl,
            style: appArabicTextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: Colors.grey.shade800,
              height: 1.15,
            ),
          ),
        ],
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 8),
      child: checklistGrid,
    ),
  ];
}

/// Flex values ×100 ≈ [365, 192, 100, 202, 142, 202, 142, 213] for reference.
final _kGoodsInvoiceTableColumns = <int, TableColumnWidth>{
  0: const FlexColumnWidth(3.70), // Goods/Services
  1: const FlexColumnWidth(1.95), // Unit excl VAT
  2: const FlexColumnWidth(1.12), // Qty
  3: const FlexColumnWidth(1.48), // Gross before VAT — narrower so amounts don't wrap
  4: const FlexColumnWidth(1.42), // Discount
  5: const FlexColumnWidth(2.02), // Total before VAT
  6: const FlexColumnWidth(1.42), // VAT
  7: const FlexColumnWidth(2.13), // Total with VAT
};

/// Each entry: `English\\nArabic` — yellow banner shows English first, Arabic below.
const _kGoodsHeaderTexts = <String>[
  'Goods/Services\nالسلعة / الخدمة',
  'Unit Price (Excl. VAT)\nسعر الوحدة (بدون ضريبة)',
  'Qty\nالكمية',
  'Gross Amt Before VAT\nالإجمالي قبل الضريبة',
  'Discount\nالخصم',
  'Total Before VAT\nالمجموع قبل الضريبة',
  'VAT\nالضريبة',
  'Total With VAT\nالإجمالي مع الضريبة',
];

String _localizedInvoiceDateBanner(BuildContext context, String legalDateStr) =>
    AppTranslationService.localizeDigitsForLanguage(
      legalDateStr,
      Localizations.maybeLocaleOf(context)?.languageCode ?? 'en',
    );

/// ScrollView + [Align] children often get unbounded max width; never pass that to [Table].
double _invoicePreviewTrackWidth(
  BuildContext context,
  BoxConstraints constraints,
) {
  var w = constraints.maxWidth;
  if (w.isFinite && w > 16) return w;
  final mqPad = MediaQuery.sizeOf(context).width - 72;
  return mqPad.clamp(260.0, 920.0);
}

/// Customer / vehicle grid cell fill — solid white per product reference.
const Color _kCustomerMetaGridBg = Color(0xFFFFFFFF);

/// Labels + values in the customer/vehicle grid — solid black (reference invoice).
const Color _kCustomerVehicleGridText = Color(0xFF000000);

const Color _kCustomerMetaBorderColor = Color(0xFF1A1A1A);

/// Fixed row height so the block matches reference density (4 rows, compact).
const double _kCustomerVehicleCellHeight = 40.0;

/// Line items table vertical padding (single-line cells).
const double _kGoodsBodyCellVPad = 8.0;

const double _kCustomerMetaBorderWidth = 1.0;

/// Goods table banner uses app primary yellow (solid).
const Color _goodsTableHeaderFill = AppColors.primaryLight;

/// Line-item body cells — white (no grey band on product rows).
const Color _kGoodsBodyCellBg = Color(0xFFFFFFFF);

const String _invoicePreviewNextChangeEn = 'Next Change';
const String _invoicePreviewNextChangeAr = 'غيار الزيت القادم';

/// Label: Arabic on top, English below (saves horizontal cell width).
Widget _invoiceMetaLabelPairCell(String en, String ar) {
  final arStyle = appArabicTextStyle(
    fontSize: 9.75,
    fontWeight: FontWeight.w700,
    color: _kCustomerVehicleGridText,
    height: 1.05,
  );
  final enStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 9.25,
    fontWeight: FontWeight.w600,
    color: _kCustomerVehicleGridText,
    height: 1.05,
  );
  return SizedBox(
    height: _kCustomerVehicleCellHeight,
    width: double.infinity,
    child: Container(
      color: _kCustomerMetaGridBg,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ar.trim(),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: arStyle,
          ),
          const SizedBox(height: 1),
          Text(
            en.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: enStyle,
          ),
        ],
      ),
    ),
  );
}

/// Value cell: single line, left-aligned, black (matches reference grid).
Widget _invoiceMetaValueOnlyCell(String primary) {
  final main = TextStyle(
    fontSize: 11.25,
    fontWeight: FontWeight.w700,
    color: _kCustomerVehicleGridText,
    height: 1.15,
  );
  final pv = primary.trim();
  return SizedBox(
    height: _kCustomerVehicleCellHeight,
    width: double.infinity,
    child: Container(
      color: _kCustomerMetaGridBg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      alignment: Alignment.centerLeft,
      child: Text(
        pv.isEmpty ? '—' : pv,
        textAlign: TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: main,
      ),
    ),
  );
}

Widget _invoiceMetaDynamicValueCell(String primary) {
  final raw = primary.trim();
  return _invoiceMetaValueOnlyCell(raw.isEmpty ? '—' : raw);
}

TableRow _invoiceTotalsLabelAmountRow(
  String labelEn,
  String labelAr,
  String sarAmount, {
  bool emphasized = false,
}) {
  final labelEnStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: emphasized ? 14.8 : 12.8,
    fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
    color: emphasized ? AppColors.secondaryLight : Colors.grey.shade900,
    height: 1.12,
  );
  final labelArStyle = appArabicTextStyle(
    fontSize: (emphasized ? 14.8 : 12.8) * 0.84,
    fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
    color: emphasized
        ? AppColors.secondaryLight
        : _kInvoicePreviewArabicOnLight,
    height: 1.08,
  );
  final sarStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: emphasized ? 15 : 13,
    fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
    color: emphasized ? AppColors.secondaryLight : Colors.grey.shade900,
  );
  const vPad = 9.0;

  return TableRow(
    children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, vPad, 6, vPad),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$labelEn:',
              style: labelEnStyle,
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, vPad, 6, vPad),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              labelAr,
              style: labelArStyle,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, vPad, 10, vPad),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(sarAmount, style: sarStyle),
          ),
        ),
      ),
    ],
  );
}

/// Simplified UAE-style tax invoice preview for the cashier **dialog** (screen),
/// aligned with product reference: branded header + QR + detailed goods breakdown.
/// ESC/POS / printer output remains separate (`Print`).
class CashierInvoicePreview extends StatelessWidget {
  final Invoice invoice;
  final String paymentMethodText;

  /// When create-invoice API omits checklist, use ticks from [PosOrder.maintenanceChecks].
  final List<bool>? maintenanceChecksFallback;

  /// Phone dialog: stacked fields + line-item cards (not the print/A4 table).
  final bool compactMobile;

  const CashierInvoicePreview({
    super.key,
    required this.invoice,
    required this.paymentMethodText,
    this.maintenanceChecksFallback,
    this.compactMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = computeThermalInvoiceTotals(invoice);
    final lineRows = computeThermalInvoiceLineRows(invoice);
    final qrData = thermalInvoiceQrPayload(
      invoice,
      t.totalInvoiceAmount,
      paymentMethodText: paymentMethodText,
      vatAmount: t.vatAmount,
    );
    final receiptChecks = _maintenanceChecksForReceipt(
      invoice,
      maintenanceChecksFallback,
    );

    final branchRibbonSegments = _branchRibbonSegments(invoice);

    final dateStr = formatInvoiceLegalDate(invoice.invoiceDate);
    final timeStr = formatInvoiceIssuedAtClock(invoice.issuedAt);
    final white70 = Colors.white.withValues(alpha: 0.70);

    final localizedTimeStr = timeStr == null
        ? '—'
        : AppTranslationService.localizeDigitsForLanguage(
            timeStr,
            Localizations.maybeLocaleOf(context)?.languageCode ?? 'en',
          );

    final localizedDateStr = _localizedInvoiceDateBanner(context, dateStr);

    return Directionality(
      // Keep the digital invoice layout identical to the English preview even
      // when the app locale is Arabic. The invoice itself is already bilingual.
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle.merge(
        // English invoice copy uses Poppins; Arabic styles set their own family.
        style: const TextStyle(fontFamily: 'Poppins'),
        child: Material(
          color: Colors.transparent,
          child: compactMobile
              ? _buildCompactMobile(
                  context,
                  t: t,
                  lineRows: lineRows,
                  qrData: qrData,
                  receiptChecks: receiptChecks,
                  branchRibbonSegments: branchRibbonSegments,
                  localizedDateStr: localizedDateStr,
                  localizedTimeStr: localizedTimeStr,
                  white70: white70,
                )
              : _buildWideLayout(
                  context,
                  t: t,
                  lineRows: lineRows,
                  qrData: qrData,
                  receiptChecks: receiptChecks,
                  branchRibbonSegments: branchRibbonSegments,
                  dateStr: dateStr,
                  localizedTimeStr: localizedTimeStr,
                  white70: white70,
                ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context, {
    required ThermalInvoiceTotals t,
    required List<ThermalInvoiceLineRow> lineRows,
    required String qrData,
    required List<bool> receiptChecks,
    required List<String> branchRibbonSegments,
    required String dateStr,
    required String localizedTimeStr,
    required Color white70,
  }) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 22, 10, 14),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'FILTER',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 34,
                                    height: 1,
                                    letterSpacing: 0.5,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 6,
                                  ),
                                  child: Text(
                                    'فلتر',
                                    textDirection: TextDirection.rtl,
                                    style: appArabicTextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 30,
                                      height: 1.02,
                                      letterSpacing: 0.15,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Car Services',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 21.5,
                                      height: 1.08,
                                      letterSpacing: 0.35,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Simplified Tax Invoice',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    height: 1.05,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'فاتورة ضريبية مبسطة',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: appArabicTextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    height: 1.05,
                                    color: white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    'رقم الفاتورة : ${invoice.invoiceNo}',
                                    textAlign: TextAlign.right,
                                    style: appArabicTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: white70,
                                      height: 1.18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    '${ThermalInvoicePdfLabels.vatRegLabelAr} : ${_dash(_invoiceSellerVatRegistrationValue(invoice))}',
                                    textAlign: TextAlign.right,
                                    style: appArabicTextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: white70,
                                      height: 1.18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        // Same ZATCA TLV + size as web CashierTaxInvoiceView.
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
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              color: AppColors.primaryLight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (branchRibbonSegments.isEmpty)
                          Text(
                            '—',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.black.withValues(alpha: 0.82),
                            ),
                          )
                        else ...[
                          for (
                            var i = 0;
                            i < branchRibbonSegments.length;
                            i++
                          ) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  i == 0
                                      ? Icons.person_rounded
                                      : Icons.location_on_rounded,
                                  size: 18,
                                  color: Colors.black.withValues(alpha: 0.88),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    branchRibbonSegments[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      height: 1.2,
                                      color: Colors.black.withValues(
                                        alpha: 0.88,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (i != branchRibbonSegments.length - 1)
                              const SizedBox(height: 9),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Date: ${_localizedInvoiceDateBanner(context, dateStr)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.25,
                            height: 1.1,
                            color: Colors.black.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final rw = _invoicePreviewTrackWidth(context, constraints);
                return SizedBox(
                  width: rw,
                  child: _buildCustomerVehicleDetailsTable(localizedTimeStr),
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = _invoicePreviewTrackWidth(context, constraints);
                return _goodsSection(lineRows, w);
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tw = _invoicePreviewTrackWidth(context, constraints);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: tw, child: _totalsBanner()),
                    SizedBox(
                      width: tw,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _totalsTable(t),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (receiptChecks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._maintenanceChecklistBlock(receiptChecks),
              const SizedBox(height: 14),
            ],
            Center(
              child: Text(
                'Thank you.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
    );
  }

  Widget _buildCompactMobile(
    BuildContext context, {
    required ThermalInvoiceTotals t,
    required List<ThermalInvoiceLineRow> lineRows,
    required String qrData,
    required List<bool> receiptChecks,
    required List<String> branchRibbonSegments,
    required String localizedDateStr,
    required String localizedTimeStr,
    required Color white70,
  }) {
    final vatReg = _dash(_invoiceSellerVatRegistrationValue(invoice));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.18),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FILTER',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            height: 1,
                            letterSpacing: 0.5,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'فلتر',
                          textDirection: TextDirection.rtl,
                          style: appArabicTextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            height: 1.05,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Car Services',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 108,
                    height: 108,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 100,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Simplified Tax Invoice + Invoice No
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Simplified Tax Invoice',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'فاتورة ضريبية مبسطة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1.15,
                            color: white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invoice No / رقم الفاتورة',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: white70,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.invoiceNo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: white70,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: VAT — pinned to right corner
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'VAT',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: white70,
                          height: 1.25,
                        ),
                      ),
                      Text(
                        ThermalInvoicePdfLabels.vatRegLabelAr,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: white70,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vatReg,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          color: AppColors.primaryLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (branchRibbonSegments.isEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '—',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Colors.black.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Date: $localizedDateStr',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.2,
                        color: Colors.black.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                )
              else
                for (var i = 0; i < branchRibbonSegments.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        i == 0
                            ? Icons.person_rounded
                            : Icons.location_on_rounded,
                        size: 18,
                        color: Colors.black.withValues(alpha: 0.88),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          branchRibbonSegments[i],
                          softWrap: true,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            height: 1.3,
                            color: Colors.black.withValues(alpha: 0.88),
                          ),
                        ),
                      ),
                      if (i == 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Date: $localizedDateStr',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.2,
                            color: Colors.black.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (i != branchRibbonSegments.length - 1)
                    const SizedBox(height: 8),
                ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _mobileCustomerFields(localizedTimeStr),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = _invoicePreviewTrackWidth(context, constraints);
            const minTableW = 640.0;
            final tableW = w < minTableW ? minTableW : w;
            final table = _goodsSection(lineRows, tableW);
            if (tableW > w + 0.5) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: tableW, child: table),
              );
            }
            return table;
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tw = _invoicePreviewTrackWidth(context, constraints);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: tw, child: _totalsBanner()),
                SizedBox(
                  width: tw,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalsTable(t),
                  ),
                ),
              ],
            );
          },
        ),
        if (receiptChecks.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._maintenanceChecklistBlock(receiptChecks),
          const SizedBox(height: 14),
        ],
        Center(
          child: Text(
            'Thank you.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileCustomerFields(String localizedTimeStr) {
    final rawPlate = invoice.plateNo.trim();
    final plateLettersFirst = rawPlate.isEmpty
        ? null
        : formatVehiclePlateLettersFirst(rawPlate);
    final nextKm = invoice.nextOilChangeKm;
    final nextKmStr = nextKm != null && nextKm > 0 ? '$nextKm' : '—';
    final odo = invoice.odometerReading;
    final mileageStr = (odo != null && odo > 0) ? '$odo' : '—';
    final phoneDisplay = formatInvoiceMobileForDisplay(invoice.customerMobile);

    final fields = <(String, String, String)>[
      (
        ThermalInvoicePdfLabels.custNameEn,
        ThermalInvoicePdfLabels.custNameAr,
        _dash(invoice.customerName),
      ),
      (
        ThermalInvoicePdfLabels.custPhoneEn,
        ThermalInvoicePdfLabels.custPhoneAr,
        phoneDisplay,
      ),
      (
        ThermalInvoicePdfLabels.custTimeEn,
        ThermalInvoicePdfLabels.custTimeAr,
        localizedTimeStr,
      ),
      (
        ThermalInvoicePdfLabels.custModelEn,
        ThermalInvoicePdfLabels.custModelAr,
        _dash(invoice.vehicleModel),
      ),
      (
        ThermalInvoicePdfLabels.mileageEn,
        ThermalInvoicePdfLabels.mileageAr,
        mileageStr,
      ),
      (
        ThermalInvoicePdfLabels.custMakeEn,
        ThermalInvoicePdfLabels.custMakeAr,
        _dash(invoice.vehicleMake),
      ),
      (
        ThermalInvoicePdfLabels.custPlateEn,
        ThermalInvoicePdfLabels.custPlateAr,
        plateLettersFirst ?? '—',
      ),
      (
        ThermalInvoicePdfLabels.vinEn,
        ThermalInvoicePdfLabels.vinAr,
        _dash(invoice.vehicleVin),
      ),
      (
        _invoicePreviewNextChangeEn,
        _invoicePreviewNextChangeAr,
        nextKmStr,
      ),
      (
        ThermalInvoicePdfLabels.custYearEn,
        ThermalInvoicePdfLabels.custYearAr,
        _dash(invoice.vehicleYear),
      ),
      (
        ThermalInvoicePdfLabels.customerTypeEn,
        ThermalInvoicePdfLabels.customerTypeAr,
        _dash(invoice.customerType),
      ),
      (
        ThermalInvoicePdfLabels.customerTaxIdEn,
        ThermalInvoicePdfLabels.customerTaxIdAr,
        _dash(invoice.customerTaxId),
      ),
    ];

    final rows = <TableRow>[];
    for (var i = 0; i < fields.length; i += 3) {
      final a = fields[i];
      final b = i + 1 < fields.length ? fields[i + 1] : null;
      final c = i + 2 < fields.length ? fields[i + 2] : null;
      rows.add(
        TableRow(
          children: [
            _mobileMetaTile(a.$1, a.$2, a.$3),
            if (b != null)
              _mobileMetaTile(b.$1, b.$2, b.$3)
            else
              const SizedBox.shrink(),
            if (c != null)
              _mobileMetaTile(c.$1, c.$2, c.$3)
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Table(
      border: TableBorder.all(
        color: _kCustomerMetaBorderColor,
        width: _kCustomerMetaBorderWidth,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: rows,
    );
  }

  Widget _mobileMetaTile(String en, String ar, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: _kCustomerVehicleGridText,
            ),
          ),
          Text(
            en,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: _kCustomerVehicleGridText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            softWrap: true,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: _kCustomerVehicleGridText,
            ),
          ),
        ],
      ),
    );
  }

  /// Bilingual 6-column × 4-row customer / vehicle block (ribbon → items table).
  Table _buildCustomerVehicleDetailsTable(String localizedTimeStr) {
    TableCell tc(Widget w) => TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: w,
    );

    final rawPlate = invoice.plateNo.trim();
    final plateLettersFirst = rawPlate.isEmpty
        ? null
        : formatVehiclePlateLettersFirst(rawPlate);

    final nextKm = invoice.nextOilChangeKm;
    final nextKmStr = nextKm != null && nextKm > 0 ? '$nextKm' : '—';

    final odo = invoice.odometerReading;
    final mileageStr = (odo != null && odo > 0) ? '$odo' : '—';

    final phoneDisplay = formatInvoiceMobileForDisplay(invoice.customerMobile);

    return Table(
      border: TableBorder.all(
        color: _kCustomerMetaBorderColor,
        width: _kCustomerMetaBorderWidth,
      ),
      columnWidths: const {
        // Labels wider so bilingual text isn't clipped; value cols 2/4/6 tighter.
        0: FlexColumnWidth(0.88),
        1: FlexColumnWidth(1.05),
        2: FlexColumnWidth(0.88),
        3: FlexColumnWidth(1.05),
        4: FlexColumnWidth(0.88),
        5: FlexColumnWidth(1.00),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custNameEn,
                ThermalInvoicePdfLabels.custNameAr,
              ),
            ),
            tc(_invoiceMetaDynamicValueCell(_dash(invoice.customerName))),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custPhoneEn,
                ThermalInvoicePdfLabels.custPhoneAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(phoneDisplay)),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custTimeEn,
                ThermalInvoicePdfLabels.custTimeAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(localizedTimeStr)),
          ],
        ),
        TableRow(
          children: [
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custModelEn,
                ThermalInvoicePdfLabels.custModelAr,
              ),
            ),
            tc(_invoiceMetaDynamicValueCell(_dash(invoice.vehicleModel))),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.mileageEn,
                ThermalInvoicePdfLabels.mileageAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(mileageStr)),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custMakeEn,
                ThermalInvoicePdfLabels.custMakeAr,
              ),
            ),
            tc(_invoiceMetaDynamicValueCell(_dash(invoice.vehicleMake))),
          ],
        ),
        TableRow(
          children: [
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custPlateEn,
                ThermalInvoicePdfLabels.custPlateAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(plateLettersFirst ?? '—')),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.vinEn,
                ThermalInvoicePdfLabels.vinAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(_dash(invoice.vehicleVin))),
            tc(
              _invoiceMetaLabelPairCell(
                _invoicePreviewNextChangeEn,
                _invoicePreviewNextChangeAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(nextKmStr)),
          ],
        ),
        TableRow(
          children: [
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.custYearEn,
                ThermalInvoicePdfLabels.custYearAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(_dash(invoice.vehicleYear))),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.customerTypeEn,
                ThermalInvoicePdfLabels.customerTypeAr,
              ),
            ),
            tc(_invoiceMetaDynamicValueCell(_dash(invoice.customerType))),
            tc(
              _invoiceMetaLabelPairCell(
                ThermalInvoicePdfLabels.customerTaxIdEn,
                ThermalInvoicePdfLabels.customerTaxIdAr,
              ),
            ),
            tc(_invoiceMetaValueOnlyCell(_dash(invoice.customerTaxId))),
          ],
        ),
      ],
    );
  }

  Widget _goodsSection(List<ThermalInvoiceLineRow> rows, double availWidth) {
    final safeW = (!availWidth.isFinite || availWidth <= 8)
        ? 360.0
        : availWidth;
    const borderColor = _kCustomerMetaBorderColor;

    const hdrRowH = 52.0;
    final fz = safeW >= 620 ? 9.35 : 8.85;
    final hdrGap = safeW >= 620 ? 2.5 : 2.0;
    final headerLabelStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: fz,
      height: 1.1,
      color: Colors.black.withValues(alpha: 0.87),
    );

    TableCell goodsHeaderCell(int idx) {
      final parts = _kGoodsHeaderTexts[idx].split('\n');
      final en = parts.first;
      final ar = parts.length > 1 ? parts[1] : '';
      final alignStart = idx == 0;
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: SizedBox(
          height: hdrRowH,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.fromLTRB(idx == 0 ? 8.0 : 4.0, 0, 3, 0),
            child: Align(
              alignment: alignStart ? Alignment.centerLeft : Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: alignStart
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    en,
                    maxLines: 1,
                    textAlign: alignStart ? TextAlign.left : TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: headerLabelStyle,
                  ),
                  SizedBox(height: hdrGap),
                  Text(
                    ar,
                    maxLines: 1,
                    textDirection: TextDirection.rtl,
                    textAlign: alignStart ? TextAlign.left : TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: headerLabelStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    TableCell bodyCellValue(
      String text, {
      TextAlign ta = TextAlign.start,
      double leadingPadding = 4,
    }) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.fill,
        child: ColoredBox(
          color: _kGoodsBodyCellBg,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              leadingPadding,
              _kGoodsBodyCellVPad,
              3,
              _kGoodsBodyCellVPad,
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                text,
                textAlign: ta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    TableCell bodyCellProductName(
      String textEn,
      String? textAr, {
      double leadingPadding = 8,
    }) {
      final cleanEn = textEn.trim();
      final cleanAr = (textAr ?? '').trim();
      final lineStyle = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade900,
        height: 1.1,
      );
      final arStyle = lineStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 10.5,
      );
      // Intrinsic height (not `fill`). If every cell in a TableRow uses
      // [TableCellVerticalAlignment.fill], Flutter sizes the row to 0.
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: ColoredBox(
          color: _kGoodsBodyCellBg,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              leadingPadding,
              _kGoodsBodyCellVPad,
              2,
              _kGoodsBodyCellVPad,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cleanAr.isEmpty && cleanEn.isEmpty)
                  Text('—', maxLines: 1, style: lineStyle)
                else ...[
                  if (cleanAr.isNotEmpty)
                    Text(
                      cleanAr,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: arStyle,
                    ),
                  if (cleanAr.isNotEmpty && cleanEn.isNotEmpty)
                    const SizedBox(height: 2),
                  if (cleanEn.isNotEmpty)
                    Text(
                      cleanEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: lineStyle,
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final table = Table(
      border: TableBorder(
        left: BorderSide(color: borderColor, width: 0.75),
        top: BorderSide(color: borderColor, width: 0.75),
        right: BorderSide(color: borderColor, width: 0.75),
        bottom: BorderSide(color: borderColor, width: 0.75),
        horizontalInside: BorderSide(color: borderColor, width: 0.75),
        verticalInside: BorderSide(color: borderColor, width: 0.75),
      ),
      columnWidths: _kGoodsInvoiceTableColumns,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: _goodsTableHeaderFill),
          children: [for (var i = 0; i < 8; i++) goodsHeaderCell(i)],
        ),
        for (final row in rows)
          TableRow(
            children: [
              bodyCellProductName(row.productName, row.productNameArabic),
              bodyCellValue(_sar(row.unitPriceExclVat)),
              bodyCellValue(_fmtQty(row.qty)),
              bodyCellValue(_sar(row.grossBeforeVat)),
              bodyCellValue(_sar(row.discount)),
              bodyCellValue(_sar(row.totalBeforeVat)),
              bodyCellValue(_sar(row.lineVat)),
              bodyCellValue(_sar(row.totalWithVat)),
            ],
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: safeW, child: table),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No line items.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  Widget _totalsTable(ThermalInvoiceTotals t) {
    return Table(
      border: TableBorder.all(
        color: _kCustomerMetaBorderColor,
        width: 0.75,
      ),
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(2.2),
        2: FlexColumnWidth(1.25),
      },
      children: [
        _invoiceTotalsLabelAmountRow(
          ThermalInvoicePdfLabels.totalExclVatEn,
          ThermalInvoicePdfLabels.totalExclVatAr,
          _sar(t.grossAmountExclVat),
        ),
        if (thermalR2(t.itemDiscountsTotal) > 0.001)
          _invoiceTotalsLabelAmountRow(
            ThermalInvoicePdfLabels.itemDiscountEn,
            ThermalInvoicePdfLabels.itemDiscountAr,
            _sar(thermalR2(t.itemDiscountsTotal)),
          ),
        if (thermalR2(t.invoiceDiscount) > 0.001)
          _invoiceTotalsLabelAmountRow(
            ThermalInvoicePdfLabels.invoiceDiscountEn,
            ThermalInvoicePdfLabels.invoiceDiscountAr,
            _sar(thermalR2(t.invoiceDiscount)),
          ),
        if (thermalR2(t.promoDiscount) > 0.001)
          _invoiceTotalsLabelAmountRow(
            ThermalInvoicePdfLabels.promoDiscountEn,
            ThermalInvoicePdfLabels.promoDiscountAr,
            _sar(thermalR2(t.promoDiscount)),
          ),
        if (thermalR2(t.referralDiscount) > 0.001)
          _invoiceTotalsLabelAmountRow(
            ThermalInvoicePdfLabels.referralDiscountEn,
            ThermalInvoicePdfLabels.referralDiscountAr,
            _sar(thermalR2(t.referralDiscount)),
          ),
        _invoiceTotalsLabelAmountRow(
          ThermalInvoicePdfLabels.taxableEn,
          ThermalInvoicePdfLabels.taxableAr,
          _sar(t.totalTaxableAmount),
        ),
        _invoiceTotalsLabelAmountRow(
          ThermalInvoicePdfLabels.totalVatEn,
          ThermalInvoicePdfLabels.totalVatAr,
          _sar(t.vatAmount),
        ),
        _invoiceTotalsLabelAmountRow(
          ThermalInvoicePdfLabels.totalDueEn,
          ThermalInvoicePdfLabels.totalDueAr,
          _sar(t.totalInvoiceAmount),
          emphasized: true,
        ),
      ],
    );
  }

  Widget _totalsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      color: AppColors.primaryLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.secondaryLight,
              height: 1.1,
            ),
          ),
          Text(
            'إجمالي المبالغ',
            textDirection: TextDirection.rtl,
            style: appArabicTextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.1,
              color: AppColors.secondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
