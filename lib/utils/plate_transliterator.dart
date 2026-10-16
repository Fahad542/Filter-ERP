//
// Saudi / GCC vehicle-plate transliteration utility.
//
// WHY THIS EXISTS
// ───────────────
// Saudi plates carry Latin letters that correspond 1-to-1 with Arabic letters
// on the official Ministry of Interior chart.  Google Translate must NOT be
// used for plates because it mangles them.  This file handles transliteration
// purely with a lookup table — no network call, no async, always instant.
//
// USAGE
// ─────
//   // In any widget — pass langCode from Localizations.localeOf(context)
//   final display = PlateTransliterator.localize('SOT 578', langCode);
//   // Arabic  → "٥٧٨  س ع ط"
//   // English → "SOT 578"  (unchanged)
//
//   // Or call directly when you already know the locale is Arabic:
//   final ar = PlateTransliterator.toArabic('FUJ 901');
//   // → "٩٠١  F و ح"  // F is unchanged because it is not in the provided chart
//
// VISUAL ORDER
// ────────────
// Arabic plates are right-to-left: the digit block appears on the left side
// of the plate and the letter block on the right.  We return the string as
// "digits  letters" so that Flutter's RTL text rendering places them
// correctly without any extra direction overrides in the caller.
//
// LETTER MAP
// ──────────
// Source: Saudi MoI standard plate alphabet (14 → 22 letters depending on
// provided chart. Letters not in that chart (C, F, I, O, P, Q, W, Y …)
// are passed through unchanged so that GCC / custom plates still render.
//
// EXTENDING
// ─────────
// To support UAE, Kuwait, or other GCC alphabets, add their mappings in
// the `_extraMappings` extension point below and adjust `_looksLikePlate`.

class PlateTransliterator {
  PlateTransliterator._();

  // ── Saudi MoI letter → Arabic letter ──────────────────────────────────────
  static const Map<String, String> _letterMap = {
    // Only the letters from the provided Saudi plate chart are transliterated.
    // Any other Latin letter is kept unchanged.
    'A': 'أ',
    'B': 'ب',
    'J': 'ح',
    'D': 'د',
    'R': 'ر',
    'S': 'س',
    'X': 'ص',
    'T': 'ط',
    'E': 'ع',
    'G': 'ق',
    'K': 'ك',
    'L': 'ل',
    'Z': 'م',
    'N': 'ن',
    'H': 'ه',
    'U': 'و',
    'V': 'ى',
  };

  // ── Western → Arabic-Indic digits ─────────────────────────────────────────
  static const List<String> _westernDigits = ['0','1','2','3','4','5','6','7','8','9'];
  static const List<String> _arabicDigits  = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];

  // ── Plate pattern ──────────────────────────────────────────────────────────
  // Matches:  "SOT 578"  "FUJ578"  "AB-1234"  "345 - DFG"  "1-ABC-23"
  static final _plateRe = RegExp(r'^([A-Z]{1,4})[\s\-]?(\d{1,5})$');
  static final _digitsFirstPlateRe = RegExp(r'^(\d{1,5})\s*[-\s]?\s*([A-Z]{1,4})$');
  static final _oldStyleRe = RegExp(r'^(\d{1,4})\s*-\s*([A-Z]{1,4})\s*-\s*(\d{1,5})$');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns true when [text] looks like a vehicle plate number.
  static bool looksLikePlate(String text) {
    final v = _normalizeWesternDigits(text).trim().toUpperCase();
    return _plateRe.hasMatch(v) ||
        _digitsFirstPlateRe.hasMatch(v) ||
        _oldStyleRe.hasMatch(v);
  }

  /// Locale-aware entry point.
  ///
  /// Returns the Arabic transliteration when [languageCode] is `'ar'`,
  /// otherwise returns [plate] unchanged.
  static String localize(String plate, String languageCode) {
    if (languageCode != 'ar') return plate;
    return toArabic(plate);
  }

  /// Unconditionally converts [plate] to its Arabic representation.
  ///
  /// • Latin letters  → Arabic letters (space-separated).
  /// • Western digits → Arabic-Indic digits.
  /// • Unrecognised letters are kept as-is.
  /// • Non-plate strings are digit-localized only (safe fallback).
  static String toArabic(String plate) {
    final v = _normalizeWesternDigits(plate).trim().toUpperCase();
    if (v.isEmpty) return plate;

    // Modern plate: "SOT 578" / "FUJ578" / "AB-1234"
    final m = _plateRe.firstMatch(v);
    if (m != null) {
      return _buildArabicPlate(m.group(1)!, m.group(2)!);
    }

    // Already formatted digit-first plate from UI helpers: "345 - DFG".
    final mf = _digitsFirstPlateRe.firstMatch(v);
    if (mf != null) {
      return _buildArabicPlate(mf.group(2)!, mf.group(1)!);
    }

    // Old-style plate: "1-ABC-23"
    final m2 = _oldStyleRe.firstMatch(v);
    if (m2 != null) {
      // prefix digits + letter block + suffix digits
      final prefix  = _localizeDigits(m2.group(1)!);
      final letters = _transliterateLetters(m2.group(2)!);
      final suffix  = _localizeDigits(m2.group(3)!);
      return '$prefix-$letters-$suffix';
    }

    // Fallback: digit-localize only.
    return _localizeDigits(v);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _buildArabicPlate(String letters, String digits) {
    final arLetters = _transliterateLetters(letters);
    final arDigits  = _localizeDigits(digits);
    // RTL visual order: digits left, letters right → return "digits  letters".
    return '$arDigits  $arLetters';
  }

  /// Converts each letter to its Arabic equivalent, space-separated.
  static String _transliterateLetters(String letters) =>
      letters.split('').map((c) => _letterMap[c] ?? c).join(' ');

  /// Converts Arabic-Indic / Eastern Arabic-Indic digits back to Western digits
  /// before regex matching. This lets already-localized UI strings such as
  /// `٣٤٥ - DFG` still transliterate their Latin letters correctly.
  static String _normalizeWesternDigits(String text) {
    const arabicIndic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    const easternArabicIndic = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    var out = text;
    for (var i = 0; i < _westernDigits.length; i++) {
      out = out.replaceAll(arabicIndic[i], _westernDigits[i]);
      out = out.replaceAll(easternArabicIndic[i], _westernDigits[i]);
    }
    return out;
  }

  /// Replaces Western digits with Arabic-Indic digits.
  static String _localizeDigits(String text) {
    var out = text;
    for (var i = 0; i < _westernDigits.length; i++) {
      out = out.replaceAll(_westernDigits[i], _arabicDigits[i]);
    }
    return out;
  }
}
