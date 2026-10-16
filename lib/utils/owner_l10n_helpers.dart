import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locker_translation_mixin.dart';

/// Localize common inventory unit labels from API (liter, piece, …).
String ownerLocalizedUnit(AppLocalizations l10n, String unit) {
  switch (unit.trim().toLowerCase()) {
    case 'liter':
    case 'litre':
    case 'l':
      return l10n.ownerUnitLiter;
    case 'piece':
    case 'pieces':
      return l10n.ownerUnitPiece;
    case 'pcs':
    case 'pc':
      return l10n.ownerUnitPcs;
    case 'kg':
    case 'kilogram':
    case 'kilograms':
      return l10n.ownerUnitKg;
    case 'ml':
    case 'milliliter':
    case 'millilitre':
      return l10n.ownerUnitMl;
    case 'box':
    case 'boxes':
      return l10n.ownerUnitBox;
    case 'set':
    case 'sets':
      return l10n.ownerUnitSet;
    default:
      return unit;
  }
}

/// Display currency code for the active locale (SAR → ر.س in Arabic).
String ownerLocalizedCurrency(BuildContext context, String code) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return code;
  return ownerLocalizedCurrencyCode(l10n, code);
}

String ownerLocalizedCurrencyCode(AppLocalizations l10n, String code) {
  if (code.trim().toUpperCase() == 'SAR') return l10n.ownerCurrencySar;
  return code;
}

String ownerLocalizedWorkshopStatus(AppLocalizations l10n, String status) {
  switch (status.trim().toLowerCase()) {
    case 'approved':
      return l10n.ownerSettingsStatusApproved;
    case 'pending':
      return l10n.ownerSettingsStatusPending;
    case 'rejected':
      return l10n.ownerSettingsStatusRejected;
    case 'active':
      return l10n.ownerSettingsStatusActive;
    default:
      return status.toUpperCase();
  }
}

/// Format money for Owner UI: `SAR 12.50` → `ر.س ١٢.٥٠` in Arabic.
String ownerFormatMoney(
  BuildContext context,
  num amount, {
  String currency = 'SAR',
  int decimals = 2,
  bool compact = false,
}) {
  final locale = Localizations.localeOf(context);
  final l10n = AppLocalizations.of(context);
  final code = l10n != null
      ? ownerLocalizedCurrencyCode(l10n, currency)
      : (locale.languageCode == 'ar' && currency.toUpperCase() == 'SAR'
          ? 'ر.س'
          : currency);
  return ownerFormatMoneyForLanguage(
    amount,
    languageCode: locale.languageCode,
    currency: code,
    decimals: decimals,
    compact: compact,
  );
}

/// Language-aware money formatter (no BuildContext).
/// [currency] should already be localized (e.g. ر.س) when [languageCode] is ar.
String ownerFormatMoneyForLanguage(
  num amount, {
  required String languageCode,
  String currency = 'SAR',
  int decimals = 2,
  bool compact = false,
}) {
  final v = amount.toDouble();
  final sign = v < 0 ? '-' : '';
  final abs = v.abs();
  final String number;
  final isAr = languageCode == 'ar';
  if (compact) {
    if (abs >= 1000000) {
      final n = (abs / 1000000).toStringAsFixed(2);
      number = isAr ? '$n مليون' : '${n}M';
    } else if (abs >= 1000) {
      final n = (abs / 1000).toStringAsFixed(2);
      number = isAr ? '$n ألف' : '${n}k';
    } else {
      number = abs.toStringAsFixed(decimals);
    }
  } else {
    number = abs.toStringAsFixed(decimals);
  }
  final raw = '$sign$currency $number';
  return AppTranslationService.localizeDigitsForLanguage(raw, languageCode);
}

/// Localize digits in an already-built display string when locale is Arabic.
String ownerLocalizeDigits(BuildContext context, String text) {
  return AppTranslationService.localizeDigitsForLanguage(
    text,
    Localizations.localeOf(context).languageCode,
  );
}
