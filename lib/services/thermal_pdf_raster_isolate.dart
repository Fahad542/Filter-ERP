import 'dart:isolate';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';

import 'thermal_esc_pos_encode.dart';

/// Encode PNG pages → ESC/POS bytes **off the UI isolate** using only pure
/// Dart. Caller must pre-load the [CapabilityProfile] on the main isolate
/// (see [warmThermalEscPosCapabilityProfile]) and rasterize the PDF to PNG
/// pages on the main isolate (see `buildEscPosBytesFromPdfRaster`).
///
/// ### What the worker uses (allowed)
///   * `package:image` PNG decode + threshold/dither/resize/crop.
///   * `package:esc_pos_utils_plus` `Generator` for ESC/POS byte assembly.
///
/// ### What the worker explicitly avoids (Flutter binding violations)
///   * `Printing.raster` — `printing` plugin's MethodChannel can't init
///     in a background isolate.
///   * `CapabilityProfile.load` — calls `rootBundle.loadString`, which
///     requires `ServicesBinding.instance`.
///   * `rootBundle`, plugins, `MethodChannel`, or any other
///     binding-bound API.
///   * `BackgroundIsolateBinaryMessenger.ensureInitialized` — not needed
///     because we don't talk to plugins from here.
///
/// Throws on encode failure. Callers may catch and run
/// [encodeEscPosBytesFromPngPagesSync] on the main isolate as a last
/// resort fallback.
Future<List<int>> encodePngPagesToEscPosOffUi(
  List<Uint8List> pngPages,
  CapabilityProfile profile,
) async {
  if (pngPages.isEmpty) {
    throw StateError('No raster pages for thermal print.');
  }

  final sw = kDebugMode ? (Stopwatch()..start()) : null;
  final bytes = await Isolate.run(
    () => encodeEscPosBytesFromPngPagesSync(pngPages, profile),
    debugName: 'ThermalEscPosEncode',
  );
  if (sw != null) {
    debugPrint(
      '[Thermal] off-UI image+ESC/POS encode ${sw.elapsedMilliseconds}ms '
      '(${bytes.length} bytes from ${pngPages.length} page(s)).',
    );
  }
  return bytes;
}
