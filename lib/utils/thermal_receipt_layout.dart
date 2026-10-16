import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared visual system for 80 mm thermal PDFs (invoice + store closing).
abstract final class ThermalReceiptLayout {
  static const PdfColor brandPrimary = PdfColor.fromInt(0xFFFCC247);
  static const PdfColor brandInk = PdfColor.fromInt(0xFF23262D);
  static const PdfColor border = PdfColor.fromInt(0xFF757575);
  static const PdfColor borderLight = PdfColor.fromInt(0xFFBDBDBD);
  static const PdfColor fillPanel = PdfColor.fromInt(0xFFF7F7F7);
  static const PdfColor fillAccent = PdfColor.fromInt(0xFFFDF4DC);

  /// Full-width rule — reads clearly after B&W rasterization.
  static pw.Widget divider({double vPad = 3.5}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: vPad),
      child: pw.Column(
        children: [
          pw.Container(width: double.infinity, height: 1.15, color: brandInk),
          pw.SizedBox(height: 1.4),
          pw.Container(width: double.infinity, height: 0.4, color: borderLight),
        ],
      ),
    );
  }

  /// Document title: Arabic above English, accent top rule.
  static pw.Widget documentTitle({
    required String titleArShaped,
    required String titleEn,
    required pw.Font fontArabic,
    required pw.Font fontBold,
    double arSize = 11.2,
    double enSize = 10.4,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(4, 5, 4, 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: brandPrimary, width: 3.5),
          bottom: pw.BorderSide(color: brandInk, width: 0.85),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            titleArShaped,
            style: pw.TextStyle(
              font: fontArabic,
              fontSize: arSize,
              height: 1.08,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 1.5),
          pw.Text(
            titleEn,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: enSize,
              height: 1.0,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Bilingual section title (Arabic on top, English below).
  static pw.Widget sectionTitle({
    required String titleArShaped,
    required String titleEn,
    required pw.Font fontArabic,
    required pw.Font fontBold,
    double arSize = 8.35,
    double enSize = 7.85,
  }) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      decoration: pw.BoxDecoration(
        color: fillAccent,
        border: pw.Border.all(color: borderLight, width: 0.45),
        borderRadius: pw.BorderRadius.circular(2.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titleArShaped,
            style: pw.TextStyle(
              font: fontArabic,
              fontSize: arSize,
              height: 1.1,
            ),
            textAlign: pw.TextAlign.left,
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            titleEn,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: enSize,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  /// Seller / workshop name under title.
  static pw.Widget sellerNameBlock({
    required String? nameArShaped,
    required String nameEn,
    required pw.Font fontArabic,
    required pw.Font fontBold,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
      child: pw.Column(
        children: [
          if (nameArShaped != null && nameArShaped.isNotEmpty) ...[
            pw.Text(
              nameArShaped,
              style: pw.TextStyle(
                font: fontArabic,
                fontSize: 10.2,
                height: 1.08,
              ),
              textAlign: pw.TextAlign.center,
              maxLines: 3,
            ),
            pw.SizedBox(height: 1),
          ],
          pw.Text(
            nameEn,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9.85,
              height: 1.0,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// Meta block (branch, VAT, invoice no, …).
  static pw.Widget infoPanel({required List<pw.Widget> children}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: pw.BoxDecoration(
        color: fillPanel,
        border: pw.Border.all(color: borderLight, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Line-items column header bar.
  static pw.Widget itemsColumnHeader({required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      decoration: pw.BoxDecoration(
        color: fillAccent,
        border: pw.Border(
          top: pw.BorderSide(color: brandInk, width: 0.7),
          bottom: pw.BorderSide(color: brandInk, width: 0.7),
        ),
      ),
      child: child,
    );
  }

  /// Grand total / highlight row.
  static pw.Widget highlightBox({required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 2, bottom: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: pw.BoxDecoration(
        color: fillAccent,
        border: pw.Border.all(color: brandInk, width: 0.75),
        borderRadius: pw.BorderRadius.circular(2.5),
      ),
      child: child,
    );
  }

  /// Footer thank-you strip.
  static pw.Widget footerThanks({
    required String thanksArShaped,
    required String thanksEn,
    required pw.Font fontArabic,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: border, width: 0.65)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            thanksEn,
            style: pw.TextStyle(font: fontBold, fontSize: 8.35),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            thanksArShaped,
            style: pw.TextStyle(
              font: fontArabic,
              fontSize: 9.1,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }

  /// Table header cell — stacked AR / EN.
  static pw.Widget tableHeadStacked({
    required String arShaped,
    required String en,
    required pw.Font fontArabic,
    required pw.Font fontBold,
    pw.TextAlign align = pw.TextAlign.left,
    double arSize = 7.95,
    double enSize = 7.35,
  }) {
    final cross = align == pw.TextAlign.right
        ? pw.CrossAxisAlignment.end
        : align == pw.TextAlign.center
        ? pw.CrossAxisAlignment.center
        : pw.CrossAxisAlignment.start;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: cross,
        children: [
          pw.Text(
            arShaped,
            style: pw.TextStyle(font: fontArabic, fontSize: arSize, height: 1.08),
            textAlign: align,
          ),
          pw.SizedBox(height: 0.5),
          pw.Text(
            en,
            style: pw.TextStyle(font: fontBold, fontSize: enSize, height: 1.05),
            textAlign: align,
          ),
        ],
      ),
    );
  }
}
