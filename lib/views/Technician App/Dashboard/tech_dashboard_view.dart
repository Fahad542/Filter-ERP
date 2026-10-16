import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_shimmer.dart';
import '../Orders/assigned_orders_view.dart';
import '../technician_view_model.dart';
import '../widgets/tech_dashboard_header.dart';
import '../widgets/tech_dashboard_shimmer.dart';

class TechDashboardView extends StatefulWidget {
  const TechDashboardView({super.key});

  @override
  State<TechDashboardView> createState() => _TechDashboardViewState();
}

class _TechDashboardViewState extends State<TechDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<TechAppViewModel>();
      if (!vm.isBootstrapped) {
        vm.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TechAppViewModel>(
      builder: (context, vm, child) {
        final ready = vm.isTechDashboardReady;
        return ColoredBox(
          color: const Color(0xFFF8F9FD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TechDashboardHeader(
                vm: vm,
                onMenuTap: () => Scaffold.of(context).openDrawer(),
                onStartDateChanged: vm.applyDashboardKpiStartDate,
                onEndDateChanged: vm.applyDashboardKpiEndDate,
              ),
              Expanded(
                child: ready
                    ? SafeArea(
                        top: false,
                        child: RefreshIndicator(
                          color: AppColors.secondaryLight,
                          backgroundColor: Colors.white,
                          onRefresh: () async {
                            await vm.init();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(l10n.techDashPerformance),
                                const SizedBox(height: 10),
                                _buildKPIGrid(context, vm),
                                const SizedBox(height: 24),
                                _buildQuickAction(context, vm),
                                const SizedBox(height: 32),
                                if (vm.isOfflineLockedByCashier)
                                  _buildOfflineLockedNotice(context)
                                else ...[
                                  _buildSectionTitle(l10n.techDashDutyMode),
                                  const SizedBox(height: 10),
                                  _buildDutyToggles(context, vm),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : const TechDashboardShimmer(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shown when cashier marked the technician offline (presence); duty toggles are hidden.
  Widget _buildOfflineLockedNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: AppColors.secondaryLight,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.techDashOfflineTitle,
                  style: TextStyle(
                    color: AppColors.secondaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.techDashOfflineBody,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.48),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDutyToggles(BuildContext context, TechAppViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                l10n.posTechWorkshopDuty,
                l10n.techDashWorkshopDutyHint,
                vm.isWorkshopDuty,
                vm.isWorkshopDutyLoading,
                (val) => vm.toggleWorkshopDuty(context, val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildToggleCard(
                l10n.posTechOnCallDuty,
                l10n.techDashOnCallDutyHint,
                vm.isOnCallDuty,
                vm.isOnCallDutyLoading,
                (val) => vm.toggleOnCallDuty(context, val),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            l10n.techDashDutyHelp,
            style: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard(
    String title,
    String sub,
    bool isActive,
    bool isLoading,
    Function(bool) onChanged,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isActive ? AppColors.primaryLight.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isActive ? AppColors.primaryLight : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.black87 : AppColors.secondaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.black87.withOpacity(0.6) : Colors.black38,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TechPillToggle(
            value: isActive,
            isLoading: isLoading,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid(BuildContext context, TechAppViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final loading = vm.isLoadingDashboardKpis;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        loading
            ? _buildStatCardShimmer()
            : _buildStatCard(
                l10n.techDashRevenueEarned,
                '${l10n.ownerCurrencySar} ${vm.dashboardRevenueEarned.toStringAsFixed(2)}',
                Icons.payments_rounded,
              ),
        loading
            ? _buildStatCardShimmer()
            : _buildStatCard(
                l10n.techDashJobsCompleted,
                vm.dashboardJobsCompleted.toString(),
                Icons.task_alt_rounded,
              ),
        loading
            ? _buildStatCardShimmer()
            : _buildStatCard(
                l10n.techDashCommissionEarned,
                '${l10n.ownerCurrencySar} ${vm.dashboardCommissionEarned.toStringAsFixed(2)}',
                Icons.star_rounded,
              ),
        _buildStatCard(
          l10n.techDashTodayRevenue,
          '${l10n.ownerCurrencySar} ${vm.todayRevenue.toStringAsFixed(2)}',
          Icons.today_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            PosShimmerBox(width: 30, height: 30, radius: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosShimmerLine(width: 78, height: 14, radius: 6),
                SizedBox(height: 6),
                PosShimmerLine(width: 54, height: 9, radius: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    Function(BuildContext)? onTap,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: onTap != null ? () => onTap(context) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primaryLight, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.secondaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, TechAppViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final count = vm.reportPeriodJobCount;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssignedOrdersView(isFromDashboard: true)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              l10n.techDashViewAssignedOrders,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechPillToggle extends StatelessWidget {
  const _TechPillToggle({
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  static const double _width = 50;
  static const double _height = 28;
  static const double _padding = 3;

  Color get _activeTrackColor =>
      Color.lerp(AppColors.primaryLight, AppColors.secondaryLight, 0.14)!;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: _width,
        height: _height,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: value ? AppColors.secondaryLight : AppColors.primaryLight,
            ),
          ),
        ),
      );
    }

    final thumbSize = _height - (_padding * 2);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: value ? _activeTrackColor : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(
            color: value
                ? AppColors.secondaryLight.withOpacity(0.12)
                : Colors.black.withOpacity(0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: value
                  ? AppColors.primaryLight.withOpacity(0.35)
                  : Colors.black.withOpacity(0.05),
              blurRadius: value ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: value ? AppColors.secondaryLight : const Color(0xFFD0D0D0),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
