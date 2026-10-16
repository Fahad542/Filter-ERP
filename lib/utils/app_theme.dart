import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_arabic_font_fallbacks.dart';
import 'app_colors.dart';

TextTheme _textThemeWithFamily(
  TextTheme theme,
  String family,
  List<String> fallback,
) {
  TextStyle? merge(TextStyle? s) {
    if (s == null) return null;
    return s.copyWith(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontWeight: family == kArabicFontFamily
          ? softenArabicFontWeight(s.fontWeight)
          : s.fontWeight,
      letterSpacing: s.letterSpacing ?? 0,
      height: s.height ?? 1.45,
    );
  }

  return theme.copyWith(
    displayLarge: merge(theme.displayLarge),
    displayMedium: merge(theme.displayMedium),
    displaySmall: merge(theme.displaySmall),
    headlineLarge: merge(theme.headlineLarge),
    headlineMedium: merge(theme.headlineMedium),
    headlineSmall: merge(theme.headlineSmall),
    titleLarge: merge(theme.titleLarge),
    titleMedium: merge(theme.titleMedium),
    titleSmall: merge(theme.titleSmall),
    bodyLarge: merge(theme.bodyLarge),
    bodyMedium: merge(theme.bodyMedium),
    bodySmall: merge(theme.bodySmall),
    labelLarge: merge(theme.labelLarge),
    labelMedium: merge(theme.labelMedium),
    labelSmall: merge(theme.labelSmall),
  );
}

/// Adds [fontFamilyFallback] per style so glyphs missing from Manrope (Arabic script)
/// render from Noto Sans Arabic without changing the Latin fontFamily.
TextTheme _manropeThemeWithArabicFallback(TextTheme manropeTheme) {
  final fb = appLatinPrimaryFontFallbacks();
  if (fb.isEmpty) return manropeTheme;

  TextStyle? merge(TextStyle? s) {
    if (s == null) return null;
    return s.copyWith(fontFamilyFallback: fb);
  }

  return manropeTheme.copyWith(
    displayLarge: merge(manropeTheme.displayLarge),
    displayMedium: merge(manropeTheme.displayMedium),
    displaySmall: merge(manropeTheme.displaySmall),
    headlineLarge: merge(manropeTheme.headlineLarge),
    headlineMedium: merge(manropeTheme.headlineMedium),
    headlineSmall: merge(manropeTheme.headlineSmall),
    titleLarge: merge(manropeTheme.titleLarge),
    titleMedium: merge(manropeTheme.titleMedium),
    titleSmall: merge(manropeTheme.titleSmall),
    bodyLarge: merge(manropeTheme.bodyLarge),
    bodyMedium: merge(manropeTheme.bodyMedium),
    bodySmall: merge(manropeTheme.bodySmall),
    labelLarge: merge(manropeTheme.labelLarge),
    labelMedium: merge(manropeTheme.labelMedium),
    labelSmall: merge(manropeTheme.labelSmall),
  );
}

class AppTheme {
  static ThemeData lightThemeFor(Locale locale) =>
      _buildTheme(Brightness.light, locale);

  static ThemeData darkThemeFor(Locale locale) =>
      _buildTheme(Brightness.dark, locale);

  static ThemeData get lightTheme => lightThemeFor(const Locale('en'));

  static ThemeData get darkTheme => darkThemeFor(const Locale('en'));

  static ThemeData _buildTheme(Brightness brightness, Locale locale) {
    final isArabic = appUsesArabicPrimaryFont(locale);
    final base =
        brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();

    final primaryFamily = isArabic ? kArabicFontFamily : kLatinFontFamily;
    final fallback = isArabic
        ? appArabicPrimaryFontFallbacks()
        : appLatinPrimaryFontFallbacks();

    final textTheme = isArabic
        ? _textThemeWithFamily(base.textTheme, primaryFamily, fallback)
        : _manropeThemeWithArabicFallback(
            GoogleFonts.manropeTextTheme(base.textTheme),
          );

    final primaryTextTheme = isArabic
        ? _textThemeWithFamily(base.primaryTextTheme, primaryFamily, fallback)
        : _manropeThemeWithArabicFallback(
            GoogleFonts.manropeTextTheme(base.primaryTextTheme),
          );

    final colorScheme = brightness == Brightness.light
        ? const ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.primaryLight,
            onPrimary: AppColors.onPrimaryLight,
            secondary: AppColors.secondaryLight,
            onSecondary: AppColors.onSecondaryLight,
            error: AppColors.errorLight,
            onError: AppColors.onErrorLight,
            background: AppColors.backgroundLight,
            onBackground: AppColors.onBackgroundLight,
            surface: AppColors.surfaceLight,
            onSurface: AppColors.onSurfaceLight,
          )
        : const ColorScheme(
            brightness: Brightness.dark,
            primary: AppColors.primaryDark,
            onPrimary: AppColors.onPrimaryDark,
            secondary: AppColors.secondaryDark,
            onSecondary: AppColors.onSecondaryDark,
            error: AppColors.errorDark,
            onError: AppColors.onErrorDark,
            background: AppColors.backgroundDark,
            onBackground: AppColors.onBackgroundDark,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.onSurfaceDark,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: primaryFamily,
      fontFamilyFallback: fallback,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.backgroundLight
          : AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
