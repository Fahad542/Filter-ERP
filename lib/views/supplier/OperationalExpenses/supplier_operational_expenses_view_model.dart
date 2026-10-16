import 'package:flutter/material.dart';

class ExpenseItem {
  final String id;
  final String date;
  final String category;
  final String amount;
  final String status;

  ExpenseItem({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.status,
  });
}

class SupplierOperationalExpensesViewModel extends ChangeNotifier {
  List<ExpenseItem> expenses = [];
  List<String> expenseCategories = ['Fuel', 'Packaging', 'Utilities'];
  bool showAddForm = false;
  String? selectedCategory;
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  SupplierOperationalExpensesViewModel() {
    loadExpenses();
    selectedCategory = expenseCategories.first;
  }

  void loadExpenses() {
    expenses = [
      ExpenseItem(
        id: '1',
        date: '12 Feb',
        category: 'Fuel',
        amount: 'SAR 850',
        status: 'Pending',
      ),
      ExpenseItem(
        id: '2',
        date: '11 Feb',
        category: 'Packaging',
        amount: 'SAR 2,300',
        status: 'Approved',
      ),
    ];
    notifyListeners();
  }

  void toggleAddForm() {
    showAddForm = !showAddForm;
    if (!showAddForm) {
      amountController.clear();
      descriptionController.clear();
    }
    notifyListeners();
  }

  void submitExpense() {
    if (selectedCategory == null || amountController.text.trim().isEmpty)
      return;
    expenses.insert(
      0,
      ExpenseItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        date: '${DateTime.now().day} ${_month(DateTime.now().month)}',
        category: selectedCategory!,
        amount: 'SAR ${amountController.text}',
        status: 'Pending',
      ),
    );
    amountController.clear();
    descriptionController.clear();
    showAddForm = false;
    notifyListeners();
  }

  static String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
