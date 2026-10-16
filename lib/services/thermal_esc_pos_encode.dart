import 'dart:math' as math;
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

import '../utils/thermal_raster_preprocess.dart';

/// True when ≥98% of pixels on [y] are near-white (paper).
bool _rowIsMostlyWhite(img.Image image, int y) {
  if (y < 0 || y >= image.height || image.width <= 0) return false;
  var white = 0;
  final w = image.width;
  for (var x = 0; x < w; x++) {
    final p = image.getPixel(x, y);
    if (p.luminance >= 245) white++;
  }
  return white * 100 >= w * 98;
}

/// Pick a strip end ≤ [maxEnd] that does not bisect ink (e.g. QR modules).
/// Falls back to [maxEnd] if no blank row is found nearby.
int _safeStripEnd(img.Image image, int startY, int maxEnd) {
  final h = image.height;
  if (maxEnd >= h) return h;
  if (maxEnd <= startY) return math.min(startY + 1, h);

  // Search upward from the nominal cut for a blank paper row.
  final searchFloor = math.max(startY + 48, maxEnd - 160);
  for (var y = maxEnd - 1; y >= searchFloor; y--) {
    if (_rowIsMostlyWhite(image, y)) {
      return y + 1;
    }
  }
  return maxEnd;
}

/// CPU-heavy PNG → ESC/POS encoder. Pure Dart — safe to run on a background
/// isolate as long as the caller passes in a pre-loaded [CapabilityProfile]
/// (never call `CapabilityProfile.load` inside a worker — it uses
/// `rootBundle` which requires a Flutter binding).
///
/// PNG decode goes through `package:image`, which is pure Dart and works
/// reliably in any isolate. (The previous raw-RGBA shortcut interacted
/// badly with Android's `Bitmap.ARGB_8888 → copyPixelsToBuffer` byte order,
/// producing all-white prints. The PNG round-trip is the proven path.)
List<int> encodeEscPosBytesFromPngPagesSync(
  List<Uint8List> pngPages,
  CapabilityProfile profile,
) {
  if (pngPages.isEmpty) {
    throw StateError('No raster pages for thermal print.');
  }

  final g = Generator(PaperSize.mm80, profile);
  var bytes = <int>[];
  bytes += g.reset();

  for (final pngBytes in pngPages) {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError(
        'Failed to decode rasterized thermal PDF page (invalid PNG).',
      );
    }

    final image = prepareThermalRasterForEscPos(decoded);
    var y = 0;
    while (y < image.height) {
      final remaining = image.height - y;
      final nominalH = remaining > kThermalPdfRasterStripMaxHeightPx
          ? kThermalPdfRasterStripMaxHeightPx
          : remaining;
      final end = _safeStripEnd(image, y, y + nominalH);
      final stripH = math.max(1, end - y);
      final strip = img.copyCrop(
        image,
        x: 0,
        y: y,
        width: image.width,
        height: stripH,
      );
      // No feed between strips — a feed mid-QR prints as a "cut" / thin bar.
      bytes += g.image(
        strip,
        align: PosAlign.center,
        isDoubleDensity: true,
      );
      y += stripH;
    }
  }

  // Original trailing feed before cut (strip-split fix is what keeps QR intact).
  bytes += g.feed(1);
  bytes += g.cut(mode: PosCutMode.full);
  return bytes;
}
