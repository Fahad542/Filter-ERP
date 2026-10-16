import 'package:flutter/material.dart';

/// Best-effort keyboard language hint.
///
/// Mobile OS keyboards decide the final layout. Flutter cannot force the user's
/// active keyboard language, but `hintLocales` gives iOS/Android IMEs the
/// correct language preference for this text field.
List<Locale> appKeyboardHintLocales(BuildContext context) {
  final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
  return lang == 'ar' ? const [Locale('ar')] : const [Locale('en')];
}
