import 'package:flutter/material.dart';

class SupplierReportsAnalyticsViewModel extends ChangeNotifier {
  int totalOrdersReceived = 156;
  String totalRevenue = 'SAR 289,400';
  String totalPaymentsReceived = 'SAR 245,600';
  String totalPayables = 'SAR 87,450';
  String avgDeliveryAccuracy = '97.8%';

  List<String> reportCategories = [
    'Sales by Workshop / Branch',
    'Product-wise Sales & Margins',
    'Delivery Performance',
    'Invoice vs Payment Aging',
    'Workshop Stock Visibility',
    'Critical Stock Alerts',
    'My Purchases & Payables',
    'Operational Expenses',
    'Workshop Statement Summary (Internal only)',
  ];

  void loadSummary() {
    notifyListeners();
  }
}
