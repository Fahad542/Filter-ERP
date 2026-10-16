import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'supplier_shell_controller.dart';
import 'Home/supplier_home_view.dart';
import 'PurchaseOrders/supplier_purchase_orders_view.dart';
import 'InventoryBalances/supplier_inventory_balances_view.dart';
import 'PaymentsReceived/supplier_payments_received_view.dart';
import 'OrderProcessingQueue/supplier_order_processing_queue_view.dart';
import 'DeliveryTasks/supplier_delivery_tasks_view.dart';
import 'ManualInvoice/supplier_manual_invoice_view.dart';
import 'StockVisibility/supplier_stock_visibility_view.dart';
import 'PurchasesPayables/supplier_purchases_payables_view.dart';
import 'OperationalExpenses/supplier_operational_expenses_view.dart';
import 'PromoBanners/supplier_promo_banners_view.dart';
import 'AddProduct/supplier_add_product_view.dart';
import 'ReportsAnalytics/supplier_reports_analytics_view.dart';
import 'Profile/supplier_profile_view.dart';
import 'StaffRoles/supplier_staff_roles_view.dart';
import 'Login/supplier_login_view.dart';
import '../../services/session_service.dart';
import '../Menu/menu_view.dart';
import '../../utils/restart_widget.dart';
import '../../widgets/app_brand_logo.dart';

class SupplierShell extends StatefulWidget {
  const SupplierShell({super.key});

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell> {
  late final SupplierShellController _ctrl;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _ctrl = SupplierShellController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    _ctrl.clearStack();
    _ctrl.switchTab(0);
  }

  List<Widget> get _screens => [
    SupplierHomeView(
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    SupplierPurchaseOrdersView(onBack: _goToDashboard),
    SupplierInventoryBalancesView(onBack: _goToDashboard),
    SupplierProfileView(onBack: _goToDashboard),
  ];

  void _onTabTap(int index) {
    if (index == 4) {
      _ctrl.clearStack();
      _scaffoldKey.currentState?.openDrawer();
    } else {
      _ctrl.switchTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;
    final showBottomBar = !isDesktop;

    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<SupplierShellController>(
        builder: (context, ctrl, _) {
          return PopScope(
            canPop: !ctrl.hasActiveScreen,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && ctrl.hasActiveScreen) {
                ctrl.pop();
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: const Color(0xFFF8F9FD),
              drawer: (isDesktop && !ctrl.hasActiveScreen)
                  ? null
                  : Drawer(
                      width: 280,
                      backgroundColor: AppColors.secondaryLight,
                      child: _buildSidebarContent(context, ctrl),
                    ),
              body: Row(
                children: [
                  if (isDesktop && !ctrl.hasActiveScreen)
                    Container(
                      width: 280,
                      color: AppColors.secondaryLight,
                      child: _buildSidebarContent(context, ctrl),
                    ),
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          isTablet || isDesktop ? 0.9 : 0.85,
                        ),
                      ),
                      child:
                          ctrl.activeScreen ??
                          IndexedStack(
                            index: ctrl.tabIndex,
                            children: _screens,
                          ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: (!isDesktop && !ctrl.hasActiveScreen)
                  ? SupplierBottomBar(
                      currentIndex: ctrl.effectiveTabIndex,
                      onTap: _onTabTap,
                      showMenuTab: false,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    SupplierShellController ctrl,
  ) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return Column(
      children: [
        // Logo / Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBrandLogo(
                height: 36,
                color: AppColors.primaryLight,
                fit: BoxFit.contain,
                colorBlendMode: BlendMode.srcIn,
                fallbackIcon: Icons.store,
                fallbackSize: 36,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SP',
                        style: TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Supplier',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildMenuItem(
                context,
                ctrl,
                'Dashboard',
                Icons.dashboard_rounded,
                0,
                null,
              ),
              if (isDesktop)
                _buildMenuItem(
                  context,
                  ctrl,
                  'All Orders',
                  Icons.receipt_long_outlined,
                  1,
                  null,
                ),
              _buildMenuItem(
                context,
                ctrl,
                'Order Queue',
                Icons.queue_rounded,
                4,
                SupplierOrderProcessingQueueView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Delivery Tasks',
                Icons.local_shipping_outlined,
                4,
                SupplierDeliveryTasksView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Submit Invoice',
                Icons.receipt_outlined,
                4,
                SupplierManualInvoiceView(onBack: _goToDashboard),
              ),
              if (isDesktop)
                _buildMenuItem(
                  context,
                  ctrl,
                  'Inventory & Stock',
                  Icons.inventory_2_outlined,
                  2,
                  null,
                ),
              _buildMenuItem(
                context,
                ctrl,
                'Stock Visibility',
                Icons.visibility_outlined,
                4,
                SupplierStockVisibilityView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Add Product',
                Icons.add_box_outlined,
                4,
                SupplierAddProductView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Payments Received',
                Icons.payments_outlined,
                4,
                SupplierPaymentsReceivedView(onBackToDashboard: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Purchases & Payables',
                Icons.account_balance_outlined,
                4,
                SupplierPurchasesPayablesView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Op Expenses',
                Icons.money_off_outlined,
                4,
                SupplierOperationalExpensesView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Reports & Analytics',
                Icons.analytics_outlined,
                4,
                SupplierReportsAnalyticsView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Promo Banners',
                Icons.campaign_outlined,
                4,
                SupplierPromoBannersView(onBack: _goToDashboard),
              ),
              _buildMenuItem(
                context,
                ctrl,
                'Staff & Roles',
                Icons.badge_outlined,
                4,
                SupplierStaffRolesView(onBack: _goToDashboard),
              ),
              if (isDesktop)
                _buildMenuItem(
                  context,
                  ctrl,
                  'Profile',
                  Icons.person_outline,
                  4,
                  SupplierProfileView(onBack: _goToDashboard),
                ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 10),
              _buildLogoutItem(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log out',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to log out from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final session = SessionService();
                        // Adjust role to match Supplier (e.g., 'supplier')
                        await session.clearSession(role: 'supplier');
                        await session.saveLastPortal('');
                        if (mounted) {
                          RestartWidget.restartApp(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    SupplierShellController ctrl,
    String title,
    IconData icon,
    int tabIndex,
    Widget? screen,
  ) {
    // If it's a main tab, check if it's selected. If it's a sub-screen, check if it's the active screen.
    final bool isSelected = screen == null
        ? ctrl.tabIndex == tabIndex && ctrl.activeScreen == null
        : ctrl.activeScreen?.runtimeType == screen.runtimeType;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
          }
          if (screen != null) {
            ctrl.navigateTo(screen, sourceTab: tabIndex);
          } else {
            ctrl.clearStack();
            ctrl.switchTab(tabIndex);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.secondaryLight : Colors.white60,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.secondaryLight
                        : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
          }
          _showLogoutDialog();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              SizedBox(width: 14),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupplierBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showMenuTab;

  const SupplierBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showMenuTab = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Home'),
              _buildNavItem(context, 1, Icons.receipt_long_outlined, 'Orders'),
              _buildNavItem(
                context,
                2,
                Icons.inventory_2_outlined,
                'Inventory',
              ),
              _buildNavItem(context, 3, Icons.person_outline, 'Profile'),
              if (showMenuTab)
                _buildNavItem(context, 4, Icons.menu_rounded, 'Menu'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? 28 : 22,
              color: isSelected ? AppColors.primaryLight : Colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isTablet ? 12 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.secondaryLight : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
