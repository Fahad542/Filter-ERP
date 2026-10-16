// ignore_for_file: non_constant_identifier_names

/// Arabic reshaper for the Dart `pdf` package.
///
/// The `pdf` package does **not** run HarfBuzz shaping or Unicode BiDi
/// reordering.  Arabic letters fed in logical order render as isolated,
/// unconnected glyphs displayed left-to-right — exactly the garbage you see
/// in the invoice preview screenshot.
///
/// This file provides [reshapeArabic]:
///   • Joins letters into their correct contextual forms (initial / medial /
///     final / isolated) using a lookup table that covers the full Arabic
///     Unicode block (U+0600–U+06FF) plus common presentation forms.
///   • Reverses the reshaped string so that `pw.Text` (which always lays
///     glyphs LTR) visually reads right-to-left on the page.
///
/// **Usage** — wrap every Arabic string before passing to `pw.Text`:
///
/// ```dart
/// pw.Text(
///   reshapeArabic('فرع النور'),   // ← was garbled, now correct
///   style: pw.TextStyle(font: fontArabic, ...),
///   // ⚠ Do NOT set textDirection: rtl — the string is already reversed.
/// )
/// ```
///
/// **pubspec.yaml** — no new dependency required.  This file is pure Dart.
///
/// **Font** — use any Arabic TTF that contains the Presentation Forms-B block
/// (U+FE70–U+FEFF), e.g. NotoSansArabic, Amiri, Cairo, Almarai.
/// NotoSansArabic-Regular.ttf (already bundled in your project) works fine.

library thermal_arabic_pdf_reshaper;

// ── Contextual-form tables ────────────────────────────────────────────────────

/// Returns true when [cp] is an Arabic letter that can connect on both sides.
bool _dualJoining(int cp) {
  // Basic Arabic letters that join on both sides
  if (cp >= 0x0626 && cp <= 0x063A) return true; // ئ … غ (skip 0x0621 ء, 0x0622–0x0625 alef variants, 0x0627 alef)
  if (cp >= 0x0641 && cp <= 0x064A) return true; // ف … ي
  // Common extras
  return const {
    0x0626, // ئ
    0x0628, // ب
    0x062A, // ت
    0x062B, // ث
    0x062C, // ج
    0x062D, // ح
    0x062E, // خ
    0x062F, // د — right-join only, but handled by _rightJoinOnly below
    0x0633, // س
    0x0634, // ش
    0x0635, // ص
    0x0636, // ض
    0x0637, // ط
    0x0638, // ظ
    0x0639, // ع
    0x063A, // غ
    0x0641, // ف
    0x0642, // ق
    0x0643, // ك
    0x0644, // ل
    0x0645, // م
    0x0646, // ن
    0x0647, // ه
    0x064A, // ي
    0x0649, // ى (alef maqsura — joins left only in some fonts; treat dual)
    0x06CC, // Farsi yeh
    0x06A9, // Keheh
    0x06AF, // Gaf
    0x06C1, // Heh goal
    0x06BE, // Heh doachashmee
  }.contains(cp);
}

/// Letters that only connect to the **right** (they break the word after them).
bool _rightJoinOnly(int cp) => const {
      0x0621, // ء
      0x0622, // آ
      0x0623, // أ
      0x0624, // ؤ
      0x0625, // إ
      0x0627, // ا
      0x062F, // د
      0x0630, // ذ
      0x0631, // ر
      0x0632, // ز
      0x0648, // و
      0x0671, // ٱ
      0x0672, 0x0673, 0x0674, 0x0675, 0x0676, 0x0677,
      0x06C6, 0x06C7, 0x06C8, 0x06CB, 0x06CD,
    }.contains(cp);

bool _isArabicLetter(int cp) =>
    (cp >= 0x0600 && cp <= 0x06FF) ||
    (cp >= 0x0750 && cp <= 0x077F) ||
    (cp >= 0x08A0 && cp <= 0x08FF) ||
    (cp >= 0xFB50 && cp <= 0xFDFF) ||
    (cp >= 0xFE70 && cp <= 0xFEFF);

bool _isArabicDiacritic(int cp) => cp >= 0x064B && cp <= 0x065F;

bool _isNonJoiner(int cp) => cp == 0x200C; // Zero Width Non-Joiner

/// Presentation-forms for the Arabic letters we handle.
///
/// Each letter has up to 4 forms: [isolated, final, initial, medial].
/// `0` means "no presentation form — keep the base character".
const Map<int, List<int>> _forms = {
  0x0621: [0xFE80, 0, 0, 0], // ء
  0x0622: [0xFE81, 0xFE82, 0, 0], // آ
  0x0623: [0xFE83, 0xFE84, 0, 0], // أ
  0x0624: [0xFE85, 0xFE86, 0, 0], // ؤ
  0x0625: [0xFE87, 0xFE88, 0, 0], // إ
  0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], // ئ
  0x0627: [0xFE8D, 0xFE8E, 0, 0], // ا
  0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], // ب
  0x0629: [0xFE93, 0xFE94, 0, 0], // ة
  0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], // ت
  0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C], // ث
  0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], // ج
  0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4], // ح
  0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], // خ
  0x062F: [0xFEA9, 0xFEAA, 0, 0], // د
  0x0630: [0xFEAB, 0xFEAC, 0, 0], // ذ
  0x0631: [0xFEAD, 0xFEAE, 0, 0], // ر
  0x0632: [0xFEAF, 0xFEB0, 0, 0], // ز
  0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4], // س
  0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], // ش
  0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC], // ص
  0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], // ض
  0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4], // ط
  0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], // ظ
  0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC], // ع
  0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], // غ
  0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4], // ف
  0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], // ق
  0x0643: [0xFED9, 0xFEDA, 0xFEDB, 0xFEDC], // ك
  0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], // ل
  0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4], // م
  0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], // ن
  0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC], // ه
  0x0648: [0xFEED, 0xFEEE, 0, 0], // و
  0x0649: [0xFEEF, 0xFEF0, 0, 0], // ى
  0x064A: [0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4], // ي

  // Lam-Alef ligatures — handled separately in [_lamalef].
  // Extended / Farsi / Urdu
  0x06A9: [0xFB8E, 0xFB8F, 0xFB90, 0xFB91], // ک keheh
  0x06AF: [0xFB92, 0xFB93, 0xFB94, 0xFB95], // گ gaf
  0x06BE: [0xFBAA, 0xFBAB, 0xFBAC, 0xFBAD], // ھ heh doachashmee
  0x06CC: [0xFBFC, 0xFBFD, 0xFBFE, 0xFBFF], // ی Farsi yeh
};

/// Special Lam-Alef ligatures.  Key = Alef codepoint; value = [isolated, final].
const Map<int, List<int>> _lamalef = {
  0x0622: [0xFEF5, 0xFEF6], // لآ
  0x0623: [0xFEF7, 0xFEF8], // لأ
  0x0625: [0xFEF9, 0xFEFA], // لإ
  0x0627: [0xFEFB, 0xFEFC], // لا
};

int _isolated(int cp) => _forms[cp]?[0] ?? cp;
int _final(int cp) => (_forms[cp]?[1] ?? 0) != 0 ? _forms[cp]![1] : _isolated(cp);
int _initial(int cp) => (_forms[cp]?[2] ?? 0) != 0 ? _forms[cp]![2] : _isolated(cp);
int _medial(int cp) => (_forms[cp]?[3] ?? 0) != 0 ? _forms[cp]![3] : _final(cp);

// ── Public API ────────────────────────────────────────────────────────────────

/// Reshapes and visually reverses an Arabic string for use with [pw.Text].
///
/// Use this for Arabic-only RTL text. The returned string is already in visual
/// order for the Dart `pdf` package, so do not also set `textDirection: rtl`.
///
/// Returns the input unchanged if it contains no Arabic script.
String reshapeArabic(String input) {
  if (input.isEmpty) return input;
  if (!input.runes.any(_isArabicLetter)) return input;

  final split = _trySplitTopLevelParenGroups(input);
  if (split != null && split.any((e) => e.isInner)) {
    return _reshapeArabicFromParenSplit(split);
  }

  final runs = _segment(input);
  final reshaped = runs
      .map((r) => r.isArabic ? _reshapeRunNoParens(r.text) : r.text)
      .toList();

  final buf = StringBuffer();
  for (var i = reshaped.length - 1; i >= 0; i--) {
    buf.write(reshaped[i]);
  }
  return buf.toString();
}

/// Reshapes Arabic runs but keeps the original LTR run order.
///
/// Use this for mixed labels such as `الفرع / Branch:` where the Arabic word
/// should stay before the English text on a left-to-right PDF line.
String reshapeArabicForMixedLtr(String input) {
  if (input.isEmpty) return input;
  if (!input.runes.any(_isArabicLetter)) return input;

  final split = _trySplitTopLevelParenGroups(input);
  if (split != null && split.any((e) => e.isInner)) {
    return _reshapeMixedLtrFromParenSplit(split);
  }

  final runs = _segment(input);
  final buf = StringBuffer();
  for (final run in runs) {
    buf.write(run.isArabic ? _reshapeRunNoParens(run.text) : run.text);
  }
  return buf.toString();
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _Run {
  _Run(this.text, {required this.isArabic});
  final String text;
  final bool isArabic;
}

/// One segment when splitting `outer ( inner ) outer …` for PDF Arabic layout.
class _ParenSeg {
  _ParenSeg._(this.text, {required this.isInner});
  final String text;
  final bool isInner;

  factory _ParenSeg.outer(String s) => _ParenSeg._(s, isInner: false);
  factory _ParenSeg.inner(String s) => _ParenSeg._(s, isInner: true);
}

/// Returns ordered [outer, inner, outer, …] or `null` if parentheses are unbalanced.
List<_ParenSeg>? _trySplitTopLevelParenGroups(String input) {
  final r = <_ParenSeg>[];
  var i = 0;
  while (i < input.length) {
    final open = input.indexOf('(', i);
    if (open < 0) {
      if (i < input.length) r.add(_ParenSeg.outer(input.substring(i)));
      break;
    }
    if (open > i) r.add(_ParenSeg.outer(input.substring(i, open)));
    var depth = 1;
    var j = open + 1;
    while (j < input.length && depth > 0) {
      final c = input.codeUnitAt(j);
      if (c == 0x28) {
        depth++;
      } else if (c == 0x29) {
        depth--;
      }
      j++;
    }
    if (depth != 0) return null;
    r.add(_ParenSeg.inner(input.substring(open + 1, j - 1)));
    i = j;
  }
  return r;
}

String _reshapeParenInnerForPdf(String inner) {
  if (!inner.runes.any(_isArabicLetter)) return inner;
  // Nested `(…)` inside the group: recurse so brackets stay with their Arabic.
  return reshapeArabic(inner);
}

/// Outer text before/after `(…)` — Latin-only stays unchanged (no glyph reversal).
String _reshapeOuterForPdf(String text) {
  if (!text.runes.any(_isArabicLetter)) return text;
  return _reshapeRunNoParens(text);
}

/// Reverses outer/inner **segments** (like BiDi) while keeping `(` `)` hugging inner text.
String _reshapeArabicFromParenSplit(List<_ParenSeg> parts) {
  final buf = StringBuffer();
  for (var k = parts.length - 1; k >= 0; k--) {
    final p = parts[k];
    if (p.isInner) {
      buf.writeCharCode(0x28);
      buf.write(_reshapeParenInnerForPdf(p.text));
      buf.writeCharCode(0x29);
    } else {
      buf.write(_reshapeOuterForPdf(p.text));
    }
  }
  return buf.toString();
}

/// Same parenthesis grouping as [_reshapeArabicFromParenSplit] but keeps segment order LTR
/// (for [reshapeArabicForMixedLtr] lines).
String _reshapeMixedLtrFromParenSplit(List<_ParenSeg> parts) {
  final buf = StringBuffer();
  for (final p in parts) {
    if (p.isInner) {
      buf.writeCharCode(0x28);
      buf.write(_reshapeParenInnerForPdf(p.text));
      buf.writeCharCode(0x29);
    } else {
      buf.write(_reshapeOuterForPdf(p.text));
    }
  }
  return buf.toString();
}

List<_Run> _segment(String input) {
  final runs = <_Run>[];
  final buf = StringBuffer();
  var inArabic = false;

  void flush(bool arabic) {
    if (buf.isNotEmpty) {
      runs.add(_Run(buf.toString(), isArabic: arabic));
      buf.clear();
    }
  }

  for (final cp in input.runes) {
    final arabic = _isArabicLetter(cp) || _isArabicDiacritic(cp) || cp == 0x0020 /* space handled below */;
    // Spaces are assigned to whichever run is current.
    if (cp == 0x0020) {
      buf.writeCharCode(cp);
      continue;
    }
    final isAr = _isArabicLetter(cp) || _isArabicDiacritic(cp);
    if (isAr != inArabic) {
      flush(inArabic);
      inArabic = isAr;
    }
    buf.writeCharCode(cp);
  }
  flush(inArabic);
  return runs;
}

/// Reshape a single Arabic-only run (no Latin content).
///
/// Caller must not pass strings that contain `(` / `)` — those are handled by
/// [_reshapeArabicFromParenSplit] on the full line in [reshapeArabic].
String _reshapeRunNoParens(String text) {
  final cps = text.runes.toList();
  final out = <int>[];
  final n = cps.length;

  // We process RTL: index 0 is the rightmost character in display order.
  // After reshaping we reverse so pw.Text (LTR) displays correctly.
  for (var i = 0; i < n; i++) {
    final cp = cps[i];

    if (!_isArabicLetter(cp)) {
      out.add(cp);
      continue;
    }

    // Determine joining context.
    final prevLetter = _prevJoiningLetter(cps, i);
    final nextLetter = _nextJoiningLetter(cps, i);

    // Logical Arabic order is right-to-left: [prevLetter] is visually on the
    // right, [nextLetter] is visually on the left. A letter joins to the right
    // only when the previous letter can extend left. It joins to the left only
    // when the current letter itself can extend left (Alef/Dal/Ra/Waw cannot).
    final connectsRight = prevLetter != null && !_rightJoinOnly(prevLetter);
    final connectsLeft = nextLetter != null && !_rightJoinOnly(cp);

    // Lam-Alef ligature?  Check if this is ل followed by an Alef.
    if (cp == 0x0644 && nextLetter != null && _lamalef.containsKey(nextLetter)) {
      final laTbl = _lamalef[nextLetter]!;
      // Use final form if lam itself has a preceding connector.
      out.add(connectsRight ? laTbl[1] : laTbl[0]);
      // Skip the next character (the Alef was consumed into ligature).
      // We do this by inserting a sentinel that the loop will skip.
      out.add(-1); // consumed marker
      i++; // advance past the Alef
      continue;
    }
    if (cp == -1) continue; // consumed by ligature

    // Pick the contextual form.
    int shaped;
    if (connectsLeft && connectsRight) {
      shaped = _medial(cp);
    } else if (connectsRight) {
      shaped = _final(cp);
    } else if (connectsLeft) {
      shaped = _initial(cp);
    } else {
      shaped = _isolated(cp);
    }
    out.add(shaped);
  }

  // Remove sentinels and reverse for LTR display.
  final filtered = out.where((c) => c != -1).toList();
  return String.fromCharCodes(filtered.reversed);
}

/// Returns the codepoint of the nearest Arabic letter **after** index [i]
/// (skipping diacritics and non-joiners), or null if none.
int? _nextJoiningLetter(List<int> cps, int i) {
  for (var j = i + 1; j < cps.length; j++) {
    final c = cps[j];
    if (_isArabicDiacritic(c) || _isNonJoiner(c)) continue;
    if (_isArabicLetter(c)) return c;
    break;
  }
  return null;
}

/// Returns the codepoint of the nearest Arabic letter **before** index [i],
/// or null if none.
int? _prevJoiningLetter(List<int> cps, int i) {
  for (var j = i - 1; j >= 0; j--) {
    final c = cps[j];
    if (_isArabicDiacritic(c) || _isNonJoiner(c)) continue;
    if (_isArabicLetter(c)) return c;
    break;
  }
  return null;
}
