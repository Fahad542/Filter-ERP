import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/app_assets.dart';

/// First successfully loaded logo bytes from [kAppBrandLogoAssetCandidates], or null.
/// Logs the missing candidates in debug mode so a regression in `pubspec.yaml`
/// or a case-sensitivity miss on iOS is visible during development.
Future<ByteData?> loadBrandLogoByteData() async {
  for (final path in kAppBrandLogoAssetCandidates) {
    try {
      return await rootBundle.load(path);
    } catch (_) {}
  }
  if (kDebugMode) {
    debugPrint(
      '[Thermal] brand logo load FAILED — none of '
      '${kAppBrandLogoAssetCandidates.join(", ")} found in assets bundle.',
    );
  }
  return null;
}
