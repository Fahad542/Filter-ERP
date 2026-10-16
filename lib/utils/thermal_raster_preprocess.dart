import 'package:image/image.dart' as img;

/// Thermal PDF → bitmap DPI. 120 is faster on Print (less UI jank); scaled to 576px roll width.
const double kThermalPdfRasterDpi = 120.0;

const int kThermalPdfRasterPrintWidthPx = 576;

/// Max height per ESC/POS bitmap strip (avoids oversized single buffers).
/// Keep high enough that a typical 80mm invoice (incl. QR) fits in one strip
/// when possible — splitting mid-QR prints as a broken / partial code.
const int kThermalPdfRasterStripMaxHeightPx = 4096;

/// Pixels darker than this become ink (0). Paper stays white (255).
/// Must stay **low** — a high cutoff marks the whole page as ink (inverted print).
const int _kInkLuminanceCutoff = 168;

img.Image _flattenOnWhite(img.Image source) {
  final flat = img.Image(width: source.width, height: source.height);
  img.fill(flat, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(flat, source);
  return flat;
}

void _binarizeInkOnWhite(img.Image image, int cutoff) {
  for (final frame in image.frames) {
    for (final p in frame) {
      if (p.a < 48) {
        p
          ..r = 255
          ..g = 255
          ..b = 255
          ..a = 255;
        continue;
      }
      final lum = p.luminance;
      final v = lum < cutoff ? 0 : 255;
      p
        ..r = v
        ..g = v
        ..b = v
        ..a = 255;
    }
  }
}

double _inkRatio(img.Image image) {
  var ink = 0;
  var total = 0;
  for (final frame in image.frames) {
    for (final p in frame) {
      if (p.a < 48) continue;
      total++;
      if (p.luminance < 128) ink++;
    }
  }
  if (total == 0) return 0;
  return ink / total;
}

/// Prepare raster for ESC/POS: **black (0) = ink**, **white (255) = paper**.
img.Image prepareThermalRasterForEscPos(img.Image source) {
  var image = _flattenOnWhite(source);
  if (image.width != kThermalPdfRasterPrintWidthPx) {
    image = img.copyResize(
      image,
      width: kThermalPdfRasterPrintWidthPx,
      interpolation: img.Interpolation.cubic,
    );
  }

  if (image.numChannels >= 3) {
    image = img.grayscale(image);
  }

  image = img.adjustColor(
    image,
    contrast: 1.28,
    brightness: 1.02,
    gamma: 1.0,
  );

  var cutoff = _kInkLuminanceCutoff;
  _binarizeInkOnWhite(image, cutoff);

  // If most of the page became ink, threshold was too high → solid black roll.
  if (_inkRatio(image) > 0.42) {
    cutoff = 128;
    _binarizeInkOnWhite(image, cutoff);
  }

  // If almost no ink, threshold was too low → faint print.
  if (_inkRatio(image) < 0.006) {
    cutoff = 190;
    _binarizeInkOnWhite(image, cutoff);
  }

  return image;
}
