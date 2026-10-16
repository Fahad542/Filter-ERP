import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop owner/widgets/owner_styled_dropdown.dart';
import 'super_admin_inventory_view_model.dart';

class SuperAdminInventoryView extends StatelessWidget {
  const SuperAdminInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SuperAdminInventoryContent();
  }
}

class _SuperAdminInventoryContent extends StatefulWidget {
  const _SuperAdminInventoryContent();

  @override
  State<_SuperAdminInventoryContent> createState() => _SuperAdminInventoryContentState();
}

class _SuperAdminInventoryContentState extends State<_SuperAdminInventoryContent> {
  late SuperAdminInventoryViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminInventoryViewModel();
    _vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<SuperAdminInventoryViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddProductDialog(context),
              backgroundColor: AppColors.primaryLight,
              elevation: 4,
              icon: const Icon(Icons.add_box_rounded, color: AppColors.secondaryLight, size: 24),
              label: const Text('Add Product', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
            ),
            body: vm.isLoading && vm.filteredProducts.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabs(context, vm),
                        const SizedBox(height: 16),
                        _buildFilters(context, vm, isDesktop),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildInventoryTable(context, vm),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTabs(BuildContext context, SuperAdminInventoryViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabItem('All', vm),
          _buildTabItem('Oils & Fluids', vm),
          _buildTabItem('Filters', vm),
          _buildTabItem('Brakes', vm),
          _buildTabItem('Ignition', vm),
          _buildTabItem('Accessories', vm),
          _buildTabItem('Electrical', vm),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, SuperAdminInventoryViewModel vm) {
    final isSelected = vm.categoryFilter.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            vm.setCategoryFilter(label);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.grey.shade200),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryLight.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
            ),
            child: Text(
              label == 'All' ? 'All Categories' : label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, SuperAdminInventoryViewModel vm, bool isDesktop) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: vm.setSearchQuery,
              style: const TextStyle(fontSize: 14, color: AppColors.secondaryLight),
              decoration: const InputDecoration(
                hintText: 'Search by product name or SKU...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(BuildContext context, SuperAdminInventoryViewModel vm) {
    return ListView.separated(
      key: ValueKey('${vm.categoryFilter}_${vm.searchQuery}'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: vm.filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = vm.filteredProducts[index];
        final stock = product.openingQty;
        final minStock = 10; // Hardcoded fallback for now, assuming API doesn't provide minStock
        final isLowStock = stock <= minStock;
                
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.red.withOpacity(0.08) : AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded, 
                      color: isLowStock ? Colors.red : AppColors.primaryLight, 
                      size: 28
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight)),
                            const Spacer(),
                            _buildInventoryAction(Icons.edit_rounded, () => _showAddProductDialog(context)),
                            const SizedBox(width: 8),
                            _buildInventoryAction(Icons.delete_rounded, () => vm.deleteProduct(product.id)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(product.id, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CATEGORY & STOCK', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStockStatus(stock, minStock),
                          const SizedBox(width: 8),
                          Text(product.categoryName ?? 'Uncategorized', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondaryLight)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('UNIT PRICE', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('SAR ${product.salePrice}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.secondaryLight)),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STOCK LEVEL', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$stock', style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isLowStock ? Colors.red : AppColors.secondaryLight,
                          )),
                          const SizedBox(width: 4),
                          Text('/ $minStock min', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (stock / (minStock * 2)).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLowStock ? Colors.red : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildStockStatus(int stock, int minStock) {
    bool isInStock = stock > minStock;
    String status = isInStock ? 'IN STOCK' : (stock == 0 ? 'OUT OF STOCK' : 'LOW STOCK');
    Color color = isInStock ? const Color(0xFF10B981) : AppColors.secondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddProductSheet(),
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuperAdminInventoryViewModel>();
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxSheetHeight =
        MediaQuery.sizeOf(context).height * 0.92 - viewInsets.bottom;

    return FocusScope(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxSheetHeight,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.secondaryLight)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Enter details for the new product.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 30),

                    _buildTextField('Product Name', Icons.inventory_2_rounded, controller: vm.nameController),
                    _buildTextField('SKU', Icons.qr_code_rounded, controller: vm.skuController),
                    _buildDropdown(
                      'Category',
                      ['Oils & Fluids', 'Filters', 'Brakes', 'Ignition', 'Accessories', 'Electrical'],
                      value: vm.categoryFilter == 'All' ? 'Oils & Fluids' : vm.categoryFilter,
                      onChanged: (val) {
                        if (val != null) vm.setCategoryFilter(val);
                      },
                    ),
                    _buildDropdown(
                      'Unit of Measure',
                      ['Pcs', 'Liter', 'Box', 'Can', 'Kg', 'Set', 'Bottle'],
                      value: vm.unitController.text,
                      onChanged: (val) {
                        if (val != null) vm.unitController.text = val;
                      },
                    ),

                    _buildTextField('Purchase Price', Icons.attach_money_rounded, isNumber: true, controller: vm.purchasePriceController),
                    _buildTextField('Product Selling Price', Icons.sell_rounded, isNumber: true, controller: vm.sellingPriceController),
                    _buildTextField('Min Corporate Price', Icons.attach_money_rounded, isNumber: true, controller: vm.minCorporatePriceController),
                    _buildTextField('Max Corporate Price', Icons.attach_money_rounded, isNumber: true, controller: vm.maxCorporatePriceController),
                    
                    _buildTextField('Opening Qty', Icons.format_list_numbered_rounded, isNumber: true, controller: vm.minStockController),
                    _buildTextField('Critical Stock Point', Icons.warning_amber_rounded, isNumber: true, controller: vm.criticalStockPointController),
                    _buildTextField('KM Type Value (e.g., 5000)', Icons.speed_rounded, isNumber: true, controller: vm.kmTypeValueController),

                    const SizedBox(height: 8),
                    _buildToggleRow('Allow Decimal Qty', vm.allowDecimalQty, (val) => vm.toggleAllowDecimal(val)),
                    _buildToggleRow('Is Active', vm.isActive, (val) => vm.toggleIsActive(val)),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : () => vm.submitProductForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size.fromHeight(56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: vm.isLoading
                    ? const CircularProgressIndicator(color: AppColors.secondaryLight)
                    : const Text(
                        'Save Product',
                        style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool isNumber = false, TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.secondaryLight, size: 20),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, {required String value, required void Function(String?) onChanged}) {
    final selected = items.contains(value) ? value : items.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          OwnerStyledDropdown<String>(
            value: selected,
            hint: label,
            height: 48,
            backgroundColor: Colors.grey.withOpacity(0.05),
            options: items
                .map((item) => OwnerDropdownOption(value: item, label: item))
                .toList(),
            onChanged: onChanged,
            triggerStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.secondaryLight,
        ),
      ],
    );
  }
}
