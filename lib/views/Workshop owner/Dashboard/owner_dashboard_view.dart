import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_branch_performance_tile.dart';
import '../widgets/owner_petty_cash_approval_card.dart';
import '../widgets/owner_dashboard_low_stock_tile.dart';
import '../widgets/owner_shimmer.dart';
import '../owner_shell.dart';
import '../Branches/branch_management_view.dart';
import '../Reports/reports_management_view.dart';
import '../widgets/owner_global_date_filters.dart';
import 'owner_branch_performance_list_view.dart';
import 'owner_dashboard_view_model.dart';
import 'owner_all_technicians_view.dart';

class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({super.key});

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<OwnerDashboardViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return Scaffold(
            backgroundColor: OwnerUi.scaffoldBackground,
            appBar: OwnerAppBar(
              title: OwnerDashboardTitle(subtitle: l10n.ownerDashboardSubtitle),
              showBackButton: false,
              showNotification: true,
              onMenuPressed: () => OwnerShell.openDrawer(context),
              bottomOverlap: const OwnerGlobalDateOverlapFilters(),
            ),
            body: const OwnerDashboardShimmer(),
          );
        }
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: OwnerDashboardTitle(subtitle: l10n.ownerDashboardSubtitle),
            showBackButton: false,
            showNotification: true,
            onMenuPressed: () => OwnerShell.openDrawer(context),
            bottomOverlap: const OwnerGlobalDateOverlapFilters(),
          ),
          body: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: vm.init,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Total Sales (combined branch sales) ─────────────────
                  _buildTotalSalesBanner(vm, l10n),
                  const SizedBox(height: 20),

                  // ── KPI Cards ───────────────────────────────────────────
                  _buildKPIGrid(vm, l10n),
                  const SizedBox(height: 20),

                  // ── Low Stock Products (hide when none) ─────────────────
                  if (vm.lowStockDisplayCount > 0) ...[
                    _buildLowStockSection(context, vm, l10n),
                    const SizedBox(height: 20),
                  ],

                  // ── Branch Performance ──────────────────────────────────
                  if (vm.selectedBranch == null &&
                      vm.branchesWithPerformance.isNotEmpty) ...[
                    _buildSectionTitle(
                      l10n.dashboardBranchPerformance,
                      badgeText: ownerLocalizeDigits(
                        context,
                        '${vm.branchPerformanceCount}',
                      ),
                      onViewAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (ctx) => OwnerBranchPerformanceListView(
                              branches: vm.branchesWithPerformance,
                            ),
                          ),
                        );
                      },
                      l10n: l10n,
                    ),
                    const SizedBox(height: 10),
                    _buildBranchListPreview(vm),
                    const SizedBox(height: 20),
                  ],

                  // ── Quick Actions ───────────────────────────────────────
                  _buildQuickActionsSection(context, vm),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Total Sales banner (combined branch sales) ─────────────────────────────

  Widget _buildTotalSalesBanner(
    OwnerDashboardViewModel vm,
    AppLocalizations l10n,
  ) {
    final amount = ownerFormatMoney(
      context,
      vm.totalSalesPeriod,
      decimals: 0,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.secondaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ownerDashboardTotalSales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.ownerDashboardTotalSalesSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Grid ────────────────────────────────────────────────────────────────

  Widget _buildKPIGrid(OwnerDashboardViewModel vm, AppLocalizations l10n) {
    final metrics = <ReusableKpiMetric>[
      ReusableKpiMetric(
        title: l10n.dashboardKpiTotalSalesToday,
        value: ownerFormatMoney(context, vm.totalSalesToday, decimals: 0),
        icon: Icons.attach_money_rounded,
        accentColor: AppColors.primaryLight,
      ),
      ReusableKpiMetric(
        title: l10n.ownerDashboardGrossMarginProfit,
        value: ownerFormatMoney(
          context,
          vm.grossMarginProfit.abs(),
          decimals: 0,
        ),
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.primaryLight,
        subtitle: l10n.ownerDashboardGrossMarginSubtitle,
      ),
      ReusableKpiMetric(
        title: l10n.dashboardKpiPendingInvoices,
        value: ownerLocalizeDigits(context, vm.pendingInvoices.toString()),
        icon: Icons.shopping_cart_outlined,
        accentColor: AppColors.primaryLight,
      ),
      ReusableKpiMetric(
        title: l10n.ownerDashboardPendingApprovalsKpi,
        value: ownerLocalizeDigits(context, vm.pendingApprovals.toString()),
        icon: Icons.fact_check_outlined,
        accentColor: AppColors.primaryLight,
      ),
    ];

    return ReusableKpiGrid(
      metrics: metrics,
      crossAxisCount: 2,
      showFeatured: false,
      mainAxisExtent: 82,
      padding: EdgeInsets.zero,
    );
  }

  // ── Quick Actions ────────────────────────────────────────────────────────────

  Widget _buildQuickActionsSection(
      BuildContext context, OwnerDashboardViewModel vm) {
    return _OwnerQuickActionsSection(pendingApprovals: vm.pendingApprovals);
  }

  Widget _buildLowStockSection(
      BuildContext context,
      OwnerDashboardViewModel vm,
      AppLocalizations l10n,
      ) {
    final items = vm.dashboardLowStockItems;
    final totalAlerts = vm.lowStockDisplayCount;
    if (totalAlerts <= 0) return const SizedBox.shrink();

    final preview = items.take(3).toList();

    void openInventory() {
      OwnerShell.goToInventoryManagement(context, withBack: true, lowStockOnly: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          l10n.ownerDashboardLowStockProducts,
          badgeText: ownerLocalizeDigits(context, '$totalAlerts'),
          onViewAll: openInventory,
          l10n: l10n,
        ),
        const SizedBox(height: 10),
        if (preview.isEmpty)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: openInventory,
              borderRadius: BorderRadius.circular(16),
              child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryLight.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.primaryLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    totalAlerts == 1
                        ? l10n.ownerDashboardLowStockAlertSingular(totalAlerts)
                        : l10n.ownerDashboardLowStockAlertPlural(totalAlerts),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade500,
                  size: 18,
                ),
              ],
            ),
          ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in preview)
                OwnerDashboardLowStockTile(
                  item: item,
                  compact: true,
                  onTap: openInventory,
                ),
            ],
          ),
      ],
    );
  }

  // ── Section Title ────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(
      String title, {
        String? badgeText,
        VoidCallback? onViewAll,
        required AppLocalizations l10n,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.h2
                      .copyWith(fontSize: 16, color: AppColors.secondaryLight),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: AppColors.secondaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.dashboardViewAll,
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildBranchListPreview(OwnerDashboardViewModel vm) {
    final preview = vm.branchesWithPerformance.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final branch in preview)
          OwnerBranchPerformanceTile(branch: branch, compact: true),
      ],
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _OwnerActionItem {
  final String id;
  final IconData icon;

  const _OwnerActionItem({
    required this.id,
    required this.icon,
  });
}

class _OwnerQuickActionsSection extends StatelessWidget {
  final int pendingApprovals;

  const _OwnerQuickActionsSection({required this.pendingApprovals});

  static const List<_OwnerActionItem> _allActions = [
    _OwnerActionItem(id: 'employees', icon: Icons.people_alt_rounded),
    _OwnerActionItem(id: 'dept_products', icon: Icons.category_rounded),
    _OwnerActionItem(id: 'approvals', icon: Icons.task_alt_rounded),
    _OwnerActionItem(id: 'suppliers', icon: Icons.handshake_rounded),
  ];

  static String _titleFor(AppLocalizations l10n, String id) {
    switch (id) {
      case 'employees':
        return l10n.ownerDashboardActionEmployeesTitle;
      case 'dept_products':
        return l10n.ownerDashboardActionDeptProductsTitle;
      case 'approvals':
        return l10n.ownerDashboardActionApprovalsTitle;
      case 'suppliers':
        return l10n.ownerDashboardActionSuppliersTitle;
      default:
        return '';
    }
  }

  static String _subtitleFor(AppLocalizations l10n, String id) {
    switch (id) {
      case 'employees':
        return l10n.ownerDashboardActionEmployeesSubtitle;
      case 'dept_products':
        return l10n.ownerDashboardActionDeptProductsSubtitle;
      case 'approvals':
        return l10n.ownerDashboardActionApprovalsSubtitle;
      case 'suppliers':
        return l10n.ownerDashboardActionSuppliersSubtitle;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ownerDashboardQuickActions,
          style: AppTextStyles.h2.copyWith(
            fontSize: 18,
            color: AppColors.secondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allActions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final item = _allActions[index];
            final badge = item.id == 'approvals' && pendingApprovals > 0
                ? pendingApprovals
                : null;
            return _OwnerQuickActionCard(
              title: _titleFor(l10n, item.id),
              subtitle: _subtitleFor(l10n, item.id),
              icon: item.icon,
              badgeCount: badge,
              onTap: () => _onActionTap(context, item),
            );
          },
        ),
      ],
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _goToShellTab(BuildContext context, int index) {
    context.findAncestorStateOfType<OwnerShellState>()?.goToIndex(index);
  }

  void _showUnavailable(BuildContext context, _OwnerActionItem item) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.ownerDashboardScreenNotConnected(_titleFor(l10n, item.id)),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onActionTap(BuildContext context, _OwnerActionItem item) {
    switch (item.id) {
      case 'employees':
        context
            .findAncestorStateOfType<OwnerShellState>()
            ?.goToIndex(2, withBack: true);
        break;
      case 'dept_products':
        context
            .findAncestorStateOfType<OwnerShellState>()
            ?.goToIndex(13, withBack: true);
        break;
      case 'approvals':
        OwnerShell.goToApprovals(context, withBack: true);
        break;
      case 'reports':
        _openPage(context, const ReportsManagementView());
        break;
      case 'branches':
        _openPage(context, const BranchManagementView());
        break;
      case 'technicians':
        final vm = context.read<OwnerDashboardViewModel>();
        _openPage(
          context,
          OwnerAllTechniciansView(branchId: vm.selectedBranch?.id),
        );
        break;
      case 'low_stock':
        OwnerShell.goToInventoryManagement(context);
        break;
      case 'petty_cash':
        OwnerShell.goToPettyCash(context);
        break;
      case 'invoices':
        _openPage(context, const ReportsManagementView());
        break;
      case 'suppliers':
        OwnerShell.goToSuppliers(context, withBack: true);
        break;
      case 'settings':
        _goToShellTab(context, 12);
        break;
      case 'payroll':
        _goToShellTab(context, 33);
        break;
      default:
        _showUnavailable(context, item);
    }
  }
}

class _OwnerQuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;

  const _OwnerQuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryLight,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.secondaryLight,
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSecondaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.onSecondaryLight.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              end: 8,
              bottom: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Directionality.of(context).name == 'rtl'
                      ? Icons.north_west_rounded
                      : Icons.north_east_rounded,
                  color: AppColors.onSecondaryLight,
                  size: 12,
                ),
              ),
            ),
            if (badgeCount != null)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}