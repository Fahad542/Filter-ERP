import 'package:flutter/material.dart';

class SupplierAddExpenseCategoryViewModel extends ChangeNotifier {
  final categoryNameController = TextEditingController();
  final descriptionController = TextEditingController();
  List<String> ledgerAccounts = [
    'Expense Account',
    'Office Supplies',
    'Travel',
  ];
  String? selectedAccountId;
  bool isActive = true;

  SupplierAddExpenseCategoryViewModel() {
    selectedAccountId = ledgerAccounts.first;
  }

  bool validate() => categoryNameController.text.trim().isNotEmpty;

  void saveCategory() {
    if (!validate()) return;
    notifyListeners();
  }

  @override
  void dispose() {
    categoryNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
