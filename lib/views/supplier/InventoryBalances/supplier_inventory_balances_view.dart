import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../InventoryTransactionLog/supplier_inventory_transaction_log_view.dart';
import '../supplier_shell_controller.dart';
import 'supplier_inventory_balances_view_model.dart';

class SupplierInventoryBalancesView extends StatefulWidget {
  final VoidCallback? onBack;

  const SupplierInventoryBalancesView({super.key, this.onBack});

  @override
  State<SupplierInventoryBalancesView> createState() =>
      _SupplierInventoryBalancesViewState();
}

class _SupplierInventoryBalancesViewState
    extends State<SupplierInventoryBalancesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;
    final isLargeScreen = isDesktop || isTablet;

    return ChangeNotifierProvider(
      create: (_) => SupplierInventoryBalancesViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isLargeScreen ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: isDesktop
              ? null
              : PosScreenAppBar(
                  title: 'Inventory Stock Balances',
                  onBack:
                      widget.onBack ??
                      () => Navigator.popUntil(
                        context,
                        ModalRoute.withName('/supplier'),
                      ),
                  showBackButton: false,
                  showGlobalLeft: true,
                ),
          body: Consumer<SupplierInventoryBalancesViewModel>(
            builder: (context, vm, _) {
              final rows = vm.filteredRows;
              return Column(
                children: [
                  Expanded(
                    child: SafeArea(
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
                                        widget.onBack ??
                                        () => Navigator.popUntil(
                                          context,
                                          ModalRoute.withName('/supplier'),
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Inventory Stock Balances',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.secondaryLight,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            // KPI Cards at Top
                            _buildKPICards(context, vm, isDesktop),
                            const SizedBox(height: 24),
                            // Desktop controls layout
                            if (isDesktop)
                              Row(
                                children: [
                                  Expanded(flex: 2, child: _buildSearchBar(vm)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDropdown(vm, isProduct: true),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDropdown(vm, isProduct: false),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildLowCriticalToggle(vm),
                                ],
                              )
                            else ...[
                              _buildSearchBar(vm),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(vm, isProduct: true),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdown(vm, isProduct: false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLowCriticalToggle(vm),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              '${rows.length} item${rows.length == 1 ? '' : 's'} found',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (rows.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 60,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 64,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No products found',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (isDesktop)
                              _buildDesktopDataTable(rows)
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: rows.length,
                                itemBuilder: (context, i) =>
                                    _InventoryCard(row: rows[i]),
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(SupplierInventoryBalancesViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          vm.searchQuery = v;
          vm.notifyListeners();
        },
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryLight,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    vm.searchQuery = '';
                    vm.notifyListeners();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    SupplierInventoryBalancesViewModel vm, {
    required bool isProduct,
  }) {
    return _ModernDropdown(
      value: isProduct ? vm.selectedProduct : vm.selectedLocation,
      items: isProduct ? vm.products : vm.locations,
      label: isProduct ? 'Product' : 'Location',
      onChanged: (v) {
        if (isProduct) {
          vm.selectedProduct = v ?? 'All';
        } else {
          vm.selectedLocation = v ?? 'All';
        }
        vm.notifyListeners();
      },
    );
  }

  Widget _buildLowCriticalToggle(SupplierInventoryBalancesViewModel vm) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          vm.lowCriticalOnly = !vm.lowCriticalOnly;
          vm.notifyListeners();
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: vm.lowCriticalOnly ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: vm.lowCriticalOnly
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: vm.lowCriticalOnly
                ? [
                    BoxShadow(
                      color: Colors.orange.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: vm.lowCriticalOnly
                    ? Colors.orange.shade800
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                'Low / Critical Only',
                style: TextStyle(
                  color: vm.lowCriticalOnly
                      ? Colors.orange.shade900
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopDataTable(List<BalanceRow> rows) {
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
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FD)),
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
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Balance')),
              DataColumn(label: Text('Last Movement')),
              DataColumn(label: Text('Reorder At')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: rows.map((r) {
              final statusColor = r.status == 'Critical'
                  ? Colors.red.shade700
                  : AppColors.primaryLight;
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: Colors.grey.shade400,
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
                    Text(
                      r.currentBalance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.lastMovement,
                      style: TextStyle(
                        color: r.lastMovement.startsWith('-')
                            ? AppColors.secondaryLight
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.reorder,
                      style: TextStyle(color: Colors.grey.shade600),
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
                        r.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                      onPressed: () {
                        // Desktop edit logic follows the form style
                      },
                      tooltip: 'Edit Quantity',
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

  Widget _buildKPICards(
    BuildContext context,
    SupplierInventoryBalancesViewModel vm,
    bool isDesktop,
  ) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _buildKPICard(
              'Warehouse Value',
              vm.totalWarehouseValue,
              Icons.warehouse_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildKPICard(
              'Workshop Value',
              vm.totalWorkshopValue,
              Icons.build_circle_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildTransactionLogCard(context)),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Warehouse',
                  vm.totalWarehouseValue,
                  Icons.warehouse_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Workshop',
                  vm.totalWorkshopValue,
                  Icons.build_circle_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildTransactionLogCard(context),
          ),
        ],
      );
    }
  }

  Widget _buildKPICard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionLogCard(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          final ctrl = context.read<SupplierShellController>();
          ctrl.navigateTo(
            SupplierInventoryTransactionLogView(onBack: ctrl.pop),
            sourceTab: ctrl.effectiveTabIndex,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction Log',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'See all history',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;

  const _ModernDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        icon: const Icon(
          Icons.expand_more_rounded,
          color: AppColors.secondaryLight,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryLight,
          fontSize: 14,
        ),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _InventoryCard extends StatefulWidget {
  final BalanceRow row;

  const _InventoryCard({required this.row});

  @override
  State<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<_InventoryCard> {
  Color get _statusColor {
    switch (widget.row.status) {
      case 'Critical':
        return Colors.red.shade600;
      default:
        return AppColors.primaryLight;
    }
  }

  void _showEditModal() {
    final qtyController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            28,
            28,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust Balance',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          widget.row.product,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: 'New Quantity',
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.primaryLight,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryLight,
                ),
                decoration: InputDecoration(
                  labelText: 'Description / Note',
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 44),
                    child: Icon(
                      Icons.notes_rounded,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondaryLight,
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final qty = qtyController.text.trim().isEmpty
                            ? widget.row.currentBalance
                            : qtyController.text.trim();
                        Navigator.pop(ctx);
                        _showSubmittedDialog(qty);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.secondaryLight.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Save Form',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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

  void _showSubmittedDialog(String qty) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Request Submitted',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your adjustment is pending approval',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Product preview card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
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
                        Icons.inventory_2_rounded,
                        color: AppColors.secondaryLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.row.product,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested Balance:',
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        qty,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Approval Flow',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _ApprovalStep(
                label: 'Submitted by Warehouse',
                sub: 'Just Now',
                isDone: true,
              ),
              const SizedBox(height: 16),
              const _ApprovalStep(
                label: 'Admin / Super Admin',
                sub: 'Pending approval',
                isDone: false,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.secondaryLight.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Got it, thanks',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    Icons.inventory_2_rounded,
                    color: AppColors.secondaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.row.product,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.row.status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _showEditModal,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: _DetailCell(
                    label: 'Current Balance',
                    value: widget.row.currentBalance,
                    valueColor: AppColors.secondaryLight,
                    isMain: true,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _DetailCell(
                    label: 'Last Flow',
                    value: widget.row.lastMovement,
                    valueColor: widget.row.lastMovement.startsWith('-')
                        ? AppColors.secondaryLight
                        : Colors.green.shade700,
                    isMain: false,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _DetailCell(
                    label: 'Reorder At',
                    value: widget.row.reorder,
                    valueColor: Colors.grey.shade700,
                    isMain: false,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _DetailCell(
                    label: 'Critical Info',
                    value: widget.row.critical,
                    valueColor: AppColors.primaryLight,
                    isMain: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMain;

  const _DetailCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w900,
            fontSize: isMain ? 22 : 16,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ApprovalStep extends StatelessWidget {
  final String label;
  final String sub;
  final bool isDone;

  const _ApprovalStep({
    required this.label,
    required this.sub,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.primaryLight.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppColors.primaryLight.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primaryLight : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.primaryLight : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              isDone ? Icons.check_rounded : Icons.pending_actions_rounded,
              size: 20,
              color: isDone ? AppColors.secondaryLight : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDone ? AppColors.primaryLight : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              isDone ? 'Done' : 'Pending',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDone ? AppColors.secondaryLight : Colors.grey.shade600,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
