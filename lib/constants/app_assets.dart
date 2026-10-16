/// Single source of truth for bundled brand logo paths.
const String kAppBrandLogoAsset = 'assets/images/Icon.png';

/// Fallback candidates if primary logo is unavailable. iOS bundled assets are
/// case-sensitive, so include lowercase / alternate spellings as defensive
/// fallbacks.
const List<String> kAppBrandLogoAssetCandidates = [
  kAppBrandLogoAsset,
  'assets/images/icon.png',
  'assets/images/icons.png',
  'assets/images/logo.png',
];
