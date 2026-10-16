import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../utils/toast_service.dart';
import 'softpos_access_service.dart';
import 'softpos_bridge.dart';
import 'softpos_settings.dart';

/// SoftPOS link status for Orders Hub pill / settings clarity.
enum SoftPosLinkStatus {
  /// SoftPOS bridge not enabled / not configured.
  disconnected,

  /// Enabled, waiting for first ping result.
  checking,

  /// Enabled but SoftPOS terminal app not reachable (closed / offline).
  offline,

  /// Enabled + SoftPOS terminal online (socket presence or LAN /health).
  online,
}

extension SoftPosLinkStatusLabel on SoftPosLinkStatus {
  String get label {
    switch (this) {
      case SoftPosLinkStatus.disconnected:
        return 'Disconnected';
      case SoftPosLinkStatus.checking:
      case SoftPosLinkStatus.offline:
      case SoftPosLinkStatus.online:
        // UI no longer shows Online/Offline — bound SoftPOS = Connected.
        return 'Connected';
    }
  }

  /// Short pill line: SoftPOS · Connected
  String get pillText => 'SoftPOS · $label';
}

/// Blocks invoice / request-payment until SoftPOS is reachable (socket or LAN).
abstract final class SoftPosConnectionGuard {
  /// Resolve UI status from settings. Bound SoftPOS shows Connected
  /// (Online/Offline presence is not surfaced in the pill).
  static SoftPosLinkStatus resolveStatus({
    required bool enabled,
    required bool? reachable,
  }) {
    if (!enabled) return SoftPosLinkStatus.disconnected;
    return SoftPosLinkStatus.online;
  }

  static Future<bool> _isReady(SoftPosSettingsSnapshot cfg) async {
    final deviceId = (cfg.deviceId ?? '').trim();
    if (deviceId.isNotEmpty) {
      return SoftPosBridge.isBoundDeviceOnline();
    }
    final host = cfg.host.trim();
    if (host.isEmpty) return false;
    return SoftPosBridge.ping(host: host, port: cfg.port, attempts: 1);
  }

  static Future<bool> isConnectionStable() async {
    if (!isSoftPosUiEnabled) return true;
    final cfg = await SoftPosSettings.load();
    if (!cfg.enabled) return true;
    return _isReady(cfg);
  }

  /// SoftPOS enabled + bound handset online (or LAN ping) — required before payment.
  static Future<bool> isSoftPosReadyForPayment() async {
    if (!isSoftPosUiEnabled) return false;
    final cfg = await SoftPosSettings.load();
    if (!cfg.enabled) return false;
    return _isReady(cfg);
  }

  /// When SoftPOS bridge is enabled, checks terminal reachability and toasts if not.
  /// Returns `true` when the action may proceed.
  static Future<bool> ensureStableOrToast(BuildContext context) async {
    if (!isSoftPosUiEnabled) return true;
    final cfg = await SoftPosSettings.load();
    if (!cfg.enabled) return true;

    final ok = await _isReady(cfg);
    if (ok) return true;

    if (context.mounted) {
      ToastService.showError(
        context,
        AppLocalizations.of(context)!.posSoftPosConnectionNotStable,
      );
    }
    return false;
  }
}

/// Typed view of [SoftPosSettings.load] for guards (avoids record friction).
typedef SoftPosSettingsSnapshot = ({
  bool enabled,
  String host,
  int port,
  String? deviceId,
  String? terminalId,
  String? deviceLabel,
});
