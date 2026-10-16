import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import 'supplier_stock_visibility_view_model.dart';

class SupplierStockVisibilityView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierStockVisibilityView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final isLargeScreen = isDesktop || isTablet;

    return ChangeNotifierProvider(
      create: (_) => SupplierStockVisibilityViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isLargeScreen ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: isDesktop
              ? null
              : PosScreenAppBar(
                  title: 'Stock Visibility',
                  showHamburger: true,
                  onMenuPressed: () => Scaffold.of(context).openDrawer(),
                  showBackButton: false,
                ),
          body: Consumer<SupplierStockVisibilityViewModel>(
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
                            InkWell(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondaryLight
                                          .withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Stock Visibility',
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

                      // Critical Alerts Header Section
                      if (vm.criticalAlerts.isNotEmpty) ...[
                        _CriticalAlertsSection(vm: vm),
                        const SizedBox(height: 32),
                      ],

                      // ── Filter Card ──────────────────────────────────────
                      _FilterCard(vm: vm),
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
                              Icons.inventory_2_rounded,
                              color: AppColors.secondaryLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Physical vs System Stock',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Stock List ───────────────────────────────────────
                      _StockList(vm: vm, isLargeScreen: isLargeScreen),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Card
// ─────────────────────────────────────────────────────────────────────────────
class _FilterCard extends StatelessWidget {
  final SupplierStockVisibilityViewModel vm;
  const _FilterCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Filter Inventory',
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: _StyledDropdown(
                  value: vm.selectedBranch,
                  items: vm.branches,
                  hint: 'Location',
                  icon: Icons.location_on_rounded,
                  onChanged: vm.setBranch,
                ),
              ),
              SizedBox(
                width: 200,
                child: _StyledDropdown(
                  value: vm.selectedProduct,
                  items: vm.products,
                  hint: 'Product',
                  icon: Icons.category_rounded,
                  onChanged: vm.setProduct,
                ),
              ),
              GestureDetector(
                onTap: () => vm.setCriticalOnly(!vm.criticalStockOnly),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: vm.criticalStockOnly
                        ? Colors.red.shade50
                        : const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: vm.criticalStockOnly
                          ? Colors.red.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vm.criticalStockOnly
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: vm.criticalStockOnly
                            ? Colors.red.shade600
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Critical Stock Only',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: vm.criticalStockOnly
                              ? Colors.red.shade700
                              : AppColors.secondaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final String hint;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        prefixIcon: Icon(icon, color: AppColors.secondaryLight, size: 20),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.secondaryLight,
      ),
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLight,
        fontSize: 15,
      ),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock List
// ─────────────────────────────────────────────────────────────────────────────
class _StockList extends StatelessWidget {
  final SupplierStockVisibilityViewModel vm;
  final bool isLargeScreen;
  const _StockList({required this.vm, required this.isLargeScreen});

  @override
  Widget build(BuildContext context) {
    final rows = vm.stockRows;

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No products match your filters',
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
              columnSpacing: 32,
              columns: const [
                DataColumn(label: Text('Branch')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Status')),
                DataColumn(
                  label: Text('Physical/System', textAlign: TextAlign.center),
                ),
                DataColumn(label: Text('Critical')),
                DataColumn(label: Text('Reorder')),
                DataColumn(label: Text('Last Updated')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows.map((r) {
                final isCritical = r.isCritical;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        r.branch,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCritical
                                ? Icons.warning_amber_rounded
                                : Icons.inventory_2_rounded,
                            size: 16,
                            color: isCritical
                                ? Colors.red.shade600
                                : AppColors.primaryLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.product,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? Colors.red.shade50
                              : AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCritical ? 'Critical' : 'Normal',
                          style: TextStyle(
                            color: isCritical
                                ? Colors.red.shade700
                                : AppColors.secondaryLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        r.currentStock,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isCritical
                              ? Colors.red.shade700
                              : AppColors.secondaryLight,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        r.criticalLevel,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    DataCell(Text(r.reorderLevel)),
                    DataCell(
                      Text(
                        r.lastUpdated,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        onPressed: () => _showComingSoon(context),
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondaryLight,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${rows.length} item${rows.length == 1 ? '' : 's'} found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...rows.map((r) => _StockCard(row: r)),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Feature coming soon!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Card
// ─────────────────────────────────────────────────────────────────────────────
class _StockCard extends StatelessWidget {
  final StockVisibilityRow row;
  const _StockCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final isCritical = row.isCritical;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isCritical ? Colors.red.shade50 : const Color(0xFFF8F9FD),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                  child: Icon(
                    isCritical
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_2_rounded,
                    color: isCritical
                        ? Colors.red.shade600
                        : AppColors.secondaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.product,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.branch,
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCritical
                        ? Colors.red.shade100
                        : AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    isCritical ? 'Critical' : 'Normal',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCritical
                          ? Colors.red.shade700
                          : AppColors.secondaryLight,
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
              children: [
                Row(
                  children: [
                    _StatCell(
                      label: 'Phy/Sys',
                      value: row.currentStock,
                      valueColor: isCritical
                          ? Colors.red.shade700
                          : AppColors.secondaryLight,
                      isHero: true,
                    ),
                    _divider(),
                    _StatCell(
                      label: 'Critical',
                      value: row.criticalLevel,
                      valueColor: Colors.orange.shade700,
                    ),
                    _divider(),
                    _StatCell(
                      label: 'Reorder',
                      value: row.reorderLevel,
                      valueColor: AppColors.secondaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last updated: ${row.lastUpdated}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _showComingSoon(context),
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.secondaryLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.grey.shade200,
  );

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isHero;

  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: isHero ? 24 : 18,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Critical Alerts Section
// ─────────────────────────────────────────────────────────────────────────────
class _CriticalAlertsSection extends StatelessWidget {
  final SupplierStockVisibilityViewModel vm;
  const _CriticalAlertsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade500.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 24,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Critical Stock Alerts',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vm.criticalAlerts.length} items require attention',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...vm.criticalAlerts.map((a) => _CriticalAlertCard(alert: a)),
        ],
      ),
    );
  }
}

class _CriticalAlertCard extends StatelessWidget {
  final CriticalAlert alert;
  const _CriticalAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 18,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.product,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${alert.branch} • Stock: ${alert.current} (Critical: ${alert.critical})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _showComingSoon(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.secondaryLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Order',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
