import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import 'supplier_inventory_transaction_log_view_model.dart';

class SupplierInventoryTransactionLogView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierInventoryTransactionLogView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final isLargeScreen = isDesktop || isTablet;

    return ChangeNotifierProvider(
      create: (_) => SupplierInventoryTransactionLogViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isLargeScreen ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: isDesktop
              ? null
              : PosScreenAppBar(
                  title: 'Inventory Transaction Log',
                  onBack:
                      onBack ??
                      () => Navigator.popUntil(
                        context,
                        ModalRoute.withName('/supplier'),
                      ),
                ),
          body: Consumer<SupplierInventoryTransactionLogViewModel>(
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
                              onPressed:
                                  onBack ??
                                  () => Navigator.popUntil(
                                    context,
                                    ModalRoute.withName('/supplier'),
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Transaction Log',
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

                      // Overview Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryLight.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: AppColors.primaryLight,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Recorded Transactions',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${vm.transactions.length}',
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Filters Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.filter_list_rounded,
                                  size: 20,
                                  color: AppColors.secondaryLight,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Filter Logs',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: isDesktop
                                      ? 220
                                      : (screenWidth - 80) / 2,
                                  child: DropdownButtonFormField<String>(
                                    value: vm.selectedProduct,
                                    decoration: InputDecoration(
                                      labelText: 'Product',
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.secondaryLight,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryLight,
                                      fontSize: 14,
                                    ),
                                    items: vm.products
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      vm.selectedProduct = v ?? 'All';
                                      vm.notifyListeners();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: isDesktop
                                      ? 220
                                      : (screenWidth - 80) / 2,
                                  child: DropdownButtonFormField<String>(
                                    value: vm.selectedType,
                                    decoration: InputDecoration(
                                      labelText: 'Transaction Type',
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.secondaryLight,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryLight,
                                      fontSize: 14,
                                    ),
                                    items: vm.types
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      vm.selectedType = v ?? 'All';
                                      vm.notifyListeners();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: isDesktop ? 220 : double.infinity,
                                  child: DropdownButtonFormField<String>(
                                    value: vm.selectedLocation,
                                    decoration: InputDecoration(
                                      labelText: 'Location',
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.secondaryLight,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryLight,
                                      fontSize: 14,
                                    ),
                                    items: vm.locations
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      vm.selectedLocation = v ?? 'All';
                                      vm.notifyListeners();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.secondaryLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Transaction History',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTable(vm, isLargeScreen),
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

  Widget _buildTable(
    SupplierInventoryTransactionLogViewModel vm,
    bool isLargeScreen,
  ) {
    if (vm.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions match your filters',
                style: AppTextStyles.bodyLarge.copyWith(
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
              columnSpacing: 40,
              columns: const [
                DataColumn(label: Text('Date & Time')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Product & Reason')),
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Before')),
                DataColumn(label: Text('Delta')),
                DataColumn(label: Text('After')),
                DataColumn(label: Text('User')),
              ],
              rows: vm.transactions.map((t) {
                final isPositive = t.delta.startsWith('+');
                final deltaColor = isPositive
                    ? const Color(0xFF4CAF50)
                    : Colors.red.shade700;

                Color typeBadgeColor;
                switch (t.type) {
                  case 'Receipt':
                  case 'Sale':
                    typeBadgeColor = AppColors.primaryLight;
                    break;
                  case 'Adjustment':
                    typeBadgeColor = Colors.orange.shade700;
                    break;
                  default:
                    typeBadgeColor = Colors.grey.shade600;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        t.dateTime,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeBadgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.type,
                          style: TextStyle(
                            color: typeBadgeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        t.reason,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    DataCell(
                      Text(
                        t.reference,
                        style: const TextStyle(color: AppColors.secondaryLight),
                      ),
                    ),
                    DataCell(Text(t.qtyBefore)),
                    DataCell(
                      Text(
                        t.delta,
                        style: TextStyle(
                          color: deltaColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        t.qtyAfter,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.user,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
      itemCount: vm.transactions.length,
      itemBuilder: (context, i) {
        final t = vm.transactions[i];
        final isPositive = t.delta.startsWith('+');
        final deltaColor = isPositive
            ? const Color(0xFF4CAF50)
            : Colors.red.shade700;

        Color typeBadgeColor;
        switch (t.type) {
          case 'Receipt':
          case 'Sale':
            typeBadgeColor = AppColors.primaryLight;
            break;
          case 'Adjustment':
            typeBadgeColor = Colors.orange.shade700;
            break;
          default:
            typeBadgeColor = Colors.grey.shade600;
        }

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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.secondaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.dateTime,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ref: ${t.reference}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: typeBadgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        t.type,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: typeBadgeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.reason,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recorded by: ${t.user}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Qty flow row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _QtyBox(
                            label: 'Before',
                            value: t.qtyBefore,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 8),
                          _QtyBox(
                            label: 'Change',
                            value: t.delta,
                            color: deltaColor,
                            highlighted: true,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 8),
                          _QtyBox(
                            label: 'After',
                            value: t.qtyAfter,
                            color: AppColors.secondaryLight,
                            highlighted: true,
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
      },
    );
  }
}

class _QtyBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlighted;

  const _QtyBox({
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: highlighted ? color.withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
