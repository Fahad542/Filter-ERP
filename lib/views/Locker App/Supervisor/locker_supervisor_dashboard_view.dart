import 'package:filter_service_providers/views/Locker%20App/PettyCash/locker_petty_cash_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../CashDeposit/locker_deposit_view.dart';
import '../Collection/record_collection_view.dart';
import '../CollectionHistory/locker_collection_history_view.dart';
import '../Requests/locker_requests_list_view.dart';
import '../Requests/requests_approval_view.dart';
import '../locker_shell.dart';
import '../widgets/locker_dashboard_shared_widgets.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_supervisor_dashboard_view_model.dart';

class LockerSupervisorDashboardView extends StatelessWidget {
  const LockerSupervisorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerSupervisorDashboardViewModel(),
      child: const _SupervisorDashboardBody(),
    );
  }
}

class _SupervisorDashboardBody extends StatefulWidget {
  const _SupervisorDashboardBody();

  @override
  State<_SupervisorDashboardBody> createState() =>
      _SupervisorDashboardBodyState();
}

class _SupervisorDashboardBodyState extends State<_SupervisorDashboardBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LockerSupervisorDashboardViewModel>().init(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LockerSupervisorDashboardViewModel>(
      builder: (context, vm, _) {
        return LockerShell(
          isSupervisor: true,
          currentItem: LockerSidebarItem.dashboard,
          titleWidget: const LockerAppBarTitle(),
          backgroundColor: OwnerUi.scaffoldBackground,
          userName: vm.userName,
          roleLabel: localizedLockerUserType(context, vm.displayRole),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  // ── Body dispatcher ───────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, LockerSupervisorDashboardViewModel vm) {
    switch (vm.state) {
      case LockerDashboardState.loading:
        return const LockerDashboardLoader();
      case LockerDashboardState.error:
        return LockerDashboardErrorView(
            message: vm.errorMessage, onRetry: vm.refresh);
      case LockerDashboardState.success:
      case LockerDashboardState.idle:
        return _buildContent(context, vm);
    }
  }

  Widget _buildContent(
      BuildContext context, LockerSupervisorDashboardViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final todays = vm.todaysCollections;

    final kpis = [
      ReusableKpiMetric(
        title: l10n.lockerKpiPending,
        value: '${vm.supervisorStats.pending}',
        subtitle: l10n.lockerOverdueCount('${vm.supervisorStats.overdue}'),
        icon: Icons.access_time_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerTodaysCollected,
        value: '${todays.requestCount}',
        subtitle: l10n.lockerCollectionsToday,
        icon: Icons.attach_money_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiMonthlyCollected,
        value:
        '${l10n.lockerSarCurrency} ${vm.monthlyCollected.toStringAsFixed(0)}',
        subtitle: l10n.lockerThisMonthApproved,
        icon: Icons.bar_chart_rounded,
      ),
    ];

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableKpiGrid.owner(
              metrics: kpis,
              crossAxisCount: 3,
              iconOnTop: true,
              padding: EdgeInsets.zero,
            ),
            // Pull Recent Collections up slightly into KPI grid leftover
            // whitespace — does not shrink KPI card size.
            Transform.translate(
              offset: const Offset(0, -14),
              child: LockerRecentCollectionsCard(
                items: vm.recentHistory.items,
                total: vm.recentHistory.total,
                isLoading: vm.isHistoryLoading,
                onViewAll: () => LockerShell.pushWithBack(
                  context,
                  const LockerRequestsListView(
                    filterMode: LockerListFilterMode.allCollected,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            LockerQuickActionsGrid(
              actions: _supervisorActions(l10n),
              onTap: (action) => _handleQuickAction(context, action),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions (supervisor-only set) ───────────────────────────────────

  List<LockerActionItem> _supervisorActions(AppLocalizations l10n) {
    return [
      LockerActionItem(
        id: 'all_requests',
        title: l10n.lockerQaPendingRequests,
        subtitle: l10n.lockerQaPendingRequestsSub,
        icon: Icons.view_list_rounded,
      ),
      LockerActionItem(
        id: 'record_collection',
        title: l10n.lockerQaRecordCollection,
        subtitle: l10n.lockerQaRecordCollectionSub,
        icon: Icons.assignment_turned_in_rounded,
      ),
      LockerActionItem(
        id: 'approvals',
        title: l10n.lockerQaApprovals,
        subtitle: l10n.lockerQaApprovalsSub,
        icon: Icons.compare_arrows_rounded,
      ),
      LockerActionItem(
        id: 'collection_history',
        title: l10n.lockerQaCollectionHistory,
        subtitle: l10n.lockerQaCollectionHistorySub,
        icon: Icons.history_rounded,
      ),
    ];
  }

  void _handleQuickAction(BuildContext context, LockerActionItem action) {
    switch (action.id) {
      case 'all_requests':
        LockerShell.pushWithBack(
          context,
          const LockerRequestsListView(initialView: 'supervisor'),
        );
        break;

      case 'record_collection':
        LockerShell.pushWithBack(
          context,
          const RecordCollectionView(),
        );
        break;

      case 'approvals':
        LockerShell.pushWithBack(
          context,
          const LockerVarianceApprovalsView(),
        );
        break;

      case 'collection_history':
        LockerShell.pushWithBack(
          context,
          const LockerCollectionHistoryView(isSupervisor: true),
        );
        break;

      case 'deposit_bank':
        LockerShell.pushWithBack(
          context,
          const LockerDepositView(isSupervisor: true),
        );
        break;

      case 'petty_cash':
        LockerShell.pushWithBack(
          context,
          const LockerPettyCashView(isSupervisor: true),
        );
        break;

      default:
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.lockerComingSoon(action.label.replaceAll('\n', ' ')),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }
}