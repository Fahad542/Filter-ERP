import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../../Workshop owner/widgets/owner_app_bar.dart';
import '../../Workshop owner/widgets/reusable_kpi_grid.dart';
import '../../Workshop owner/widgets/owner_shimmer.dart';
import '../../Workshop owner/LockerManagement/locker_kpi_section.dart';
import '../../Workshop owner/LockerManagement/locker_collections_tab.dart';
import '../../Workshop owner/LockerManagement/locker_deposits_tab.dart';
import '../../Workshop owner/LockerManagement/locker_management_view_model.dart';
import '../../Workshop owner/LockerManagement/locker_petty_cash_tab.dart';
import '../../Workshop owner/LockerManagement/locker_requests_tab.dart';
import '../../Workshop owner/LockerManagement/locker_staff_tab.dart';

/// Public entry point — self-contained so it works no matter where/how
/// this screen is navigated to. It creates its own
/// `LockerManagementViewModel` and provides it to the subtree below,
/// instead of relying on a provider being set up higher in the tree
/// (e.g. in main.dart / route builder), which is what was missing and
/// caused the ProviderNotFoundException.
class LockerManagementView extends StatelessWidget {
  const LockerManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LockerManagementViewModel>(
      create: (context) => LockerManagementViewModel(
        ownerRepository: context.read<OwnerRepository>(),
        sessionService: context.read<SessionService>(),
      ),
      child: const _LockerManagementViewBody(),
    );
  }
}

class _LockerManagementViewBody extends StatefulWidget {
  const _LockerManagementViewBody();

  @override
  State<_LockerManagementViewBody> createState() => _LockerManagementViewBodyState();
}

class _LockerManagementViewBodyState extends State<_LockerManagementViewBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LockerManagementViewModel>().fetchLockerOverview();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: l10n.ownerLockerTitle,
        showDrawer: true,
      ),
      body: Consumer<LockerManagementViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.response == null) {
            return const OwnerListPageShimmer(showKpi: true, showTabs: true);
          }

          return RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: vm.refresh,
            child: Column(
              children: [
                // Thin bar instead of blocking the screen — keeps stale
                // data visible/usable while a background refresh (e.g.
                // after pull-to-refresh) is in flight on a slow network.
                if (vm.isRefreshing && vm.response != null)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primaryLight,
                    backgroundColor: Colors.transparent,
                  ),
                if (vm.error != null) _buildErrorBanner(vm),
                _buildSummaryGrid(context, vm),
                _buildTabBar(l10n),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LockerRequestsTab(vm: vm),
                      LockerCollectionsTab(vm: vm),
                      LockerDepositsTab(vm: vm),
                      LockerPettyCashTab(vm: vm),
                      LockerStaffTab(vm: vm),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Error banner ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner(LockerManagementViewModel vm) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.error!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade400),
            ),
          ),
          TextButton(
            onPressed: vm.isRefreshing ? null : vm.refresh,
            child: Text(
              vm.isRefreshing ? 'Retrying…' : 'Retry',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI summary: single horizontally scrollable row ───────────────────────
  Widget _buildSummaryGrid(BuildContext context, LockerManagementViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final k = vm.kpis;

    return LockerKpiSection(
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerLockerVaultBalance,
          value: ownerFormatMoney(context, k.lockerVaultBalance, decimals: 0),
          icon: Icons.account_balance_wallet_rounded,
          subtitle: l10n.ownerLockerCashInTransit,
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerPendingPickups,
          value: ownerLocalizeDigits(context, '${k.pendingRequests}'),
          icon: Icons.move_to_inbox_rounded,
          subtitle: l10n.ownerLockerCashierClosings,
          onTap: () => _tabController.animateTo(0),
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerAssigned,
          value: ownerLocalizeDigits(context, '${k.assignedRequests}'),
          icon: Icons.person_pin_circle_rounded,
          subtitle: l10n.ownerLockerOnTheWay,
          onTap: () => _tabController.animateTo(0),
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerOverdue,
          value: ownerLocalizeDigits(context, '${k.overdueRequests}'),
          icon: Icons.warning_amber_rounded,
          accentColor: k.overdueRequests > 0 ? Colors.red.shade300 : null,
          subtitle: l10n.ownerLockerOverdueSubtitle,
          onTap: () => _tabController.animateTo(0),
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerPendingApprovals,
          value: ownerLocalizeDigits(context, '${k.pendingApprovals}'),
          icon: Icons.pending_actions_rounded,
          subtitle: l10n.ownerLockerPendingApprovalsSubtitle,
          onTap: () => _tabController.animateTo(1),
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerCollectedToday,
          value: ownerLocalizeDigits(context, '${k.collectionsToday}'),
          icon: Icons.check_circle_rounded,
          onTap: () => _tabController.animateTo(1),
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerMonthlyCollected,
          value: formatKpiAmount(k.monthlyCollected, context: context),
          icon: Icons.payments_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.ownerLockerOpenShiftVariance,
          value: formatKpiAmount(k.openShiftVariance, context: context),
          icon: Icons.show_chart_rounded,
          subtitle: l10n.ownerLockerOpenShiftSubtitle,
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return OwnerSegmentedTabs(
      controller: _tabController,
      tabs: [
        l10n.ownerLockerTabRequests,
        l10n.ownerLockerTabCollections,
        l10n.ownerLockerTabDeposits,
        l10n.ownerLockerTabPettyCash,
        l10n.ownerLockerTabStaff,
      ],
    );
  }
}