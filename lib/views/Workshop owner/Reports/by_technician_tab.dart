import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import 'reports_management_view_model.dart';

class _TechnicianItem {
  final String name;
  final int completedJobs;
  final double revenue;
  final double commission;

  _TechnicianItem({
    required this.name,
    required this.completedJobs,
    required this.revenue,
    required this.commission,
  });
}

class ByTechnicianTab extends StatelessWidget {
  final String searchQuery;
  final ReportsManagementViewModel vm;

  const ByTechnicianTab({
    super.key,
    required this.searchQuery,
    required this.vm,
  });

  List<_TechnicianItem> get _items {
    final byTech = vm.reportsData?.byTechnician ?? [];
    if (byTech.isNotEmpty) {
      return byTech
          .map(
            (r) => _TechnicianItem(
              name: r.displayName,
              completedJobs: r.completedJobs,
              revenue: r.revenueSar,
              commission: r.commissionSar,
            ),
          )
          .toList();
    }
    return (vm.reportsData?.operationalPerformance ?? [])
        .map((op) => _TechnicianItem(
              name: op.name,
              completedJobs: op.totalJobs,
              revenue: 0,
              commission: op.commission,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      final q = searchQuery.toLowerCase();
      return q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.completedJobs.toString().contains(q) ||
          i.revenue.toString().contains(q);
    }).toList();

    double maxJobs = 1.0;
    if (_items.isNotEmpty) {
      maxJobs = _items
          .map((e) => e.completedJobs.toDouble())
          .reduce((a, b) => a > b ? a : b);
      if (maxJobs == 0) maxJobs = 1.0;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Horizontal bar chart card
          if (_items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue by Technician',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._items.map((t) {
                          final ratio = maxJobs > 0
                              ? (t.completedJobs / maxJobs).clamp(0.0, 1.0)
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    t.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 10,
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.1),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryLight),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${t.completedJobs}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Unified table
                ReportsTable(
                  columns: [
                    AppLocalizations.of(context)!.ownerReportsColTechnician,
                    AppLocalizations.of(context)!.ownerReportsColCompletedJobs,
                    AppLocalizations.of(context)!.ownerReportsColRevenue,
                    AppLocalizations.of(context)!.ownerReportsColCommission,
                  ],
                  rows: filtered.map((t) => [
                    Text(t.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis) as Widget,
                    Text(ownerLocalizeDigits(context, '${t.completedJobs}'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(ownerFormatMoney(context, t.revenue, decimals: 0),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900)),
                    Text(ownerFormatMoney(context, t.commission),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        )),
                  ]).toList(),
                  emptyWidget: _EmptyState(
                    message: searchQuery.isNotEmpty
                        ? 'No technicians match your search.'
                        : 'No technician data available.',
                  ),
                ),
              ],
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
