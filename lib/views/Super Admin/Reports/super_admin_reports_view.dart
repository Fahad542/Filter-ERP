import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';

import 'super_admin_reports_view_model.dart';

class SuperAdminReportsView extends StatelessWidget {
  const SuperAdminReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SuperAdminReportsViewModel(),
      child: const _SuperAdminReportsContent(),
    );
  }
}

class _SuperAdminReportsContent extends StatefulWidget {
  const _SuperAdminReportsContent();

  @override
  State<_SuperAdminReportsContent> createState() => _SuperAdminReportsContentState();
}

class _SuperAdminReportsContentState extends State<_SuperAdminReportsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminReportsViewModel>().refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuperAdminReportsViewModel>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: vm.refreshData,
        color: AppColors.primaryLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildChartSection(vm),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildRecentOrdersSidebar(vm),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildChartSection(vm),
                    const SizedBox(height: 24),
                    _buildRecentOrdersSidebar(vm),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(SuperAdminReportsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade100, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5000,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value / 1000).toInt()}k', style: TextStyle(color: Colors.grey.shade500, fontSize: 12));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 30000,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(vm.salesData.length, (index) => FlSpot(index.toDouble(), vm.salesData[index])),
                    isCurved: true,
                    color: AppColors.primaryLight,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppColors.primaryLight,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryLight.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSidebar(SuperAdminReportsViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
              const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
            ],
          ),
          const SizedBox(height: 20),
          ...vm.recentOrders.map((order) => _buildOrderTile(order)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final isCompleted = order['status'] == 'Completed';
    final isPending = order['status'] == 'Pending';
    final isCancelled = order['status'] == 'Cancelled';
    
    Color statusColor = Colors.grey;
    if (isCompleted) statusColor = const Color(0xFF10B981);
    else if (isPending) statusColor = const Color(0xFFF59E0B);
    else if (isCancelled) statusColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.secondaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['customer'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.secondaryLight)),
                const SizedBox(height: 2),
                Text('${order['id']} • ${order['branch']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SAR ${order['amount'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.secondaryLight)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
