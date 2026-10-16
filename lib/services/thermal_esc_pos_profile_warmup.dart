import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Loads the printer [CapabilityProfile] **on the main isolate** and caches
/// the Future so subsequent calls return immediately.
///
/// `CapabilityProfile.load` reads `packages/esc_pos_utils_plus/resources/
/// capabilities.json` via `rootBundle`, which is plugin/binding work — it
/// **must not** run inside `Isolate.run`. Worker isolates that need the
/// profile (e.g. ESC/POS encode) should `await` this future on the main
/// isolate and pass the resulting `CapabilityProfile` object across the
/// isolate boundary as plain data.
Future<CapabilityProfile>? _profileFuture;

Future<CapabilityProfile> warmThermalEscPosCapabilityProfile() {
  return _profileFuture ??= CapabilityProfile.load(name: 'default');
}
