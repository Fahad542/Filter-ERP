import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import 'reports_management_view_model.dart';

class _CashierItem {
  final String name;
  final int totalOrders;
  final double totalRevenue;

  _CashierItem({
    required this.name,
    required this.totalOrders,
    required this.totalRevenue,
  });
}

class ByCashierTab extends StatelessWidget {
  final String searchQuery;
  final ReportsManagementViewModel vm;

  const ByCashierTab({
    super.key,
    required this.searchQuery,
    required this.vm,
  });

  List<_CashierItem> get _items {
    return (vm.reportsData?.byCashier ?? [])
        .map(
          (r) => _CashierItem(
            name: r.displayName.isNotEmpty ? r.displayName : '—',
            totalOrders: r.ordersCount,
            totalRevenue: r.revenueSar,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      final q = searchQuery.toLowerCase();
      return q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.totalRevenue.toString().contains(q) ||
          i.totalOrders.toString().contains(q);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ReportsTable(
        columns: [
          AppLocalizations.of(context)!.ownerReportsColCashier,
          AppLocalizations.of(context)!.ownerReportsColTotalOrders,
          Localizations.localeOf(context).languageCode == 'ar'
              ? AppLocalizations.of(context)!.ownerReportsColTotalRevenue.replaceAll('SAR', 'ر.س')
              : AppLocalizations.of(context)!.ownerReportsColTotalRevenue,
        ],
        rows: filtered.map((c) => [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                child: const Icon(Icons.point_of_sale_rounded,
                    size: 14, color: AppColors.secondaryLight),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ) as Widget,
          Text(ownerLocalizeDigits(context, '${c.totalOrders}'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
          Text(ownerFormatMoney(context, c.totalRevenue),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900)),
        ]).toList(),
        emptyWidget: _EmptyState(
          message: searchQuery.isNotEmpty
              ? 'No cashiers match your search.'
              : 'No cashier sales in this scope.',
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
