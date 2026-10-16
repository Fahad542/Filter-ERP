import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

import 'Dashboard/super_admin_dashboard_view.dart';
import 'Branches/super_admin_branches_view.dart';
import 'Users/super_admin_users_view.dart';
import 'Corporate/super_admin_corporate_view.dart';
import 'Inventory/super_admin_inventory_view.dart';
import 'Lockers/super_admin_lockers_view.dart';
import 'Orders/super_admin_orders_view.dart';
import 'Finance/super_admin_finance_view.dart';
import 'Settings/super_admin_settings_view.dart';
import 'Reports/super_admin_reports_view.dart';
import 'Departments/super_admin_departments_view.dart'; // newly added import
import '../Menu/menu_view.dart';
import '../../services/session_service.dart';

import 'widgets/super_admin_bottom_bar.dart';
import '../../utils/restart_widget.dart';
import '../../widgets/app_brand_logo.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  static void goHome(BuildContext context) {
    final state = context.findAncestorStateOfType<SuperAdminShellState>();
    if (state != null) {
      state.goHome();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  State<SuperAdminShell> createState() => SuperAdminShellState();
}

class SuperAdminShellState extends State<SuperAdminShell> {
  int _selectedIndex = 0;
  String _adminName = 'Super Admin';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SessionService().getUser(role: 'admin');
    if (user != null && user.name != null) {
      setState(() {
        _adminName = user.name ?? 'Super Admin';
      });
    }
  }

  void goHome() {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
  }

  void goToIndex(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  final List<Widget> _views = const [
    SuperAdminDashboardView(),  // 0
    SuperAdminBranchesView(),   // 1
    SuperAdminUsersView(),      // 2
    SuperAdminCorporateView(),  // 3
    SuperAdminInventoryView(),  // 4
    SuperAdminLockersView(),    // 5
    SuperAdminOrdersView(),     // 6
    SuperAdminFinanceView(),    // 7
    SuperAdminSettingsView(),   // 8
    SuperAdminReportsView(),    // 9
    const SuperAdminDepartmentsView(), // 10
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final bool isDashboard = _selectedIndex == 0;
    final bool showBottomBar = [0, 9, 6, 8].contains(_selectedIndex) && !isDesktop;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FD),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: isDashboard 
                ? Stack(
                    children: [
                      Column(
                        children: [
                          _buildAppBar(context, isDesktop, 170),
                          Expanded(child: Container()),
                        ],
                      ),
                      Positioned.fill(
                        top: 130, // Adjusted for slightly larger header
                        child: _views[_selectedIndex],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildAppBar(context, isDesktop, 75),
                      Expanded(
                        child: _views[_selectedIndex],
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomBar 
          ? SuperAdminBottomBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            )
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDesktop, double height) {
    final bool isDashboard = _selectedIndex == 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        top: !isDashboard,
        bottom: false,
        child: Container(
          height: height,
          padding: EdgeInsets.only(
            left: 16, 
            right: 16, 
            top: isDashboard ? 40 : 0, // Moved further down as requested
          ),
          child: Align(
            alignment: isDashboard ? Alignment.topCenter : Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isDesktop)
                InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  ),
                )
              else
                InkWell(
                  onTap: () {},
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset('assets/images/global.png', width: 22, color: Colors.black,
                        errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 22, color: Colors.black)),
                    ),
                  ),
                ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SUPER ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppColors.secondaryLight.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      _getAppTitle(_selectedIndex),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              if (!isDesktop)
                InkWell(
                  onTap: () {},
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset('assets/images/global.png', width: 22, color: Colors.black,
                        errorBuilder: (_, __, ___) => const Icon(Icons.language, size: 22, color: Colors.black)),
                    ),
                  ),
                ),
              
              const SizedBox(width: 12),
              
              InkWell(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/images/notifications.png', width: 22, color: Colors.black,
                        errorBuilder: (_, __, ___) => const Icon(Icons.notifications_rounded, size: 22, color: Colors.black)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Profile
              if (isDesktop) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _adminName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondaryLight),
                    ),
                    const Text(
                      'Super Admin',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: AppColors.secondaryLight),
                    ),
                  ],
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: AppColors.secondaryLight,
      child: _buildSidebarContent(context),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.secondaryLight,
      child: _buildSidebarContent(context),
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
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
                fallbackIcon: Icons.store_mall_directory_rounded,
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
                        'SA',
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
                    'Super Admin',
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
              _buildMenuItem(0, 'Dashboard', Icons.dashboard_rounded),
              _buildMenuItem(1, 'Branch Management', Icons.account_tree_rounded),
              _buildMenuItem(2, 'Users Management', Icons.people_alt_rounded),
              _buildMenuItem(3, 'Corporate Clients', Icons.business_center_rounded),
              _buildMenuItem(4, 'Inventory / Warehouse', Icons.inventory_2_rounded),
              _buildMenuItem(10, 'Departments', Icons.domain_rounded), // newly added tab
              _buildMenuItem(5, 'Lockers System', Icons.lock_rounded),
              _buildMenuItem(7, 'Finance & Accounts', Icons.account_balance_wallet_rounded),
              _buildMenuItem(9, 'Report & Analytics', Icons.bar_chart_rounded),
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

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          goToIndex(index);
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
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
                    color: isSelected ? AppColors.secondaryLight : Colors.white70,
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
        onTap: () => _showLogoutDialog(context),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log out',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondaryLight),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to log out of Super Admin?',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondaryLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final session = SessionService();
                        await session.clearSession(role: 'admin');
                        await session.saveLastPortal('');
                        if (context.mounted) {
                          RestartWidget.restartApp(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Log out', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w800)),
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

  String _getAppTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Branch Management';
      case 2: return 'Users Management';
      case 3: return 'Corporate Clients';
      case 4: return 'Inventory / Warehouse';
      case 5: return 'Lockers System';
      case 6: return 'Orders & POS Reports';
      case 7: return 'Finance & Accounts';
      case 8: return 'Profile';
      case 9: return 'Report & Analytics';
      case 10: return 'Departments'; // Add the appbar title
      default: return 'Super Admin';
    }
  }
}
