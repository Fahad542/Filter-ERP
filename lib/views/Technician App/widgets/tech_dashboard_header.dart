import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../technician_view_model.dart';
import 'tech_app_bar_actions.dart';
import 'tech_dashboard_filter_bar.dart';

class TechDashboardHeader extends StatelessWidget {
  const TechDashboardHeader({
    super.key,
    required this.vm,
    required this.onMenuTap,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  final TechAppViewModel vm;
  final VoidCallback onMenuTap;
  final Future<void> Function(DateTime date) onStartDateChanged;
  final Future<void> Function(DateTime date) onEndDateChanged;

  static const _filterOverlap = 46.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPad = MediaQuery.paddingOf(context).top;
    const headerBodyHeight = 118.0;

    return SizedBox(
      height: topPad + headerBodyHeight + _filterOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + headerBodyHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 36),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.techDashWelcomeBack,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vm.dashboardGreetingName.isNotEmpty
                              ? vm.dashboardGreetingName
                              : l10n.techShellTechnicianRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: techAppBarTrailingActions(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: TechDashboardOverlapFilters(
              startDate: vm.dashboardKpiFrom,
              endDate: vm.dashboardKpiTo,
              onStartDateChanged: onStartDateChanged,
              onEndDateChanged: onEndDateChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton() {
    return GestureDetector(
      onTap: onMenuTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
