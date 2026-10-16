import 'package:flutter/material.dart';
import 'locker_translation_mixin.dart';
import '../utils/app_arabic_font_fallbacks.dart';

/// Text widget for dynamic strings coming from API/database.
///
/// Optimized for POS lists/grids:
/// - English locale returns a normal Text immediately.
/// - Empty/already-Arabic/numeric/code/phone/plate values skip translation.
/// - Same text + locale is cached.
/// - Same text + locale in-flight Future is reused, so rebuilds do not start
///   duplicate translation work.
class LocalizedApiText extends StatelessWidget {
  const LocalizedApiText(
    this.text, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.uppercase = false,
  });

  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  /// When true, applies .toUpperCase() to the resolved string.
  /// Arabic text is not upper-cased.
  final bool uppercase;

  /// Optional manual clear hook for locale/logout/debug flows.
  static void clearTranslationCache() => _LocalizedApiTextCache.clear();

  /// Public helper for non-widget places that need the same optimized cache.
  static Future<String> resolve(String text, String languageCode) {
    if (!_LocalizedApiTextCache.shouldTranslate(text, languageCode)) {
      return Future<String>.value(
        AppTranslationService.localizeDigitsForLanguage(text, languageCode),
      );
    }
    final cached = _LocalizedApiTextCache.cachedValue(text, languageCode);
    if (cached != null) return Future<String>.value(cached);
    return _LocalizedApiTextCache.translate(text, languageCode);
  }

  /// Fire-and-forget warmup for visible list/grid items.
  static void precache(Iterable<String> texts, String languageCode) {
    if (languageCode != 'ar') return;
    for (final text in texts) {
      final clean = text.trim();
      if (clean.isEmpty) continue;
      if (_LocalizedApiTextCache.cachedValue(clean, languageCode) != null) {
        continue;
      }
      if (!_LocalizedApiTextCache.shouldTranslate(clean, languageCode)) {
        continue;
      }
      _LocalizedApiTextCache.translate(clean, languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final raw = text;
    final instant = AppTranslationService.localizeDigitsForLanguage(
      raw,
      langCode,
    );

    if (!_LocalizedApiTextCache.shouldTranslate(raw, langCode)) {
      return _text(context, _formatForDisplay(instant, langCode));
    }

    final cached = _LocalizedApiTextCache.cachedValue(raw, langCode);
    if (cached != null) {
      return _text(context, _formatForDisplay(cached, langCode));
    }

    return FutureBuilder<String>(
      key: ValueKey<String>('$langCode::$raw::$uppercase'),
      future: _LocalizedApiTextCache.translate(raw, langCode),
      initialData: instant,
      builder: (context, snapshot) {
        final resolved = snapshot.data ?? instant;
        return _text(context, _formatForDisplay(resolved, langCode));
      },
    );
  }

  String _formatForDisplay(String value, String langCode) {
    if (uppercase && langCode != 'ar') return value.toUpperCase();
    return value;
  }

  Widget _text(BuildContext context, String display) {
    return Text(
      display,
      style: style == null ? null : applyAppLocaleTypography(context, style!),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

class _LocalizedApiTextCache {
  static const int _maxEntries = 1000;
  static final Map<String, String> _values = <String, String>{};
  static final Map<String, Future<String>> _futures = <String, Future<String>>{};

  static final RegExp _latinLetter = RegExp(r'[A-Za-z]');
  static final RegExp _arabicLetter = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  static final RegExp _digit = RegExp(r'[0-9٠-٩۰-۹]');

  static String _key(String raw, String langCode) => '$langCode\u0000${raw.trim().toLowerCase()}';

  static void clear() {
    _values.clear();
    _futures.clear();
  }

  static String? cachedValue(String raw, String langCode) {
    return _values[_key(raw, langCode)];
  }

  static Future<String> translate(String raw, String langCode) {
    final clean = raw.trim();
    final k = _key(clean, langCode);
    final cached = _values[k];
    if (cached != null) return Future<String>.value(cached);

    return _futures.putIfAbsent(k, () async {
      try {
        final translated = await AppTranslationService
            .localizedDynamicValueForLanguage(clean, langCode);
        final safe = translated.trim().isEmpty
            ? AppTranslationService.localizeDigitsForLanguage(clean, langCode)
            : translated;
        _remember(k, safe);
        return safe;
      } catch (_) {
        final fallback = AppTranslationService.localizeDigitsForLanguage(
          clean,
          langCode,
        );
        _remember(k, fallback);
        return fallback;
      } finally {
        _futures.remove(k);
      }
    });
  }

  static void _remember(String key, String value) {
    if (_values.length >= _maxEntries) {
      _values.remove(_values.keys.first);
    }
    _values[key] = value;
  }

  static bool shouldTranslate(String raw, String langCode) {
    final clean = raw.trim();
    if (clean.isEmpty) return false;

    // English UI should show raw API values instantly.
    if (langCode != 'ar') return false;

    // Already Arabic/mixed Arabic: only digit localization is needed.
    if (_arabicLetter.hasMatch(clean)) return false;

    // No Latin words means there is nothing useful to machine-translate.
    if (!_latinLetter.hasMatch(clean)) return false;

    // Avoid translating short identifiers/codes that must remain stable.
    if (_looksLikePlateInvoicePhoneOrCode(clean)) return false;

    return true;
  }

  static bool _looksLikePlateInvoicePhoneOrCode(String clean) {
    final normalized = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    final upper = normalized.toUpperCase();

    // Invoice/order/customer identifiers: INV-00002, JOB-12, ORD_4, etc.
    if (RegExp(r'^[A-Z]{2,6}[-_/# ]?\d+[A-Z0-9\-_/]*$').hasMatch(upper)) {
      return true;
    }

    // Saudi plate display formats: QSD - 1234, 1234 - QSD, ASD 1231, 1231ASD.
    if (RegExp(r'^[A-Z]{1,4}\s*[- ]\s*\d{1,5}$').hasMatch(upper)) {
      return true;
    }
    if (RegExp(r'^\d{1,5}\s*[- ]\s*[A-Z]{1,4}$').hasMatch(upper)) {
      return true;
    }
    if (RegExp(r'^[A-Z]{1,4}\d{1,5}$').hasMatch(upper)) {
      return true;
    }
    if (RegExp(r'^\d{1,5}[A-Z]{1,4}$').hasMatch(upper)) {
      return true;
    }

    // Phone-like values with optional +, spaces or hyphens.
    if (RegExp(r'^\+?[0-9٠-٩۰-۹][0-9٠-٩۰-۹\s\-()]{5,}$')
        .hasMatch(normalized)) {
      return true;
    }

    // Very short all-caps alphanumeric codes with digits should not be translated.
    if (normalized.length <= 12 &&
        _digit.hasMatch(normalized) &&
        RegExp(r'^[A-Z0-9\-_/ .#]+$').hasMatch(upper)) {
      return true;
    }

    return false;
  }
}

/// Nullable variant — renders an empty string when [text] is null.
class LocalizedApiTextNullable extends StatelessWidget {
  const LocalizedApiTextNullable(
    this.text, {
    super.key,
    this.style,
    this.overflow,
    this.maxLines,
    this.textAlign,
  });

  final String? text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
    return LocalizedApiText(
      text!,
      style: style,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
