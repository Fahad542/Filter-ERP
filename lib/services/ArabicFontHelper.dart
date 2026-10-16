// lib/services/arabic_font_helper.dart
//
// Arabic Font Helper — uses bundled Noto Sans Arabic for Arabic UI.

import 'package:flutter/material.dart';

import '../utils/app_arabic_font_fallbacks.dart';

class ArabicFontHelper {
  ArabicFontHelper._();

  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  static bool isArabicLocale(Locale locale) => appUsesArabicPrimaryFont(locale);

  static TextStyle maybeArabicStyle(BuildContext context, [TextStyle? style]) {
    if (!isArabic(context)) return style ?? const TextStyle();
    return _applyArabicFont(style ?? const TextStyle());
  }

  static TextStyle arabicStyle([TextStyle? style]) =>
      _applyArabicFont(style ?? const TextStyle());

  static TextStyle _applyArabicFont(TextStyle style) {
    return style.copyWith(
      fontFamily: kArabicFontFamily,
      fontFamilyFallback: appArabicPrimaryFontFallbacks(),
      fontWeight: softenArabicFontWeight(style.fontWeight),
      height: style.height ?? 1.45,
      letterSpacing: 0,
    );
  }

  static TextTheme arabicTextTheme(TextTheme base) {
    TextStyle apply(TextStyle style) => _applyArabicFont(style);

    return base.copyWith(
      displayLarge: apply(base.displayLarge ?? const TextStyle()),
      displayMedium: apply(base.displayMedium ?? const TextStyle()),
      displaySmall: apply(base.displaySmall ?? const TextStyle()),
      headlineLarge: apply(base.headlineLarge ?? const TextStyle()),
      headlineMedium: apply(base.headlineMedium ?? const TextStyle()),
      headlineSmall: apply(base.headlineSmall ?? const TextStyle()),
      titleLarge: apply(base.titleLarge ?? const TextStyle()),
      titleMedium: apply(base.titleMedium ?? const TextStyle()),
      titleSmall: apply(base.titleSmall ?? const TextStyle()),
      bodyLarge: apply(base.bodyLarge ?? const TextStyle()),
      bodyMedium: apply(base.bodyMedium ?? const TextStyle()),
      bodySmall: apply(base.bodySmall ?? const TextStyle()),
      labelLarge: apply(base.labelLarge ?? const TextStyle()),
      labelMedium: apply(base.labelMedium ?? const TextStyle()),
      labelSmall: apply(base.labelSmall ?? const TextStyle()),
    );
  }

  static ThemeData arabicAwareTheme(ThemeData base, Locale locale) {
    if (!isArabicLocale(locale)) return base;
    return base.copyWith(
      textTheme: arabicTextTheme(base.textTheme),
      primaryTextTheme: arabicTextTheme(base.primaryTextTheme),
    );
  }

  static Widget wrap(BuildContext context, {required Widget child}) {
    if (!isArabic(context)) return child;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    );
  }
}
