import 'package:flutter/material.dart';

class BalanceRow {
  final String product;
  final String critical;
  final String status;
  final String primaryUnit;
  final String currentBalance;
  final String lastMovement;
  final String reorder;

  BalanceRow({
    required this.product,
    required this.critical,
    required this.status,
    required this.primaryUnit,
    required this.currentBalance,
    required this.lastMovement,
    required this.reorder,
  });
}

class SupplierInventoryBalancesViewModel extends ChangeNotifier {
  List<String> products = ['All', '5W-30 Oil', 'Brake Pads'];
  List<String> locations = ['All', 'Warehouse', 'Workshop'];
  String selectedProduct = 'All';
  String selectedLocation = 'All';
  bool lowCriticalOnly = false;
  String searchQuery = '';
  List<BalanceRow> balanceRows = [];
  String totalWarehouseValue = 'SAR 1,150,000';
  String totalWorkshopValue = 'SAR 320,000';

  SupplierInventoryBalancesViewModel() {
    loadBalances();
  }

  void loadBalances() {
    balanceRows = [
      BalanceRow(
        product: '5W-30 Oil',
        critical: '300 L',
        status: 'Normal',
        primaryUnit: 'Liter',
        currentBalance: '1,245 L',
        lastMovement: '+200 L',
        reorder: '500 L',
      ),
      BalanceRow(
        product: 'Brake Pads',
        critical: '400',
        status: 'Low',
        primaryUnit: 'Piece',
        currentBalance: '1,820 pcs',
        lastMovement: '-40 pcs',
        reorder: '1,000',
      ),
    ];
    notifyListeners();
  }

  List<BalanceRow> get filteredRows {
    var list = balanceRows;
    if (lowCriticalOnly)
      list = list
          .where((r) => r.status == 'Low' || r.status == 'Critical')
          .toList();
    if (selectedProduct != 'All')
      list = list.where((r) => r.product == selectedProduct).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((r) => r.product.toLowerCase().contains(q)).toList();
    }
    return list;
  }
}
