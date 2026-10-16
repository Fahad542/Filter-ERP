import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Busy / loading state for branded buttons:
/// — fill color stays identical when loading (`onPressed: null`)
/// — ring color: primary (yellow) fill → secondary loader; secondary (charcoal)
///   fill → primary loader; other fills → sensible contrast vs luminance.
class AppButtonBusy {
  AppButtonBusy._();

  static const double loaderSize = 22;
  static const double loaderStrokeWidth = 2.25;

  /// Circular progress ring inside a button while it stays visually “enabled”.
  static Widget circularLoader(
    Color ringColor, {
    double size = loaderSize,
    double strokeWidth = loaderStrokeWidth,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: ringColor,
      ),
    );
  }

  /// Primary yellow (`AppColors.primaryLight`) → charcoal ring.
  /// Charcoal secondary (`AppColors.secondaryLight`) → yellow ring.
  static Widget loaderOnFill(
    Color fillColor, {
    double size = loaderSize,
    double strokeWidth = loaderStrokeWidth,
  }) {
    final ring =
        (_sameRgb(fillColor, AppColors.primaryLight))
            ? AppColors.secondaryLight
            : (_sameRgb(fillColor, AppColors.secondaryLight))
                ? AppColors.primaryLight
                : ThemeData.estimateBrightnessForColor(fillColor) ==
                        Brightness.dark
                    ? AppColors.primaryLight
                    : AppColors.secondaryLight;

    return circularLoader(
      ring,
      size: size,
      strokeWidth: strokeWidth,
    );
  }

  static bool _sameRgb(Color a, Color b) =>
      a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;

  /// Locked fill + fg across **disabled** so loading (`onPressed: null`) doesn’t tint the button.
  /// Safer than `disabledBackgroundColor` alone under Material 3.
  static ButtonStyle elevatedLocked({
    required Color backgroundColor,
    required Color foregroundColor,
    double elevation = 0,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    MaterialTapTargetSize? tapTargetSize,
    OutlinedBorder? shape,
  }) {
    final resolvedShape =
        shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color?>(backgroundColor),
      foregroundColor: WidgetStatePropertyAll<Color?>(foregroundColor),
      iconColor: WidgetStatePropertyAll<Color?>(foregroundColor),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        return null;
      }),
      elevation: WidgetStatePropertyAll<double>(elevation),
      shadowColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
      shape: WidgetStatePropertyAll<OutlinedBorder>(resolvedShape),
      padding: padding != null ? WidgetStatePropertyAll(padding) : null,
      minimumSize:
          minimumSize != null ? WidgetStatePropertyAll(minimumSize) : null,
      tapTargetSize: tapTargetSize,
    );
  }

  /// Same semantics as [elevatedLocked] for [FilledButton].
  static ButtonStyle filledLocked({
    required Color backgroundColor,
    required Color foregroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    MaterialTapTargetSize? tapTargetSize,
    OutlinedBorder? shape,
  }) =>
      elevatedLocked(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        padding: padding,
        minimumSize: minimumSize,
        tapTargetSize: tapTargetSize,
        shape: shape,
      );
}
