import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bundled Arabic UI font (Noto Sans Arabic).
const String kArabicFontFamily = 'Noto Sans Arabic';

/// Bundled Latin UI font.
const String kLatinFontFamily = 'Manrope';

bool appUsesArabicPrimaryFont(Locale locale) =>
    locale.languageCode == 'ar';

/// Noto Sans Arabic Bold looks heavy at w700+; step down one notch in Arabic UI.
FontWeight softenArabicFontWeight(FontWeight? weight) {
  final index = (weight ?? FontWeight.w400).index;
  if (index >= FontWeight.w900.index) return FontWeight.w700;
  if (index >= FontWeight.w800.index) return FontWeight.w600;
  if (index >= FontWeight.w700.index) return FontWeight.w600;
  if (index >= FontWeight.w600.index) return FontWeight.w500;
  return weight ?? FontWeight.w400;
}

FontWeight localeFontWeight(BuildContext context, FontWeight weight) {
  if (!appUsesArabicPrimaryFont(Localizations.localeOf(context))) return weight;
  return softenArabicFontWeight(weight);
}

TextStyle applyAppLocaleTypography(BuildContext context, TextStyle style) {
  if (!appUsesArabicPrimaryFont(Localizations.localeOf(context))) return style;
  return style.copyWith(
    fontWeight: softenArabicFontWeight(style.fontWeight),
    fontFamily: style.fontFamily ?? kArabicFontFamily,
    fontFamilyFallback: style.fontFamilyFallback ?? appArabicPrimaryFontFallbacks(),
    letterSpacing: style.letterSpacing ?? 0,
    height: style.height ?? 1.45,
  );
}

/// Fallback when Manrope is primary (English UI with Arabic snippets).
List<String> appLatinPrimaryFontFallbacks() => const [kArabicFontFamily];

/// Fallback when Noto Sans Arabic is primary (Arabic UI with Latin snippets).
List<String> appArabicPrimaryFontFallbacks() => const [kLatinFontFamily];

/// Arabic script fallbacks appended to Manrope (English locale theme).
List<String> appArabicFontFallbacks() => appLatinPrimaryFontFallbacks();

/// Primary UI text style — Noto Sans Arabic in Arabic locale, Manrope otherwise.
TextStyle appManropeTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  Locale? locale,
}) {
  if (locale != null && appUsesArabicPrimaryFont(locale)) {
    return appArabicTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  final base = GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
  return base.copyWith(fontFamilyFallback: appLatinPrimaryFontFallbacks());
}

/// Explicit Arabic Naskh style (Noto Sans Arabic).
TextStyle appArabicTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: kArabicFontFamily,
    fontFamilyFallback: appArabicPrimaryFontFallbacks(),
    fontSize: fontSize,
    fontWeight: softenArabicFontWeight(fontWeight),
    color: color,
    height: height ?? 1.45,
    letterSpacing: letterSpacing ?? 0,
  );
}
