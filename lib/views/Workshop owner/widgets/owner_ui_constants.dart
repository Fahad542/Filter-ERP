import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

/// Shared Workshop Owner layout tokens.
abstract final class OwnerUi {
  static const scaffoldBackground = AppColors.backgroundLight;
  static const contentBackground = Color(0xFFFBFBFD);

  /// Segmented tab sizing — slightly larger than POS cashier defaults.
  static double segmentedTabFontSize(bool isTablet) => isTablet ? 13.5 : 12.5;
  static double segmentedTabVerticalPad(bool isTablet) => isTablet ? 9.0 : 8.0;
  static double segmentedTabHorizontalPad(bool isTablet) => isTablet ? 14.0 : 12.0;
  static const segmentedTabOuterRadius = 14.0;
  static const segmentedTabInnerRadius = 10.0;
  static const segmentedTabGap = 5.0;
  static const segmentedTabContainerPad = 5.0;
  /// Default bottom-sheet heights for Workshop Owner popups (slightly under full screen).
  static const sheetInitialSize = 0.86;
  static const sheetMinSize = 0.45;
  static const sheetMaxSize = 0.92;
  static const sheetFormInitialSize = 0.88;
  static const sheetFormMaxSize = 0.92;
}
