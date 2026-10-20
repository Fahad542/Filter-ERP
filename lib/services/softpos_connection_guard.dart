import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../utils/toast_service.dart';
import 'softpos_access_service.dart';
import 'softpos_settings.dart';

/// SoftPOS link status for Orders Hub pill / settings clarity.
enum SoftPosLinkStatus {
  /// SoftPOS bridge not enabled / not configured.
  disconnected,

  /// Enabled, waiting for first ping result.
  checking,

  /// Enabled but SoftPOS terminal app not reachable (closed / offline).
  offline,

  /// Enabled + SoftPOS terminal bound (backend socket).
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

/// Blocks invoice / request-payment until SoftPOS is bound (backend socket).
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

  /// Bound SoftPOS (= Connected) is enough to send a payment request.
  /// Online/offline presence is not required — the handset picks up via socket
  /// when it comes online.
  static Future<bool> _isReady(SoftPosSettingsSnapshot cfg) async {
    return (cfg.deviceId ?? '').trim().isNotEmpty;
  }

  static Future<bool> isConnectionStable() async {
    if (!isSoftPosUiEnabled) return true;
    final cfg = await SoftPosSettings.load();
    if (!cfg.enabled) return true;
    return _isReady(cfg);
  }

  /// SoftPOS enabled + a terminal Connected (bound). Online presence optional.
  static Future<bool> isSoftPosReadyForPayment() async {
    if (!isSoftPosUiEnabled) return false;
    final cfg = await SoftPosSettings.load();
    if (!cfg.enabled) return false;
    return _isReady(cfg);
  }

  /// When SoftPOS bridge is enabled, requires a Connected (bound) terminal.
  /// Does not block on Online/Offline presence. Returns `true` to proceed.
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
  String? userId,
  String? branchId,
});
