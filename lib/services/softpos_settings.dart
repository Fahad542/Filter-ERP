import 'package:shared_preferences/shared_preferences.dart';

import 'session_service.dart';
import 'softpos_protocol.dart';

/// SoftPOS terminal binding for Filter ERP (paired handset + backend socket).
///
/// Preferences are scoped by cashier [userId] + [branchId] so a phone
/// connected in one branch never appears as Connected in another.
abstract final class SoftPosSettings {
  static const prefEnabled = 'pos_softpos_bridge_enabled';
  static const prefHost = 'pos_softpos_host';
  static const prefPort = 'pos_softpos_port';
  static const prefDeviceId = 'pos_softpos_bound_device_id';
  static const prefTerminalId = 'pos_softpos_bound_terminal_id';
  static const prefDeviceLabel = 'pos_softpos_bound_device_label';
  static const _legacyMigratedFlag = 'pos_softpos_legacy_cleared_v1';

  static const defaultHost = '192.168.1.50';
  static const defaultPort = SoftPosProtocol.defaultServerPort;

  static bool isPlausibleHost(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s.length > 253) return false;
    return RegExp(r'^[a-zA-Z0-9.\-]+$').hasMatch(s);
  }

  /// Resolves cashier user + branch for preference keys.
  static Future<({String? userId, String? branchId})> resolveScope({
    String? userId,
    String? branchId,
  }) async {
    var uid = (userId ?? '').trim();
    var bid = (branchId ?? '').trim();
    if (uid.isEmpty || bid.isEmpty) {
      final user = await SessionService().getUser(role: 'cashier');
      uid = uid.isEmpty ? (user?.id?.toString().trim() ?? '') : uid;
      bid = bid.isEmpty ? (user?.branchId?.trim() ?? '') : bid;
    }
    return (
      userId: uid.isEmpty ? null : uid,
      branchId: bid.isEmpty ? null : bid,
    );
  }

  static String _scopedKey(String base, String? userId, String? branchId) {
    final uid = (userId ?? '').trim();
    final bid = (branchId ?? '').trim();
    if (uid.isNotEmpty && bid.isNotEmpty) return '${base}_${uid}_$bid';
    if (bid.isNotEmpty) return '${base}_b_$bid';
    if (uid.isNotEmpty) return '${base}_u_$uid';
    return base;
  }

  static Future<void> _clearLegacyGlobals(SharedPreferences p) async {
    if (p.getBool(_legacyMigratedFlag) == true) return;
    await p.remove(prefEnabled);
    await p.remove(prefHost);
    await p.remove(prefPort);
    await p.remove(prefDeviceId);
    await p.remove(prefTerminalId);
    await p.remove(prefDeviceLabel);
    await p.setBool(_legacyMigratedFlag, true);
  }

  static Future<({
    bool enabled,
    String host,
    int port,
    String? deviceId,
    String? terminalId,
    String? deviceLabel,
    String? userId,
    String? branchId,
  })> load({String? userId, String? branchId}) async {
    final scope = await resolveScope(userId: userId, branchId: branchId);
    final p = await SharedPreferences.getInstance();
    // Drop pre-branch-scoped prefs so another branch's Connected state
    // cannot leak into this session.
    await _clearLegacyGlobals(p);

    final kEnabled = _scopedKey(prefEnabled, scope.userId, scope.branchId);
    final kHost = _scopedKey(prefHost, scope.userId, scope.branchId);
    final kPort = _scopedKey(prefPort, scope.userId, scope.branchId);
    final kDeviceId = _scopedKey(prefDeviceId, scope.userId, scope.branchId);
    final kTerminalId =
        _scopedKey(prefTerminalId, scope.userId, scope.branchId);
    final kDeviceLabel =
        _scopedKey(prefDeviceLabel, scope.userId, scope.branchId);

    final enabled = p.getBool(kEnabled) ?? false;
    final host = (p.getString(kHost) ?? '').trim();
    final port = p.getInt(kPort) ?? SoftPosProtocol.defaultServerPort;
    final deviceId = (p.getString(kDeviceId) ?? '').trim();
    final terminalId = (p.getString(kTerminalId) ?? '').trim();
    final deviceLabel = (p.getString(kDeviceLabel) ?? '').trim();
    return (
      enabled: enabled,
      host: host.isNotEmpty ? host : defaultHost,
      port: (port >= 1 && port <= 65535) ? port : defaultPort,
      deviceId: deviceId.isEmpty ? null : deviceId,
      terminalId: terminalId.isEmpty ? null : terminalId,
      deviceLabel: deviceLabel.isEmpty ? null : deviceLabel,
      userId: scope.userId,
      branchId: scope.branchId,
    );
  }

  static Future<void> save({
    required bool enabled,
    required String host,
    required int port,
    String? deviceId,
    String? terminalId,
    String? deviceLabel,
    String? userId,
    String? branchId,
  }) async {
    final scope = await resolveScope(userId: userId, branchId: branchId);
    final p = await SharedPreferences.getInstance();
    await _clearLegacyGlobals(p);

    final kEnabled = _scopedKey(prefEnabled, scope.userId, scope.branchId);
    final kHost = _scopedKey(prefHost, scope.userId, scope.branchId);
    final kPort = _scopedKey(prefPort, scope.userId, scope.branchId);
    final kDeviceId = _scopedKey(prefDeviceId, scope.userId, scope.branchId);
    final kTerminalId =
        _scopedKey(prefTerminalId, scope.userId, scope.branchId);
    final kDeviceLabel =
        _scopedKey(prefDeviceLabel, scope.userId, scope.branchId);

    await p.setBool(kEnabled, enabled);
    await p.setString(kHost, host.trim());
    await p.setInt(kPort, port);
    final did = (deviceId ?? '').trim();
    final tid = (terminalId ?? '').trim();
    final label = (deviceLabel ?? '').trim();
    if (did.isEmpty) {
      await p.remove(kDeviceId);
    } else {
      await p.setString(kDeviceId, did);
    }
    if (tid.isEmpty) {
      await p.remove(kTerminalId);
    } else {
      await p.setString(kTerminalId, tid);
    }
    if (label.isEmpty) {
      await p.remove(kDeviceLabel);
    } else {
      await p.setString(kDeviceLabel, label);
    }
  }

  static Future<void> clearBinding({String? userId, String? branchId}) async {
    final scope = await resolveScope(userId: userId, branchId: branchId);
    final p = await SharedPreferences.getInstance();
    await _clearLegacyGlobals(p);

    final kEnabled = _scopedKey(prefEnabled, scope.userId, scope.branchId);
    final kDeviceId = _scopedKey(prefDeviceId, scope.userId, scope.branchId);
    final kTerminalId =
        _scopedKey(prefTerminalId, scope.userId, scope.branchId);
    final kDeviceLabel =
        _scopedKey(prefDeviceLabel, scope.userId, scope.branchId);

    await p.setBool(kEnabled, false);
    await p.remove(kDeviceId);
    await p.remove(kTerminalId);
    await p.remove(kDeviceLabel);
  }
}
