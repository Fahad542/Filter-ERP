import 'package:flutter/material.dart';

/// Workshop POS density for ~11" tablets: readable type without oversized chrome.
abstract final class PosTabletLayout {
  PosTabletLayout._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Landscape tablet: tighter login form + side menu (POS requires landscape).
  static bool compactLandscapeChrome(BuildContext context) =>
      isTablet(context) && isLandscape(context);

  /// Replaces legacy 1.4× shell scaling.
  static double textScale(BuildContext context) {
    if (compactLandscapeChrome(context)) return 1.0;
    return isTablet(context) ? 1.08 : 1.0;
  }

  static TextScaler textScaler(BuildContext context) =>
      TextScaler.linear(textScale(context));

  /// PosAppBar / PosScreenAppBar / shell rail offset.
  static const double appBarHeight = 56;

  static const double appBarIconBox = 36;
  static const double appBarIconGlyph = 20;
  static const double appBarTitleSize = 15;
  static const double appBarBackIcon = 24;
  static const double appBarBottomRadius = 18;
  static const double appBarLogoHeight = 26;
}
