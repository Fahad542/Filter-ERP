import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/owner_data_service.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';

/// App-wide start/end date-time filter (same scope model as the branch picker).
///
/// Writes to [OwnerDataService]; [OwnerShell] reloads only the visible tab.
class OwnerGlobalDateOverlapFilters extends StatelessWidget {
  const OwnerGlobalDateOverlapFilters({
    super.key,
    this.dateOnly = false,
  });

  /// When true, only calendar days are picked (petty-cash report style).
  final bool dateOnly;

  @override
  Widget build(BuildContext context) {
    return Consumer<OwnerDataService>(
      builder: (context, data, _) {
        return TechDashboardOverlapFilters(
          startDate: data.filterFrom,
          endDate: data.filterTo,
          dateOnly: dateOnly,
          onStartDateChanged: (d) async => data.setFilterFrom(d),
          onEndDateChanged: (d) async => data.setFilterTo(d),
        );
      },
    );
  }
}
