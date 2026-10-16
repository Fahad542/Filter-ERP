import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../supplier_shell_controller.dart';
import '../OrderProcessingQueue/supplier_order_processing_queue_view.dart';
import '../DeliveryTasks/supplier_delivery_tasks_view.dart';
import '../ManualInvoice/supplier_manual_invoice_view.dart';
import '../StockVisibility/supplier_stock_visibility_view.dart';
import '../PurchasesPayables/supplier_purchases_payables_view.dart';
import '../OperationalExpenses/supplier_operational_expenses_view.dart';
import '../PromoBanners/supplier_promo_banners_view.dart';
import '../AddProduct/supplier_add_product_view.dart';
import '../InventoryTransactionLog/supplier_inventory_transaction_log_view.dart';
import '../ReportsAnalytics/supplier_reports_analytics_view.dart';
import 'supplier_home_view_model.dart';

class SupplierHomeView extends StatelessWidget {
  final VoidCallback? onOpenDrawer;

  const SupplierHomeView({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupplierHomeViewModel(),
      child: _SupplierHomeContent(onOpenDrawer: onOpenDrawer),
    );
  }
}

class _SupplierHomeContent extends StatelessWidget {
  final VoidCallback? onOpenDrawer;

  const _SupplierHomeContent({this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final vm = context.watch<SupplierHomeViewModel>();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(isTablet || isDesktop ? 0.9 : 0.85),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handled by shell
        appBar: isDesktop
            ? null
            : PosAppBar(
                userName: vm.companyName,
                infoTitle: 'Supplier Portal',
                infoBranch: vm.showInternalWarehouseBadge
                    ? 'Internal Warehouse'
                    : '',
                infoTime: isTablet
                    ? DateFormat('dd MMM yyyy · hh:mm a').format(DateTime.now())
                    : null,

                showBackButton: false,
                onMenuPressed: onOpenDrawer,
              ),
        body: SafeArea(
          top: isDesktop,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop || isTablet ? 32 : 24,
              vertical: 24,
            ),
            children: [
              if (isDesktop) ...[
                const Text(
                  'Supplier Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (vm.criticalStockAlerts.isNotEmpty) ...[
                _buildCriticalStockAlerts(context, vm),
                const SizedBox(height: 24),
              ],
              _buildKpiCards(context, isDesktop || isTablet, vm),
              const SizedBox(height: 24),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: Column(children: [])),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildFinancialSummary(vm),
                          const SizedBox(height: 24),
                          _QuickActionsSection(
                            isDesktop: true,
                            onAction: (label) => _onQuickAction(context, label),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildFinancialSummary(vm),
                    const SizedBox(height: 24),

                    _QuickActionsSection(
                      isDesktop: false,
                      onAction: (label) => _onQuickAction(context, label),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

extension _SupplierHomeContentExtension on _SupplierHomeContent {
  Widget _buildKpiCards(
    BuildContext context,
    bool isLargeScreen,
    SupplierHomeViewModel vm,
  ) {
    if (isLargeScreen) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Revenue',
              vm.monthRevenue,
              Icons.account_balance_wallet_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Today Orders',
              vm.newOrdersToday.toString(),
              Icons.shopping_cart_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total Invoiced',
              vm.totalInvoiced,
              Icons.receipt_long_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Payments Received',
              vm.paymentsReceived,
              Icons.payments_rounded,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Revenue',
                  vm.monthRevenue,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Today Orders',
                  vm.newOrdersToday.toString(),
                  Icons.shopping_cart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Invoiced',
                  vm.totalInvoiced,
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Payments Received',
                  vm.paymentsReceived,
                  Icons.payments_rounded,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      height: 115,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryLight,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  double _parseAmount(String s) =>
      double.tryParse(s.replaceAll('SAR', '').replaceAll(',', '').trim()) ?? 0;

  Widget _buildFinancialSummary(SupplierHomeViewModel vm) {
    final total = _parseAmount(vm.currentPayables);
    final overdue = _parseAmount(vm.overdueAmount);
    final normal = (total - overdue).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Current Payables / Liabilities',
                  style: TextStyle(
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Doughnut chart
            SizedBox(
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 58,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: normal,
                          color: const Color(0xFFEEEEEE),
                          title: '',
                          radius: 28,
                        ),
                        PieChartSectionData(
                          value: overdue,
                          color: Colors.orangeAccent,
                          title: '',
                          radius: 28,
                        ),
                      ],
                    ),
                  ),
                  // Center label inside the hole
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.secondaryLight.withOpacity(0.5),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        vm.currentPayables,
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chartLegend(
                  const Color(0xFFE0E0E0),
                  'Payable',
                  labelColor: AppColors.secondaryLight,
                ),
                const SizedBox(width: 24),
                _chartLegend(
                  Colors.orangeAccent,
                  'Overdue',
                  labelColor: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Big amount display
            Text(
              vm.currentPayables,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'Overdue: ${vm.overdueAmount}',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegend(Color color, String label, {Color? labelColor}) {
    final textColor = labelColor ?? Colors.black87;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static const Color _criticalRed = Color(0xFFB71C1C);
  static const Color _criticalRedLight = Color(0xFFFFEBEE);

  Widget _buildCriticalStockAlerts(
    BuildContext context,
    SupplierHomeViewModel vm,
  ) {
    final count = vm.criticalStockAlerts.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _criticalRed.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: _criticalRedLight, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            decoration: const BoxDecoration(
              color: _criticalRed,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: _criticalRed,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Critical Stock Alerts ($count)',
                        style: const TextStyle(
                          color: _criticalRed,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final alert in vm.criticalStockAlerts)
                  Container(
                    width: double.infinity,
                    color: _criticalRedLight.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.message,
                            style: const TextStyle(
                              color: _criticalRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: _criticalRed,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Quick Order – Coming soon'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                'Quick Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQuickAction(BuildContext context, String action) {
    final ctrl = context.read<SupplierShellController>();

    // Screens that are main tabs → just switch the tab.
    switch (action) {
      case 'View All Orders':
        ctrl.switchTab(1);
        return;
      case 'Inventory Stock Balances':
        ctrl.switchTab(2);
        return;
      case 'Profile':
        ctrl.switchTab(3);
        return;
      default:
        break;
    }

    // All other screens open as an overlay inside the shell (bottom bar stays).
    Widget? screen;
    switch (action) {
      case 'Order Processing Queue':
        screen = SupplierOrderProcessingQueueView(onBack: ctrl.pop);
        break;
      case 'Delivery Tasks':
        screen = SupplierDeliveryTasksView(onBack: ctrl.pop);
        break;
      case 'Submit Invoice':
        screen = SupplierManualInvoiceView(onBack: ctrl.pop);
        break;
      case 'Workshop Stock Visibility':
        screen = SupplierStockVisibilityView(onBack: ctrl.pop);
        break;
      case 'My Purchases & Payables':
        screen = SupplierPurchasesPayablesView(onBack: ctrl.pop);
        break;
      case 'Operational Expenses':
        screen = SupplierOperationalExpensesView(onBack: ctrl.pop);
        break;
      case 'Promotional Banners':
        screen = SupplierPromoBannersView(onBack: ctrl.pop);
        break;
      case 'Add Product':
        screen = SupplierAddProductView(onBack: ctrl.pop);
        break;
      case 'Inventory Transaction Log':
        screen = SupplierInventoryTransactionLogView(onBack: ctrl.pop);
        break;
      case 'Reports & Analytics':
        screen = SupplierReportsAnalyticsView(onBack: ctrl.pop);
        break;
    }

    if (screen != null) {
      ctrl.navigateTo(screen, sourceTab: 0); // keep Home tab highlighted
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action – Coming soon'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _QuickActionsSection extends StatefulWidget {
  final bool isDesktop;
  final void Function(String label) onAction;

  const _QuickActionsSection({required this.isDesktop, required this.onAction});

  @override
  State<_QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<_QuickActionsSection> {
  bool _expanded = false;

  static const List<(String, IconData)> _actions = [
    ('All Orders', Icons.list_alt),
    ('Order Queue', Icons.queue),
    ('Delivery Tasks', Icons.local_shipping),
    ('Submit Invoice', Icons.receipt_long),
    ('Payments Rcvd', Icons.payment),
    ('Stock Vis', Icons.visibility),
    ('Payables', Icons.account_balance_wallet),
    ('Op Expenses', Icons.receipt),
    ('Promo Banners', Icons.campaign),
    ('Add Product', Icons.add_box),
    ('Stock Bal', Icons.inventory),
    ('Inv Log', Icons.list),
    ('Reports', Icons.analytics),
  ];

  @override
  Widget build(BuildContext context) {
    final displayItems = _expanded
        ? [..._actions, ('Less', Icons.expand_less)]
        : [..._actions.take(5), ('More', Icons.expand_more)];

    final rows = <List<(String, IconData)>>[];
    for (var i = 0; i < displayItems.length; i += 3) {
      rows.add(
        displayItems.sublist(
          i,
          i + 3 > displayItems.length ? displayItems.length : i + 3,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          ...rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;
            return Column(
              children: [
                if (rowIndex > 0) const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ...row.map((e) {
                      final label = e.$1;
                      final icon = e.$2;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                if (label == 'More') {
                                  setState(() => _expanded = true);
                                } else if (label == 'Less') {
                                  setState(() => _expanded = false);
                                } else {
                                  final fullActionName = _getFullActionName(
                                    label,
                                  );
                                  widget.onAction(fullActionName);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 24,
                                      color: AppColors.primaryLight,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (row.length < 3)
                      ...List.generate(
                        3 - row.length,
                        (_) => const Expanded(child: SizedBox()),
                      ),
                  ],
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getFullActionName(String shortLabel) {
    switch (shortLabel) {
      case 'All Orders':
        return 'View All Orders';
      case 'Order Queue':
        return 'Order Processing Queue';
      case 'Payments Rcvd':
        return 'Payments Received';
      case 'Stock Vis':
        return 'Workshop Stock Visibility';
      case 'Payables':
        return 'My Purchases & Payables';
      case 'Op Expenses':
        return 'Operational Expenses';
      case 'Promo Banners':
        return 'Promotional Banners';
      case 'Stock Bal':
        return 'Inventory Stock Balances';
      case 'Inv Log':
        return 'Inventory Transaction Log';
      case 'Reports':
        return 'Reports & Analytics';
      default:
        return shortLabel;
    }
  }
}
