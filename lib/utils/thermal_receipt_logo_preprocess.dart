import 'dart:typed_data';

import 'package:image/image.dart';

/// Logo for thermal receipts: **pure black silhouette on white**, narrow enough
/// for an 80 mm roll and visible regardless of source colour.
///
/// Strategy (in priority order):
///
///  1. **Alpha-mask path** — when the source PNG has meaningful transparency
///     (>3% transparent pixels), every visible pixel becomes black and every
///     transparent pixel becomes white. This keeps the original logo shape
///     even when the artwork is white, gradient, coloured, or photographic.
///  2. **Luminance threshold path** — for fully opaque artwork, anything
///     darker than mid-grey becomes black, anything lighter becomes white.
///     The threshold (0.62) is intentionally lenient so anti-aliased strokes
///     don't all wash out to white on the receipt.
///
/// Output is always pure two-tone (#000000 / #FFFFFF, alpha = 255), which is
/// what thermal printer head bitmaps and B&W PDFs expect.
Uint8List? preprocessThermalReceiptLogoPng(
  Uint8List pngBytes, {
  int targetMaxWidth = 260,
}) {
  final decoded = decodeImage(pngBytes);
  if (decoded == null) return null;

  var img = decoded;
  if (img.width > targetMaxWidth) {
    img = copyResize(img, width: targetMaxWidth);
  }

  // Decide which silhouette strategy to use BEFORE we overwrite alpha with 255.
  final useAlphaSilhouette = _hasMeaningfulTransparency(img);

  if (!useAlphaSilhouette) {
    img = grayscale(img);
  }

  const double luminanceCutoff = 0.62;
  for (final frame in img.frames) {
    for (final p in frame) {
      late int v;
      if (useAlphaSilhouette) {
        // Visible source pixel → ink (black). Transparent → paper (white).
        v = p.a >= 96 ? 0 : 255;
      } else {
        // Hard transparent regions (rare on opaque logos) still go to white.
        if (p.a < 32) {
          v = 255;
        } else {
          v = p.luminanceNormalized > luminanceCutoff ? 255 : 0;
        }
      }
      p
        ..r = v
        ..g = v
        ..b = v
        ..a = 255;
    }
  }

  return Uint8List.fromList(encodePng(img));
}

/// True when the source has enough transparent pixels that we can safely treat
/// alpha as a silhouette mask. A handful of stray transparent pixels (1–2%)
/// shouldn't trigger this path — those are usually JPEG-style edge artefacts.
bool _hasMeaningfulTransparency(Image img) {
  var transparent = 0;
  var total = 0;
  for (final frame in img.frames) {
    for (final p in frame) {
      total++;
      if (p.a < 96) transparent++;
    }
  }
  if (total == 0) return false;
  final ratio = transparent / total;
  return ratio > 0.03;
}
