import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';

import 'super_admin_dashboard_view_model.dart';

class SuperAdminDashboardView extends StatelessWidget {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SuperAdminDashboardViewModel(),
      child: const _SuperAdminDashboardContent(),
    );
  }
}

class _SuperAdminDashboardContent extends StatefulWidget {
  const _SuperAdminDashboardContent();

  @override
  State<_SuperAdminDashboardContent> createState() => _SuperAdminDashboardContentState();
}

class _SuperAdminDashboardContentState extends State<_SuperAdminDashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminDashboardViewModel>().refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuperAdminDashboardViewModel>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primaryLight,
        elevation: 4,
        icon: const Icon(Icons.download_rounded, color: AppColors.secondaryLight, size: 24),
        label: const Text('Export Report', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: vm.refreshData,
        color: AppColors.primaryLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stats Row
              if (isDesktop)
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Revenue', 'SAR ${vm.totalRevenue.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Total Orders', vm.totalOrders.toString(), Icons.shopping_cart_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Active Branches', vm.totalBranches.toString(), Icons.store_mall_directory_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Total Users', vm.totalUsers.toString(), Icons.people_alt_rounded)),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Revenue', 'SAR ${vm.totalRevenue.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Total Orders', vm.totalOrders.toString(), Icons.shopping_cart_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Active Branches', vm.totalBranches.toString(), Icons.store_mall_directory_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Total Users', vm.totalUsers.toString(), Icons.people_alt_rounded)),
                    ],
                  ),
                ],
              ),
            
            const SizedBox(height: 24),

            // Main Content Area
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildQuickActions(),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildQuickActions(),
                ],
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      height: 130, // Synced with Finance
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondaryLight, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.secondaryLight.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.add_business_rounded, 'Add Branch')),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.person_add_rounded, 'New User')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.campaign_rounded, 'Broadcast')),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.settings_suggest_rounded, 'Config')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
