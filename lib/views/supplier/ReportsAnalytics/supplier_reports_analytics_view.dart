import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/widgets.dart';
import 'supplier_reports_analytics_view_model.dart';

class SupplierReportsAnalyticsView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierReportsAnalyticsView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChangeNotifierProvider(
      create: (_) => SupplierReportsAnalyticsViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PosScreenAppBar(
            title: 'Reports & Analytics',
            showHamburger: true,
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
            showBackButton: false,
          ),
          body: Consumer<SupplierReportsAnalyticsViewModel>(
            builder: (context, vm, _) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Summary',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 24),
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          switch (i) {
                            case 0:
                              return SizedBox(
                                width: 260,
                                child: _summaryCard(
                                  Icons.receipt_long_outlined,
                                  'Total Orders Received',
                                  '${vm.totalOrdersReceived}',
                                ),
                              );
                            case 1:
                              return SizedBox(
                                width: 260,
                                child: _summaryCard(
                                  Icons.payments_outlined,
                                  'Total Revenue',
                                  vm.totalRevenue,
                                ),
                              );
                            case 2:
                              return SizedBox(
                                width: 260,
                                child: _summaryCard(
                                  Icons.account_balance_wallet_outlined,
                                  'Total Payments Received',
                                  vm.totalPaymentsReceived,
                                ),
                              );
                            case 3:
                              return SizedBox(
                                width: 260,
                                child: _summaryCard(
                                  Icons.account_balance_outlined,
                                  'Total Payables',
                                  vm.totalPayables,
                                ),
                              );
                            default:
                              return SizedBox(
                                width: 260,
                                child: _summaryCard(
                                  Icons.delivery_dining_outlined,
                                  'Avg Delivery Accuracy',
                                  vm.avgDeliveryAccuracy,
                                ),
                              );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Report Categories',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...vm.reportCategories.map(
                      (label) => _reportCategoryTile(context, label),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: CustomButton(
                          text: 'Generate Custom Report',
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coming soon'),
                                  duration: Duration(seconds: 1),
                                ),
                              ),
                          backgroundColor: AppColors.primaryLight,
                          textColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _reportCategoryTile(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label – Coming soon'),
                duration: const Duration(seconds: 1),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    _reportCategoryIcon(label),
                    size: 22,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _reportCategoryIcon(String label) {
    if (label.startsWith('Sales by Workshop')) return Icons.store_outlined;
    if (label.startsWith('Product-wise')) return Icons.pie_chart_outline;
    if (label.startsWith('Delivery')) return Icons.local_shipping_outlined;
    if (label.startsWith('Invoice')) return Icons.receipt_long_outlined;
    if (label.startsWith('Workshop Stock')) return Icons.inventory_2_outlined;
    if (label.startsWith('Critical Stock')) return Icons.warning_amber_rounded;
    if (label.startsWith('My Purchases'))
      return Icons.account_balance_wallet_outlined;
    if (label.startsWith('Operational')) return Icons.receipt_outlined;
    if (label.startsWith('Workshop Statement'))
      return Icons.description_outlined;
    return Icons.analytics_outlined;
  }

  Widget _summaryCard(IconData icon, String title, String value) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.primaryLight),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryLight,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
