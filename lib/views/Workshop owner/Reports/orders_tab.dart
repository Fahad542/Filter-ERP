import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import '../../../../utils/toast_service.dart';
import '../../../../widgets/pos_widgets.dart';
import '../../../../services/invoice_dialog_launcher.dart';
import 'reports_management_view_model.dart';

class _OrderItem {
  final RecentOrder source;
  final String invoiceNo;
  final String type;
  final String dateTime;
  final String customerName;
  final String plateNo;
  final double total;

  _OrderItem({
    required this.source,
    required this.invoiceNo,
    required this.type,
    required this.dateTime,
    required this.customerName,
    required this.plateNo,
    required this.total,
  });
}

class OrdersTab extends StatelessWidget {
  final String searchQuery;
  final String selectedPaymentMethod;
  final ReportsManagementViewModel vm;

  const OrdersTab({
    super.key,
    required this.searchQuery,
    required this.selectedPaymentMethod,
    required this.vm,
  });

  static String _fmtDateTime(BuildContext context, String isoOrDate) {
    final dt = DateTime.tryParse(isoOrDate)?.toLocal();
    if (dt == null || isoOrDate.isEmpty) return isoOrDate;
    final locale = Localizations.localeOf(context).toString();
    final formatted =
        DateFormat('MMM d, y, h:mm a', locale).format(dt);
    return ownerLocalizeDigits(context, formatted);
  }

  static String _displayInvoice(RecentOrder o) {
    if (o.invoiceNo.trim().isNotEmpty) return o.invoiceNo;
    if (o.salesOrderId.isNotEmpty) return o.salesOrderId;
    return '—';
  }

  static String _displayType(BuildContext context, RecentOrder o) {
    final l10n = AppLocalizations.of(context)!;
    final src = o.orderSource.trim().toLowerCase().replaceAll('-', '_');
    if (src.isEmpty) return '—';
    if (src == 'walk_in' || src == 'walk in' || src == 'walkin') {
      return l10n.ownerReportsOrderWalkIn;
    }
    return o.orderSource
        .replaceAll('_', ' ')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  List<_OrderItem> _orders(BuildContext context) {
    return vm.recentOrders
        .map(
          (o) => _OrderItem(
            source: o,
            invoiceNo: _displayInvoice(o),
            type: _displayType(context, o),
            dateTime: _fmtDateTime(
              context,
              o.issuedAt.isNotEmpty ? o.issuedAt : o.invoiceDate,
            ),
            customerName: o.displayCustomerName,
            plateNo: o.plateNo,
            total: o.invoiceTotal,
          ),
        )
        .toList();
  }

  Future<void> _openInvoice(BuildContext context, RecentOrder order) async {
    final l10n = AppLocalizations.of(context)!;
    final invoiceId = order.invoiceId.trim();
    if (invoiceId.isEmpty) {
      ToastService.showError(context, l10n.ownerReportsNoInvoiceYet);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      ),
    );

    try {
      final invoice = await vm.fetchRecentOrderInvoice(invoiceId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (invoice == null) {
        ToastService.showError(context, l10n.ownerReportsCouldNotLoadInvoice);
        return;
      }

      final paymentText = invoiceDialogPaymentMethodText(invoice);
      await showInvoiceDialogAfterPrintPrefetch(
        context: context,
        invoice: invoice,
        paymentMethodText: paymentText,
        barrierDismissible: true,
        builder: (ctx) => InvoiceDialog(
          invoice: invoice,
          onDone: () {},
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ToastService.showError(context, l10n.ownerReportsFailedOpenInvoice);
      debugPrint('[OrdersTab] open invoice error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final q = searchQuery.trim().toLowerCase();
    final orders = _orders(context);
    final filtered = orders.where((o) {
      if (q.isEmpty) return true;
      return o.invoiceNo.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.plateNo.toLowerCase().contains(q) ||
          o.type.toLowerCase().contains(q);
    }).toList();

    assert(selectedPaymentMethod.isNotEmpty);

    if (vm.ordersLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ReportsTable(
        columns: [
          l10n.ownerReportsColInvoice,
          l10n.ownerReportsColOrderType,
          l10n.ownerReportsColStatus,
          isAr ? l10n.ownerReportsColTotalSarAr : l10n.ownerReportsColTotalSar,
        ],
        columnFlex: const [3, 2, 2, 2],
        columnAlignments: const [
          Alignment.centerLeft,
          Alignment.center,
          Alignment.center,
          Alignment.centerRight,
        ],
        rows: filtered
            .map((o) => [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.invoiceNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o.dateTime,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.25,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ) as Widget,
                  Text(
                    (o.type.isNotEmpty && o.type != '—') ? o.type : '—',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  _StatusBadge(status: l10n.ownerReportsStatusInvoiced),
                  Text(
                    ownerFormatMoney(context, o.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ])
            .toList(),
        onRowTap: (index) {
          if (index < 0 || index >= filtered.length) return;
          _openInvoice(context, filtered[index].source);
        },
        emptyWidget: _EmptyState(
          message: searchQuery.isNotEmpty
              ? l10n.ownerReportsEmptyOrdersSearch
              : l10n.ownerReportsEmptyOrdersScope,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
