import 'package:shared_preferences/shared_preferences.dart';

import 'softpos_protocol.dart';

/// SoftPOS terminal binding for Filter ERP (paired handset + LAN bridge).
abstract final class SoftPosSettings {
  static const prefEnabled = 'pos_softpos_bridge_enabled';
  static const prefHost = 'pos_softpos_host';
  static const prefPort = 'pos_softpos_port';
  static const prefDeviceId = 'pos_softpos_bound_device_id';
  static const prefTerminalId = 'pos_softpos_bound_terminal_id';
  static const prefDeviceLabel = 'pos_softpos_bound_device_label';

  static const defaultHost = '192.168.1.50';
  static const defaultPort = SoftPosProtocol.defaultServerPort;

  static bool isPlausibleHost(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s.length > 253) return false;
    return RegExp(r'^[a-zA-Z0-9.\-]+$').hasMatch(s);
  }

  static Future<({
    bool enabled,
    String host,
    int port,
    String? deviceId,
    String? terminalId,
    String? deviceLabel,
  })> load() async {
    final p = await SharedPreferences.getInstance();
    final enabled = p.getBool(prefEnabled) ?? false;
    final host = (p.getString(prefHost) ?? '').trim();
    final port = p.getInt(prefPort) ?? SoftPosProtocol.defaultServerPort;
    final deviceId = (p.getString(prefDeviceId) ?? '').trim();
    final terminalId = (p.getString(prefTerminalId) ?? '').trim();
    final deviceLabel = (p.getString(prefDeviceLabel) ?? '').trim();
    return (
      enabled: enabled,
      host: host.isNotEmpty ? host : defaultHost,
      port: (port >= 1 && port <= 65535) ? port : defaultPort,
      deviceId: deviceId.isEmpty ? null : deviceId,
      terminalId: terminalId.isEmpty ? null : terminalId,
      deviceLabel: deviceLabel.isEmpty ? null : deviceLabel,
    );
  }

  static Future<void> save({
    required bool enabled,
    required String host,
    required int port,
    String? deviceId,
    String? terminalId,
    String? deviceLabel,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(prefEnabled, enabled);
    await p.setString(prefHost, host.trim());
    await p.setInt(prefPort, port);
    final did = (deviceId ?? '').trim();
    final tid = (terminalId ?? '').trim();
    final label = (deviceLabel ?? '').trim();
    if (did.isEmpty) {
      await p.remove(prefDeviceId);
    } else {
      await p.setString(prefDeviceId, did);
    }
    if (tid.isEmpty) {
      await p.remove(prefTerminalId);
    } else {
      await p.setString(prefTerminalId, tid);
    }
    if (label.isEmpty) {
      await p.remove(prefDeviceLabel);
    } else {
      await p.setString(prefDeviceLabel, label);
    }
  }

  static Future<void> clearBinding() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(prefEnabled, false);
    await p.remove(prefDeviceId);
    await p.remove(prefTerminalId);
    await p.remove(prefDeviceLabel);
  }
}
