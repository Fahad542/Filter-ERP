/// Strips bidi / invisible characters only. Keeps Unicode for PDFs that embed
/// fonts (e.g. Poppins / Arabic) so names are not mangled or reordered.
String pdfStripBidiAndInvisible(String input) {
  return input.replaceAll(
    RegExp(
      r'[\u061C\u200B-\u200D\uFEFF\u2060\u200E\u200F\u2066-\u2069\u00AD]',
    ),
    '',
  );
}

/// Printable ASCII for thermal ESC/POS (latin1) and PDF Helvetica.
String thermalSafeText(String input) {
  final normalized = input
      .replaceAll(RegExp(r'[\u2010-\u2015\u2212\uFE63\uFF0D]'), '-')
      .replaceAll('\u00a0', ' ')
      .replaceAll('\u2026', '...')
      .replaceAll(RegExp(r'[\u2018\u2019\u0091\u0092\u201B]'), "'")
      .replaceAll(RegExp(r'[\u201C\u201D\u0093\u0094\u201F]'), '"')
      .replaceAll('\u2022', '*')
      .replaceAll(RegExp(r'[\u061C\u200E\u200F\u2066-\u2069\u2060]'), '');

  final b = StringBuffer();
  for (final code in normalized.runes) {
    if (code >= 0x20 && code <= 0x7e) {
      b.writeCharCode(code);
    } else if (code == 0x09 || code == 0x0a || code == 0x0d) {
      b.writeCharCode(code);
    }
  }
  return b.toString();
}
