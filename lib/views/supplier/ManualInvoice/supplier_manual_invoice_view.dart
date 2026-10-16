import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/widgets.dart';
import 'supplier_manual_invoice_view_model.dart';

class SupplierManualInvoiceView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierManualInvoiceView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChangeNotifierProvider(
      create: (_) => SupplierManualInvoiceViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PosScreenAppBar(
            title: 'Submit Invoice',
            showHamburger: true,
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
            showBackButton: false,
          ),
          body: Consumer<SupplierManualInvoiceViewModel>(
            builder: (context, vm, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Workshop / Branch:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: vm.selectedWorkshopId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: vm.workshops
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              vm.selectedWorkshopId = v;
                              vm.notifyListeners();
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Add Items',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Product',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Product List',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLineItemsTable(context, vm, isTablet),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Notes / Reference',
                            controller: vm.notesController,
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: 'Submit Invoice for Workshop Approval',
                                backgroundColor: AppColors.primaryLight,
                                textColor: Colors.black,
                                onPressed: () {
                                  if (vm.selectedWorkshopId != null &&
                                      vm.lineItems.isNotEmpty) {
                                    vm.submitInvoice();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invoice submitted'),
                                      ),
                                    );
                                    Navigator.maybePop(context);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subtotal: SAR ${vm.subtotal.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'VAT 15%: SAR ${vm.vatAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grand Total: SAR ${vm.grandTotal.toStringAsFixed(2)}',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

  Widget _buildLineItemsTable(
    BuildContext context,
    SupplierManualInvoiceViewModel vm,
    bool isTablet,
  ) {
    if (vm.lineItems.isEmpty) return const SizedBox.shrink();
    if (isTablet) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Last Purchase')),
            DataColumn(label: Text('Sales Price')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Profit %')),
            DataColumn(label: Text('Line Total')),
            DataColumn(label: Text('')),
          ],
          rows: vm.lineItems.asMap().entries.map((e) {
            final i = e.value;
            return DataRow(
              cells: [
                DataCell(Text(i.product)),
                DataCell(Text('SAR ${i.lastPurchase.toStringAsFixed(2)}')),
                DataCell(Text('SAR ${i.salesPrice.toStringAsFixed(2)}')),
                DataCell(Text('${i.qty}')),
                DataCell(Text('${i.profitPercent.toStringAsFixed(1)}%')),
                DataCell(Text('SAR ${i.lineTotal.toStringAsFixed(2)}')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => vm.removeLine(e.key),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.lineItems.length,
      itemBuilder: (context, i) {
        final item = vm.lineItems[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SAR ${item.salesPrice} x ${item.qty} = SAR ${item.lineTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black54),
                  onPressed: () => vm.removeLine(i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
