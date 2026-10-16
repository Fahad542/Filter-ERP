import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'gcc_plate.dart' as gcc_plate;

export 'gcc_plate.dart'
    show
        parseGccPlate,
        GccPlateRegistration,
        GccPlateCountry,
        UaeEmirate,
        canonicalGccPlateForApi;

/// Invoice date/time patterns — pattern-only (no named locale) so PDF build works
/// in background isolates without [initializeDateFormatting].
final DateFormat _invoiceLegalDateFmt = DateFormat('dd/MM/yyyy');
final DateFormat _invoiceIssuedAtDateTimeFmt = DateFormat('dd/MM/yyyy hh:mm a');
final DateFormat _invoiceIssuedAtClockFmt = DateFormat('hh:mm a');

/// Tax / legal invoice date — **date only** (`dd/MM/yyyy`). Ignores time on ISO strings
/// (avoids showing `00:00` when the backend sends midnight).
String formatInvoiceLegalDate(String? invoiceDateIso) {
  final raw = invoiceDateIso?.trim() ?? '';
  if (raw.isEmpty) return '—';
  final datePart = raw.split('T').first.split(' ').first.trim();
  var d = DateTime.tryParse(raw);
  if (d == null && datePart.length <= 10) {
    d = DateTime.tryParse('${datePart}T00:00:00');
  }
  if (d != null) {
    return _invoiceLegalDateFmt.format(DateTime(d.year, d.month, d.day));
  }
  if (datePart.isNotEmpty) return datePart;
  return '—';
}

/// Full date+time when the invoice was **issued** (`dd/MM/yyyy hh:mm a` local; no seconds).
/// Returns `null` when [issuedAtIso] is empty or unparseable.
String? formatInvoiceIssuedAtDateTime(String? issuedAtIso) {
  final raw = issuedAtIso?.trim() ?? '';
  if (raw.isEmpty) return null;
  final d = DateTime.tryParse(raw);
  if (d == null) return null;
  return _invoiceIssuedAtDateTimeFmt.format(d.toLocal());
}

/// Clock time only (`hh:mm a` local; no seconds). Returns `null` for legacy rows with no `issuedAt`.
String? formatInvoiceIssuedAtClock(String? issuedAtIso) {
  final raw = issuedAtIso?.trim() ?? '';
  if (raw.isEmpty) return null;
  final d = DateTime.tryParse(raw);
  if (d == null) return null;
  return _invoiceIssuedAtClockFmt.format(d.toLocal());
}

/// Same digit rules as WhatsApp/Bevatel E.164: returns `966` + NSN, digits only, or `null`.
String? normalizeSaudiMobileTo966Digits(String? raw) {
  var d = raw == null
      ? ''
      : RegExp(r'\d').allMatches(raw).map((m) => m.group(0)!).join();
  if (d.isEmpty) return null;
  if (d.length == 10 && d.startsWith('05')) {
    d = '966${d.substring(1)}';
  }
  if (d.length == 9 && d.startsWith('5')) {
    d = '966$d';
  }
  if (d.length == 10 && d.startsWith('5')) {
    d = '966$d';
  }
  if (d.length == 10 && d.startsWith('3') && !d.startsWith('35')) {
    d = '9665${d.substring(1)}';
  }
  if (!d.startsWith('966')) {
    return null;
  }
  if (d.length > 12) {
    d = d.substring(0, 12);
  }
  if (d.length < 11) {
    return null;
  }
  return d;
}

/// Shows **+966** with spacing (e.g. `+966 56 535 6263`) for KSA mobiles. Otherwise trimmed [raw] or `—`.
String formatInvoiceMobileForDisplay(String? raw) {
  final d = normalizeSaudiMobileTo966Digits(raw);
  if (d == null) {
    final t = raw?.trim() ?? '';
    return t.isEmpty ? '—' : t;
  }
  final nsn = d.substring(3);
  if (nsn.length == 9) {
    return '+966 ${nsn.substring(0, 2)} ${nsn.substring(2, 5)} ${nsn.substring(5, 9)}';
  }
  return '+$d';
}

/// Display helper: plates are stored compact as **letters then digits** (e.g. `DDS1234`).
/// UI shows **[letters] - [digits]** for quicker alphabet scanning.
///
/// Recognizes leading digits + trailing letters, or leading letters + trailing digits.
/// Otherwise returns [raw] trimmed unchanged.
String formatVehiclePlateLettersFirst(String? raw) {
  final original = (raw ?? '').trim();
  if (original.isEmpty) return original;

  final converted = EnglishNumberFormatter.convert(original);
  final n = converted.replaceAll(RegExp(r'[\s\-\|]'), '');
  if (n.isEmpty) return original;

  bool isDigit(String c) => RegExp(r'^[0-9]$').hasMatch(c);
  bool isLatinLetter(String c) => RegExp(r'^[A-Za-z]$').hasMatch(c);
  bool isArabicLetter(String c) => RegExp(r'^[\u0621-\u064A]$').hasMatch(c);
  bool isLetterChar(String c) => isLatinLetter(c) || isArabicLetter(c);

  String upperLatin(String s) {
    final b = StringBuffer();
    for (final ch in s.split('')) {
      if (RegExp(r'^[a-z]$').hasMatch(ch)) {
        b.write(ch.toUpperCase());
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  if (isDigit(n[0])) {
    var i = 0;
    while (i < n.length && isDigit(n[i])) i++;
    final digitPart = n.substring(0, i);
    final letterPart = n.substring(i);
    if (digitPart.isNotEmpty &&
        letterPart.isNotEmpty &&
        letterPart.split('').every(isLetterChar)) {
      return '${upperLatin(letterPart)} - $digitPart';
    }
  } else if (isLetterChar(n[0])) {
    var i = 0;
    while (i < n.length && isLetterChar(n[i])) i++;
    final letterPart = n.substring(0, i);
    final rest = n.substring(i);
    if (letterPart.isNotEmpty &&
        rest.isNotEmpty &&
        rest.split('').every(isDigit)) {
      return '${upperLatin(letterPart)} - $rest';
    }
  }

  return original;
}

bool _saudiPlateLetterForLiveInput(String ch) {
  return RegExp(r'^[A-Z]$').hasMatch(ch) ||
      RegExp(r'^[\u0621-\u064A]$').hasMatch(ch);
}

/// Output of [shapeSaudiPlateForLiveInput] for Saudi plate fields (Add Customer + invoice dialog).
class SaudiPlateLiveShape {
  const SaudiPlateLiveShape({
    required this.displayText,
    this.rejectedExtraLetter = false,
    this.rejectedExtraDigit = false,
  });

  final String displayText;
  final bool rejectedExtraLetter;
  final bool rejectedExtraDigit;
}

SaudiPlateLiveShape _shapeSaudiPlateDigitsFirstLive(String raw) {
  final digits = StringBuffer();
  final letters = StringBuffer();
  var seenLetter = false;
  var rejL = false;
  var rejD = false;
  for (final ch in raw.split('')) {
    final isDig = RegExp(r'^[0-9]$').hasMatch(ch);
    final isLet = _saudiPlateLetterForLiveInput(ch);
    if (!seenLetter) {
      if (isDig) {
        if (digits.length < 4) {
          digits.write(ch);
        } else {
          rejD = true;
        }
      } else if (isLet) {
        seenLetter = true;
        letters.write(ch);
      }
    } else {
      if (isLet) {
        if (letters.length < 3) {
          letters.write(ch);
        } else {
          rejL = true;
        }
      } else if (isDig) {
        rejD = true;
      }
    }
  }
  final ls = letters.toString();
  final ds = digits.toString();
  final text = ls.isNotEmpty && ds.isNotEmpty
      ? '$ls - $ds'
      : (ls.isNotEmpty ? ls : ds);
  return SaudiPlateLiveShape(
    displayText: text,
    rejectedExtraLetter: rejL,
    rejectedExtraDigit: rejD,
  );
}

SaudiPlateLiveShape _shapeSaudiPlateLettersFirstLive(String raw) {
  final letters = StringBuffer();
  final digits = StringBuffer();
  var seenDigit = false;
  var rejL = false;
  var rejD = false;
  for (final ch in raw.split('')) {
    final isDig = RegExp(r'^[0-9]$').hasMatch(ch);
    final isLet = _saudiPlateLetterForLiveInput(ch);
    if (!seenDigit) {
      if (isLet) {
        if (letters.length < 3) {
          letters.write(ch);
        } else {
          rejL = true;
        }
      } else if (isDig) {
        seenDigit = true;
        if (digits.length < 4) {
          digits.write(ch);
        } else {
          rejD = true;
        }
      }
    } else {
      if (isDig) {
        if (digits.length < 4) {
          digits.write(ch);
        } else {
          rejD = true;
        }
      } else if (isLet) {
        rejL = true;
      }
    }
  }
  final ls = letters.toString();
  final ds = digits.toString();
  final text = ds.isNotEmpty ? '$ls - $ds' : ls;
  return SaudiPlateLiveShape(
    displayText: text,
    rejectedExtraLetter: rejL,
    rejectedExtraDigit: rejD,
  );
}

/// Shapes live keyboard input into **`[letters] - [digits]`** when both parts exist.
///
/// [normalizedNoSeparatorsUppercase] must match POS normalisation: separators stripped,
/// Latin letters uppercased (see `EnglishNumberFormatter.convert` + strip `\\s\\-\\|`).
///
/// Supports **digits-first** typing (`1231` then `QWE` → `QWE - 1231`) and **letters-first**
/// (`QWE` then `1231`), same as Add Customer / invoice dialog.
SaudiPlateLiveShape shapeSaudiPlateForLiveInput(String normalizedNoSeparatorsUppercase) {
  final raw = normalizedNoSeparatorsUppercase;
  if (raw.isEmpty) {
    return const SaudiPlateLiveShape(displayText: '');
  }

  var m = RegExp(r'^([0-9]{1,4})([A-Z\u0621-\u064A]{3})$').firstMatch(raw);
  if (m != null) {
    return SaudiPlateLiveShape(
      displayText: '${m.group(2)} - ${m.group(1)}',
    );
  }
  m = RegExp(r'^([A-Z\u0621-\u064A]{3})([0-9]{1,4})$').firstMatch(raw);
  if (m != null) {
    return SaudiPlateLiveShape(
      displayText: '${m.group(1)} - ${m.group(2)}',
    );
  }

  if (RegExp(r'^[0-9]').hasMatch(raw)) {
    return _shapeSaudiPlateDigitsFirstLive(raw);
  }
  if (RegExp(r'^[A-Z\u0621-\u064A]').hasMatch(raw)) {
    return _shapeSaudiPlateLettersFirstLive(raw);
  }
  return const SaudiPlateLiveShape(displayText: '');
}

/// Saudi motorcycle plates: 2 letters + 4 digits (`AB - 1234`).
SaudiPlateLiveShape shapeSaudiBikePlateForLiveInput(
  String normalizedNoSeparatorsUppercase,
) {
  final raw = normalizedNoSeparatorsUppercase;
  if (raw.isEmpty) {
    return const SaudiPlateLiveShape(displayText: '');
  }

  final letters = StringBuffer();
  final digits = StringBuffer();
  var seenDigit = false;
  var rejL = false;
  var rejD = false;
  for (final ch in raw.split('')) {
    final isDig = RegExp(r'^[0-9]$').hasMatch(ch);
    final isLet = _saudiPlateLetterForLiveInput(ch);
    if (!seenDigit) {
      if (isLet) {
        if (letters.length < 2) {
          letters.write(ch);
        } else {
          rejL = true;
        }
      } else if (isDig) {
        seenDigit = true;
        if (digits.length < 4) {
          digits.write(ch);
        } else {
          rejD = true;
        }
      }
    } else {
      if (isDig) {
        if (digits.length < 4) {
          digits.write(ch);
        } else {
          rejD = true;
        }
      } else if (isLet) {
        rejL = true;
      }
    }
  }
  final ls = letters.toString();
  final ds = digits.toString();
  final text = ds.isNotEmpty ? '$ls - $ds' : ls;
  return SaudiPlateLiveShape(
    displayText: text,
    rejectedExtraLetter: rejL,
    rejectedExtraDigit: rejD,
  );
}

/// Saudi normalized key (`1234ABJ`) — see [gcc_plate.parseGccPlate] for full structure.
String canonicalSaudiPlateForApi(String? raw) =>
    gcc_plate.canonicalSaudiPlateForApi(raw);

/// Allows non-negative decimal quantities: digits, optional single `.`, limited fractional digits.
class DecimalQtyTextInputFormatter extends TextInputFormatter {
  final int maxFractionDigits;

  const DecimalQtyTextInputFormatter({this.maxFractionDigits = 2});

  static final _validChars = RegExp(r'^[0-9.]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(',', '.');
    if (text.isEmpty) return newValue;
    if (!_validChars.hasMatch(text)) return oldValue;

    final firstDot = text.indexOf('.');
    if (firstDot != -1 && text.indexOf('.', firstDot + 1) != -1) {
      return oldValue;
    }
    if (firstDot != -1 && maxFractionDigits >= 0) {
      final frac = text.substring(firstDot + 1);
      if (frac.length > maxFractionDigits) return oldValue;
    }

    if (text != newValue.text) {
      return TextEditingValue(
        text: text,
        selection: newValue.selection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}

class EnglishNumberFormatter extends TextInputFormatter {
  static const Map<String, String> _mapping = {
    // Eastern Arabic numerals (Arabic)
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    // Persian numerals
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    // Devanagari (Hindi) numerals
    '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
    '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
  };

  static String convert(String text) {
    if (text.isEmpty) return text;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      buffer.write(_mapping[char] ?? char);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final String newText = convert(newValue.text);
    if (newText == newValue.text) return newValue;

    return TextEditingValue(
      text: newText,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
