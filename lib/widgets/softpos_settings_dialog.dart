import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/pos_order_model.dart';
import '../services/payment_intents_service.dart';
import '../services/session_service.dart';
import '../services/softpos_bridge.dart';
import '../services/softpos_connection_guard.dart';
import '../services/softpos_invoice_flow.dart';
import '../services/softpos_protocol.dart';
import '../services/softpos_settings.dart';
import '../services/softpos_terminals_api.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_button_busy.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/toast_service.dart';
import '../views/Workshop pos app/Home Screen/pos_view_model.dart';
import 'app_bar_live_clock.dart';
import 'pos_shimmer.dart';

Future<bool> showSoftPosSettingsDialog(BuildContext context) async {
  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const _SoftPosSettingsDialog(),
  );
  return result ?? false;
}

class _SoftPosSettingsDialog extends StatefulWidget {
  const _SoftPosSettingsDialog();

  @override
  State<_SoftPosSettingsDialog> createState() => _SoftPosSettingsDialogState();
}

class _SoftPosSettingsDialogState extends State<_SoftPosSettingsDialog> {
  final _api = SoftPosTerminalsApi();
  bool _loading = true;
  bool _binding = false;
  bool _enabled = false;
  bool? _reachable;
  String? _error;
  String? _boundDeviceId;
  String? _connectingDeviceId;
  List<SoftPosTerminalItem> _items = const [];

  List<SoftPosTerminalItem> _sortedTerminals(
    List<SoftPosTerminalItem> items, {
    String? boundDeviceId,
  }) {
    if (items.isEmpty) return List.of(items);
    final boundId = (boundDeviceId ?? _boundDeviceId ?? '').trim();
    int rank(SoftPosTerminalItem t) {
      final mine = (boundId.isNotEmpty && t.deviceId == boundId) || t.bound;
      if (mine) return 0;
      if (t.boundToOther) return 2;
      return 1;
    }

    final sorted = List<SoftPosTerminalItem>.of(items);
    sorted.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cfg = await SoftPosSettings.load();
      final listed = await _api.listTerminals();
      if (!mounted) return;

      SoftPosTerminalItem? bound;
      final listedBoundId = (listed.boundDeviceId ?? '').trim();
      for (final item in listed.items) {
        if (item.bound ||
            (listedBoundId.isNotEmpty && item.deviceId == listedBoundId)) {
          bound = item;
          break;
        }
      }

      var enabled = false;
      var reachable = false;
      if (bound != null) {
        // Socket bridge: presence `online` is enough (no same Wi‑Fi required).
        reachable = bound.online;
        final host = (bound.lanHost ?? cfg.host).trim();
        final port = bound.lanPort ?? cfg.port;
        await SoftPosSettings.save(
          enabled: true,
          host: SoftPosSettings.isPlausibleHost(host)
              ? host
              : SoftPosSettings.defaultHost,
          port: port,
          deviceId: bound.deviceId,
          terminalId: (bound.nearpayTerminalId ??
                  bound.terminalTid ??
                  bound.terminalId)
              ?.trim(),
          deviceLabel: bound.label,
        );
        enabled = true;
      } else {
        // No binding for this cashier+branch — never show another branch's phone.
        await SoftPosSettings.clearBinding();
      }

      if (!mounted) return;
      final boundId = bound?.deviceId ??
          (listedBoundId.isEmpty ? null : listedBoundId);
      setState(() {
        _boundDeviceId = boundId;
        _items = _sortedTerminals(listed.items, boundDeviceId: boundId);
        _enabled = enabled;
        _reachable = enabled ? reachable : false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _connect(SoftPosTerminalItem item) async {
    if (item.boundToOther) {
      final who = (item.boundByName ?? '').trim();
      setState(() {
        _error = who.isNotEmpty
            ? 'This SoftPOS is connected by $who. Ask them to disconnect first.'
            : 'This SoftPOS is already connected by another cashier.';
      });
      return;
    }
    setState(() {
      _binding = true;
      _connectingDeviceId = item.deviceId;
      _error = null;
    });
    try {
      final bound = await _api.bind(item.deviceId);
      // SoftPOS may still be pushing presence — refresh once for LAN IP.
      final listed = await _api.listTerminals();
      SoftPosTerminalItem fresh = bound;
      for (final row in listed.items) {
        if (row.deviceId == bound.deviceId) {
          fresh = row;
          break;
        }
      }

      final host = (fresh.lanHost ?? '').trim();
      final port = fresh.lanPort ?? SoftPosSettings.defaultPort;
      // Backend socket only — bind enables SoftPOS immediately.
      final ok = fresh.online;
      await SoftPosSettings.save(
        enabled: true,
        host: SoftPosSettings.isPlausibleHost(host)
            ? host
            : SoftPosSettings.defaultHost,
        port: SoftPosSettings.isPlausibleHost(host)
            ? port
            : SoftPosSettings.defaultPort,
        deviceId: fresh.deviceId,
        terminalId: (fresh.nearpayTerminalId ??
                fresh.terminalTid ??
                fresh.terminalId)
            ?.trim(),
        deviceLabel: fresh.label,
      );
      if (!mounted) return;
      setState(() {
        _binding = false;
        _connectingDeviceId = null;
        _boundDeviceId = fresh.deviceId;
        _items = _sortedTerminals(
          listed.items,
          boundDeviceId: fresh.deviceId,
        );
        _enabled = true;
        _reachable = ok;
        _error = null;
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _binding = false;
        _connectingDeviceId = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _binding = true;
      _connectingDeviceId = _boundDeviceId;
      _error = null;
    });
    try {
      await _api.unbind();
      await SoftPosSettings.clearBinding();
      if (!mounted) return;
      setState(() {
        _binding = false;
        _connectingDeviceId = null;
        _boundDeviceId = null;
        _enabled = false;
        _reachable = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _binding = false;
        _connectingDeviceId = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: PosShimmer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PosShimmerBox(width: 180, height: 18, radius: 6),
                  const SizedBox(height: 12),
                  const PosShimmerBox(width: double.infinity, height: 36, radius: 8),
                  const SizedBox(height: 16),
                  const PosShimmerBox(width: double.infinity, height: 52, radius: 12),
                  const SizedBox(height: 10),
                  const PosShimmerBox(width: double.infinity, height: 64, radius: 14),
                  const SizedBox(height: 10),
                  const PosShimmerBox(width: double.infinity, height: 64, radius: 14),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(child: PosShimmerBox(width: double.infinity, height: 42, radius: 12)),
                      SizedBox(width: 8),
                      Expanded(child: PosShimmerBox(width: double.infinity, height: 42, radius: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SoftPOS terminals',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available SoftPOS terminals',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red.shade700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: _items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'No paired SoftPOS terminals in this branch yet.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isBound = item.deviceId == _boundDeviceId;
                        final takenByOther = item.boundToOther && !isBound;
                        final connecting =
                            _connectingDeviceId == item.deviceId;
                        final tid = (item.nearpayTerminalId ??
                                item.terminalTid ??
                                '')
                            .trim();
                        final maskedTid = tid.length <= 3
                            ? tid
                            : '***${tid.substring(tid.length - 3)}';
                        final otherName = (item.boundByName ?? '').trim();
                        final statusText = isBound
                            ? 'Connected'
                            : takenByOther
                                ? (otherName.isNotEmpty
                                    ? 'Connected by $otherName'
                                    : 'Connected by another cashier')
                                : 'Not connected';
                        final actionLabel = isBound
                            ? 'Logout'
                            : takenByOther
                                ? (otherName.isNotEmpty
                                    ? otherName
                                    : 'In use')
                                : 'Connect';
                        return Material(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _binding || takenByOther
                                ? null
                                : () {
                                    if (isBound) {
                                      _disconnect();
                                    } else {
                                      _connect(item);
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE8ECF1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      color: AppColors.secondaryLight,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          maskedTid.isNotEmpty
                                              ? '${item.label} ($maskedTid)'
                                              : item.label,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.secondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isBound
                                                    ? const Color(0xFF2E7D32)
                                                    : takenByOther
                                                        ? const Color(0xFFF9A825)
                                                        : const Color(0xFFC62828),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Flexible(
                                              child: Text(
                                                statusText,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 78,
                                      minHeight: 28,
                                      maxWidth: 120,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isBound
                                          ? const Color(0xFFC62828)
                                          : takenByOther
                                              ? const Color(0xFF90A4AE)
                                              : const Color(0xFF757575),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isBound
                                            ? const Color(0xFFC62828)
                                            : takenByOther
                                                ? const Color(0xFF90A4AE)
                                                : const Color(0xFF757575),
                                      ),
                                    ),
                                    child: connecting
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            actionLabel,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    // Keep enabled colors while binding; ignore taps.
                    onPressed: () {
                      if (_binding) return;
                      Navigator.of(context).pop(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.secondaryLight,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      l10n.posOrdersNoBtn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    // Keep enabled colors while binding; ignore taps.
                    onPressed: () {
                      if (_binding) return;
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.secondaryLight,
                      disabledBackgroundColor: AppColors.primaryLight,
                      disabledForegroundColor: AppColors.secondaryLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _orderHasProductsOrServices(PosOrder order) {
  for (final job in order.jobs) {
    if (job.isCancelledJob) continue;
    if (job.items.isNotEmpty) return true;
  }
  return order.items.isNotEmpty || order.draftPosOrderPayableDisplay > 0.0001;
}

/// SoftPOS payment amount dialog.
///
/// When [skipReadyGate] is true (Orders Hub already knows Online), open
/// immediately — do not await a LAN ping before showing UI.
/// Otherwise: settings first if SoftPOS is not reachable, then payment.
/// Returns `true` when SoftPOS approved and amount was recorded on the order.
Future<bool> showSoftPosSendRequestDialog(
  BuildContext context, {
  required PosOrder order,
  double? suggestedAmount,
  bool skipReadyGate = false,
  /// When true, amount field is read-only (Save flow from Edit customer).
  bool lockAmount = false,
}) async {
  if (!context.mounted) return false;

  // Only open SoftPOS terminals list when no terminal is Connected.
  // Bound (Connected) → send request even if handset Online/Offline.
  if (!skipReadyGate) {
    var ready = await SoftPosConnectionGuard.isSoftPosReadyForPayment();
    if (!ready) {
      await showSoftPosSettingsDialog(context);
      if (!context.mounted) return false;
      ready = await SoftPosConnectionGuard.isSoftPosReadyForPayment();
      if (!ready) {
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.posSoftPosConnectionNotStable,
        );
        return false;
      }
    }
  }

  final amount = suggestedAmount ??
      (_orderHasProductsOrServices(order)
          ? order.draftPosOrderPayableDisplay
          : 0.0);
  // Amount dialog pops before SoftPOS waiting finishes — wait on Completer.
  final completer = Completer<bool>();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    useRootNavigator: true,
    builder: (_) => _SoftPosSendRequestDialog(
      order: order,
      initialAmount: amount > 0.0001 ? amount : null,
      lockAmount: lockAmount && amount > 0.0001,
      onCompleted: (ok) {
        if (!completer.isCompleted) completer.complete(ok);
      },
    ),
  );
  return completer.future;
}

class _SoftPosSendRequestDialog extends StatefulWidget {
  const _SoftPosSendRequestDialog({
    required this.order,
    this.initialAmount,
    this.lockAmount = false,
    this.onCompleted,
  });

  final PosOrder order;
  final double? initialAmount;
  final bool lockAmount;
  final ValueChanged<bool>? onCompleted;

  @override
  State<_SoftPosSendRequestDialog> createState() =>
      _SoftPosSendRequestDialogState();
}

class _SoftPosSendRequestDialogState extends State<_SoftPosSendRequestDialog> {
  late final TextEditingController _amountCtrl;
  bool _sending = false;
  String? _deviceLabel;
  String? _terminalTid;
  bool _softPosEnabled = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    _amountCtrl = TextEditingController(
      text: initial != null && initial > 0.0001
          ? initial.toStringAsFixed(2)
          : '',
    );
    unawaited(_loadSoftPosEndpoint());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _maskTerminalId(String raw) {
    final tid = raw.trim();
    if (tid.isEmpty) return '';
    if (tid.length <= 3) return tid;
    return '***${tid.substring(tid.length - 3)}';
  }

  Future<void> _loadSoftPosEndpoint() async {
    final cfg = await SoftPosSettings.load();
    if (!mounted) return;
    setState(() {
      _softPosEnabled = cfg.enabled;
      _deviceLabel = (cfg.deviceLabel ?? '').trim().isNotEmpty
          ? cfg.deviceLabel!.trim()
          : null;
      _terminalTid = (cfg.terminalId ?? '').trim().isNotEmpty
          ? cfg.terminalId!.trim()
          : null;
    });
  }

  String get _endpointLabel {
    final name = (_deviceLabel ?? '').trim();
    final masked = _maskTerminalId(_terminalTid ?? '');
    if (name.isEmpty) {
      if (!_softPosEnabled) return 'SoftPOS not configured';
      return masked.isNotEmpty
          ? 'SoftPOS terminal ($masked)'
          : 'SoftPOS terminal';
    }
    if (!_softPosEnabled) {
      return masked.isNotEmpty ? '$name ($masked · off)' : '$name (off)';
    }
    return masked.isNotEmpty ? '$name ($masked)' : name;
  }

  Future<void> _openSettingsKeepThisDialog() async {
    if (_sending) return;
    // Keep payment dialog open — settings is nested.
    await showSoftPosSettingsDialog(context);
    if (!mounted) return;
    await _loadSoftPosEndpoint();
  }

  double? _parseAmount() {
    final raw = _amountCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _sendRequest() async {
    final amount = _parseAmount();
    if (amount == null || amount <= 0.0001) {
      ToastService.showError(context, 'Enter a valid amount');
      return;
    }
    setState(() => _sending = true);
    try {
      final settings = await SoftPosSettings.load();
      if (!settings.enabled) {
        throw const SoftPosBridgeException(
          'SoftPOS is not enabled. Save SoftPOS settings first.',
        );
      }
      final deviceId = (settings.deviceId ?? '').trim();
      if (deviceId.isEmpty) {
        throw const SoftPosBridgeException(
          'SoftPOS is not bound. Bind a terminal in SoftPOS settings first.',
        );
      }

      final order = widget.order;
      String? intentUuid;
      final token = await SessionService().getToken(role: 'cashier');
      if (token != null) {
        try {
          final intent = await PaymentIntentsService.createPosCardIntent(
            token: token,
            amount: amount,
            orderId: order.id,
            externalReference: order.invoiceNo ?? 'ORD-${order.id}',
          );
          intentUuid = intent.intentId;
        } on PaymentIntentException catch (e) {
          throw SoftPosBridgeException(
            'Could not create payment intent: ${e.message}',
          );
        }
      }

      if (!mounted) return;
      // Capture host before closing this dialog — after pop, [context] is disposed
      // and must not be used to show waiting UI or record payment (that was the bug:
      // SoftPOS charged the card but ERP never marked the order paid).
      final navigator = Navigator.of(context);
      PosViewModel? posVm;
      try {
        posVm = context.read<PosViewModel>();
      } catch (_) {}
      navigator.pop();

      if (!navigator.mounted) return;
      final host = navigator.context;

      final payRequest = SoftPosPaymentRequest(
        requestId: SoftPosBridge.newRequestId(),
        callbackUrl: '',
        amount: amount,
        orderId: order.id,
        orderNo: order.invoiceNo ?? order.id,
        intentUuid: intentUuid,
        paymentLabel: 'Tap to Pay',
        customerName: (order.customer?.name ?? '').trim().isNotEmpty
            ? order.customer!.name.trim()
            : null,
        customerMobile: (order.customer?.mobile ?? '').trim().isNotEmpty
            ? order.customer!.mobile.trim()
            : null,
        plateNo: (order.vehicle?.plateNo ?? '').trim().isNotEmpty
            ? order.vehicle!.plateNo.trim()
            : null,
        lineSummary: softPosLineSummaryFromOrder(order),
        lineItems: softPosLineItemsFromOrder(order),
        totalBeforeDiscount: softPosTotalBeforeDiscountFromOrder(order),
        totalDiscount: softPosTotalDiscountFromOrder(order),
        vatAmount: softPosVatFromOrder(order, amount: amount),
        vehicleMake: (order.vehicle?.make ?? '').trim().isNotEmpty
            ? order.vehicle!.make.trim()
            : null,
        vehicleModel: (order.vehicle?.model ?? '').trim().isNotEmpty
            ? order.vehicle!.model.trim()
            : null,
        vehicleVin: (order.vehicle?.vin ?? '').trim().isNotEmpty
            ? order.vehicle!.vin!.trim()
            : null,
        mileage: order.odometerReading > 0 ? order.odometerReading : null,
        customerType: softPosCustomerTypeFromOrder(order),
        customerTaxId: (order.customer?.vatNumber ?? '').trim().isNotEmpty
            ? order.customer!.vatNumber.trim()
            : null,
      );
      final paymentFuture =
          SoftPosBridge.requestPaymentViaSocket(request: payRequest);
      final approved = await showSoftPosWaitingDialog(
        host,
        amount: amount,
        paymentFuture: paymentFuture.then((r) => r.approved),
      );
      if (!navigator.mounted) {
        widget.onCompleted?.call(false);
        return;
      }
      if (!approved) {
        ToastService.showError(host, 'SoftPOS payment was not approved');
        widget.onCompleted?.call(false);
        return;
      }

      // Record received amount against the order (methods stay unlocked).
      if (posVm != null) {
        final err = await posVm.recordSoftPosAppBarPayment(
          order: order,
          paidAmount: amount,
          intentUuid: intentUuid,
        );
        if (!navigator.mounted) {
          widget.onCompleted?.call(false);
          return;
        }
        if (err != null) {
          ToastService.showError(host, err);
          widget.onCompleted?.call(false);
          return;
        }
      } else {
        ToastService.showError(
          host,
          'Payment approved on SoftPOS but could not be recorded on the order. Sync and retry.',
        );
        widget.onCompleted?.call(false);
        return;
      }
      ToastService.showSuccess(
        host,
        'Payment received — SAR ${amount.toStringAsFixed(2)} recorded',
      );
      widget.onCompleted?.call(true);
    } on SoftPosBridgeException catch (e) {
      widget.onCompleted?.call(false);
      if (mounted) ToastService.showError(context, e.message);
    } catch (e) {
      widget.onCompleted?.call(false);
      if (mounted) ToastService.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final plate = (order.vehicle?.plateNo ?? order.plateNumber).trim();
    final orderLine = plate.isNotEmpty
        ? 'Order #${order.id} · $plate'
        : 'Order #${order.id}';

    return PopScope(
      canPop: !_sending,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/tap_to_pay.png',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.contactless_rounded,
                    size: 72,
                    color: AppColors.secondaryLight.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SoftPOS payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                orderLine,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _sending ? null : _openSettingsKeepThisDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _endpointLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _softPosEnabled
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFC62828),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    _softPosEnabled
                                        ? 'Connected'
                                        : 'Disconnected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                autofocus: !widget.lockAmount,
                enabled: !_sending,
                readOnly: widget.lockAmount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[\d٠-٩]*[.,]?[\d٠-٩]{0,2}$'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount (SAR)',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryLight,
                      width: 1.4,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sending
                          ? null
                          : () {
                              widget.onCompleted?.call(false);
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendRequest,
                      style: AppButtonBusy.elevatedLocked(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _sending
                          ? AppButtonBusy.loaderOnFill(
                              AppColors.primaryLight,
                              size: 20,
                            )
                          : const Text(
                              'Send Request',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Waiting overlay while SoftPOS processes the demo payment.
Future<bool> showSoftPosWaitingDialog(
  BuildContext context, {
  required double amount,
  required Future<bool> paymentFuture,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SoftPosWaitingDialog(
      amount: amount,
      paymentFuture: paymentFuture,
    ),
  );
  return result ?? false;
}

class _SoftPosWaitingDialog extends StatefulWidget {
  final double amount;
  final Future<bool> paymentFuture;

  const _SoftPosWaitingDialog({
    required this.amount,
    required this.paymentFuture,
  });

  @override
  State<_SoftPosWaitingDialog> createState() => _SoftPosWaitingDialogState();
}

class _SoftPosWaitingDialogState extends State<_SoftPosWaitingDialog> {
  String _status = 'Waiting for SoftPOS…';
  bool _done = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _cancelPayment() async {
    if (_done || _cancelled) return;
    setState(() {
      _cancelled = true;
      _status = 'Cancelling…';
    });
    await SoftPosBridge.cancelActivePayment();
  }

  Future<void> _run() async {
    try {
      final ok = await widget.paymentFuture;
      if (!mounted) return;
      setState(() {
        _done = true;
        _status = ok
            ? 'Payment approved'
            : _cancelled
                ? 'Payment cancelled'
                : 'Payment declined';
      });
      if (ok) {
        ToastService.showSuccess(context, 'SoftPOS payment approved');
      }
      final delayMs = ok ? 600 : (_cancelled ? 0 : 600);
      if (delayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
      if (mounted) Navigator.pop(context, ok);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _done = true;
        _status = e.toString().replaceFirst('SoftPosBridgeException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = _done && !_status.contains('approved') && !_cancelled;
    final isWaiting = !_done && !_cancelled;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/tap_to_pay.png',
                          height: 150,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.contactless_outlined,
                            size: 88,
                            color: AppColors.secondaryLight
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Soft',
                            style: AppTextStyles.h2.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondaryLight,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'POS',
                            style: AppTextStyles.h2.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (isWaiting)
                        Text(
                          'Complete the card tap on the SoftPOS device',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondaryLight
                                .withValues(alpha: 0.62),
                            height: 1.45,
                          ),
                        ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${widget.amount.toStringAsFixed(2)} SAR',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (isWaiting) ...[
                        const SizedBox(height: 22),
                        PosShimmer(
                          child: Column(
                            children: const [
                              PosShimmerBox(
                                width: double.infinity,
                                height: 12,
                                radius: 6,
                              ),
                              SizedBox(height: 8),
                              PosShimmerBox(width: 160, height: 12, radius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryLight
                                .withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isError
                                ? Colors.red.shade700
                                : AppColors.secondaryLight
                                    .withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (isError) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.secondaryLight,
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isWaiting)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _cancelPayment,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: AppColors.secondaryLight
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Orders Hub app bar — SoftPOS · Connected / Disconnected.
class OrdersHubSoftPosAppBarAction extends StatefulWidget {
  const OrdersHubSoftPosAppBarAction({super.key});

  @override
  State<OrdersHubSoftPosAppBarAction> createState() =>
      _OrdersHubSoftPosAppBarActionState();
}

class _OrdersHubSoftPosAppBarActionState
    extends State<OrdersHubSoftPosAppBarAction> with WidgetsBindingObserver {
  bool _enabled = false;
  bool? _reachable;
  String? _deviceLabel;
  bool _editDialogOpen = false;
  Timer? _pingTimer;

  SoftPosLinkStatus get _status => SoftPosConnectionGuard.resolveStatus(
        enabled: _enabled,
        reachable: _reachable,
      );

  String get _pillText {
    final name = (_deviceLabel ?? '').trim();
    // Bound SoftPOS: show device name only — no "Connected" label.
    if (!_enabled) return 'SoftPOS · Disconnected';
    if (name.isNotEmpty) return 'SoftPOS · $name';
    return 'SoftPOS';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_pingNow());
    _pingTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_pingNow()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_pingNow());
    }
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pingNow() async {
    // Authoritative source: server binding for this cashier's current branch.
    SoftPosTerminalItem? serverBound;
    var serverChecked = false;
    try {
      serverBound = await SoftPosTerminalsApi().getBinding();
      serverChecked = true;
    } catch (_) {
      // Keep last local state if API is unreachable.
    }

    if (serverChecked) {
      if (serverBound == null) {
        await SoftPosSettings.clearBinding();
        if (!mounted) return;
        setState(() {
          _enabled = false;
          _reachable = false;
          _deviceLabel = null;
        });
        return;
      }
      final host = (serverBound.lanHost ?? '').trim();
      await SoftPosSettings.save(
        enabled: true,
        host: SoftPosSettings.isPlausibleHost(host)
            ? host
            : SoftPosSettings.defaultHost,
        port: serverBound.lanPort ?? SoftPosSettings.defaultPort,
        deviceId: serverBound.deviceId,
        terminalId: (serverBound.nearpayTerminalId ??
                serverBound.terminalTid ??
                serverBound.terminalId)
            ?.trim(),
        deviceLabel: serverBound.label,
      );
    }

    final cfg = await SoftPosSettings.load();
    if (!mounted) return;
    final label = (cfg.deviceLabel ?? '').trim();
    if (!cfg.enabled) {
      setState(() {
        _enabled = false;
        _reachable = false;
        _deviceLabel = null;
      });
      return;
    }
    // Mark Connected immediately; keep last Online/Offline while re-pinging
    // so the pill does not flicker to Checking every few seconds.
    if (!_enabled || _deviceLabel != label) {
      setState(() {
        _enabled = true;
        _deviceLabel = label.isEmpty ? null : label;
      });
    }
    final deviceId = (cfg.deviceId ?? '').trim();
    final ok = deviceId.isNotEmpty
        ? await SoftPosBridge.isBoundDeviceOnline()
        : false;
    if (mounted) {
      setState(() {
        _enabled = true;
        _reachable = ok;
        _deviceLabel = label.isEmpty ? null : label;
      });
    }
  }

  /// Tap opens SoftPOS terminal settings only.
  /// Payment receive popup lives under Edit customer → Tap to Pay.
  Future<void> _onSoftPosTap() async {
    if (_editDialogOpen) return;
    _editDialogOpen = true;
    try {
      await showSoftPosSettingsDialog(context);
      if (!mounted) return;
      await _pingNow();
    } finally {
      if (mounted) _editDialogOpen = false;
    }
  }

  Future<void> _onSoftPosLongPress() async {
    if (_editDialogOpen) return;
    _editDialogOpen = true;
    try {
      final ok = await showSoftPosSettingsDialog(context);
      if (!mounted) return;
      await _pingNow();
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SoftPOS settings saved · ${_status.label}'),
          ),
        );
      }
    } finally {
      if (mounted) _editDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final status = _status;

    final IconData statusIcon;
    final Color statusColor;
    switch (status) {
      case SoftPosLinkStatus.online:
      case SoftPosLinkStatus.offline:
      case SoftPosLinkStatus.checking:
        statusIcon = Icons.phone_android_rounded;
        statusColor = const Color(0xFF2E7D32);
      case SoftPosLinkStatus.disconnected:
        statusIcon = Icons.link_off;
        statusColor = const Color(0xFFC62828);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onLongPress: _editDialogOpen ? null : _onSoftPosLongPress,
        child: PosAppBarSingleLinePill(
          text: _pillText,
          trailingIcon: statusIcon,
          trailingIconColor: statusColor,
          onTap: _editDialogOpen ? null : _onSoftPosTap,
          maxWidth: isTablet ? 260 : 220,
        ),
      ),
    );
  }
}
