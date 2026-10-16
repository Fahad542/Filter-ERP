import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/app_assets.dart';
import '../utils/thermal_receipt_logo_preprocess.dart';

/// Bundle of bytes the thermal PDF builders need to render a receipt without
/// touching [rootBundle] from a background isolate.
///
/// Asset loads (logo PNG + Noto Sans Arabic TTFs) are done once on the **main
/// isolate** by [loadThermalPdfAssetsOnMainIsolate] — where
/// `WidgetsFlutterBinding.ensureInitialized()` has run and [AssetManifest]
/// works. The resulting [Uint8List]s are then transferred into the PDF worker
/// via closure capture (`Isolate.run`), so the worker performs only pure CPU
/// work (PDF assembly) and never needs the asset API.
///
/// This eliminates three cascading failures observed in production:
///   1. `[Thermal] brand logo load FAILED — none of …` (asset lookup in worker
///      fails because the worker isolate has no [ServicesBinding]).
///   2. `Error loading AssetManifest API: Binding has not yet been
///      initialized.` (same root cause).
///   3. `Courier has no Unicode support` — fallback Helvetica/Courier is used
///      for Arabic glyphs after the network `PdfGoogleFonts` cascade also
///      fails inside the isolate, producing blank boxes on the receipt.
class ThermalPdfAssetBytes {
  /// PNG bytes for the brand logo (already preprocessed for thermal receipt
  /// width), or `null` if none of [kAppBrandLogoAssetCandidates] resolved.
  final Uint8List? logoPng;

  /// `assets/fonts/NotoSansArabic-Regular.ttf` raw bytes.
  final Uint8List notoRegular;

  /// `assets/fonts/NotoSansArabic-Bold.ttf` raw bytes.
  final Uint8List notoBold;

  const ThermalPdfAssetBytes({
    required this.logoPng,
    required this.notoRegular,
    required this.notoBold,
  });
}

Future<ThermalPdfAssetBytes>? _cached;

/// Loads brand logo + Noto Sans Arabic fonts on the **main isolate** and
/// memoizes the result. Subsequent invoices reuse the cached bytes without
/// touching the asset bundle again.
///
/// Throws if either Noto font asset is missing — callers expect bilingual
/// Arabic rendering, and silently falling back to Helvetica produces blank
/// glyphs on receipts (the `Courier has no Unicode support` symptom).
Future<ThermalPdfAssetBytes> loadThermalPdfAssetsOnMainIsolate() {
  return _cached ??= _load().catchError((Object err, StackTrace st) {
    // Reset cache on failure so a transient bundle read can be retried later.
    _cached = null;
    if (kDebugMode) {
      debugPrint('[Thermal] asset preload FAILED on main isolate: $err\n$st');
    }
    throw err;
  });
}

Future<ThermalPdfAssetBytes> _load() async {
  final logo = await _loadLogoBytes();
  final notoRegular = await rootBundle.load(
    'assets/fonts/NotoSansArabic-Regular.ttf',
  );
  final notoBold = await rootBundle.load(
    'assets/fonts/NotoSansArabic-Bold.ttf',
  );

  return ThermalPdfAssetBytes(
    logoPng: logo,
    notoRegular: notoRegular.buffer.asUint8List(),
    notoBold: notoBold.buffer.asUint8List(),
  );
}

Future<Uint8List?> _loadLogoBytes() async {
  for (final path in kAppBrandLogoAssetCandidates) {
    try {
      final data = await rootBundle.load(path);
      final raw = data.buffer.asUint8List();
      return preprocessThermalReceiptLogoPng(raw, targetMaxWidth: 230) ?? raw;
    } catch (_) {
      // Try the next candidate path.
    }
  }
  if (kDebugMode) {
    debugPrint(
      '[Thermal] brand logo load FAILED — none of '
      '${kAppBrandLogoAssetCandidates.join(", ")} found in assets bundle.',
    );
  }
  return null;
}
