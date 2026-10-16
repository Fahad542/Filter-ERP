import 'dart:convert';
import 'dart:typed_data';

/// ZATCA Phase 2 cryptographic stamp fields. Populate when ZATCA e-invoicing
/// API integration becomes available — pre-Phase 2 invoices keep working with
/// only the Phase 1 fields.
///
/// Phase 2 adds 4 TLV tags on top of the Phase 1 5:
///   * Tag 6 — SHA-256 hash of the signed XML invoice (base64 string).
///   * Tag 7 — ECDSA invoice signature bytes.
///   * Tag 8 — X.509 ECDSA public-key DER bytes.
///   * Tag 9 — ECDSA signature of the cryptographic stamp.
class ZatcaQrPhase2Crypto {
  /// SHA-256 of the signed invoice XML, **already base64-encoded**.
  final String invoiceXmlHashB64;

  /// ECDSA signature over the invoice (raw bytes from the cert).
  final Uint8List signatureBytes;

  /// X.509 public-key DER bytes (from the device cert).
  final Uint8List publicKeyDerBytes;

  /// ECDSA signature of the cryptographic stamp identifier.
  final Uint8List stampSignatureBytes;

  const ZatcaQrPhase2Crypto({
    required this.invoiceXmlHashB64,
    required this.signatureBytes,
    required this.publicKeyDerBytes,
    required this.stampSignatureBytes,
  });
}

/// True when [value] base64-decodes to ZATCA TLV with tags 1–5 present.
/// Rejects bare SHA-256 invoice/PIH hashes (exactly 32 bytes) that were
/// previously mistaken for QR payloads — same rule as web `zatcaQr.js`.
bool isValidZatcaQrTlvBase64(String? value) {
  final b64 = (value ?? '').replaceAll(RegExp(r'\s+'), '').trim();
  if (b64.isEmpty || b64.length < 16) return false;

  late final Uint8List buf;
  try {
    buf = Uint8List.fromList(base64.decode(b64));
  } catch (_) {
    return false;
  }
  if (buf.length < 40 || buf[0] != 1) return false;

  final seen = <int>{};
  var i = 0;
  while (i + 2 <= buf.length) {
    final tag = buf[i];
    var len = buf[i + 1];
    var header = 2;
    if (len == 0x81 && i + 3 <= buf.length) {
      len = buf[i + 2];
      header = 3;
    } else if (len == 0x82 && i + 4 <= buf.length) {
      len = (buf[i + 2] << 8) | buf[i + 3];
      header = 4;
    }
    if (len < 0 || i + header + len > buf.length) {
      // Phase-2 crypto stamp may leave trailing / non-strict bytes.
      break;
    }
    if (tag >= 1 && tag <= 9) seen.add(tag);
    i += header + len;
  }
  return seen.contains(1) &&
      seen.contains(2) &&
      seen.contains(3) &&
      seen.contains(4) &&
      seen.contains(5);
}

/// ISO-8601 without milliseconds — Qeemah rejects `…T00:00:00.000Z`.
String toZatcaIsoTimestamp(DateTime date) {
  final d = date.toUtc();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final h = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  final s = d.second.toString().padLeft(2, '0');
  return '$y-$m-${day}T$h:$min:${s}Z';
}

/// ZATCA tag 3 timestamp — uses printed invoice date for backdated invoices.
DateTime invoiceDateToZatcaTimestamp({
  String? invoiceDate,
  String? issuedAt,
}) {
  final rawDate = (invoiceDate ?? '').trim();
  final rawIssued = (issuedAt ?? '').trim();
  final raw = rawDate.isNotEmpty ? rawDate : rawIssued;
  if (raw.isEmpty) return DateTime.now().toUtc();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    // Noon UTC avoids date-boundary shifts; ZATCA wants no milliseconds.
    return DateTime.parse('${raw}T12:00:00Z').toUtc();
  }
  final d = DateTime.tryParse(raw);
  if (d == null) return DateTime.now().toUtc();
  return d.toUtc();
}

/// Build a ZATCA-compliant QR payload (TLV → base64) per the e-invoicing spec.
///
/// Phase 1 (always required, all 5 must be present):
///   1. Seller name
///   2. VAT registration number
///   3. ISO-8601 timestamp (UTC, no milliseconds)
///   4. Invoice total **including** VAT (string)
///   5. VAT amount (string)
///
/// Phase 2 (optional — populated by ZATCA API integration):
///   6. SHA-256 base64 of signed invoice XML
///   7. ECDSA signature
///   8. ECDSA public key
///   9. Stamp signature
///
/// Returns `null` if any of the 5 required Phase 1 fields are missing — caller
/// should fall back to a non-TLV payload (e.g. public invoice URL).
String? buildZatcaQrTlvBase64({
  required String sellerName,
  required String vatNumber,
  required DateTime timestampUtc,
  required String totalWithVat,
  required String vatAmount,
  ZatcaQrPhase2Crypto? phase2,
}) {
  final s = sellerName.trim();
  final v = vatNumber.trim();
  final ts = toZatcaIsoTimestamp(timestampUtc);
  final t = totalWithVat.trim();
  final va = vatAmount.trim();

  if (s.isEmpty || v.isEmpty || t.isEmpty || va.isEmpty) {
    return null;
  }

  final builder = BytesBuilder();
  void writeTlv(int tag, List<int> value) {
    if (value.length > 255) {
      // ZATCA uses single-byte length; truncate to fit (only realistic for
      // user-entered seller name on phase 1).
      value = value.sublist(0, 255);
    }
    builder
      ..addByte(tag)
      ..addByte(value.length)
      ..add(value);
  }

  writeTlv(1, utf8.encode(s));
  writeTlv(2, utf8.encode(v));
  writeTlv(3, utf8.encode(ts));
  writeTlv(4, utf8.encode(t));
  writeTlv(5, utf8.encode(va));

  if (phase2 != null) {
    writeTlv(6, utf8.encode(phase2.invoiceXmlHashB64));
    writeTlv(7, phase2.signatureBytes);
    writeTlv(8, phase2.publicKeyDerBytes);
    writeTlv(9, phase2.stampSignatureBytes);
  }

  return base64.encode(builder.toBytes());
}

/// Phase-1 only (tags 1–5) — same as web `buildZatcaPhase1QrPayloadFromInvoice`.
String? buildZatcaPhase1QrPayloadFromInvoice({
  required String sellerName,
  required String vatNumber,
  String? invoiceDate,
  String? issuedAt,
  required String totalWithVat,
  required String vatAmount,
}) {
  return buildZatcaQrTlvBase64(
    sellerName: sellerName,
    vatNumber: vatNumber,
    timestampUtc: invoiceDateToZatcaTimestamp(
      invoiceDate: invoiceDate,
      issuedAt: issuedAt,
    ),
    totalWithVat: totalWithVat,
    vatAmount: vatAmount,
  );
}
