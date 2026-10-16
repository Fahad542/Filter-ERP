import 'package:flutter/material.dart';

class PurchaseOrderItem {
  final String id;
  final String poNumber;
  final String branch;
  final String date;
  final String itemsSummary;
  final String total;
  final String status;

  PurchaseOrderItem({
    required this.id,
    required this.poNumber,
    required this.branch,
    required this.date,
    required this.itemsSummary,
    required this.total,
    required this.status,
  });
}

class SupplierPurchaseOrdersViewModel extends ChangeNotifier {
  List<String> statusTabs = [
    'All',
    'Pending',
    'Accepted',
    'Processing',
    'Ready to Deliver',
    'On the Way',
    'Delivered',
  ];
  int selectedStatusTabIndex = 0;
  List<PurchaseOrderItem> orders = [];
  String selectedBranch = 'All';
  String selectedStatus = 'All';
  String selectedProduct = 'All';

  int get pendingCount => orders.where((o) => o.status == 'Pending').length;
  int get acceptedCount => orders.where((o) => o.status == 'Accepted').length;
  int get processingCount =>
      orders.where((o) => o.status == 'Processing').length;
  int get readyToDeliverCount =>
      orders.where((o) => o.status == 'Ready to Deliver').length;
  int get onTheWayCount => orders.where((o) => o.status == 'On the Way').length;
  int get deliveredCount => orders.where((o) => o.status == 'Delivered').length;

  SupplierPurchaseOrdersViewModel() {
    loadOrders();
  }

  void loadOrders() {
    orders = [
      PurchaseOrderItem(
        id: '1',
        poNumber: 'PO-9876',
        branch: 'Riyadh Main',
        date: '12 Feb',
        itemsSummary: '5W-30 Oil x50',
        total: 'SAR 1,600',
        status: 'Pending',
      ),
      PurchaseOrderItem(
        id: '2',
        poNumber: 'PO-9875',
        branch: 'Jeddah',
        date: '11 Feb',
        itemsSummary: 'Brake Pads x20',
        total: 'SAR 4,200',
        status: 'Accepted',
      ),
    ];
    notifyListeners();
  }

  List<PurchaseOrderItem> get filteredOrders {
    var list = orders;
    final tab = statusTabs[selectedStatusTabIndex];
    if (tab != 'All') list = list.where((o) => o.status == tab).toList();
    return list;
  }

  void setStatusTab(int index) {
    selectedStatusTabIndex = index;
    notifyListeners();
  }

  void accept(String poId) {
    final i = orders.indexWhere((o) => o.id == poId);
    if (i >= 0 && orders[i].status == 'Pending') {
      final o = orders[i];
      orders[i] = PurchaseOrderItem(
        id: o.id,
        poNumber: o.poNumber,
        branch: o.branch,
        date: o.date,
        itemsSummary: o.itemsSummary,
        total: o.total,
        status: 'Accepted',
      );
      notifyListeners();
    }
  }

  void reject(String poId) {
    orders.removeWhere((o) => o.id == poId);
    notifyListeners();
  }

  void process(String poId) {
    final i = orders.indexWhere((o) => o.id == poId);
    if (i >= 0 && orders[i].status == 'Accepted') {
      final o = orders[i];
      orders[i] = PurchaseOrderItem(
        id: o.id,
        poNumber: o.poNumber,
        branch: o.branch,
        date: o.date,
        itemsSummary: o.itemsSummary,
        total: o.total,
        status: 'Processing',
      );
      notifyListeners();
    }
  }
}
