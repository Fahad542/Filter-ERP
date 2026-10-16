import 'dart:math';

import 'package:flutter/services.dart';

import '../../../utils/app_formatters.dart';

/// Country calling code for Add Customer (Normal) mobile field — Saudi Arabia only.
enum PosAddCustomerMobileDial { saudiArabia }

extension PosAddCustomerMobileDialX on PosAddCustomerMobileDial {
  String get dialDigits => '966';

  String get flagEmoji => '🇸🇦';

  /// Placeholder sample (national digits only; user types without +country).
  String get inputHintSample => '5X XXX XXXX';
}

/// National mobile display + validation for Saudi Arabia (Add Customer).
class PosAddCustomerPhoneFormat {
  PosAddCustomerPhoneFormat._();

  static String digitsOnly(String s) =>
      EnglishNumberFormatter.convert(s).replaceAll(RegExp(r'\D'), '');

  static String _digits(String s) => digitsOnly(s);

  /// Strips non-digits and caps length while typing.
  static String capDigits(PosAddCustomerMobileDial dial, String rawDigits) {
    var d = _digits(rawDigits);
    if (d.isEmpty) return d;
    if (d.startsWith('966') && d.length > 3) {
      d = d.substring(3);
    }
    if (d.startsWith('05')) {
      d = d.substring(1);
    }
    if (d.startsWith('0')) {
      d = d.substring(1);
    }
    return d.length > 9 ? d.substring(0, 9) : d;
  }

  static String _chunk(String digits, List<int> sizes) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    var i = 0;
    var si = 0;
    while (i < digits.length && si < sizes.length) {
      final remain = digits.length - i;
      final take = min(sizes[si], remain);
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(digits.substring(i, i + take));
      i += take;
      si++;
    }
    if (i < digits.length) {
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(digits.substring(i));
    }
    return buf.toString();
  }

  /// Formats national digits (no country code) with spaces for display.
  static String formatDigits(PosAddCustomerMobileDial dial, String rawDigits) {
    final d = capDigits(dial, rawDigits);
    if (d.isEmpty) return '';
    return _chunk(d, [2, 3, 4]);
  }

  /// Normalizes to national mobile digits only (no +country, no spaces).
  /// Saudi: `5XXXXXXXX` (9 digits).
  static String normalizeNational(PosAddCustomerMobileDial dial, String raw) {
    var d = _digits(raw);
    if (d.startsWith('966')) {
      d = d.length > 3 ? d.substring(3) : '';
    }
    if (d.length == 10 && d.startsWith('05')) {
      d = d.substring(1);
    } else if (d.length > 9 && d.startsWith('05')) {
      d = d.substring(1, 10);
    }
    return d;
  }

  static bool isValidNational(PosAddCustomerMobileDial dial, String raw) {
    final n = normalizeNational(dial, raw);
    return RegExp(r'^5\d{8}$').hasMatch(n);
  }
}

/// Keeps display formatted; strips non-digits and reapplies grouping for the selected country.
class PosAddCustomerNationalMobileFormatter extends TextInputFormatter {
  PosAddCustomerNationalMobileFormatter(this.dial);
  final PosAddCustomerMobileDial dial;

  static int _digitCountBefore(String s, int offset) {
    if (offset <= 0) return 0;
    final sub = s.substring(0, min(offset, s.length));
    return _digits(sub).length;
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static int _offsetForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;
    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        count++;
        if (count == digitIndex) return i + 1;
      }
    }
    return formatted.length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = PosAddCustomerPhoneFormat.capDigits(
      dial,
      _digits(newValue.text),
    );
    final formatted = PosAddCustomerPhoneFormat.formatDigits(dial, rawDigits);

    final oldOffset = newValue.selection.baseOffset;
    final digitsBefore = _digitCountBefore(newValue.text, oldOffset);
    final newOffset = _offsetForDigitIndex(formatted, digitsBefore);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newOffset.clamp(0, formatted.length),
      ),
    );
  }
}
