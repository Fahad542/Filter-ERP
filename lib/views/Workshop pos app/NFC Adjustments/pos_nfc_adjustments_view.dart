import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/softpos_adjustment_model.dart';
import '../../../services/invoice_dialog_launcher.dart';
import '../../../utils/app_button_busy.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/business_timezone.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import '../Home Screen/pos_view_model.dart';

/// SoftPOS app-bar prepaid vs order/invoice total — mismatch list for cashiers.
class PosNfcAdjustmentsView extends StatefulWidget {
  const PosNfcAdjustmentsView({super.key});

  @override
  State<PosNfcAdjustmentsView> createState() => _PosNfcAdjustmentsViewState();
}

class _PosNfcAdjustmentsViewState extends State<PosNfcAdjustmentsView> {
  bool _loading = false;
  String? _error;
  List<SoftPosAdjustmentRow> _rows = const [];
  double _totalDiff = 0;
  String? _openingInvoiceOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vm = context.read<PosViewModel>();
      final token = await vm.sessionService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Sign in again.');
      }
      final res = await vm.posRepository.getSoftPosAdjustments(token);
      if (!mounted) return;
      setState(() {
        _rows = res.items;
        _totalDiff = res.totalDifference;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _rows = const [];
        _totalDiff = 0;
      });
      ToastService.showError(
        context,
        _error ?? 'Failed to load Soft POS adjustments',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final wall = BusinessTimezone.toWall(dt);
    final locale = Localizations.localeOf(context).languageCode;
    try {
      return DateFormat('dd MMM yyyy · hh:mm a', locale).format(wall);
    } catch (_) {
      return DateFormat('dd MMM yyyy · hh:mm a').format(wall);
    }
  }

  Future<void> _openInvoice(SoftPosAdjustmentRow row) async {
    final invoiceNo = (row.invoiceNo ?? '').trim();
    if (invoiceNo.isEmpty) {
      ToastService.showInfo(
        context,
        'Invoice not generated yet for this order.',
      );
      return;
    }
    final orderId = row.orderId.trim();
    if (orderId.isEmpty) return;
    if (_openingInvoiceOrderId != null) return;

    setState(() => _openingInvoiceOrderId = orderId);
    // Let the button loader paint before the network call.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    try {
      final posVm = context.read<PosViewModel>();
      final response = await posVm.fetchInvoiceByOrder(orderId);
      if (!mounted) return;
      if (response == null || !response.success || response.invoice == null) {
        ToastService.showError(
          context,
          response?.message.isNotEmpty == true
              ? response!.message
              : 'Could not load invoice.',
        );
        return;
      }
      final inv = response.invoice!;
      final paymentText = invoiceDialogPaymentMethodText(inv);
      await showInvoiceDialogAfterPrintPrefetch(
        context: context,
        invoice: inv,
        paymentMethodText: paymentText,
        barrierDismissible: true,
        builder: (ctx) => InvoiceDialog(invoice: inv),
      );
    } finally {
      if (mounted && _openingInvoiceOrderId == orderId) {
        setState(() => _openingInvoiceOrderId = null);
      }
    }
  }

  void _openDetails(SoftPosAdjustmentRow row, bool isTablet) {
    final over = row.difference > 0.05;
    final under = row.difference < -0.05;
    final diffColor = over
        ? const Color(0xFFC62828)
        : under
            ? const Color(0xFF1565C0)
            : AppColors.secondaryLight;
    final diffLabel = over
        ? 'Underpaid'
        : under
            ? 'Overpaid'
            : 'Difference';
    final invoiceNo = (row.invoiceNo ?? '').trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: isTablet ? 460 : MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 14,
                  vertical: isTablet ? 14 : 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADJUSTMENT DETAILS',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row.plate.isNotEmpty
                                ? row.plate
                                : '#${row.orderId}',
                            style: TextStyle(
                              color: const Color(0xFF1E2124),
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$diffLabel ${row.difference >= 0 ? '+' : ''}${row.difference.toStringAsFixed(2)} SAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: diffColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isTablet ? 18 : 14),
                child: Column(
                  children: [
                    _detailRow('Order ID', '#${row.orderId}'),
                    if (row.customerName.isNotEmpty)
                      _detailRow('Customer', row.customerName),
                    if (row.plate.isNotEmpty) _detailRow('Plate', row.plate),
                    _detailRow('Status', row.status.isEmpty ? '—' : row.status),
                    _detailRow(
                      'Customer paid',
                      'SAR ${row.paidAmount.toStringAsFixed(2)}',
                    ),
                    _detailRow(
                      invoiceNo.isNotEmpty ? 'Invoice total' : 'Order total',
                      'SAR ${row.orderTotal.toStringAsFixed(2)}',
                    ),
                    if (invoiceNo.isNotEmpty)
                      _detailRow('Invoice', invoiceNo),
                    if (_formatDateTime(row.orderCreatedAtDate).isNotEmpty)
                      _detailRow(
                        'Order placed',
                        _formatDateTime(row.orderCreatedAtDate),
                      ),
                    if (_formatDateTime(row.invoiceIssuedAtDate).isNotEmpty)
                      _detailRow(
                        'Invoice generated',
                        _formatDateTime(row.invoiceIssuedAtDate),
                      )
                    else
                      _detailRow('Invoice generated', 'Not invoiced yet'),
                    if (_formatDateTime(row.prepaidAtDate).isNotEmpty)
                      _detailRow(
                        'SoftPOS paid',
                        _formatDateTime(row.prepaidAtDate),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 18 : 14,
                  0,
                  isTablet ? 18 : 14,
                  isTablet ? 16 : 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryLight,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (invoiceNo.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            unawaited(_openInvoice(row));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.secondaryLight,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.posProductViewInvoice,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2124),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final l10n = AppLocalizations.of(context)!;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: PosScreenAppBar(
          title: 'Soft POS Adjustment',
          showBackButton: false,
          showHamburger: true,
          onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _refresh,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: wrapPosShellRailBody(
          context,
          Column(
            children: [
              Expanded(
                child: _loading && _rows.isEmpty
                    ? _SoftPosAdjustmentShimmerGrid(isTablet: isTablet)
                    : _rows.isEmpty
                        ? Center(
                            child: Text(
                              _error == null
                                  ? 'No SoftPOS amount mismatches'
                                  : _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isTablet ? 3 : 1,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              // Fits header + times + amounts + buttons (was 1px short at 208).
                              mainAxisExtent: isTablet ? 214 : 222,
                            ),
                            itemCount: _rows.length,
                            itemBuilder: (context, i) => Align(
                              alignment: Alignment.topCenter,
                              child: _buildAdjustmentCard(
                                _rows[i],
                                isTablet: isTablet,
                                l10n: l10n,
                              ),
                            ),
                          ),
              ),
              _buildBottomBar(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustmentCard(
    SoftPosAdjustmentRow row, {
    required bool isTablet,
    required AppLocalizations l10n,
  }) {
    final over = row.difference > 0.05;
    final under = row.difference < -0.05;
    final diffColor = over
        ? const Color(0xFFC62828)
        : under
            ? const Color(0xFF1565C0)
            : AppColors.secondaryLight;
    // orderTotal - paid: positive = shortfall (underpaid), negative = overpaid
    final diffLabel = over
        ? 'Underpaid'
        : under
            ? 'Overpaid'
            : 'Difference';
    final invoiceNo = (row.invoiceNo ?? '').trim();
    final opening = _openingInvoiceOrderId == row.orderId;
    final orderWhen = _formatDateTime(row.orderCreatedAtDate);
    final invoiceWhen = _formatDateTime(row.invoiceIssuedAtDate);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 12 : 10,
                isTablet ? 10 : 9,
                isTablet ? 12 : 10,
                4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.nfc_rounded,
                      color: AppColors.secondaryLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.plate.isNotEmpty
                                    ? row.plate
                                    : '#${row.orderId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Color(0xFF1E2124),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$diffLabel ${row.difference >= 0 ? '+' : ''}${row.difference.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  color: diffColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          row.customerName.isNotEmpty
                              ? '${row.customerName} · #${row.orderId}'
                              : 'Order #${row.orderId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoiceNo.isNotEmpty
                              ? 'Invoice $invoiceNo'
                              : 'Not invoiced yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (orderWhen.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Order: $orderWhen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          invoiceWhen.isNotEmpty
                              ? 'Invoice: $invoiceWhen'
                              : 'Invoice: Not generated yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 12 : 10,
                2,
                isTablet ? 12 : 10,
                6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _amountCell('Customer paid', row.paidAmount),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _amountCell(
                      invoiceNo.isNotEmpty ? 'Invoice total' : 'Order total',
                      row.orderTotal,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 10 : 8,
                0,
                isTablet ? 10 : 8,
                isTablet ? 8 : 7,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: opening
                          ? null
                          : () => _openDetails(row, isTablet),
                      style: AppButtonBusy.elevatedLocked(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                      ).copyWith(
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(
                            vertical: isTablet ? 9 : 8,
                            horizontal: 6,
                          ),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.techOrdersViewDetails,
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: opening ? null : () => _openInvoice(row),
                      style: AppButtonBusy.elevatedLocked(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                      ).copyWith(
                        minimumSize: WidgetStateProperty.all(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(
                            vertical: isTablet ? 9 : 8,
                            horizontal: 6,
                          ),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: opening
                          ? SizedBox(
                              height: isTablet ? 18 : 16,
                              child: Center(
                                child: AppButtonBusy.loaderOnFill(
                                  AppColors.primaryLight,
                                  size: 16,
                                ),
                              ),
                            )
                          : Text(
                              l10n.posProductViewInvoice,
                              style: TextStyle(
                                fontSize: isTablet ? 11 : 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondaryLight,
                              ),
                              maxLines: 1,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountCell(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SAR ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2124),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    final sign = _totalDiff >= 0 ? '+' : '';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total difference: ${l10n.ownerCurrencySar} $sign${_totalDiff.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.onSecondaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${_rows.length} mismatch${_rows.length == 1 ? '' : 'es'} · SoftPOS vs invoice',
                      style: TextStyle(
                        color: AppColors.onSecondaryLight
                            .withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftPosAdjustmentShimmerGrid extends StatelessWidget {
  const _SoftPosAdjustmentShimmerGrid({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: isTablet ? 214 : 222,
      ),
      itemCount: isTablet ? 6 : 4,
      itemBuilder: (_, __) => const Align(
        alignment: Alignment.topCenter,
        child: _SoftPosAdjustmentShimmerCard(),
      ),
    );
  }
}

class _SoftPosAdjustmentShimmerCard extends StatelessWidget {
  const _SoftPosAdjustmentShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const PosShimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosShimmerBox(width: 34, height: 34, radius: 9),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: PosShimmerBox(
                              width: double.infinity,
                              height: 12,
                              radius: 6,
                            ),
                          ),
                          SizedBox(width: 8),
                          PosShimmerBox(width: 78, height: 18, radius: 7),
                        ],
                      ),
                      SizedBox(height: 8),
                      PosShimmerBox(
                        width: double.infinity,
                        height: 10,
                        radius: 5,
                      ),
                      SizedBox(height: 6),
                      PosShimmerBox(width: 120, height: 10, radius: 5),
                      SizedBox(height: 6),
                      PosShimmerBox(width: 140, height: 10, radius: 5),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 42,
                    radius: 8,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 42,
                    radius: 8,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 34,
                    radius: 8,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 34,
                    radius: 8,
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
