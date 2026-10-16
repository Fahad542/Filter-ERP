import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_formatters.dart' show EnglishNumberFormatter, shapeSaudiBikePlateForLiveInput, shapeSaudiPlateForLiveInput;

/// Supported GCC plate countries (ISO 3166-1 alpha-2).
class GccPlateCountry {
  const GccPlateCountry({
    required this.code,
    required this.nameEn,
    required this.nameAr,
  });

  final String code;
  final String nameEn;
  final String nameAr;

  static const sa = GccPlateCountry(
    code: 'SA',
    nameEn: 'Saudi Arabia',
    nameAr: 'السعودية',
  );
  static const ae = GccPlateCountry(
    code: 'AE',
    nameEn: 'UAE',
    nameAr: 'الإمارات',
  );
  static const kw = GccPlateCountry(
    code: 'KW',
    nameEn: 'Kuwait',
    nameAr: 'الكويت',
  );
  static const bh = GccPlateCountry(
    code: 'BH',
    nameEn: 'Bahrain',
    nameAr: 'البحرين',
  );
  static const qa = GccPlateCountry(
    code: 'QA',
    nameEn: 'Qatar',
    nameAr: 'قطر',
  );
  static const om = GccPlateCountry(
    code: 'OM',
    nameEn: 'Oman',
    nameAr: 'عُمان',
  );

  static const List<GccPlateCountry> all = [sa, ae, kw, bh, qa, om];

  static GccPlateCountry? tryParse(String? code) {
    final c = (code ?? '').trim().toUpperCase();
    if (c.isEmpty) return null;
    for (final country in all) {
      if (country.code == c) return country;
    }
    return null;
  }

  static GccPlateCountry parseOrDefault(String? code) =>
      tryParse(code) ?? sa;
}

/// UAE emirates for plate normalization (`AE{EMIRATE}{plate}`).
class UaeEmirate {
  const UaeEmirate({required this.key, required this.nameEn, required this.nameAr});

  final String key;
  final String nameEn;
  final String nameAr;

  static const List<UaeEmirate> all = [
    UaeEmirate(key: 'AbuDhabi', nameEn: 'Abu Dhabi', nameAr: 'أبوظبي'),
    UaeEmirate(key: 'Dubai', nameEn: 'Dubai', nameAr: 'دبي'),
    UaeEmirate(key: 'Sharjah', nameEn: 'Sharjah', nameAr: 'الشارقة'),
    UaeEmirate(key: 'Ajman', nameEn: 'Ajman', nameAr: 'عجمان'),
    UaeEmirate(key: 'UmmAlQuwain', nameEn: 'Umm Al Quwain', nameAr: 'أم القيوين'),
    UaeEmirate(key: 'RasAlKhaimah', nameEn: 'Ras Al Khaimah', nameAr: 'رأس الخيمة'),
    UaeEmirate(key: 'Fujairah', nameEn: 'Fujairah', nameAr: 'الفجيرة'),
  ];

  static UaeEmirate? tryParse(String? key) {
    final k = (key ?? '').trim();
    if (k.isEmpty) return null;
    for (final e in all) {
      if (e.key == k) return e;
    }
    return null;
  }

  static UaeEmirate parseOrDefault(String? key) => tryParse(key) ?? all[1];
}

/// GCC plate registration — display vs normalized vs structured fields.
///
/// Matches backend `gcc-plate.util.ts` / `vehicle-plate.persistence.ts`.
class GccPlateRegistration {
  final String countryCode;
  final String display;
  final String normalized;
  final String plateNumber;
  final String plateLettersEn;
  final String plateLettersAr;
  final String? emirate;

  const GccPlateRegistration({
    this.countryCode = 'SA',
    required this.display,
    required this.normalized,
    this.plateNumber = '',
    this.plateLettersEn = '',
    this.plateLettersAr = '',
    this.emirate,
  });

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'display': display,
        'normalized': normalized,
        if (plateNumber.isNotEmpty) 'plateNumber': plateNumber,
        if (plateLettersEn.isNotEmpty) 'plateLettersEn': plateLettersEn,
        if (plateLettersAr.isNotEmpty) 'plateLettersAr': plateLettersAr,
        if (emirate != null && emirate!.trim().isNotEmpty) 'emirate': emirate,
      };
}

const _saArabicToLatin = <String, String>{
  'أ': 'A', 'ا': 'A', 'آ': 'A', 'إ': 'A',
  'ب': 'B', 'ح': 'J', 'ج': 'J', 'د': 'D', 'ر': 'R', 'س': 'S', 'ص': 'X',
  'ط': 'T', 'ع': 'E', 'ق': 'G', 'ك': 'K', 'ل': 'L', 'م': 'Z', 'ن': 'N',
  'ه': 'H', 'و': 'U', 'ى': 'V', 'ي': 'V',
};

const _latinToSaArabic = <String, String>{
  'A': 'أ', 'B': 'ب', 'J': 'ح', 'D': 'د', 'R': 'ر', 'S': 'س', 'X': 'ص',
  'T': 'ط', 'E': 'ع', 'G': 'ق', 'K': 'ك', 'L': 'ل', 'Z': 'م', 'N': 'ن',
  'H': 'ه', 'U': 'و', 'V': 'ى',
};

String _westernizeDigits(String text) =>
    EnglishNumberFormatter.convert(text);

bool _isDigit(String c) => RegExp(r'^[0-9]$').hasMatch(c);
bool _isLatin(String c) => RegExp(r'^[a-zA-Z]$').hasMatch(c);
bool _isArabic(String c) => RegExp(r'^[\u0621-\u064A]$').hasMatch(c);

String _compactUpper(String raw) =>
    _westernizeDigits(raw).replaceAll(RegExp(r'[\s\-\|]'), '').toUpperCase();

String _countryPrefix(String countryCode, {String? emirate}) {
  final cc = countryCode.toUpperCase();
  switch (cc) {
    case 'AE':
      final em = UaeEmirate.parseOrDefault(emirate).key.toUpperCase();
      return 'AE$em';
    case 'KW':
      return 'KW';
    case 'BH':
      return 'BH';
    case 'QA':
      return 'QA';
    case 'OM':
      return 'OM';
    default:
      return '';
  }
}

/// Parse user plate input into structured registration (default Saudi).
GccPlateRegistration parseGccPlate(
  String? raw, {
  String countryCode = 'SA',
  String? emirate,
}) {
  final cc = GccPlateCountry.parseOrDefault(countryCode).code;
  final displaySource = (raw ?? '').trim();
  if (displaySource.isEmpty) {
    return GccPlateRegistration(countryCode: cc, display: '', normalized: '');
  }

  final western = _westernizeDigits(displaySource);
  final digits = StringBuffer();
  final latin = <String>[];
  final arabic = <String>[];

  for (final ch in western.split('')) {
    if (_isDigit(ch)) {
      digits.write(ch);
    } else if (_isLatin(ch)) {
      latin.add(ch.toUpperCase());
    } else if (_isArabic(ch)) {
      arabic.add(ch);
    }
  }

  final latinFromArabic = arabic
      .map((c) => _saArabicToLatin[c] ?? '')
      .where((c) => c.isNotEmpty)
      .join();

  final plateNumber = digits.toString();
  final plateLettersEn = latin.join() + latinFromArabic;
  final plateLettersAr = arabic.isNotEmpty
      ? arabic.join(' ')
      : plateLettersEn
          .split('')
          .map((c) => _latinToSaArabic[c] ?? c)
          .join(' ');

  var body = '${plateNumber}${plateLettersEn}'.toUpperCase();
  if (body.isEmpty) body = _compactUpper(displaySource);

  var normalized = body;
  final prefix = _countryPrefix(cc, emirate: emirate);
  if (prefix.isNotEmpty && normalized.isNotEmpty) {
    normalized = '$prefix$normalized';
  }

  final display = _hasArabic(displaySource)
      ? displaySource
      : (plateLettersEn.isNotEmpty && plateNumber.isNotEmpty)
          ? '$plateLettersEn - $plateNumber'
          : displaySource;

  return GccPlateRegistration(
    countryCode: cc,
    display: display,
    normalized: normalized,
    plateNumber: plateNumber,
    plateLettersEn: plateLettersEn,
    plateLettersAr: plateLettersAr,
    emirate: cc == 'AE' ? UaeEmirate.parseOrDefault(emirate).key : emirate,
  );
}

bool _hasArabic(String s) => RegExp(r'[\u0621-\u064A]').hasMatch(s);

/// Legacy helper — returns [normalized] for search/API dedup (Saudi default).
String canonicalSaudiPlateForApi(String? raw) =>
    canonicalGccPlateForApi(raw, countryCode: 'SA');

/// Normalized plate key for search/API dedup.
String canonicalGccPlateForApi(
  String? raw, {
  String countryCode = 'SA',
  String? emirate,
}) =>
    parseGccPlate(raw, countryCode: countryCode, emirate: emirate).normalized;

bool _isEnglishPlateLetter(String c) => RegExp(r'^[a-zA-Z]$').hasMatch(c);
bool _isArabicPlateLetter(String c) =>
    RegExp(r'^[\u0621-\u064A]$').hasMatch(c);

/// Validates Saudi plates: exactly 3 letters and 1–4 digits (e.g. `ABC - 4`).
String? validateSaudiPlateInput(
  String? raw, {
  required String emptyMessage,
  required String threeLettersMessage,
  required String digitsMessage,
  required String letterCharsMessage,
}) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) return emptyMessage;

  final reg = parseGccPlate(trimmed, countryCode: 'SA');

  if (reg.plateLettersEn.length != 3) {
    return threeLettersMessage;
  }
  if (!RegExp(r'^[0-9]{1,4}$').hasMatch(reg.plateNumber)) {
    return digitsMessage;
  }

  final western = _westernizeDigits(trimmed);
  for (final ch in western.split('')) {
    if (_isDigit(ch) || ch == ' ' || ch == '-' || ch == '|') continue;
    if (!_isEnglishPlateLetter(ch) && !_isArabicPlateLetter(ch)) {
      return letterCharsMessage;
    }
  }

  return null;
}

/// Saudi motorcycle plates: exactly 2 letters and 4 digits.
String? validateSaudiBikePlateInput(
  String? raw, {
  required String emptyMessage,
  required String twoLettersMessage,
  required String fourDigitsMessage,
  required String letterCharsMessage,
}) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) return emptyMessage;

  final reg = parseGccPlate(trimmed, countryCode: 'SA');

  if (reg.plateLettersEn.length != 2) {
    return twoLettersMessage;
  }
  if (!RegExp(r'^[0-9]{4}$').hasMatch(reg.plateNumber)) {
    return fourDigitsMessage;
  }

  final western = _westernizeDigits(trimmed);
  for (final ch in western.split('')) {
    if (_isDigit(ch) || ch == ' ' || ch == '-' || ch == '|') continue;
    if (!_isEnglishPlateLetter(ch) && !_isArabicPlateLetter(ch)) {
      return letterCharsMessage;
    }
  }

  return null;
}

/// Validates GCC plates for the selected country.
String? validateGccPlateInput(
  String? raw, {
  required String countryCode,
  String? emirate,
  required String emptyMessage,
  required String saudiThreeLettersMessage,
  required String saudiDigitsMessage,
  required String saudiLetterCharsMessage,
  required String gccFormatMessage,
  required String emirateRequiredMessage,
}) {
  final cc = GccPlateCountry.parseOrDefault(countryCode).code;
  if (cc == 'SA') {
    return validateSaudiPlateInput(
      raw,
      emptyMessage: emptyMessage,
      threeLettersMessage: saudiThreeLettersMessage,
      digitsMessage: saudiDigitsMessage,
      letterCharsMessage: saudiLetterCharsMessage,
    );
  }

  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) return emptyMessage;
  if (cc == 'AE' && (emirate == null || emirate.trim().isEmpty)) {
    return emirateRequiredMessage;
  }

  final reg = parseGccPlate(trimmed, countryCode: cc, emirate: emirate);
  if (reg.plateLettersEn.isEmpty || reg.plateNumber.isEmpty) {
    return gccFormatMessage;
  }
  if (reg.plateLettersEn.length > 4 || reg.plateNumber.length > 6) {
    return gccFormatMessage;
  }

  final western = _westernizeDigits(trimmed);
  for (final ch in western.split('')) {
    if (_isDigit(ch) || ch == ' ' || ch == '-' || ch == '|') continue;
    if (!_isEnglishPlateLetter(ch) && !_isArabicPlateLetter(ch)) {
      return saudiLetterCharsMessage;
    }
  }
  return null;
}

/// Live-input formatter for Saudi motorcycle plates (2 letters + 4 digits).
TextInputFormatter saudiBikePlateInputFormatter({
  VoidCallback? onRejectedDigitBeyondFour,
  VoidCallback? onRejectedLetterBeyondTwo,
}) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    final raw = newValue.text
        .replaceAll(RegExp(r'[\s\-\|]'), '')
        .toUpperCase();
    final normalized = EnglishNumberFormatter.convert(raw);
    if (normalized.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final shaped = shapeSaudiBikePlateForLiveInput(normalized);
    if (shaped.rejectedExtraLetter && onRejectedLetterBeyondTwo != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onRejectedLetterBeyondTwo();
      });
    }
    if (shaped.rejectedExtraDigit && onRejectedDigitBeyondFour != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onRejectedDigitBeyondFour();
      });
    }
    final formatted = shaped.displayText;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  });
}

/// Live-input formatter for GCC plates (Saudi uses strict 3+4 shaping).
TextInputFormatter gccPlateInputFormatter({
  required String countryCode,
  VoidCallback? onRejectedDigitBeyondFour,
  VoidCallback? onRejectedLetterBeyondThree,
}) {
  final cc = GccPlateCountry.parseOrDefault(countryCode).code;
  if (cc == 'SA') {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final raw = newValue.text
          .replaceAll(RegExp(r'[\s\-\|]'), '')
          .toUpperCase();
      final normalized = EnglishNumberFormatter.convert(raw);
      if (normalized.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      final shaped = shapeSaudiPlateForLiveInput(normalized);
      if (shaped.rejectedExtraLetter && onRejectedLetterBeyondThree != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          onRejectedLetterBeyondThree();
        });
      }
      if (shaped.rejectedExtraDigit && onRejectedDigitBeyondFour != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          onRejectedDigitBeyondFour();
        });
      }
      final formatted = shaped.displayText;
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  return TextInputFormatter.withFunction((oldValue, newValue) {
    final raw = EnglishNumberFormatter.convert(newValue.text);
    final compact = _compactUpper(raw);
    if (compact.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final shaped = _shapeGenericGccPlateLive(compact);
    return TextEditingValue(
      text: shaped,
      selection: TextSelection.collapsed(offset: shaped.length),
    );
  });
}

String _shapeGenericGccPlateLive(String compact) {
  final digits = StringBuffer();
  final letters = StringBuffer();
  for (final ch in compact.split('')) {
    if (_isDigit(ch)) {
      if (digits.length < 6) digits.write(ch);
    } else if (_isLatin(ch) || _isArabic(ch)) {
      if (letters.length < 4) {
        letters.write(
          _isArabic(ch) ? (_saArabicToLatin[ch] ?? ch) : ch.toUpperCase(),
        );
      }
    }
  }
  final d = digits.toString();
  final l = letters.toString();
  if (l.isNotEmpty && d.isNotEmpty) return '$l - $d';
  if (l.isNotEmpty) return l;
  return d;
}
