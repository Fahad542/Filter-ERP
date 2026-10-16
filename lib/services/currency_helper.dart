// lib/services/currency_helper.dart
//
// CurrencyHelper — locale-aware currency formatting.
//
// In English: "SAR 120.50"
// In Arabic:  "١٢٠.٥٠ ر.س"  (symbol on right, Arabic-Indic numerals)
//
// USAGE:
//   // In widgets:
//   Text(CurrencyHelper.format(context, amount))
//   Text(CurrencyHelper.symbol(context)) // just "SAR" or "ر.س"
//
//   // In view models (without context, using languageCode):
//   CurrencyHelper.formatForLang(amount, 'ar')
//   CurrencyHelper.formatForLang(amount, 'en')

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class CurrencyHelper {
  CurrencyHelper._();

  // ── Symbol ──────────────────────────────────────────────────────────────────

  /// Returns the currency symbol for the current locale.
  /// English → "SAR"  |  Arabic → "ر.س"
  static String symbol(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return 'SAR';
    final lang = Localizations.localeOf(context).languageCode;
    return lang == 'ar' ? l10n.currencySymbolAr : l10n.currencySymbol;
  }

  /// Returns currency symbol without context, based on language code.
  static String symbolForLang(String languageCode) =>
      languageCode == 'ar' ? 'ر.س' : 'SAR';

  // ── Formatting ───────────────────────────────────────────────────────────────

  /// Formats [amount] with the locale-correct currency symbol and digit style.
  ///
  /// English:  "SAR 120.50"
  /// Arabic:   "١٢٠.٥٠ ر.س"
  static String format(BuildContext context, double amount, {int decimals = 2}) {
    final lang = Localizations.localeOf(context).languageCode;
    return formatForLang(amount, lang, decimals: decimals);
  }

  /// Formats [amount] for a given [languageCode] (no BuildContext needed).
  static String formatForLang(double amount, String languageCode, {int decimals = 2}) {
    final formatted = amount.toStringAsFixed(decimals);
    if (languageCode == 'ar') {
      final arabicNumerals = _toArabicNumerals(formatted);
      return '$arabicNumerals ر.س';
    }
    return 'SAR $formatted';
  }

  /// Formats from a string that may already be a number.
  static String formatString(BuildContext context, String amountStr, {int decimals = 2}) {
    final parsed = double.tryParse(amountStr) ?? 0.0;
    return format(context, parsed, decimals: decimals);
  }

  // ── Negative formatting ─────────────────────────────────────────────────────

  /// For showing discounts: "-SAR 10.00" or "١٠.٠٠- ر.س"
  static String formatNegative(BuildContext context, double amount, {int decimals = 2}) {
    final lang = Localizations.localeOf(context).languageCode;
    final formatted = amount.abs().toStringAsFixed(decimals);
    if (lang == 'ar') {
      final arabicNumerals = _toArabicNumerals(formatted);
      return '$arabicNumerals- ر.س';
    }
    return '-SAR $formatted';
  }

  // ── Arabic-Indic numeral conversion ─────────────────────────────────────────

  /// Converts Western Arabic numerals (0-9) to Arabic-Indic numerals (٠-٩).
  /// This is optional — some Arabic UIs keep Western numerals for amounts.
  /// Set [useArabicIndic] = false to keep Western numerals even in Arabic.
  static String _toArabicNumerals(String input) {
    // For POS applications, Western numerals in Arabic context are standard.
    // Uncomment below to switch to Arabic-Indic numerals if needed:
    // const westernToArabicIndic = {
    //   '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
    //   '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩',
    // };
    // return input.split('').map((c) => westernToArabicIndic[c] ?? c).join();
    return input; // Keep Western numerals for financial clarity
  }
}
