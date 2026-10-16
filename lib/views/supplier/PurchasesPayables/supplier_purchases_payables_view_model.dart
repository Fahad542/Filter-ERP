import 'package:flutter/material.dart';

class PurchaseItem {
  final String date;
  final String supplier;
  final String amount;
  final String status;
  PurchaseItem({
    required this.date,
    required this.supplier,
    required this.amount,
    required this.status,
  });
}

class LiabilityItem {
  final String id;
  final String supplier;
  final String invoice;
  final String dueDate;
  final String amount;
  final String status;
  LiabilityItem({
    required this.id,
    required this.supplier,
    required this.invoice,
    required this.dueDate,
    required this.amount,
    required this.status,
  });
}

class SupplierPurchasesPayablesViewModel extends ChangeNotifier {
  int selectedTabIndex = 0;
  List<PurchaseItem> purchases = [];
  List<LiabilityItem> liabilities = [];
  String totalLiabilities = 'SAR 87,450';
  String overdueAmount = 'SAR 23,100';
  double totalLiabilitiesValue = 87450;
  double overdueValue = 23100;

  SupplierPurchasesPayablesViewModel() {
    loadPurchases();
    loadLiabilities();
  }

  void loadPurchases() {
    purchases = [
      PurchaseItem(
        date: '10 Feb',
        supplier: 'Main Oil Co.',
        amount: 'SAR 45,000',
        status: 'Received',
      ),
    ];
    notifyListeners();
  }

  void loadLiabilities() {
    liabilities = [
      LiabilityItem(
        id: '1',
        supplier: 'Main Oil Co.',
        invoice: 'INV-P-123',
        dueDate: '20 Feb',
        amount: 'SAR 45,000',
        status: 'Pending',
      ),
      LiabilityItem(
        id: '2',
        supplier: 'Filter Co.',
        invoice: 'INV-P-124',
        dueDate: '15 Feb',
        amount: 'SAR 12,300',
        status: 'Overdue',
      ),
    ];
    notifyListeners();
  }

  void setTab(int index) {
    selectedTabIndex = index;
    notifyListeners();
  }
}
