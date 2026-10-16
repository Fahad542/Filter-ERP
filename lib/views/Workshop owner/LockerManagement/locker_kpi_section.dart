import 'package:flutter/material.dart';
import '../widgets/reusable_kpi_grid.dart';

/// All locker KPI cards in one horizontally scrollable row.
class LockerKpiSection extends StatelessWidget {
  final List<ReusableKpiMetric> metrics;
  final EdgeInsetsGeometry padding;

  const LockerKpiSection({
    super.key,
    required this.metrics,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return ReusableKpiGrid(
      metrics: metrics,
      layout: KpiGridLayout.singleRow,
      showFeatured: false,
      iconOnTop: false,
      dense: true,
      mainAxisExtent: 96,
      singleRowCardWidth: 140,
      padding: padding,
    );
  }
}
