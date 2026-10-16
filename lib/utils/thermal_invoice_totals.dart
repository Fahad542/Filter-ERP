import 'dart:convert' show utf8;

import '../data/network/api_constants.dart';
import '../models/create_invoice_model.dart';
import 'app_formatters.dart';
import 'zatca_qr.dart';

double thermalR2(double v) => (v * 100).roundToDouble() / 100;

final _thermalArabicChar = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]',
);

bool thermalTextHasArabic(String s) => _thermalArabicChar.hasMatch(s);

List<String> _thermalCleanParts(Iterable<String> parts) => parts
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

List<String> _thermalOnlyArabicParts(Iterable<String> parts) =>
    _thermalCleanParts(parts).where(thermalTextHasArabic).toList();

/// Arabic-only catalog lines (newlines / SKU splits). English lines excluded.
List<String> thermalItemArabicNameLines(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return [];

  final fromBreaks = _thermalOnlyArabicParts(t.split(RegExp(r'[\r\n]+')));
  if (fromBreaks.length > 1) return fromBreaks;

  final single = fromBreaks.isEmpty ? t : fromBreaks.first;
  if (!thermalTextHasArabic(single)) return [];

  final arThenCode = _thermalOnlyArabicParts(
    single.split(
      RegExp(
        r'(?<=[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF])(?=[#0-9A-Za-z])',
      ),
    ),
  );
  if (arThenCode.length > 1) return arThenCode;

  final codeThenAr = _thermalOnlyArabicParts(
    single.split(
      RegExp(
        r'(?<=[0-9A-Za-z])(?=[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF])',
      ),
    ),
  );
  if (codeThenAr.length > 1) return codeThenAr;

  return [single];
}

/// One settled payment line on the invoice (method label + amount).
class ThermalInvoicePaymentLine {
  final String method;
  final double amount;

  const ThermalInvoicePaymentLine(this.method, this.amount);
}

/// Per-method amounts from [Invoice.payments], or single [Invoice.paymentMethod].
List<ThermalInvoicePaymentLine> thermalInvoicePaymentBreakdown(
  Invoice invoice, {
  double? fallbackTotal,
}) {
  final lines = <ThermalInvoicePaymentLine>[];
  for (final p in invoice.payments) {
    final method = p.method.trim();
    if (method.isNotEmpty && p.amount > 0.0001) {
      lines.add(ThermalInvoicePaymentLine(method, thermalR2(p.amount)));
    }
  }
  if (lines.isNotEmpty) return lines;

  final single = (invoice.paymentMethod ?? '').trim();
  if (single.isEmpty) return lines;

  final total = fallbackTotal ?? invoice.totalAmount;
  if (total > 0.0001) {
    lines.add(ThermalInvoicePaymentLine(single, thermalR2(total)));
  }
  return lines;
}

/// e.g. `Card: 20.00 SR, Cash: 16.00 SR` for legacy single-line fields.
String thermalInvoicePaymentBreakdownSummary(
  Invoice invoice, {
  double? fallbackTotal,
}) {
  final lines = thermalInvoicePaymentBreakdown(
    invoice,
    fallbackTotal: fallbackTotal,
  );
  if (lines.isEmpty) return '-';
  return lines
      .map((e) => '${e.method}: ${e.amount.toStringAsFixed(2)} SR')
      .join(', ');
}

/// Referral customer benefit excluding VAT.
double thermalReferralDiscountExVat(Invoice invoice) {
  final explicit = invoice.referralDiscountAmount;
  if (explicit > 0.001) return thermalR2(explicit);
  if (invoice.subtotal <= 0.001 || invoice.totalAmount <= 0.001) return 0;
  final preDue = invoice.vatAmount > 0.001
      ? thermalR2(invoice.subtotal + invoice.vatAmount)
      : thermalR2(invoice.subtotal * 1.15);
  final gap = thermalR2(preDue - invoice.totalAmount);
  if (gap <= 0.05) return 0;
  return thermalR2(gap / 1.15);
}

/// Shared totals logic for ESC/POS, on-screen thermal preview, and PDF.
class ThermalInvoiceTotals {
  final double grossAmountExclVat;
  final double itemDiscountsTotal;
  final double invoiceDiscount;
  final double promoDiscount;
  final double referralDiscount;
  final double totalDiscountLine;
  final double grossExVatBeforeDiscount;
  final double totalTaxableAmount;
  final double vatAmount;
  final double totalInvoiceAmount;

  ThermalInvoiceTotals({
    required this.grossAmountExclVat,
    required this.itemDiscountsTotal,
    required this.invoiceDiscount,
    required this.promoDiscount,
    required this.referralDiscount,
    required this.totalDiscountLine,
    required this.grossExVatBeforeDiscount,
    required this.totalTaxableAmount,
    required this.vatAmount,
    required this.totalInvoiceAmount,
  });
}

void accumulateInvoiceItems(Invoice invoice, void Function(InvoiceItem) emit) {
  if (invoice.departments.isNotEmpty) {
    for (final dept in invoice.departments) {
      for (final item in dept.items) {
        emit(item);
      }
    }
  } else {
    for (final item in invoice.items) {
      emit(item);
    }
  }
}

ThermalInvoiceTotals computeThermalInvoiceTotals(Invoice invoice) {
  double grossAmountExclVat = 0;
  double itemDiscountsTotal = 0;

  accumulateInvoiceItems(invoice, (InvoiceItem item) {
    final unitExcl = thermalR2(item.unitPrice / 1.15);
    final gross = thermalR2(unitExcl * item.qty);
    var disc = 0.0;
    if (item.discountType == 'percent' || item.discountType == 'percentage') {
      disc = thermalR2(gross * ((item.discountValue ?? 0) / 100));
    } else if ((item.discountValue ?? 0) > 0) {
      disc = item.discountValue ?? 0;
    }
    grossAmountExclVat += gross;
    itemDiscountsTotal += disc;
  });

  double invoiceDiscount = 0;
  double promoDiscount = 0;
  if (invoice.departments.isNotEmpty) {
    for (final dept in invoice.departments) {
      final afterLine = dept.amountAfterDiscount > 0
          ? dept.amountAfterDiscount
          : (grossAmountExclVat - itemDiscountsTotal);
      if (dept.totalDiscountType == 'percent' ||
          dept.totalDiscountType == 'percentage') {
        invoiceDiscount +=
            thermalR2(afterLine * (dept.totalDiscountValue / 100));
      } else {
        invoiceDiscount += dept.totalDiscountValue;
      }
      promoDiscount += dept.promoDiscountAmount;
    }
  }

  // When the API sends an authoritative ex-VAT [Invoice.subtotal], any discount
  // not captured on job rows (e.g. legacy flat jobs / missing totalDiscountType)
  // still reduces taxable — attribute the gap to invoice-level discount so
  // digital, thermal, PDF, and QR text stay consistent with the money columns.
  final afterItem = thermalR2(grossAmountExclVat - itemDiscountsTotal);
  if (invoice.subtotal > 0.001 && afterItem > 0.001) {
    final authTaxable = thermalR2(invoice.subtotal);
    final impliedNonItem = thermalR2(afterItem - authTaxable);
    if (impliedNonItem > 0.001) {
      final attributedNonItem = thermalR2(invoiceDiscount + promoDiscount);
      const tol = 0.015;
      if (impliedNonItem > attributedNonItem + tol) {
        invoiceDiscount = thermalR2(
          invoiceDiscount + (impliedNonItem - attributedNonItem),
        );
      }
    }
  }

  final referralDiscount = thermalReferralDiscountExVat(invoice);

  var totalDiscountLine = thermalR2(
    itemDiscountsTotal + invoiceDiscount + promoDiscount + referralDiscount,
  );
  if (invoice.discountAmount > 0.001) {
    totalDiscountLine = thermalR2(invoice.discountAmount);
  }

  var totalTaxableAmount = thermalR2(grossAmountExclVat -
      itemDiscountsTotal -
      invoiceDiscount -
      promoDiscount -
      referralDiscount);

  // Prefer authoritative taxable from API when present, then apply referral
  // (subtotal is after promo, before referral).
  if (invoice.subtotal > 0.001) {
    totalTaxableAmount = thermalR2(
      (invoice.subtotal - referralDiscount).clamp(0.0, double.infinity),
    );
  }
  var vatAmount = thermalR2(totalTaxableAmount * 0.15);
  var totalInvoiceAmount = thermalR2(totalTaxableAmount + vatAmount);
  if (invoice.totalAmount > 0.001) {
    totalInvoiceAmount = thermalR2(invoice.totalAmount);
    vatAmount = thermalR2(
      (totalInvoiceAmount - totalTaxableAmount).clamp(0.0, double.infinity),
    );
  }

  final grossExVatBeforeDiscount = grossAmountExclVat > 0.001
      ? grossAmountExclVat
      : thermalR2(totalTaxableAmount + totalDiscountLine);

  return ThermalInvoiceTotals(
    grossAmountExclVat: grossAmountExclVat,
    itemDiscountsTotal: itemDiscountsTotal,
    invoiceDiscount: invoiceDiscount,
    promoDiscount: promoDiscount,
    referralDiscount: referralDiscount,
    totalDiscountLine: totalDiscountLine,
    grossExVatBeforeDiscount: grossExVatBeforeDiscount,
    totalTaxableAmount: totalTaxableAmount,
    vatAmount: vatAmount,
    totalInvoiceAmount: totalInvoiceAmount,
  );
}

/// Line breakdown for detailed goods table (dialog preview only).
class ThermalInvoiceLineRow {
  final String productName;
  final String? productNameArabic;
  final double unitPriceExclVat;
  final double qty;
  final double grossBeforeVat;
  final double discount;
  final double totalBeforeVat;
  final double lineVat;
  final double totalWithVat;

  ThermalInvoiceLineRow({
    required this.productName,
    this.productNameArabic,
    required this.unitPriceExclVat,
    required this.qty,
    required this.grossBeforeVat,
    required this.discount,
    required this.totalBeforeVat,
    required this.lineVat,
    required this.totalWithVat,
  });
}

List<ThermalInvoiceLineRow> computeThermalInvoiceLineRows(Invoice invoice) {
  final rows = <ThermalInvoiceLineRow>[];
  accumulateInvoiceItems(invoice, (InvoiceItem item) {
    final unitExcl = thermalR2(item.unitPrice / 1.15);
    final gross = thermalR2(unitExcl * item.qty);
    var disc = 0.0;
    if (item.discountType == 'percent' ||
        item.discountType == 'percentage') {
      disc = thermalR2(gross * ((item.discountValue ?? 0) / 100));
    } else if ((item.discountValue ?? 0) > 0) {
      disc = thermalR2(item.discountValue ?? 0);
    }
    final totalBeforeVat = thermalR2(gross - disc);
    final lineVat = thermalR2(totalBeforeVat * 0.15);
    final totalWithVat = thermalR2(totalBeforeVat + lineVat);
    rows.add(
      ThermalInvoiceLineRow(
        productName: item.productName,
        productNameArabic: item.productNameArabic,
        unitPriceExclVat: unitExcl,
        qty: item.qty,
        grossBeforeVat: gross,
        discount: disc,
        totalBeforeVat: totalBeforeVat,
        lineVat: lineVat,
        totalWithVat: totalWithVat,
      ),
    );
  });
  return rows;
}

/// Some QR backends (PDF [BarcodeWidget], printer firmware) only accept ASCII /
/// latin-1 subsets; strip/replace typography like em‑dash (“—”) before encoding.
String asciiSafeBarcodeQrData(String data) => data
    .replaceAll('\u2014', '-') // em dash
    .replaceAll('\u2013', '-') // en dash
    .replaceAll(RegExp(r'[^\x20-\x7E]'), '');

/// Local API has no TLS. `https://localhost` in QR or [ApiConstants.baseUrl] causes
/// Chrome `ERR_SSL_PROTOCOL_ERROR` — force `http://` for loopback hosts.
String normalizeLocalhostToHttp(String baseOrFullUrl) {
  var b = baseOrFullUrl.trim();
  while (b.endsWith('/')) {
    b = b.substring(0, b.length - 1);
  }
  if (b.isEmpty) return b;
  final lower = b.toLowerCase();
  if (lower.startsWith('https://localhost') ||
      lower.startsWith('https://127.0.0.1') ||
      lower.startsWith('https://[::1]')) {
    return 'http://${b.substring('https://'.length)}';
  }
  if (!lower.contains('://')) {
    return 'http://$b';
  }
  return b;
}

final RegExp _httpLocalhostPrefix = RegExp(
  r'^http://localhost(?=:\d|[/]|$)',
  caseSensitive: false,
);

/// Chrome may force **HTTPS** for hostname `localhost` (HSTS / “always secure”),
/// which breaks plain HTTP (`ERR_SSL_PROTOCOL_ERROR`). Replace with `127.0.0.1`
/// in QR links only; API [ApiConstants.baseUrl] can stay `localhost`.
String preferLoopbackIpForLocalQr(String url) {
  final u = url.trim();
  if (u.isEmpty) return u;
  if (!_httpLocalhostPrefix.hasMatch(u)) return u;
  return u.replaceFirst(
    RegExp(r'^http://localhost', caseSensitive: false),
    'http://127.0.0.1',
  );
}

/// Full URL encoded in the invoice QR.
///
/// **Always** uses [ApiConstants.baseUrl] + `publicInvoicePath` so the scanned link
/// matches the API you configured (localhost vs production). Do not use
/// `invoice.publicInvoiceUrl` here — that comes from the server env
/// `PUBLIC_INVOICE_BASE_URL` and often points at the wrong host while developing.
///
/// Fallback: if the API omits `publicInvoicePath` (legacy), use `publicInvoiceUrl`.
String? resolveInvoicePublicQrUrl(Invoice invoice) {
  final path = invoice.publicInvoicePath?.trim();
  if (path != null && path.isNotEmpty) {
    final base = normalizeLocalhostToHttp(ApiConstants.baseUrl);
    if (base.isEmpty) return null;
    final p = path.startsWith('/') ? path : '/$path';
    return preferLoopbackIpForLocalQr('$base$p');
  }
  final legacy = invoice.publicInvoiceUrl?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    return preferLoopbackIpForLocalQr(normalizeLocalhostToHttp(legacy));
  }
  return null;
}

/// QR payload — same priority as web `CashierTaxInvoiceView`:
/// 1) valid server Phase-2 ZATCA TLV
/// 2) client Phase-1 TLV (branch seller + VAT)
/// 3) public invoice URL
/// 4) compact `INV:…` fallback
String thermalInvoiceQrPayload(
  Invoice invoice,
  double totalWithVat, {
  String paymentMethodText = '',
  bool includeFullText = true,
  ZatcaQrPhase2Crypto? zatcaPhase2,
  double? vatAmount,
}) {
  String shortPayload() {
    final raw =
        'INV:${invoice.invoiceNo},ID:${invoice.id},TOTAL:${totalWithVat.toStringAsFixed(2)}';
    return asciiSafeBarcodeQrData(raw);
  }

  // Prefer a *valid* server Phase-2 ZATCA TLV when present. Never encode a
  // bare invoice/PIH hash (common API mistake) — Qeemah reports "Invalid TLV".
  final serverRaw = (invoice.zatcaQrBase64 ?? '').trim();
  if (isValidZatcaQrTlvBase64(serverRaw)) {
    return serverRaw;
  }

  final vatForQr = thermalR2(vatAmount ?? invoice.vatAmount);

  // Fallback: client Phase-1 TLV (or Phase-2 if [zatcaPhase2] supplied).
  final tlv = zatcaPhase2 != null
      ? buildZatcaQrTlvBase64(
          sellerName: invoice.zatcaSellerName,
          vatNumber: invoice.zatcaSellerVatNumber,
          timestampUtc: invoiceDateToZatcaTimestamp(
            invoiceDate: invoice.invoiceDate,
            issuedAt: invoice.issuedAt,
          ),
          totalWithVat: totalWithVat.toStringAsFixed(2),
          vatAmount: vatForQr.toStringAsFixed(2),
          phase2: zatcaPhase2,
        )
      : buildZatcaPhase1QrPayloadFromInvoice(
          sellerName: invoice.zatcaSellerName,
          vatNumber: invoice.zatcaSellerVatNumber,
          invoiceDate: invoice.invoiceDate,
          issuedAt: invoice.issuedAt,
          totalWithVat: totalWithVat.toStringAsFixed(2),
          vatAmount: vatForQr.toStringAsFixed(2),
        );
  if (tlv != null && tlv.isNotEmpty) {
    return tlv;
  }

  // Fallback: public invoice URL (legacy behaviour) when seller / VAT not yet
  // captured on the branch.
  final publicLink = resolveInvoicePublicQrUrl(invoice);
  if (publicLink != null && publicLink.isNotEmpty) {
    return asciiSafeBarcodeQrData(publicLink);
  }

  if (!includeFullText) return shortPayload();

  const maxQrUtf8Bytes = 2880;

  final fullRaw = _buildThermalInvoiceFullText(
    invoice,
    totalWithVat,
    paymentMethodText,
  );
  final fullText = _breakQrUrlAndEmailDetection(fullRaw);

  final publicUrl = _invoicePublicQrHttpsUrl(invoice);
  if (publicUrl != null) {
    final combined = '$publicUrl\n\n$fullText';
    if (utf8.encode(combined).length <= maxQrUtf8Bytes) {
      return combined;
    }
    return publicUrl;
  }

  if (utf8.encode(fullText).length > maxQrUtf8Bytes) return shortPayload();
  return fullText;
}

/// Returns `https://…/{invoiceId}` when [ApiConstants.invoicePublicQrViewBaseUrl]
/// is configured; otherwise null. ID is path-encoded for safety.
String? _invoicePublicQrHttpsUrl(Invoice invoice) {
  final id = invoice.id.trim();
  if (id.isEmpty) return null;
  var base = ApiConstants.invoicePublicQrViewBaseUrl.trim();
  if (base.isEmpty) return null;
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  if (!base.toLowerCase().startsWith('https://')) return null;
  return '$base/${Uri.encodeComponent(id)}';
}

String _buildThermalInvoiceFullText(
  Invoice invoice,
  double totalWithVat,
  String paymentMethodText,
) {
  final t = computeThermalInvoiceTotals(invoice);
  final issued = formatInvoiceIssuedAtDateTime(invoice.issuedAt) ??
      formatInvoiceLegalDate(invoice.invoiceDate);
  final seller = (invoice.branchName ?? '').trim();
  final vatNo = invoice.zatcaSellerVatNumber.trim();
  final addr =
      (invoice.branchAddress ?? invoice.workshopAddress ?? '').trim();
  final branchCodeLine = (invoice.branchCode ?? '').trim();
  final hr = '-' * 40;
  final money = (double v) => '${v.toStringAsFixed(2)} SR';

  final sb = StringBuffer();

  // Leading sentinel — keeps the QR payload from looking like a phone /
  // URL / email so iOS Camera and similar scanners present the full text
  // rather than offering a single tap-to-call action on a number it
  // detected inside the receipt.
  sb.writeln('=== FILTER TAX INVOICE ===');
  sb.writeln('Simplified Tax Invoice');
  sb.writeln('فاتورة ضريبية مبسطة');
  if (seller.isNotEmpty) {
    sb.writeln('');
    sb.writeln(seller);
  }
  sb.writeln('');

  // Header meta (English-only labels — values may already be Arabic data).
  sb.writeln('Branch: ${branchCodeLine.isEmpty ? '-' : branchCodeLine}');
  sb.writeln('VAT: ${vatNo.isEmpty ? '-' : vatNo}');
  sb.writeln('Address: ${addr.isEmpty ? '-' : addr}');
  sb.writeln('Invoice No: ${invoice.invoiceNo}');
  sb.writeln('Date: $issued');
  sb.writeln('Cashier: ${invoice.cashierName ?? '-'}');
  sb.writeln(hr);

  // Items
  sb.writeln('Item / الصنف   Qty   Unit Price   Total');
  sb.writeln(hr);
  accumulateInvoiceItems(invoice, (item) {
    final qty = item.qty % 1 == 0
        ? '${item.qty.toInt()}'
        : item.qty.toStringAsFixed(2);
    final unit = item.qty > 0.0001
        ? thermalR2(item.lineTotal / item.qty)
        : thermalR2(item.unitPrice);
    final total = thermalR2(item.lineTotal);
    final arName = (item.productNameArabic ?? '').trim();
    if (arName.isNotEmpty) sb.writeln(arName);
    sb.writeln(item.productName);
    sb.writeln(
      '  Qty $qty   Unit ${unit.toStringAsFixed(2)} SR   Total ${money(total)}',
    );
  });
  sb.writeln(hr);

  // Totals — bilingual to mirror the printed receipt.
  sb.writeln('Total (Excluding VAT): ${money(t.grossExVatBeforeDiscount)}');
  sb.writeln('الإجمالي (غير شاملة ضريبة القيمة المضافة)');
  if (t.itemDiscountsTotal > 0.001) {
    sb.writeln('Item Discount: ${money(thermalR2(t.itemDiscountsTotal))}');
    sb.writeln('خصم الأصناف');
  }
  if (t.invoiceDiscount > 0.001) {
    sb.writeln('Invoice Discount: ${money(thermalR2(t.invoiceDiscount))}');
    sb.writeln('خصم الفاتورة');
  }
  if (t.promoDiscount > 0.001) {
    sb.writeln(
      'Promo Code Discount: ${money(thermalR2(t.promoDiscount))}',
    );
    sb.writeln('خصم الرمز الترويجي');
  }
  if (t.referralDiscount > 0.001) {
    sb.writeln(
      'Referral Discount: ${money(thermalR2(t.referralDiscount))}',
    );
    sb.writeln('خصم الإحالة');
  }
  sb.writeln(
    'Total Taxable Amount (Excluding VAT): ${money(t.totalTaxableAmount)}',
  );
  sb.writeln('الإجمالي الخاضع للضريبة (غير شاملة ضريبة القيمة المضافة)');
  sb.writeln('Total VAT: ${money(t.vatAmount)}');
  sb.writeln('مجموع ضريبة القيمة المضافة');
  sb.writeln('Total Amount Due: ${money(totalWithVat)}');
  sb.writeln('إجمالي المبلغ المستحق');

  // Payment — per-method amounts when available.
  final payLines = thermalInvoicePaymentBreakdown(
    invoice,
    fallbackTotal: totalWithVat,
  );
  if (payLines.isNotEmpty) {
    sb.writeln('');
    sb.writeln('Payment:');
    sb.writeln('تفاصيل الدفع');
    for (final line in payLines) {
      sb.writeln('${line.method}: ${money(line.amount)}');
    }
  } else if (paymentMethodText.trim().isNotEmpty) {
    sb.writeln('');
    final p = paymentMethodText.trim();
    sb.writeln('Payment type ( $p )');
    sb.writeln(_paymentArabicLine(p));
  }

  // Customer details
  sb.writeln(hr);
  sb.writeln('CUSTOMER DETAILS');
  sb.writeln(hr);
  final customerName = invoice.customerName.trim();
  if (customerName.isNotEmpty &&
      customerName.toLowerCase() != 'unknown') {
    sb.writeln('Name: $customerName');
  }
  final mobile = (invoice.customerMobile ?? '').trim();
  if (mobile.isNotEmpty) {
    // Inject a zero-width non-joiner between every consecutive pair of
    // digits so iOS / Android scanners do not classify the mobile as a
    // dialable phone number (which previously hijacked the scan result
    // into a "tap to call" action and hid the rest of the invoice text).
    final mobileDisplay = _breakPhonePattern(mobile);
    sb.writeln('Mobile: $mobileDisplay');
  }
  final taxId = (invoice.customerTaxId ?? '').trim();
  if (taxId.isNotEmpty) sb.writeln('Tax ID: $taxId');
  final custType = invoice.thermalDisplayedCustomerType.trim();
  if (custType.isNotEmpty) sb.writeln('Customer type: $custType');
  final make = invoice.vehicleMake.trim();
  final model = invoice.vehicleModel.trim();
  if (make.isEmpty && model.isEmpty && invoice.vehicleInfo.trim().isNotEmpty) {
    sb.writeln('Vehicle: ${invoice.vehicleInfo.trim()}');
  } else {
    if (make.isNotEmpty) sb.writeln('Make: $make');
    if (model.isNotEmpty) sb.writeln('Model: $model');
  }
  if (invoice.vehicleYear.trim().isNotEmpty) {
    sb.writeln('Year: ${invoice.vehicleYear.trim()}');
  }
  if (invoice.plateNo.trim().isNotEmpty) {
    final plateRaw = invoice.plateNo.trim();
    final plate = formatVehiclePlateLettersFirst(plateRaw);
    sb.writeln('Plate: ${plate.isEmpty ? plateRaw : plate}');
  }
  if (invoice.vehicleVin.trim().isNotEmpty) {
    sb.writeln('VIN: ${invoice.vehicleVin.trim()}');
  }
  if (invoice.odometerReading != null && invoice.odometerReading! > 0) {
    sb.writeln('Odometer: ${invoice.odometerReading}');
  }

  return sb.toString().trimRight();
}

/// Camera / scanner apps often treat substrings like `https://`, `www.`, or
/// `user@host` as tappable links and hide the rest of the decoded text. Break
/// those patterns with ZWNJ (invisible) so the full invoice stays visible as
/// plain text while looking the same to humans.
String _breakQrUrlAndEmailDetection(String raw) {
  const zwnj = '\u200C';
  var s = raw.replaceAllMapped(
    RegExp(r'https?://', caseSensitive: false),
    (m) => m.group(0)!.split('').join(zwnj),
  );
  s = s.replaceAllMapped(RegExp(r'\bwww\.', caseSensitive: false), (m) {
    final g = m.group(0)!;
    return '${g[0]}$zwnj${g[1]}$zwnj${g[2]}$zwnj.';
  });
  s = s.replaceAll('@', '$zwnj@$zwnj');
  return s;
}

/// Insert a zero-width non-joiner (U+200C) between every pair of digits in
/// [raw] so phone-detection regexes (iOS Camera, Android scanners, etc.)
/// no longer classify the value as a callable number. The visible text is
/// unchanged for the human reading the QR scan result.
String _breakPhonePattern(String raw) {
  const zwnj = '\u200C';
  final sb = StringBuffer();
  final digit = RegExp(r'\d');
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    sb.write(ch);
    if (i + 1 < raw.length && digit.hasMatch(ch) && digit.hasMatch(raw[i + 1])) {
      sb.write(zwnj);
    }
  }
  return sb.toString();
}

/// Same Arabic payment-line copy used by the printed receipt
/// (kept locally to avoid a UI-layer import from this utility file).
String _paymentArabicLine(String paymentEnglish) {
  final p = paymentEnglish.toLowerCase().trim();
  String inner;
  if (p.contains('card') ||
      p.contains('visa') ||
      p.contains('mada') ||
      p.contains('master')) {
    inner = 'البطاقة';
  } else if (p.contains('cash')) {
    inner = 'نقداً';
  } else if (p.contains('employee')) {
    inner = 'الموظفين';
  } else if (p.contains('split')) {
    inner = 'مشترك';
  } else if (p.contains('bank') || p.contains('transfer')) {
    inner = 'تحويل بنكي';
  } else if (p.contains('corporate') ||
      p.contains('company') ||
      p.contains('billing') ||
      p.contains('monthly')) {
    inner = 'الشركات';
  } else {
    inner = paymentEnglish.trim().isEmpty ? '-' : paymentEnglish.trim();
  }
  return 'نوع الدفع ( $inner )';
}

/// Invoice header brand mark (`splash_logo.png`, tinted with primary yellow).
const String kThermalInvoiceLogoAsset = 'assets/images/filter_invoice_icon.png';
