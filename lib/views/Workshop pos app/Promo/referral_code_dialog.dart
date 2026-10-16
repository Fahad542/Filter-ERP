import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../models/pos_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/toast_service.dart';
import '../Home Screen/pos_view_model.dart';

/// Order Summary / Takeaway: enter or scan a marketing referral code.
/// UI matches POS logout confirm dialog (radius 24, centered title, pill actions).
class ReferralCodeDialog extends StatefulWidget {
  const ReferralCodeDialog({
    super.key,
    this.order,
    required this.orderAmountInclVat,
    this.appliedReferralCode = '',
    this.customerMobile,
    this.onApplyLocal,
    this.onRemoveLocal,
  });

  final PosOrder? order;
  final double orderAmountInclVat;
  final String appliedReferralCode;
  final String? customerMobile;

  /// Takeaway / cart mode — no order stamp; parent keeps local state.
  final Future<bool> Function(String code, double discountInclVat)? onApplyLocal;
  final Future<bool> Function()? onRemoveLocal;

  static Future<void> show(
    BuildContext context, {
    required PosOrder order,
    required double orderAmountInclVat,
    String appliedReferralCode = '',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => ReferralCodeDialog(
        order: order,
        orderAmountInclVat: orderAmountInclVat,
        appliedReferralCode: appliedReferralCode,
      ),
    );
  }

  /// Takeaway cart — validate via API, apply/remove via callbacks.
  static Future<void> showLocal(
    BuildContext context, {
    required double orderAmountInclVat,
    String appliedReferralCode = '',
    String? customerMobile,
    required Future<bool> Function(String code, double discountInclVat)
        onApply,
    required Future<bool> Function() onRemove,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => ReferralCodeDialog(
        orderAmountInclVat: orderAmountInclVat,
        appliedReferralCode: appliedReferralCode,
        customerMobile: customerMobile,
        onApplyLocal: onApply,
        onRemoveLocal: onRemove,
      ),
    );
  }

  @override
  State<ReferralCodeDialog> createState() => _ReferralCodeDialogState();
}

class _ReferralCodeDialogState extends State<ReferralCodeDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _previewMessage;
  bool _previewValid = false;
  double _previewDiscount = 0;

  bool get _isLocalMode => widget.onApplyLocal != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.appliedReferralCode.trim();
    if (existing.isNotEmpty) {
      _controller.text = existing;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _checkCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _previewValid = false;
        _previewMessage = _isAr ? 'أدخل رمز الإحالة' : 'Enter a referral code';
        _previewDiscount = 0;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final vm = context.read<PosViewModel>();
      final token = await vm.sessionService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      final mobile = (widget.customerMobile ??
              widget.order?.customer?.mobile ??
              '')
          .trim();
      final res = await vm.posRepository.applyReferralCode(
        code,
        token,
        orderId: widget.order?.id,
        orderAmountInclVat: widget.orderAmountInclVat,
        customerMobile: mobile.isEmpty ? null : mobile,
      );
      if (!mounted) return;
      final valid = res['valid'] == true;
      setState(() {
        _previewValid = valid;
        _previewMessage = res['message']?.toString();
        _previewDiscount =
            double.tryParse(res['discountAmount']?.toString() ?? '0') ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewValid = false;
        _previewMessage = e.toString().replaceFirst('Exception: ', '');
        _previewDiscount = 0;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (_isLocalMode) {
        final ok = await widget.onApplyLocal!(code, _previewDiscount);
        if (!mounted) return;
        if (ok) {
          ToastService.showSuccess(
            context,
            code,
            title: _isAr ? 'تم تطبيق رمز الإحالة' : 'Referral applied',
          );
          Navigator.of(context).pop();
        } else {
          ToastService.showError(
            context,
            _isAr ? 'رمز الإحالة غير صالح' : 'Invalid referral code',
          );
        }
        return;
      }

      final order = widget.order;
      if (order == null) return;
      final vm = context.read<PosViewModel>();
      final ok = await vm.applyReferralCodeToOrder(
        order: order,
        referralCode: code,
      );
      if (!mounted) return;
      if (ok) {
        ToastService.showSuccess(
          context,
          code,
          title: _isAr ? 'تم تطبيق رمز الإحالة' : 'Referral applied',
        );
        Navigator.of(context).pop();
      } else {
        ToastService.showError(
          context,
          vm.errorMessage ??
              (_isAr ? 'رمز الإحالة غير صالح' : 'Invalid referral code'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      if (_isLocalMode) {
        final ok = await widget.onRemoveLocal!();
        if (!mounted) return;
        if (ok) {
          ToastService.showSuccess(
            context,
            _isAr ? 'تمت إزالة رمز الإحالة' : 'Referral removed',
            messageOnly: true,
          );
          Navigator.of(context).pop();
        } else {
          ToastService.showError(
            context,
            _isAr ? 'تعذر إزالة الرمز' : 'Failed to remove referral',
          );
        }
        return;
      }

      final order = widget.order;
      if (order == null) return;
      final vm = context.read<PosViewModel>();
      final ok = await vm.removeReferralCodeFromOrder(order);
      if (!mounted) return;
      if (ok) {
        ToastService.showSuccess(
          context,
          _isAr ? 'تمت إزالة رمز الإحالة' : 'Referral removed',
          messageOnly: true,
        );
        Navigator.of(context).pop();
      } else {
        ToastService.showError(
          context,
          vm.errorMessage ??
              (_isAr ? 'تعذر إزالة الرمز' : 'Failed to remove referral'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ReferralQrScanPage()),
    );
    if (!mounted || code == null || code.trim().isEmpty) return;
    setState(() {
      _controller.text = code.trim();
      _previewMessage = null;
      _previewValid = false;
      _previewDiscount = 0;
    });
    await _checkCode();
  }

  @override
  Widget build(BuildContext context) {
    final hasApplied = widget.appliedReferralCode.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isAr ? 'رمز الإحالة' : 'Referral code',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAr
                  ? 'أدخل رمز الإحالة المسجّل في النظام أو امسحه من QR.'
                  : 'Enter a referral code from the system, or scan its QR.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              enabled: !_busy,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryLight,
              ),
              decoration: InputDecoration(
                hintText: _isAr ? 'مثال: AHMED10' : 'e.g. AHMED10',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.secondaryLight,
                    width: 1.4,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                suffixIcon: IconButton(
                  tooltip: _isAr ? 'مسح QR' : 'Scan QR',
                  onPressed: _busy ? null : _scanQr,
                  icon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              onSubmitted: (_) => _checkCode(),
            ),
            if (_previewMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _previewValid && _previewDiscount > 0
                    ? (_isAr
                        ? '$_previewMessage — خصم ${_previewDiscount.toStringAsFixed(2)} ر.س'
                        : '$_previewMessage — discount SAR ${_previewDiscount.toStringAsFixed(2)}')
                    : _previewMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: _previewValid
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.secondaryLight),
                    ),
                    child: Text(
                      _isAr ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            await _checkCode();
                            if (!mounted || !_previewValid) return;
                            await _apply();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondaryLight,
                            ),
                          )
                        : Text(
                            _isAr ? 'تطبيق' : 'Apply',
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (hasApplied) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _remove,
                child: Text(
                  _isAr ? 'إزالة رمز الإحالة' : 'Remove referral code',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReferralQrScanPage extends StatefulWidget {
  const _ReferralQrScanPage();

  @override
  State<_ReferralQrScanPage> createState() => _ReferralQrScanPageState();
}

class _ReferralQrScanPageState extends State<_ReferralQrScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isAr ? 'مسح رمز الإحالة' : 'Scan referral QR'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final raw = capture.barcodes
              .map((b) => b.rawValue?.trim() ?? '')
              .firstWhere((v) => v.isNotEmpty, orElse: () => '');
          if (raw.isEmpty) return;
          _handled = true;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
