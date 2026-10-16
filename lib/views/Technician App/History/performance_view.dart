import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../technician_view_model.dart';
import '../widgets/tech_app_bar_actions.dart';
import '../widgets/tech_dashboard_shimmer.dart';
import '../widgets/tech_month_filter_bar.dart';
import 'recent_jobs_view.dart';

class TechPerformanceView extends StatefulWidget {
  const TechPerformanceView({super.key});

  @override
  State<TechPerformanceView> createState() => _TechPerformanceViewState();
}

class _TechPerformanceViewState extends State<TechPerformanceView> {
  @override
  void initState() {
    super.initState();
    // Fetch data only when this tab is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<TechAppViewModel>();
      vm.fetchDailyPerformance();
      vm.fetchMonthlyKpi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TechAppViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: _buildAppBar(context, l10n),
          body: vm.isLoading
              ? const TechDashboardShimmer()
              : RefreshIndicator(
                  onRefresh: () async {
                    await vm.fetchDailyPerformance();
                    await vm.fetchMonthlyKpi();
                  },
                  color: AppColors.primaryLight,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TechMonthFilterBar(
                          month: vm.kpiMonth,
                          year: vm.kpiYear,
                          isLoading: vm.isLoadingMonthlyKpi,
                          onChanged: vm.setKpiMonthYear,
                          onApply: () => vm.fetchMonthlyKpi(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCards(context, l10n, vm),
                              const SizedBox(height: 32),
                              _buildSectionHeader(
                                l10n.techPerfCommissionTimeline,
                              ),
                              const SizedBox(height: 16),
                              _buildMonthlyChart(l10n, vm),
                              const SizedBox(height: 32),
                              _buildSectionHeader(
                                l10n.techPerfRecentJobs,
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RecentJobsView(),
                                    ),
                                  );
                                },
                                seeAllLabel: l10n.techPerfSeeAll,
                              ),
                              const SizedBox(height: 16),
                              _buildHistoryList(l10n, vm),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      backgroundColor: AppColors.primaryLight,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: Center(
        child: GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
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
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      title: Text(
        l10n.techPerfDailyPerformance,
        style: const TextStyle(
          color: AppColors.secondaryLight,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 1,
        ),
      ),
      centerTitle: true,
      actions: techAppBarTrailingActions(context),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AppLocalizations l10n,
    TechAppViewModel vm,
  ) {
    final monthLabel = TechMonthFilterBar.monthYearLabel(
      vm.kpiMonth,
      vm.kpiYear,
      Localizations.localeOf(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthLabel.toUpperCase(),
          style: const TextStyle(
            color: Colors.black38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSimpleStat(
                l10n.techPerfTotalJobs,
                vm.monthlyTotalJobs.toString(),
                Icons.assignment_turned_in_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleStat(
                l10n.techPerfTotalCommission,
                l10n.techMoneyAmount(
                  l10n.ownerCurrencySar,
                  vm.monthlyTotalCommission.toStringAsFixed(2),
                ),
                Icons.payments_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(AppLocalizations l10n, TechAppViewModel vm) {
    final timeline = vm.monthlyCommissionTimeline;
    double maxAmt = 1.0;
    if (timeline.isNotEmpty) {
      maxAmt = timeline.fold(1.0, (max, e) => e.amount > max ? e.amount : max);
      if (maxAmt == 0) maxAmt = 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.techPerfDailyCommission,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    l10n.techMoneyAmount(
                      l10n.ownerCurrencySar,
                      vm.monthlyTotalCommission.toStringAsFixed(2),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 135,
            child: timeline.isEmpty
                ? Center(
                    child: Text(
                      l10n.techPerfNoCommissionMonth,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: timeline.map((item) {
                        final heightRatio =
                            (item.amount / maxAmt).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildBarItem(
                            '${item.day}',
                            heightRatio,
                            item.amount,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(
    String day,
    double height,
    double amount, {
    bool isSelected = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amount >= 1000
              ? '${(amount / 1000).toStringAsFixed(1)}k'
              : amount.toStringAsFixed(0),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 24,
          height: (80 * height).clamp(4.0, 80.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(AppLocalizations l10n, TechAppViewModel vm) {
    if (vm.assignedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            l10n.techPerfNoRecentJobs,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.assignedOrders.length > 3 ? 3 : vm.assignedOrders.length,
      itemBuilder: (context, index) {
        final order = vm.assignedOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.03)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.vehicleModel,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            order.id,
                            style: const TextStyle(
                              color: Colors.black26,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.techMoneyAmount(
                  l10n.ownerCurrencySar,
                  order.commission.toInt().toString(),
                ),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onSeeAll,
    String? seeAllLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              seeAllLabel ?? '',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
