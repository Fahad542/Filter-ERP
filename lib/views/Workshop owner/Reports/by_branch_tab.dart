import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import 'reports_management_view_model.dart';

class _BranchItem {
  final String name;
  final int completedOrders;
  final double revenue;

  _BranchItem({
    required this.name,
    required this.completedOrders,
    required this.revenue,
  });
}

class ByBranchTab extends StatelessWidget {
  final String searchQuery;
  final ReportsManagementViewModel vm;

  const ByBranchTab({
    super.key,
    required this.searchQuery,
    required this.vm,
  });

  List<_BranchItem> get _items {
    return (vm.reportsData?.byBranch ?? [])
        .map(
          (r) => _BranchItem(
            name: r.displayBranchName.isNotEmpty ? r.displayBranchName : '—',
            completedOrders: r.completedOrders,
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
          i.name.toLowerCase().contains(q) ||
          i.revenue.toString().contains(q);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ReportsTable(
        columns: [
          AppLocalizations.of(context)!.ownerReportsColBranch,
          AppLocalizations.of(context)!.ownerReportsColCompletedOrders,
          Localizations.localeOf(context).languageCode == 'ar'
              ? AppLocalizations.of(context)!.ownerReportsColRevenue.replaceAll('(SAR)', '(ر.س)')
              : AppLocalizations.of(context)!.ownerReportsColRevenue,
        ],
        rows: filtered.map((b) => [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store_rounded,
                    size: 14, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  b.name,
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
          Text(ownerLocalizeDigits(context, '${b.completedOrders}'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
          Text(ownerFormatMoney(context, b.revenue),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900)),
        ]).toList(),
        emptyWidget: _EmptyState(
          message: searchQuery.isNotEmpty
              ? 'No branches match your search.'
              : 'No branch breakdown (try "All branches").',
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
