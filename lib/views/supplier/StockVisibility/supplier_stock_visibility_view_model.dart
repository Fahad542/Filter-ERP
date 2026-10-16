import 'package:flutter/material.dart';

class StockVisibilityRow {
  final String id;
  final String branch;
  final String product;
  final String currentStock;
  final String reorderLevel;
  final String criticalLevel;
  final String lastUpdated;
  final bool isCritical;

  StockVisibilityRow({
    required this.id,
    required this.branch,
    required this.product,
    required this.currentStock,
    required this.reorderLevel,
    required this.criticalLevel,
    required this.lastUpdated,
    this.isCritical = false,
  });
}

class CriticalAlert {
  final String branch;
  final String product;
  final String current;
  final String critical;
  final String message;

  CriticalAlert({
    required this.branch,
    required this.product,
    required this.current,
    required this.critical,
    required this.message,
  });
}

class SupplierStockVisibilityViewModel extends ChangeNotifier {
  List<String> branches = ['Location', 'Riyadh Main', 'Jeddah'];
  List<String> products = ['Date', '5W-30 Engine Oil', 'Brake Pads'];
  String selectedBranch = 'Location';
  String selectedProduct = 'Date';
  bool criticalStockOnly = false;

  List<StockVisibilityRow> _allRows = [];
  List<StockVisibilityRow> get stockRows {
    var list = _allRows;
    if (criticalStockOnly) list = list.where((r) => r.isCritical).toList();
    if (selectedBranch != 'Location')
      list = list.where((r) => r.branch == selectedBranch).toList();
    if (selectedProduct != 'Date')
      list = list.where((r) => r.product == selectedProduct).toList();
    return list;
  }

  List<CriticalAlert> get criticalAlerts => _allRows
      .where((r) => r.isCritical)
      .map(
        (r) => CriticalAlert(
          branch: r.branch,
          product: r.product,
          current: r.currentStock,
          critical: r.criticalLevel,
          message:
              '${r.branch} - ${r.product} below critical level (${r.currentStock} < ${r.criticalLevel})',
        ),
      )
      .toList();

  SupplierStockVisibilityViewModel() {
    loadStock();
  }

  void loadStock() {
    _allRows = [
      StockVisibilityRow(
        id: '1',
        branch: 'Riyadh Main',
        product: '5W-30 Engine Oil',
        currentStock: '28 L',
        reorderLevel: '50 L',
        criticalLevel: '30 L',
        lastUpdated: '2 hrs ago',
        isCritical: true,
      ),
      StockVisibilityRow(
        id: '2',
        branch: 'Jeddah',
        product: 'Brake Pads',
        currentStock: '12 pcs',
        reorderLevel: '40 pcs',
        criticalLevel: '15 pcs',
        lastUpdated: '1 day ago',
        isCritical: false,
      ),
    ];
    notifyListeners();
  }

  void setBranch(String? v) {
    if (v != null) {
      selectedBranch = v;
      notifyListeners();
    }
  }

  void setProduct(String? v) {
    if (v != null) {
      selectedProduct = v;
      notifyListeners();
    }
  }

  void setCriticalOnly(bool v) {
    criticalStockOnly = v;
    notifyListeners();
  }
}
