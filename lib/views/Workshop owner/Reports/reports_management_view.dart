import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../l10n/app_localizations.dart';
import 'reports_management_view_model.dart';
import 'reports_search_bar.dart';
import 'by_branch_tab.dart';
import 'by_cashier_tab.dart';
import 'by_customer_tab.dart';
import 'by_department_tab.dart';
import 'by_product_tab.dart';
import 'by_technician_tab.dart';
import 'daily_sales_tab.dart';
import 'orders_tab.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../owner_shell.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_global_date_filters.dart';

class ReportsManagementView extends StatefulWidget {
  const ReportsManagementView({super.key});

  @override
  State<ReportsManagementView> createState() => _ReportsManagementViewState();
}

class _ReportsManagementViewState extends State<ReportsManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  String _searchQuery = '';
  String _selectedTechnician = 'All technicians';
  String _selectedPaymentMethod = 'All payment methods';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _searchQuery = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<_TabConfig> _tabs = [
    _TabConfig(icon: Icons.receipt_long_rounded),
    _TabConfig(icon: Icons.bar_chart_rounded),
    _TabConfig(icon: Icons.person_pin_rounded),
    _TabConfig(icon: Icons.people_rounded),
    _TabConfig(icon: Icons.inventory_2_rounded),
    _TabConfig(icon: Icons.account_tree_rounded),
    _TabConfig(icon: Icons.store_rounded),
    _TabConfig(icon: Icons.point_of_sale_rounded),
  ];

  List<String> _tabLabels(AppLocalizations l10n) => [
        l10n.ownerReportsTabOrders,
        l10n.ownerReportsTabDailySales,
        l10n.ownerReportsTabByTechnician,
        l10n.ownerReportsTabByCustomer,
        l10n.ownerReportsTabByProduct,
        l10n.ownerReportsTabByDepartment,
        l10n.ownerReportsTabByBranch,
        l10n.ownerReportsTabByCashier,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ReportsManagementViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: l10n.ownerReportsTitle,
            showGlobalLeft: true,
            showNotification: true,
            showBackButton: false,
            showDrawer: false,
            onNotificationPressed: () =>
                OwnerShell.goToNotifications(context),
            bottomOverlap: const OwnerGlobalDateOverlapFilters(),
          ),
          body: _buildBody(vm, l10n),
        );
      },
    );
  }

  Widget _buildBody(ReportsManagementViewModel vm, AppLocalizations l10n) {
    // ── Initial hard loading ───────────────────────────────────────────────
    if (vm.isLoading) {
      return const OwnerTablePageShimmer();
    }

    // ── Fatal error (no cached data) ───────────────────────────────────────
    if (vm.hasError && vm.reportsData == null) {
      return _ErrorView(
        error: vm.error!,
        onRetry: vm.retryFetch,
      );
    }

    // ── Normal / refresh overlay ───────────────────────────────────────────
    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: Column(
        children: [
          // Soft-error banner (data shown but last refresh failed)
          if (vm.hasError && vm.reportsData != null)
            _ErrorBanner(
              message: vm.error!.userFriendlyMessage,
              onRetry: vm.refresh,
            ),

          // Soft refresh only (pull-to-refresh) — branch change uses shimmer via isLoading.
          if (vm.isRefreshing)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primaryLight,
              backgroundColor: Colors.transparent,
            ),

          _buildKPICards(vm, l10n),
          _buildReportTypeAndSearch(l10n),
          if (_selectedTab == 0) _buildPaymentMethodTabs(l10n),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildTabViews(vm),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Summary Cards ──────────────────────────────────────────────────────

  Widget _buildKPICards(ReportsManagementViewModel vm, AppLocalizations l10n) {
    final fin = vm.reportsData?.financialOverview;
    final inv = vm.reportsData?.inventoryValuation;

    final totalRev = fin?.totalRevenue ?? 0.0;
    final revChange = fin?.revenueChangePercent ?? 0.0;
    final stockVal = inv?.stockValueCost ?? 0.0;
    final potProfit = inv?.potentialProfit ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: ReusableKpiGrid(
        layout: KpiGridLayout.singleRow,
        metrics: [
          ReusableKpiMetric(
            title: l10n.ownerReportsKpiTotalRevenue,
            value: formatKpiAmount(totalRev, context: context),
            icon: Icons.attach_money_rounded,
            accentColor: AppColors.primaryLight,
          ),
          ReusableKpiMetric(
            title: l10n.ownerReportsKpiRevenueChange,
            value: ownerLocalizeDigits(
              context,
              '${revChange >= 0 ? '+' : ''}${revChange.toStringAsFixed(1)}%',
            ),
            icon: Icons.trending_up_rounded,
            accentColor: AppColors.primaryLight,
            subtitle: l10n.ownerReportsKpiRevenueChangeSubtitle,
          ),
          ReusableKpiMetric(
            title: l10n.ownerReportsKpiStockValue,
            value: formatKpiAmount(stockVal, context: context),
            icon: Icons.inventory_2_outlined,
            accentColor: AppColors.primaryLight,
            subtitle: l10n.ownerReportsKpiStockValueSubtitle(inv?.activeSkus ?? 0),
          ),
          ReusableKpiMetric(
            title: l10n.ownerReportsKpiPotentialProfit,
            value: formatKpiAmount(potProfit, context: context),
            icon: Icons.savings_outlined,
            accentColor: AppColors.primaryLight,
          ),
        ],
        showFeatured: false,
        mainAxisExtent: 86,
        singleRowCardWidth: 168,
        padding: EdgeInsets.zero,
      ),
    );
  }


  // ── Report type dropdown + search ─────────────────────────────────────────

  static const _paymentMethods = [
    'All payment methods',
    'Cash',
    'Card',
    'Bank Transfer',
  ];

  String _paymentMethodLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'Cash':
        return l10n.ownerReportsPaymentCash;
      case 'Card':
        return l10n.ownerReportsPaymentCard;
      case 'Bank Transfer':
        return l10n.ownerReportsPaymentBankTransfer;
      default:
        return l10n.ownerReportsPaymentAll;
    }
  }

  String _searchHint(AppLocalizations l10n) {
    switch (_selectedTab) {
      case 0:
        return l10n.ownerReportsSearchHintOrders;
      case 1:
        return l10n.ownerReportsSearchHintDailySales;
      case 2:
        return l10n.ownerReportsSearchHintTechnician;
      case 3:
        return l10n.ownerReportsSearchHintCustomer;
      case 4:
        return l10n.ownerReportsSearchHintProduct;
      case 5:
        return l10n.ownerReportsSearchHintDepartment;
      case 6:
        return l10n.ownerReportsSearchHintBranch;
      case 7:
        return l10n.ownerReportsSearchHintCashier;
      default:
        return l10n.ownerReportsSearchHintDefault;
    }
  }

  Widget _buildReportTypeAndSearch(AppLocalizations l10n) {
    final labels = _tabLabels(l10n);
    final selectedLabel = labels[_selectedTab.clamp(0, labels.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: ReportsSearchBar(
              key: ValueKey('reports-search-$_selectedTab'),
              hint: _searchHint(l10n),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: OwnerStyledDropdown<String>(
              value: selectedLabel,
              options: [
                for (final label in labels)
                  OwnerDropdownOption(value: label, label: label),
              ],
              onChanged: (label) {
                if (label == null) return;
                final index = labels.indexOf(label);
                if (index < 0 || index == _tabController.index) return;
                _tabController.animateTo(index);
              },
              height: 44,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              menuMinWidth: 180,
              menuMaxWidth: 240,
              localizeLabels: false,
              triggerStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _paymentMethodApiValue(String uiId) {
    switch (uiId) {
      case 'Cash':
        return 'cash';
      case 'Card':
        return 'card';
      case 'Bank Transfer':
        return 'bank';
      default:
        return null; // All
    }
  }

  Widget _buildPaymentMethodTabs(AppLocalizations l10n) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final vm = context.read<ReportsManagementViewModel>();
    return PosSegmentedListTabs(
      tabs: [
        for (final method in _paymentMethods)
          PosSegmentedTab(
            id: method,
            label: _paymentMethodLabel(l10n, method),
          ),
      ],
      selectedId: _selectedPaymentMethod,
      onSelected: (id) {
        setState(() => _selectedPaymentMethod = id);
        vm.setOrdersPaymentMethod(_paymentMethodApiValue(id));
      },
      layout: PosSegmentedTabLayout.expanded,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      outerRadius: OwnerUi.segmentedTabOuterRadius,
      innerRadius: OwnerUi.segmentedTabInnerRadius,
      tabGap: 2,
      containerInnerPadding: 4,
      tabVerticalPadding: OwnerUi.segmentedTabVerticalPad(isTablet),
      tabHorizontalPadding: isTablet ? 8.0 : 4.0,
      fontSize: isTablet ? 12.5 : 11.5,
    );
  }

  // ── Tab Content ────────────────────────────────────────────────────────────

  List<Widget> _buildTabViews(ReportsManagementViewModel vm) {
    return [
      OrdersTab(
        searchQuery: _searchQuery,
        selectedPaymentMethod: _selectedPaymentMethod,
        vm: vm,
      ),
      DailySalesTab(
        searchQuery: _searchQuery,
        vm: vm,
      ),
      ByTechnicianTab(
        searchQuery: _searchQuery,
        vm: vm,
      ),
      ByCustomerTab(
        searchQuery: _searchQuery,
        vm: vm,
      ),
      ByProductTab(
        searchQuery: _searchQuery,
        selectedTechnician: _selectedTechnician,
        onTechnicianChanged: (v) =>
            setState(() => _selectedTechnician = v),
        vm: vm,
      ),
      ByDepartmentTab(
        searchQuery: _searchQuery,
        vm: vm,
      ),
      ByBranchTab(
        searchQuery: _searchQuery,
        vm: vm,
      ),
      ByCashierTab(
        searchQuery: _searchQuery,
        vm: vm,
      ),
    ];
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}k';
    return v.toStringAsFixed(2);
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _TabConfig {
  final IconData icon;
  const _TabConfig({required this.icon});
}

/// Full-screen error state shown when there's no cached data.
class _ErrorView extends StatelessWidget {
  final ReportsError error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNetwork = error.type == ReportsErrorType.network;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                color: AppColors.primaryLight,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNetwork ? l10n.ownerReportsErrorNoConnection : l10n.ownerReportsErrorGeneric,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              error.userFriendlyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            if (error.isRetryable)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.ownerReportsTryAgain),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thin banner shown at top when a refresh fails but data is still shown.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.primaryLight, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              AppLocalizations.of(context)!.ownerReportsRetry,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}