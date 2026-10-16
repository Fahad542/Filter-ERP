import 'dart:ui' as ui;

import 'package:image/image.dart' as im;

import 'thermal_arabic_raster.dart';
import 'thermal_safe_text.dart';

/// One maintenance line as a bitmap: drawn checkmark or empty box + Latin label
/// (Noto Arabic includes basic Latin; avoids `✓` / `latin1` issues on network printers).
Future<im.Image?> thermalRasterizeMaintenanceChecklistLine({
  required bool checked,
  required String labelEn,
}) async {
  try {
    await ensureThermalArabicFontLoaded();
  } catch (_) {
    return null;
  }

  final label = thermalSafeText(labelEn.trim());
  if (label.isEmpty) return null;

  const double leftGutter = 38;
  const double padY = 5;
  const double labelFontSize = 15;
  const double layoutWidth = 400;

  final pb = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontFamily: kThermalArabicFontFamily,
      fontSize: labelFontSize,
      textAlign: ui.TextAlign.left,
      maxLines: 2,
      height: 1.18,
      textDirection: ui.TextDirection.ltr,
    ),
  );
  pb.pushStyle(
    ui.TextStyle(
      fontFamily: kThermalArabicFontFamily,
      fontSize: labelFontSize,
      color: const ui.Color(0xFF000000),
    ),
  );
  pb.addText(label);
  final paragraph = pb.build();
  paragraph.layout(
    ui.ParagraphConstraints(width: layoutWidth - leftGutter - 6),
  );

  final w = layoutWidth.ceil();
  final h = (paragraph.height + padY * 2).ceil().clamp(28, 52);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );

  final boxLeft = 5.0;
  final boxTop = (h - 22) / 2;
  if (checked) {
    final tickPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;
    final p = ui.Path()
      ..moveTo(boxLeft + 3, boxTop + 11)
      ..lineTo(boxLeft + 9, boxTop + 17)
      ..lineTo(boxLeft + 19, boxTop + 5);
    canvas.drawPath(p, tickPaint);
  } else {
    final border = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(boxLeft + 2, boxTop + 4, 17, 14),
        const ui.Radius.circular(2),
      ),
      border,
    );
  }

  canvas.drawParagraph(paragraph, ui.Offset(leftGutter, padY));

  final picture = recorder.endRecording();
  ui.Image? uiImage;
  try {
    uiImage = await picture.toImage(w, h);
  } catch (_) {
    return null;
  }
  try {
    final bd = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) return null;
    return im.decodeImage(bd.buffer.asUint8List());
  } finally {
    uiImage.dispose();
  }
}
