import 'package:shared_preferences/shared_preferences.dart';

/// Saved Wi‑Fi ESC/POS target (e.g. Epson TM‑m30II on LAN port 9100).
///
/// Keys [prefHost] / [prefPort] are **device‑local** and must **not** be removed
/// on cashier logout (see [LoginViewModel.logout]).
abstract final class ThermalPrinterSettings {
  static const prefHost = 'pos_thermal_printer_host';
  static const prefPort = 'pos_thermal_printer_port';

  static const defaultHost = '192.168.8.55';
  static const defaultPort = 9100;

  /// Simple host/IP sanity check (IPv4 or hostname); avoids saving garbage.
  static bool isPlausibleHost(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s.length > 253) return false;
    return RegExp(r'^[a-zA-Z0-9.\-]+$').hasMatch(s);
  }

  static Future<({String host, int port})> load() async {
    final p = await SharedPreferences.getInstance();
    final String host;
    if (p.containsKey(prefHost)) {
      final stored = p.getString(prefHost)?.trim() ?? '';
      host = stored.isNotEmpty ? stored : defaultHost;
    } else {
      host = defaultHost;
    }
    int port;
    if (p.containsKey(prefPort)) {
      final v = p.getInt(prefPort);
      port = (v != null && v >= 1 && v <= 65535) ? v : defaultPort;
    } else {
      port = defaultPort;
    }
    return (host: host, port: port);
  }

  static Future<void> save(String host, int port) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(prefHost, host.trim());
    await p.setInt(prefPort, port);
  }
}
