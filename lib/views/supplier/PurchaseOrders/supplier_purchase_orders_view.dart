import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import 'supplier_purchase_orders_view_model.dart';

class SupplierPurchaseOrdersView extends StatelessWidget {
  final VoidCallback? onBack;

  const SupplierPurchaseOrdersView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final isLargeScreen = isDesktop || isTablet;
    final goToDashboard =
        onBack ??
        () => Navigator.popUntil(context, ModalRoute.withName('/supplier'));

    return ChangeNotifierProvider(
      create: (_) => SupplierPurchaseOrdersViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isLargeScreen ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: isDesktop
              ? null
              : PosScreenAppBar(
                  title: 'All Orders',
                  onBack: goToDashboard,
                  showBackButton: false,
                  showGlobalLeft: true,
                ),
          body: Consumer<SupplierPurchaseOrdersViewModel>(
            builder: (context, vm, _) {
              return SafeArea(
                top: isDesktop,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 32 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: AppColors.secondaryLight,
                              ),
                              onPressed: goToDashboard,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'All Orders',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                      _buildOrderStatusSummary(context, isLargeScreen, vm),
                      const SizedBox(height: 32),

                      Text(
                        'Status Tabs:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(vm.statusTabs.length, (i) {
                            final isSelected = vm.selectedStatusTabIndex == i;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: Text(
                                  vm.statusTabs[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.secondaryLight
                                        : Colors.grey.shade600,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) => vm.setStatusTab(i),
                                selectedColor: AppColors.primaryLight,
                                backgroundColor: Colors.white,
                                elevation: isSelected ? 4 : 0,
                                shadowColor: AppColors.primaryLight.withOpacity(
                                  0.4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                showCheckmark: false,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Orders',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOrdersList(context, vm, isLargeScreen),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    SupplierPurchaseOrdersViewModel vm,
    bool isLargeScreen,
  ) {
    final list = vm.filteredOrders;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No orders found',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLargeScreen) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF8F9FD),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLight,
                fontSize: 14,
              ),
              columnSpacing: 32,
              columns: const [
                DataColumn(label: Text('PO #')),
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: list.map((o) {
                final statusColor = o.status == 'Accepted'
                    ? Colors.green
                    : (o.status == 'Pending'
                          ? Colors.orange
                          : AppColors.primaryLight);
                return DataRow(
                  cells: [
                    DataCell(Text(o.poNumber)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(o.branch),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        o.date,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    DataCell(
                      Text(
                        o.itemsSummary,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    DataCell(
                      Text(
                        o.total,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          o.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: _buildRowActions(context, vm, o),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final o = list[i];
        final statusColor = o.status == 'Accepted'
            ? const Color(0xFF2E7D32)
            : (o.status == 'Pending'
                  ? Colors.orange.shade800
                  : AppColors.primaryLight);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_outlined,
                        color: AppColors.secondaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        o.poNumber,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        o.status,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Card body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch & date row
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          o.branch,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          o.date,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Items & total row
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            o.itemsSummary,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          o.total,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Actions
                    _buildRowActions(context, vm, o),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRowActions(
    BuildContext context,
    SupplierPurchaseOrdersViewModel vm,
    PurchaseOrderItem o,
  ) {
    if (o.status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => vm.accept(o.id),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'Accept',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.secondaryLight,
                elevation: 4,
                shadowColor: AppColors.primaryLight.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => vm.reject(o.id),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200, width: 1.5),
                backgroundColor: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (o.status == 'Accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => vm.process(o.id),
          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: const Text(
            'Process & Fulfill',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: AppColors.secondaryLight.withOpacity(0.3),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          side: const BorderSide(color: AppColors.secondaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'View Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildOrderStatusSummary(
    BuildContext context,
    bool isLargeScreen,
    SupplierPurchaseOrdersViewModel vm,
  ) {
    final items = [
      ('Pending', vm.pendingCount, Icons.hourglass_empty_rounded),
      ('Accepted', vm.acceptedCount, Icons.check_circle_outline_rounded),
      ('Processing', vm.processingCount, Icons.settings_outlined),
      ('Ready to Deliver', vm.readyToDeliverCount, Icons.inventory_2_outlined),
      ('On the Way', vm.onTheWayCount, Icons.local_shipping_outlined),
      ('Delivered', vm.deliveredCount, Icons.task_alt_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((e) {
          final label = e.$1;
          final count = e.$2;
          final icon = e.$3;
          return Container(
            width: 120, // Fixed width for each item in the row
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryLight.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
