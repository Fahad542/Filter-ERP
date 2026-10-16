import 'dart:convert' show utf8;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart';
import 'package:intl/intl.dart';

import '../models/store_closing_model.dart';
import '../utils/business_timezone.dart';
import '../utils/thermal_invoice_totals.dart' show kThermalInvoiceLogoAsset;
import '../widgets/thermal_invoice_pdf_ar_constants.dart';
import 'invoice_thermal_escpos.dart'
    show loadInvoiceEscPosCapabilityProfile, thermalBilingualLine, thermalSafeText;

String _ascii(String s) => thermalSafeText(s);

String _line(String s) => thermalBilingualLine(s);

String _money(double v) => '${v.toStringAsFixed(2)} SR';

String _signed(double v) {
  final t = v.toStringAsFixed(2);
  return v >= 0 ? '+$t' : t;
}

/// Native ESC/POS store-closing receipt (no PDF raster).
Future<List<int>> buildStoreClosingEscPosBytes({
  required StoreClosingReport report,
  String? closingId,
}) async {
  final profile = await loadInvoiceEscPosCapabilityProfile();
  final g = Generator(PaperSize.mm80, profile, codec: utf8);
  var bytes = <int>[];
  bytes += g.reset();

  try {
    final snap = await rootBundle.load(kThermalInvoiceLogoAsset);
    final decoded = decodeImage(snap.buffer.asUint8List());
    if (decoded != null) {
      var logo = decoded;
      if (decoded.width > 210) {
        logo = copyResize(decoded, width: 210);
      }
      bytes += g.image(logo, align: PosAlign.center);
    }
  } catch (_) {}

  final dateStr = DateFormat('dd/MM/yyyy hh:mm a')
      .format(report.timestamp.toLocal());
  String sessionDt(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy hh:mm a')
        .format(BusinessTimezone.toWall(dt));
  }
  final branchRaw =
      report.branch.trim().isEmpty ? '-' : report.branch.trim();
  final rawWorkshop = report.workshopName.trim();
  final workshopLine = _line(
    rawWorkshop.isNotEmpty &&
            rawWorkshop != 'Loading...' &&
            rawWorkshop != '...'
        ? rawWorkshop
        : (branchRaw != '-' ? branchRaw : 'FILTER'),
  );
  final cashierLine = _ascii(
    report.cashierName.trim().isEmpty ? '-' : report.cashierName.trim(),
  );
  final closingIdLine = _ascii((closingId ?? report.id).trim());

  final systemHdr = report.salesReturnsTotal > 0.001 ? 'Sys(g)' : 'System';
  final diffHdr =
      report.salesReturnsTotal > 0.001 ? 'Diff(n)' : 'Diff';

  bytes += g.text(
    _line(ThermalInvoicePdfLabels.documentSubtitleAr),
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += g.text(
    _line(ThermalInvoicePdfLabels.storeClosingTitleAr),
    styles: const PosStyles(align: PosAlign.center, bold: true),
  );
  bytes += g.text(
    _ascii('STORE CLOSING REPORT'),
    styles: const PosStyles(align: PosAlign.center, bold: true),
    linesAfter: 1,
  );

  bytes += g.text(
    workshopLine,
    styles: const PosStyles(align: PosAlign.center, bold: true),
  );
  bytes += g.text(_ascii('Branch:'), linesAfter: 0);
  if (branchRaw != '-') {
    bytes += g.text(_line(branchRaw), linesAfter: 0);
  }
  bytes += g.text(_line(': ${ThermalInvoicePdfLabels.branchLabelAr}'), linesAfter: 0);
  bytes += g.text(_ascii('Cashier: $cashierLine'), linesAfter: 0);
  bytes += g.text(_line(': ${ThermalInvoicePdfLabels.cashierLabelAr}'), linesAfter: 0);
  bytes += g.text(_ascii('Closing ID: $closingIdLine'), linesAfter: 0);
  bytes += g.text(_line(': ${ThermalInvoicePdfLabels.closingIdAr}'), linesAfter: 0);
  bytes += g.text(_ascii('Date: $dateStr'), linesAfter: 0);
  bytes += g.text(_line(': ${ThermalInvoicePdfLabels.dateLabelAr}'), linesAfter: 0);
  if (report.sessionOpenedAt != null) {
    bytes += g.text(
      _ascii(
        '${ThermalInvoicePdfLabels.sessionStartEn}: ${sessionDt(report.sessionOpenedAt)}',
      ),
      linesAfter: 0,
    );
    bytes += g.text(
      _line(': ${ThermalInvoicePdfLabels.sessionStartAr}'),
      linesAfter: 0,
    );
  }
  if (report.sessionClosedAt != null) {
    bytes += g.text(
      _ascii(
        '${ThermalInvoicePdfLabels.sessionEndEn}: ${sessionDt(report.sessionClosedAt)}',
      ),
      linesAfter: 0,
    );
    bytes += g.text(
      _line(': ${ThermalInvoicePdfLabels.sessionEndAr}'),
      linesAfter: 0,
    );
  }
  bytes += g.text('', linesAfter: 1);
  bytes += g.hr(ch: '.', linesAfter: 1);

  const kHdr = PosStyles(bold: true);

  if (report.departmentBreakdown.isNotEmpty) {
    bytes += g.text(
      _ascii(ThermalInvoicePdfLabels.departmentSalesSectionEn),
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 0,
    );
    bytes += g.text(
      _line(ThermalInvoicePdfLabels.departmentSalesSectionAr),
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    );
    bytes += g.row(
      [
        PosColumn(text: _ascii('Dept'), width: 5, styles: kHdr),
        PosColumn(
          text: _ascii('Ord'),
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          text: _ascii('Rev'),
          width: 5,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ],
      multiLine: false,
    );
    bytes += g.hr(ch: '.', linesAfter: 0);
    var deptTotal = 0.0;
    for (final row in report.departmentBreakdown) {
      deptTotal += row.revenueSar;
      bytes += g.text(_line(row.departmentName), linesAfter: 0);
      bytes += g.row(
        [
          PosColumn(text: '', width: 5),
          PosColumn(
            text: _ascii('${row.ordersCount}'),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: _ascii(_money(row.revenueSar)),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ],
        multiLine: false,
      );
    }
    bytes += g.hr(ch: '.', linesAfter: 0);
    bytes += g.text(
      _ascii('${ThermalInvoicePdfLabels.closingTotalEn}: ${_money(deptTotal)}'),
      styles: const PosStyles(bold: true),
      linesAfter: 1,
    );
    bytes += g.hr(ch: '.', linesAfter: 1);
  }

  bytes += g.text(
    _ascii(ThermalInvoicePdfLabels.storeClosingSectionEn),
    styles: const PosStyles(align: PosAlign.center, bold: true),
    linesAfter: 1,
  );
  bytes += g.row(
    [
      PosColumn(text: _ascii('Cat'), width: 4, styles: kHdr),
      PosColumn(
        text: _ascii(systemHdr),
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: _ascii('Phys'),
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: _ascii(diffHdr),
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ],
    multiLine: false,
  );
  bytes += g.hr(ch: '.', linesAfter: 0);

  void emitBucket(
    String en,
    String ar,
    double systemGross,
    double physical,
    double diff, {
    bool emphasis = false,
  }) {
    final style = PosStyles(bold: emphasis);
    bytes += g.text(_ascii(en), styles: style, linesAfter: 0);
    bytes += g.text(_line(ar), linesAfter: 0);
    bytes += g.row(
      [
        PosColumn(text: '', width: 4),
        PosColumn(
          text: _ascii(_money(systemGross)),
          width: 3,
          styles: PosStyles(bold: emphasis, align: PosAlign.right),
        ),
        PosColumn(
          text: _ascii(_money(physical)),
          width: 2,
          styles: PosStyles(bold: emphasis, align: PosAlign.right),
        ),
        PosColumn(
          text: _ascii(_signed(diff)),
          width: 3,
          styles: PosStyles(bold: emphasis, align: PosAlign.right),
        ),
      ],
      multiLine: false,
    );
  }

  emitBucket(
    ThermalInvoicePdfLabels.closingCashEn,
    ThermalInvoicePdfLabels.closingCashAr,
    report.systemCashGross,
    report.physicalCash,
    report.cashDiff,
  );
  emitBucket(
    ThermalInvoicePdfLabels.closingBankEn,
    ThermalInvoicePdfLabels.closingBankAr,
    report.systemBankGross,
    report.physicalBank,
    report.bankDiff,
  );
  emitBucket(
    ThermalInvoicePdfLabels.closingCorporateEn,
    ThermalInvoicePdfLabels.closingCorporateAr,
    report.systemCorporateGross,
    report.physicalCorporate,
    report.corporateDiff,
  );
  emitBucket(
    ThermalInvoicePdfLabels.closingTamaraEn,
    ThermalInvoicePdfLabels.closingTamaraAr,
    report.systemTamaraGross,
    report.physicalTamara,
    report.tamaraDiff,
  );
  emitBucket(
    ThermalInvoicePdfLabels.closingTabbyEn,
    ThermalInvoicePdfLabels.closingTabbyAr,
    report.systemTabbyGross,
    report.physicalTabby,
    report.tabbyDiff,
  );
  emitBucket(
    ThermalInvoicePdfLabels.closingOthersEn,
    ThermalInvoicePdfLabels.closingOthersAr,
    report.systemOthersGross,
    report.physicalOthers,
    report.othersDiff,
  );

  bytes += g.hr(ch: '.', linesAfter: 0);
  emitBucket(
    ThermalInvoicePdfLabels.closingTotalEn,
    ThermalInvoicePdfLabels.closingTotalAr,
    report.systemBucketsSumGross,
    report.physicalTotal,
    report.diffBucketsSum,
    emphasis: true,
  );

  if (report.salesReturnsTotal > 0.001) {
    bytes += g.hr(ch: '.', linesAfter: 0);
    bytes += g.text(
      _line(ThermalInvoicePdfLabels.closingSalesReturnAr),
      linesAfter: 0,
    );
    bytes += g.text(
      _ascii('${ThermalInvoicePdfLabels.closingSalesReturnEn}: -${_money(report.salesReturnsTotal)}'),
      styles: const PosStyles(bold: true),
      linesAfter: 1,
    );
  }

  bytes += g.hr(ch: '.', linesAfter: 0);
  bytes += g.text(
    _line(ThermalInvoicePdfLabels.closingGrandTotalAr),
    linesAfter: 0,
  );
  bytes += g.text(
    _ascii(
      '${ThermalInvoicePdfLabels.closingGrandTotalEn}: ${_money(report.systemSales)}',
    ),
    styles: const PosStyles(bold: true),
    linesAfter: 1,
  );

  if (report.commissionAmount > 0.001 || report.commissionPercent > 0) {
    bytes += g.hr(ch: '.', linesAfter: 0);
    bytes += g.text(
      _line(ThermalInvoicePdfLabels.closingCommissionAr),
      linesAfter: 0,
    );
    bytes += g.text(
      _ascii(
        '${ThermalInvoicePdfLabels.closingCommissionEn} (${report.commissionPercent.toStringAsFixed(2)}%): ${_money(report.commissionAmount)}',
      ),
      styles: const PosStyles(bold: true),
      linesAfter: 1,
    );
  }

  bytes += g.emptyLines(1);
  bytes += g.cut(mode: PosCutMode.full);
  return bytes;
}
