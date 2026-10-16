import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import 'reports_management_view_model.dart';

class _CustomerItem {
  final String phone;
  final String plateNumber;
  final int orders;
  final double revenue;

  _CustomerItem({
    required this.phone,
    required this.plateNumber,
    required this.orders,
    required this.revenue,
  });
}

class ByCustomerTab extends StatelessWidget {
  final String searchQuery;
  final ReportsManagementViewModel vm;

  const ByCustomerTab({
    super.key,
    required this.searchQuery,
    required this.vm,
  });

  List<_CustomerItem> get _items {
    return (vm.reportsData?.byCustomer ?? [])
        .map(
          (r) => _CustomerItem(
            phone: r.phone.isNotEmpty
                ? r.phone
                : (r.displayCustomerName.isNotEmpty ? r.displayCustomerName : '—'),
            plateNumber: r.plateNo.isNotEmpty
                ? r.plateNo
                : (r.plateNumbers.isNotEmpty ? r.plateNumbers.first : '—'),
            orders: r.ordersCount,
            revenue: r.revenueSar,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      final q = searchQuery.toLowerCase();
      return q.isEmpty ||
          i.phone.toLowerCase().contains(q) ||
          i.plateNumber.toLowerCase().contains(q) ||
          i.orders.toString().contains(q) ||
          i.revenue.toString().contains(q);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ReportsTable(
              columns: [
                AppLocalizations.of(context)!.ownerReportsColPhone,
                AppLocalizations.of(context)!.ownerReportsColPlate,
                AppLocalizations.of(context)!.ownerReportsColOrders,
                AppLocalizations.of(context)!.ownerReportsColRevenue,
              ],
              rows: filtered.map((c) => [
                Text(c.phone,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis) as Widget,
                Text(c.plateNumber,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(ownerLocalizeDigits(context, '${c.orders}'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(ownerFormatMoney(context, c.revenue),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900)),
              ]).toList(),
              emptyWidget: _EmptyState(
                message: searchQuery.isNotEmpty
                    ? 'No customers match your search.'
                    : 'No customer breakdown for this scope.',
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded,
                color: Colors.grey.shade400, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
