import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Reports/reports_table.dart';
import 'reports_management_view_model.dart';

class _DailySalesItem {
  final String day;
  final String date;
  final double revenue;

  _DailySalesItem({
    required this.day,
    required this.date,
    required this.revenue,
  });
}

class DailySalesTab extends StatelessWidget {
  final String searchQuery;
  final ReportsManagementViewModel vm;

  const DailySalesTab({
    super.key,
    required this.searchQuery,
    required this.vm,
  });

  List<_DailySalesItem> get _items {
    return (vm.reportsData?.financialOverview.dailyRevenue ?? [])
        .map((d) =>
            _DailySalesItem(day: d.day, date: d.date, revenue: d.amount))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      final q = searchQuery.toLowerCase();
      return q.isEmpty ||
          i.day.toLowerCase().contains(q) ||
          i.date.toLowerCase().contains(q) ||
          i.revenue.toString().contains(q);
    }).toList();

    double maxAmt = 1.0;
    if (_items.isNotEmpty) {
      maxAmt = _items.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
      if (maxAmt == 0) maxAmt = 1.0;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
                // ── Bar chart card ─────────────────────────────────────────
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
                        'Daily Revenue',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: _items.isEmpty
                            ? Center(
                                child: Text(
                                  'No data available',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final minBarWidth = 36.0;
                                  final totalMinWidth =
                                      _items.length * minBarWidth;
                                  final useScroll =
                                      totalMinWidth > constraints.maxWidth;

                                  Widget buildRow(double rowWidth) => SizedBox(
                                        width: rowWidth,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: _items.map((r) {
                                            final ratio = maxAmt > 0
                                                ? (r.revenue / maxAmt)
                                                    .clamp(0.0, 1.0)
                                                : 0.0;
                                            final isToday = r.date ==
                                                DateTime.now()
                                                    .toString()
                                                    .split(' ')[0];
                                            return _ChartBar(
                                              day: r.day,
                                              ratio: ratio,
                                              amount: r.revenue,
                                              isToday: isToday,
                                            );
                                          }).toList(),
                                        ),
                                      );

                                  return useScroll
                                      ? SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: buildRow(totalMinWidth),
                                        )
                                      : buildRow(constraints.maxWidth);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Unified table ──────────────────────────────────────────
                ReportsTable(
                  columns: [
                    AppLocalizations.of(context)!.ownerReportsColDay,
                    AppLocalizations.of(context)!.ownerReportsColDate,
                    AppLocalizations.of(context)!.ownerReportsColRevenue,
                  ],
                  rows: filtered.map((item) => [
                    Text(item.day,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLight,
                        )) as Widget,
                    Text(item.date,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    Text(ownerFormatMoney(context, item.revenue),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900)),
                  ]).toList(),
                  emptyWidget: _EmptyState(
                    message: searchQuery.isNotEmpty
                        ? 'No results match your search.'
                        : 'No daily sales data available.',
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String day;
  final double ratio;
  final double amount;
  final bool isToday;

  const _ChartBar({
    required this.day,
    required this.ratio,
    required this.amount,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    const double maxBarH = 60.0;
    final barH = (maxBarH * ratio).clamp(4.0, maxBarH);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amount >= 1000
              ? '${(amount / 1000).toStringAsFixed(1)}k'
              : amount.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isToday ? AppColors.primaryLight : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
          height: barH,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primaryLight
                : Colors.grey.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
