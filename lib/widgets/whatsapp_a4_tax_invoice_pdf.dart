import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/create_invoice_model.dart';
import '../utils/app_formatters.dart';
import '../utils/plate_transliterator.dart';
import '../utils/bundle_brand_logo.dart';
import '../utils/thermal_invoice_totals.dart';
import '../utils/thermal_receipt_logo_preprocess.dart';
import '../utils/thermal_safe_text.dart';
import 'thermal_invoice_pdf_ar_constants.dart';

/// A4 bilingual **Simplified Tax Invoice** for WhatsApp (document template).
/// Layout inspired by official FILTER tax-invoice style: header + QR, meta grid,
/// customer/vehicle grid, full line table (ex-VAT, discount, VAT, total with VAT).
Future<Uint8List> buildWhatsAppSimplifiedTaxInvoicePdfBytes({
  required Invoice invoice,
  required String paymentMethodText,
  List<bool>? maintenanceChecksFallback,
}) async {
  Uint8List? logoBytes;
  try {
    final data = await loadBrandLogoByteData();
    if (data != null) {
      final raw = data.buffer.asUint8List();
      logoBytes =
          preprocessThermalReceiptLogoPng(raw, targetMaxWidth: 360) ?? raw;
    }
  } catch (_) {
    logoBytes = null;
  }

  pw.Font font;
  pw.Font fontBold;
  pw.Font fontArabic;
  try {
    final notoBytes =
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
    final noto = pw.Font.ttf(notoBytes);
    font = noto;
    fontBold = noto;
    fontArabic = noto;
  } catch (_) {
    try {
      font = await PdfGoogleFonts.poppinsRegular();
      fontBold = await PdfGoogleFonts.poppinsBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }
    try {
      fontArabic = await PdfGoogleFonts.almaraiBold();
    } catch (_) {
      try {
        fontArabic = await PdfGoogleFonts.cairoBold();
      } catch (_) {
        fontArabic = fontBold;
      }
    }
  }

  final doc = buildWhatsAppSimplifiedTaxInvoicePdfDocument(
    invoice: invoice,
    paymentMethodText: paymentMethodText,
    filterLogoPngBytes: logoBytes,
    font: font,
    fontBold: fontBold,
    fontArabic: fontArabic,
    maintenanceChecksFallback: maintenanceChecksFallback,
  );
  return doc.save();
}

String _a4Clean(String s) => pdfStripBidiAndInvisible(s.trim());

bool _hasArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

String? _timeHm24(String? issuedAtIso) {
  final raw = issuedAtIso?.trim() ?? '';
  if (raw.isEmpty) return null;
  final d = DateTime.tryParse(raw);
  if (d == null) return null;
  return DateFormat('HH:mm').format(d.toLocal());
}

String _fmtQty(double q) =>
    q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

const PdfColor _yellowBrand = PdfColor.fromInt(0xFFF5BE0B);
const PdfColor _ink = PdfColor.fromInt(0xFF1F2937);

pw.Widget _cellPad(pw.Widget child, {double inset = 5}) =>
    pw.Padding(padding: pw.EdgeInsets.all(inset), child: child);

pw.Widget _biHeader(
  String ar,
  String en, {
  required pw.Font arabic,
  required pw.Font latin,
  pw.TextAlign align = pw.TextAlign.center,
  double arSize = 6.6,
  double enSize = 6.4,
}) =>
    _cellPad(
      pw.Column(
        crossAxisAlignment: align == pw.TextAlign.center
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            ar,
            style: pw.TextStyle(font: arabic, fontSize: arSize, height: 1.08),
            textDirection: pw.TextDirection.rtl,
            textAlign: align,
          ),
          pw.SizedBox(height: 1.2),
          pw.Text(
            en,
            style:
                pw.TextStyle(font: latin, fontSize: enSize, height: 1.05, color: _ink),
            textAlign: align,
          ),
        ],
      ),
      inset: 4,
    );

pw.Widget _goodsCell(
  ThermalInvoiceLineRow row, {
  required pw.Font latin,
  required pw.Font arabic,
}) {
  final en = thermalSafeText(row.productName);
  final ar = _a4Clean(row.productNameArabic ?? '');
  return _cellPad(
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (ar.isNotEmpty)
          pw.Text(
            ar,
            style: pw.TextStyle(font: arabic, fontSize: 8, height: 1.12),
            textDirection: pw.TextDirection.rtl,
            maxLines: 4,
          ),
        if (ar.isNotEmpty && en.isNotEmpty) pw.SizedBox(height: 2),
        if (en.isNotEmpty)
          pw.Text(
            en,
            style:
                pw.TextStyle(font: latin, fontSize: 8.6, height: 1.08, color: _ink),
            maxLines: 4,
          ),
      ],
    ),
    inset: 4,
  );
}

pw.Widget _moneyCell(String txt, pw.Font f, {pw.TextAlign ta = pw.TextAlign.right}) =>
    _cellPad(
      pw.Align(
        alignment: ta == pw.TextAlign.right
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
        child: pw.Text(
          txt,
          style: pw.TextStyle(font: f, fontSize: 8.2, color: _ink),
          textAlign: ta,
        ),
      ),
      inset: 4,
    );

pw.Document buildWhatsAppSimplifiedTaxInvoicePdfDocument({
  required Invoice invoice,
  required String paymentMethodText,
  Uint8List? filterLogoPngBytes,
  required pw.Font font,
  required pw.Font fontBold,
  required pw.Font fontArabic,
  List<bool>? maintenanceChecksFallback,
}) {
  maintenanceChecksFallback; // parity with thermal PDF API; checklist omitted on A4
  final t = computeThermalInvoiceTotals(invoice);
  final lineRows = computeThermalInvoiceLineRows(invoice);
  final qrData = thermalInvoiceQrPayload(
    invoice,
    t.totalInvoiceAmount,
    paymentMethodText: paymentMethodText,
    vatAmount: t.vatAmount,
  );
  final legalDate = formatInvoiceLegalDate(invoice.invoiceDate);
  final issuedFull = formatInvoiceIssuedAtDateTime(invoice.issuedAt) ??
      formatInvoiceLegalDate(invoice.invoiceDate);
  final timeHm = _timeHm24(invoice.issuedAt) ?? '—';
  final workshopLine = (invoice.workshopName ?? '').trim();
  final seller = invoice.zatcaSellerName.isNotEmpty
      ? invoice.zatcaSellerName
      : (workshopLine.isNotEmpty ? workshopLine : 'FILTER Car Services');
  final vatNo = invoice.zatcaSellerVatNumber.trim().wxFill('—');
  final addr =
      (invoice.branchAddress ?? invoice.workshopAddress ?? '').trim().wxFill('—');
  final branch = (invoice.branchName ?? '').trim().wxFill('—');
  final pdfItemDiscount = thermalR2(t.itemDiscountsTotal);
  final pdfInvoiceDiscount = thermalR2(t.invoiceDiscount);
  final pdfPromoDiscount = thermalR2(t.promoDiscount);
  final pdfReferralDiscount = thermalR2(t.referralDiscount);

  String customerNameShown() {
    final n = invoice.customerName.trim();
    if (n.isEmpty || n.toLowerCase() == 'unknown') return '—';
    return _a4Clean(n);
  }

  String phoneShown() =>
      formatInvoiceMobileForDisplay(invoice.customerMobile);

  String mileageShown() => invoice.odometerReading != null &&
          invoice.odometerReading! > 0
      ? '${invoice.odometerReading}'
      : '—';

  final corporateNameTrimmed = (invoice.corporateCompanyName ?? '').trim();

  pw.Widget labelValueBi(
    String ar,
    String en,
    String value, {
    bool valueMayArabic = false,
  }) {
    final v =
        valueMayArabic && _hasArabic(value)
            ? _a4Clean(value)
            : thermalSafeText(value);
    final valStyleArabic =
        pw.TextStyle(font: fontArabic, fontSize: 8.6, color: _ink, height: 1.06);
    final valStyleLatin =
        pw.TextStyle(font: font, fontSize: 8.6, color: _ink);

    final valueWidget =
        valueMayArabic && _hasArabic(v)
            ? pw.Text(
                v,
                style: valStyleArabic,
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
              )
            : pw.Text(v, style: valStyleLatin, textAlign: pw.TextAlign.right);

    return _cellPad(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  ar,
                  style: pw.TextStyle(
                    font: fontArabic,
                    fontSize: 7.8,
                    height: 1.08,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.left,
                ),
                pw.SizedBox(height: 0.65),
                pw.Text(
                  en,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 7.9,
                    color: _ink,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(flex: 6, child: valueWidget),
        ],
      ),
      inset: 5,
    );
  }

  /// Same plate display as POS list / cashier preview: letters-first Latin + Arabic line.
  pw.Widget plateInvoiceCell() {
    final raw = invoice.plateNo.trim();
    if (raw.isEmpty) {
      return labelValueBi(
        ThermalInvoicePdfLabels.custPlateAr,
        ThermalInvoicePdfLabels.custPlateEn,
        '—',
      );
    }
    final enFmt = formatVehiclePlateLettersFirst(raw);
    final en = thermalSafeText(enFmt);
    final ar = PlateTransliterator.localize(enFmt, 'ar');

    final valStyleLatin =
        pw.TextStyle(font: font, fontSize: 8.6, color: _ink, height: 1.06);
    final valStyleAr = pw.TextStyle(
      font: fontArabic,
      fontSize: 8,
      color: _ink,
      height: 1.06,
    );

    final valueColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(en, style: valStyleLatin, textAlign: pw.TextAlign.right),
        pw.SizedBox(height: 2),
        pw.Text(
          ar,
          style: valStyleAr,
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.right,
        ),
      ],
    );

    return _cellPad(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  ThermalInvoicePdfLabels.custPlateAr,
                  style: pw.TextStyle(
                    font: fontArabic,
                    fontSize: 7.8,
                    height: 1.08,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.left,
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  ThermalInvoicePdfLabels.custPlateEn,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 7.9,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(flex: 6, child: valueColumn),
        ],
      ),
      inset: 5,
    );
  }

  final border = pw.TableBorder.all(width: 0.6, color: PdfColors.grey600);

  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 34, vertical: 30),
      build: (_) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (filterLogoPngBytes != null &&
                          filterLogoPngBytes.isNotEmpty) ...[
                        pw.Image(
                          pw.MemoryImage(filterLogoPngBytes),
                          height: 36,
                          fit: pw.BoxFit.contain,
                        ),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'FILTER',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 26,
                              color: _yellowBrand,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.Text(
                            'فلتر',
                            style: pw.TextStyle(
                              font: fontArabic,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: _yellowBrand,
                              height: 1.0,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'Car Services',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          ThermalInvoicePdfLabels.documentTitleAr,
                          style: pw.TextStyle(
                            font: fontArabic,
                            fontSize: 14,
                            height: 1.05,
                          ),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          ThermalInvoicePdfLabels.documentTitleEn,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            color: _ink,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      _a4Clean(seller),
                      style: pw.TextStyle(
                        font: fontArabic,
                        fontSize: 12,
                        height: 1.1,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Column(
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: 108,
                  height: 108,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Table(
          border: border,
          columnWidths: {
            0: const pw.FlexColumnWidth(1.1),
            1: const pw.FlexColumnWidth(1.3),
          },
          children: [
            pw.TableRow(
              children: [
                labelValueBi(
                  ThermalInvoicePdfLabels.invoiceNoLabelAr,
                  ThermalInvoicePdfLabels.invoiceNoLabelEn,
                  thermalSafeText(invoice.invoiceNo),
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.vatRegLabelAr,
                  ThermalInvoicePdfLabels.vatRegLabelEn,
                  vatNo,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                labelValueBi(
                  ThermalInvoicePdfLabels.branchLabelAr,
                  ThermalInvoicePdfLabels.branchLabelEn,
                  branch,
                  valueMayArabic: true,
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.dateLabelAr,
                  ThermalInvoicePdfLabels.dateLabelEn,
                  legalDate,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                labelValueBi(
                  ThermalInvoicePdfLabels.locationLabelAr,
                  ThermalInvoicePdfLabels.locationLabelEn,
                  addr,
                  valueMayArabic: true,
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.cashierLabelAr,
                  ThermalInvoicePdfLabels.cashierLabelEn,
                  (invoice.cashierName ?? '—').trim().isEmpty
                      ? '—'
                      : _a4Clean(invoice.cashierName!),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: border,
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                labelValueBi(
                  ThermalInvoicePdfLabels.custNameAr,
                  ThermalInvoicePdfLabels.custNameEn,
                  customerNameShown(),
                  valueMayArabic: true,
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.custPhoneAr,
                  ThermalInvoicePdfLabels.custPhoneEn,
                  phoneShown(),
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.custModelAr,
                  ThermalInvoicePdfLabels.custModelEn,
                  invoice.vehicleModel.trim().isEmpty
                      ? '—'
                      : _a4Clean(invoice.vehicleModel),
                  valueMayArabic: true,
                ),
                plateInvoiceCell(),
              ],
            ),
            pw.TableRow(
              children: [
                labelValueBi(
                  ThermalInvoicePdfLabels.custTimeAr,
                  ThermalInvoicePdfLabels.custTimeEn,
                  timeHm,
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.mileageAr,
                  ThermalInvoicePdfLabels.mileageEn,
                  mileageShown(),
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.vinAr,
                  ThermalInvoicePdfLabels.vinEn,
                  invoice.vehicleVin.trim().isEmpty
                      ? '—'
                      : _a4Clean(invoice.vehicleVin),
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.custMakeAr,
                  ThermalInvoicePdfLabels.custMakeEn,
                  invoice.vehicleMake.trim().isEmpty
                      ? '—'
                      : _a4Clean(invoice.vehicleMake),
                  valueMayArabic: true,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                labelValueBi(
                  ThermalInvoicePdfLabels.custYearAr,
                  ThermalInvoicePdfLabels.custYearEn,
                  invoice.vehicleYear.trim().isEmpty
                      ? '—'
                      : _a4Clean(invoice.vehicleYear),
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.nextOilChangeAr,
                  ThermalInvoicePdfLabels.nextOilChangeEn,
                  invoice.nextOilChangeKm != null &&
                          invoice.nextOilChangeKm! > 0
                      ? '${invoice.nextOilChangeKm}'
                      : '—',
                ),
                labelValueBi(
                  ThermalInvoicePdfLabels.customerTaxIdAr,
                  ThermalInvoicePdfLabels.customerTaxIdEn,
                  (invoice.customerTaxId ?? '').trim().isEmpty
                      ? '—'
                      : _a4Clean(invoice.customerTaxId!),
                ),
                labelValueBi(
                  corporateNameTrimmed.isNotEmpty
                      ? ThermalInvoicePdfLabels.corporateCompanyAr
                      : ThermalInvoicePdfLabels.customerTypeAr,
                  corporateNameTrimmed.isNotEmpty
                      ? ThermalInvoicePdfLabels.corporateCompanyEn
                      : ThermalInvoicePdfLabels.customerTypeEn,
                  corporateNameTrimmed.isNotEmpty
                      ? _a4Clean(corporateNameTrimmed)
                      : (invoice.customerType.trim().isEmpty
                          ? '—'
                          : thermalSafeText(invoice.customerType)),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          issuedFull,
          style: pw.TextStyle(font: font, fontSize: 8.2, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: border,
          columnWidths: {
            0: const pw.FlexColumnWidth(3.1),
            1: const pw.FlexColumnWidth(1.15),
            2: const pw.FlexColumnWidth(0.85),
            3: const pw.FlexColumnWidth(0.95),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.0),
            6: const pw.FlexColumnWidth(1.15),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _biHeader(
                  ThermalInvoicePdfLabels.goodsServicesAr,
                  ThermalInvoicePdfLabels.goodsServicesEn,
                  arabic: fontArabic,
                  latin: fontBold,
                  align: pw.TextAlign.left,
                ),
                _biHeader(
                  ThermalInvoicePdfLabels.unitPriceExclFullAr,
                  ThermalInvoicePdfLabels.unitPriceExclFullEn,
                  arabic: fontArabic,
                  latin: fontBold,
                ),
                _biHeader(
                  ThermalInvoicePdfLabels.quantityFullAr,
                  ThermalInvoicePdfLabels.quantityFullEn,
                  arabic: fontArabic,
                  latin: fontBold,
                ),
                _biHeader(
                  ThermalInvoicePdfLabels.discountColAr,
                  ThermalInvoicePdfLabels.discountColEn,
                  arabic: fontArabic,
                  latin: fontBold,
                ),
                _biHeader(
                  ThermalInvoicePdfLabels.totalBeforeTaxColAr,
                  ThermalInvoicePdfLabels.totalBeforeTaxColEn,
                  arabic: fontArabic,
                  latin: fontBold,
                ),
                _biHeader(
                  ThermalInvoicePdfLabels.vatPercentColAr,
                  '${ThermalInvoicePdfLabels.vatPercentColEn} (15%)',
                  arabic: fontArabic,
                  latin: fontBold,
                ),
                _biHeader(
                  ThermalInvoicePdfLabels.totalWithVatColAr,
                  ThermalInvoicePdfLabels.totalWithVatColEn,
                  arabic: fontArabic,
                  latin: fontBold,
                ),
              ],
            ),
            for (final row in lineRows)
              pw.TableRow(
                children: [
                  _goodsCell(row, latin: font, arabic: fontArabic),
                  _moneyCell(
                    row.unitPriceExclVat.toStringAsFixed(2),
                    font,
                  ),
                  _moneyCell(_fmtQty(row.qty), font),
                  _moneyCell(
                    row.discount > 0.001
                        ? row.discount.toStringAsFixed(2)
                        : '0.00',
                    font,
                  ),
                  _moneyCell(
                    row.totalBeforeVat.toStringAsFixed(2),
                    font,
                  ),
                  _moneyCell(row.lineVat.toStringAsFixed(2), font),
                  _moneyCell(
                    row.totalWithVat.toStringAsFixed(2),
                    fontBold,
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.SizedBox()),
            pw.Container(
              width: 220,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  labelValueBi(
                    ThermalInvoicePdfLabels.totalExclVatAr,
                    ThermalInvoicePdfLabels.totalExclVatEn,
                    '${t.grossExVatBeforeDiscount.toStringAsFixed(2)} SAR',
                  ),
                  if (pdfItemDiscount > 0.001)
                    labelValueBi(
                      ThermalInvoicePdfLabels.itemDiscountAr,
                      ThermalInvoicePdfLabels.itemDiscountEn,
                      '${pdfItemDiscount.toStringAsFixed(2)} SAR',
                    ),
                  if (pdfInvoiceDiscount > 0.001)
                    labelValueBi(
                      ThermalInvoicePdfLabels.invoiceDiscountAr,
                      ThermalInvoicePdfLabels.invoiceDiscountEn,
                      '${pdfInvoiceDiscount.toStringAsFixed(2)} SAR',
                    ),
                  if (pdfPromoDiscount > 0.001)
                    labelValueBi(
                      ThermalInvoicePdfLabels.promoDiscountAr,
                      ThermalInvoicePdfLabels.promoDiscountEn,
                      '${pdfPromoDiscount.toStringAsFixed(2)} SAR',
                    ),
                  if (pdfReferralDiscount > 0.001)
                    labelValueBi(
                      ThermalInvoicePdfLabels.referralDiscountAr,
                      ThermalInvoicePdfLabels.referralDiscountEn,
                      '${pdfReferralDiscount.toStringAsFixed(2)} SAR',
                    ),
                  labelValueBi(
                    ThermalInvoicePdfLabels.taxableAr,
                    ThermalInvoicePdfLabels.taxableEn,
                    '${t.totalTaxableAmount.toStringAsFixed(2)} SAR',
                  ),
                  labelValueBi(
                    ThermalInvoicePdfLabels.totalVatAr,
                    '${ThermalInvoicePdfLabels.totalVatEn} (15%)',
                    '${t.vatAmount.toStringAsFixed(2)} SAR',
                  ),
                  labelValueBi(
                    ThermalInvoicePdfLabels.totalDueAr,
                    ThermalInvoicePdfLabels.totalDueEn,
                    '${t.totalInvoiceAmount.toStringAsFixed(2)} SAR',
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              ThermalInvoicePdfLabels.paymentArabicLine(paymentMethodText),
              style: pw.TextStyle(font: fontArabic, fontSize: 9.2, height: 1.1),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.left,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Payment type ( ${thermalSafeText(paymentMethodText).trim().isEmpty ? '-' : thermalSafeText(paymentMethodText)} )',
              style: pw.TextStyle(font: fontBold, fontSize: 9.4, color: _ink),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'www.filter.com.sa',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Customer Service: +966 500 266 513',
                style: pw.TextStyle(font: font, fontSize: 8.4, color: _ink),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Page 1 of 1',
                style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return pdf;
}

extension _WxPdfStringFallback on String {
  String wxFill(String fallback) => trim().isEmpty ? fallback : this;
}
