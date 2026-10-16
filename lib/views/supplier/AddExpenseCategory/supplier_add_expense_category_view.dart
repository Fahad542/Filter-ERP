import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/widgets.dart';
import 'supplier_add_expense_category_view_model.dart';

class SupplierAddExpenseCategoryView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierAddExpenseCategoryView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChangeNotifierProvider(
      create: (_) => SupplierAddExpenseCategoryViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PosScreenAppBar(
            title: 'Add Expense Category',
            onBack:
                onBack ??
                () => Navigator.popUntil(
                  context,
                  ModalRoute.withName('/supplier'),
                ),
          ),
          body: Consumer<SupplierAddExpenseCategoryViewModel>(
            builder: (context, vm, _) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'Category Name *',
                      controller: vm.categoryNameController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      showBorder: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Description',
                      controller: vm.descriptionController,
                      showBorder: false,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: vm.selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Default Account (Ledger)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      items: vm.ledgerAccounts
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) {
                        vm.selectedAccountId = v;
                        vm.notifyListeners();
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: vm.isActive,
                          onChanged: (_) {
                            vm.isActive = true;
                            vm.notifyListeners();
                          },
                          activeColor: AppColors.primaryLight,
                        ),
                        const Text('Active'),
                        const SizedBox(width: 24),
                        Radio<bool>(
                          value: false,
                          groupValue: vm.isActive,
                          onChanged: (_) {
                            vm.isActive = false;
                            vm.notifyListeners();
                          },
                          activeColor: AppColors.primaryLight,
                        ),
                        const Text('Inactive'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: CustomButton(
                              text: 'Save',
                              onPressed: () {
                                if (vm.validate()) {
                                  vm.saveCategory();
                                  if (onBack != null) {
                                    onBack!();
                                  } else {
                                    Navigator.maybePop(context);
                                  }
                                }
                              },
                              backgroundColor: AppColors.primaryLight,
                              textColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed:
                                  onBack ?? () => Navigator.maybePop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 0.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                      ],
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
}
