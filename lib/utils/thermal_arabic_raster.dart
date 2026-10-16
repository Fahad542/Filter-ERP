import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as im;

/// Registered with [FontLoader]; matches bundled TTF in `pubspec.yaml` assets.
const String kThermalArabicFontFamily = '_ThermalInvoiceNotoArabic';

bool _thermalArabicFontReady = false;

/// True when the string contains Arabic presentation / blocks (needs raster for ESC/POS).
bool thermalTextNeedsRaster(String input) {
  for (final c in input.runes) {
    if ((c >= 0x0600 && c <= 0x06FF) ||
        (c >= 0x0750 && c <= 0x077F) ||
        (c >= 0x08A0 && c <= 0x08FF) ||
        (c >= 0xFB50 && c <= 0xFDFF) ||
        (c >= 0xFE70 && c <= 0xFEFF)) {
      return true;
    }
  }
  return false;
}

Future<void> ensureThermalArabicFontLoaded() async {
  if (_thermalArabicFontReady) return;
  final loader = FontLoader(kThermalArabicFontFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  await loader.load();
  _thermalArabicFontReady = true;
}

/// Renders [text] to a bitmap (PNG → [im.Image]) for ESC/POS `g.image` (works on printers without UTF‑8).
Future<im.Image?> thermalRasterizeText(
  String text, {
  required double layoutWidth,
  double fontSize = 20,
  int maxLines = 14,
}) async {
  final t = text.trim();
  if (t.isEmpty) return null;
  try {
    await ensureThermalArabicFontLoaded();
  } catch (_) {
    return null;
  }

  final pb = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontFamily: kThermalArabicFontFamily,
      fontSize: fontSize,
      textAlign: ui.TextAlign.center,
      maxLines: maxLines,
      textDirection: ui.TextDirection.ltr,
      height: 1.15,
    ),
  );
  pb.pushStyle(
    ui.TextStyle(
      fontFamily: kThermalArabicFontFamily,
      fontSize: fontSize,
      color: const ui.Color(0xFF000000),
    ),
  );
  pb.addText(t);
  final paragraph = pb.build();
  paragraph.layout(ui.ParagraphConstraints(width: layoutWidth));

  final w = layoutWidth.ceil().clamp(32, 576);
  final h = paragraph.height.ceil().clamp(12, 520);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  canvas.drawParagraph(paragraph, ui.Offset.zero);
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
