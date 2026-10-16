import 'package:flutter/material.dart';

class CriticalStockAlertItem {
  final String id;
  final String message;

  CriticalStockAlertItem({required this.id, required this.message});
}

class SupplierHomeViewModel extends ChangeNotifier {
  String companyName = 'ABC Parts Trading';
  bool showInternalWarehouseBadge = true;

  int newOrdersToday = 12;
  String monthRevenue = 'SAR 124,500';
  String totalInvoiced = 'SAR 89,200';
  String paymentsReceived = 'SAR 67,300';

  String currentPayables = 'SAR 87,450';
  String overdueAmount = 'SAR 23,100';

  /// Critical stock alerts to show on dashboard. When non-empty, the Critical Stock Alerts card is shown.
  List<CriticalStockAlertItem> criticalStockAlerts = [
    CriticalStockAlertItem(
      id: '1',
      message:
          'Main - Car Wash Normal - Small below critical level (0 service < 0 service)',
    ),
  ];
}
