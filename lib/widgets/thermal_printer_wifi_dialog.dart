import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_button_busy.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'app_bar_live_clock.dart';
import '../services/thermal_printer_settings.dart';

/// Wi‑Fi ESC/POS printer IP/port (SharedPreferences). Returns `true` when saved.
Future<bool> showThermalPrinterWifiDialog(
  BuildContext context, {
  String primaryButtonLabel = 'Save',
  bool ipOnly = false,
}) async {
  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => _ThermalPrinterWifiDialog(
      primaryButtonLabel: primaryButtonLabel,
      ipOnly: ipOnly,
    ),
  );

  return result ?? false;
}

/// Orders Hub app bar — same light-yellow pill as [AppBarDateTimeBlock].
class OrdersHubThermalPrinterAppBarAction extends StatefulWidget {
  const OrdersHubThermalPrinterAppBarAction({super.key});

  @override
  State<OrdersHubThermalPrinterAppBarAction> createState() =>
      _OrdersHubThermalPrinterAppBarActionState();
}

class _OrdersHubThermalPrinterAppBarActionState
    extends State<OrdersHubThermalPrinterAppBarAction> {
  late Future<({String host, int port})> _cfgFuture;
  bool _editDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _cfgFuture = ThermalPrinterSettings.load();
    });
  }

  Future<void> _openEdit() async {
    if (_editDialogOpen) return;
    _editDialogOpen = true;
    try {
      final ok = await showThermalPrinterWifiDialog(
        context,
        ipOnly: true,
      );
      if (!mounted) return;
      if (ok) {
        _reload();
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.posThermalPrinterSaved)),
        );
      }
    } finally {
      _editDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return FutureBuilder<({String host, int port})>(
      future: _cfgFuture,
      builder: (context, snap) {
        final line = 'Printer';

        return Directionality(
          textDirection: TextDirection.ltr,
          child: PosAppBarSingleLinePill(
            text: line,
            trailingIcon: Icons.edit_outlined,
            onTap: _editDialogOpen ? null : _openEdit,
            maxWidth: isTablet ? 118 : 100,
          ),
        );
      },
    );
  }
}

class _ThermalPrinterWifiDialog extends StatefulWidget {
  const _ThermalPrinterWifiDialog({
    required this.primaryButtonLabel,
    this.ipOnly = false,
  });

  final String primaryButtonLabel;
  final bool ipOnly;

  @override
  State<_ThermalPrinterWifiDialog> createState() =>
      _ThermalPrinterWifiDialogState();
}

class _ThermalPrinterWifiDialogState extends State<_ThermalPrinterWifiDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  String? _error;
  bool _saving = false;
  int _savedPort = ThermalPrinterSettings.defaultPort;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final cfg = await ThermalPrinterSettings.load();
    if (!mounted) return;
    _ipController.text = cfg.host;
    _portController.text = cfg.port.toString();
    setState(() => _savedPort = cfg.port);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final rawIp = _ipController.text.trim();
    if (!ThermalPrinterSettings.isPlausibleHost(rawIp)) {
      setState(() => _error = l10n.posThermalPrinterInvalidHost);
      return;
    }
    int port = _savedPort;
    if (!widget.ipOnly) {
      port = int.tryParse(_portController.text.trim()) ?? -1;
      if (port < 1 || port > 65535) {
        setState(() => _error = l10n.posThermalPrinterInvalidPort);
        return;
      }
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ThermalPrinterSettings.save(rawIp, port);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.posThermalPrinterSaveFailed;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.ipOnly
        ? l10n.posThermalPrinterIpLabel
        : l10n.posThermalPrinterTitle;
    final ipHint = widget.ipOnly
        ? l10n.posThermalPrinterIpEnterPlaceholder
        : l10n.posThermalPrinterIpHint;
    final saveLabel = widget.primaryButtonLabel == 'Save'
        ? l10n.posCommonSave
        : widget.primaryButtonLabel;

    InputDecoration fieldDecoration({
      required String label,
      String? hint,
      String? helper,
      String? error,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: error,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(fontSize: 20),
            ),
            if (!widget.ipOnly) ...[
              const SizedBox(height: 8),
              Text(
                l10n.posThermalPrinterPortHelper,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              decoration: fieldDecoration(
                label: l10n.posThermalPrinterIpLabel,
                hint: ipHint,
                error: _error,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              autofocus: true,
            ),
            if (!widget.ipOnly) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                decoration: fieldDecoration(
                  label: l10n.posThermalPrinterPortLabel,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.secondaryLight,
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.posOrdersNoBtn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: AppButtonBusy.elevatedLocked(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.onPrimaryLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _saving
                        ? AppButtonBusy.loaderOnFill(
                            AppColors.primaryLight,
                            size: 20,
                          )
                        : Text(
                            saveLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
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
