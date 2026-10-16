import 'package:flutter/material.dart';

class SupplierAddProductViewModel extends ChangeNotifier {
  final productNameController = TextEditingController();
  final skuController = TextEditingController();
  final conversionFactorController = TextEditingController(text: '20');
  final pricePerWarehouseController = TextEditingController(text: '490');
  final minStockController = TextEditingController(text: '10');
  final criticalStockController = TextEditingController(text: '5');

  List<String> categories = ['Engine Oil', 'Brake Pads', 'Filters'];
  List<String> warehouseUnits = ['Box', 'Carton', 'Piece'];
  List<String> workshopUnits = ['Liter', 'Piece', 'Set'];
  String? selectedCategory;
  String? selectedWarehouseUnit;
  String? selectedWorkshopUnit;
  bool isActive = true;

  double get pricePerWarehouseUnit =>
      double.tryParse(pricePerWarehouseController.text) ?? 0;
  double get conversionFactor =>
      double.tryParse(conversionFactorController.text) ?? 1;
  String get pricePerWorkshopUnitFormatted {
    if (conversionFactor <= 0) return '—';
    final p = pricePerWarehouseUnit / conversionFactor;
    return p.toStringAsFixed(2);
  }

  SupplierAddProductViewModel() {
    selectedCategory = categories.first;
    selectedWarehouseUnit = warehouseUnits.first;
    selectedWorkshopUnit = workshopUnits.first;
    pricePerWarehouseController.addListener(notifyListeners);
    conversionFactorController.addListener(notifyListeners);
  }

  @override
  void dispose() {
    productNameController.dispose();
    skuController.dispose();
    conversionFactorController.dispose();
    pricePerWarehouseController.dispose();
    minStockController.dispose();
    criticalStockController.dispose();
    super.dispose();
  }

  bool validate() {
    return productNameController.text.trim().isNotEmpty;
  }

  void save() {
    if (!validate()) return;
    // Stub: would call API
    notifyListeners();
  }
}
