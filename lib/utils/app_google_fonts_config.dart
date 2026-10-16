import 'package:google_fonts/google_fonts.dart';

/// Bundled fonts from [pubspec.yaml] (`assets/google_fonts/`) — no runtime fetch.
void configureBundledGoogleFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
}
