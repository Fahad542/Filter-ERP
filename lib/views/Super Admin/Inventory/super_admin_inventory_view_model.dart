import 'package:flutter/material.dart';
import '../../../data/repositories/super_admin_repository.dart';
import '../../../services/session_service.dart';
import '../../../models/super_admin_products_api_model.dart';

class SuperAdminInventoryViewModel extends ChangeNotifier {
  final SuperAdminRepository _repository = SuperAdminRepository();
  final SessionService _sessionService = SessionService();

  bool isLoading = false;
  String searchQuery = '';
  String categoryFilter = 'All';

  // Form Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController minCorporatePriceController = TextEditingController();
  final TextEditingController maxCorporatePriceController = TextEditingController();
  final TextEditingController criticalStockPointController = TextEditingController();
  final TextEditingController kmTypeValueController = TextEditingController();
  
  bool allowDecimalQty = false;
  bool isActive = true;

  void clearForm() {
    nameController.clear();
    skuController.clear();
    priceController.clear();
    minStockController.clear();
    unitController.text = 'Pcs';
    purchasePriceController.clear();
    sellingPriceController.clear();
    minCorporatePriceController.clear();
    maxCorporatePriceController.clear();
    criticalStockPointController.clear();
    kmTypeValueController.clear();
    allowDecimalQty = false;
    isActive = true;
    notifyListeners();
  }

  void toggleAllowDecimal(bool value) {
    allowDecimalQty = value;
    notifyListeners();
  }

  void toggleIsActive(bool value) {
    isActive = value;
    notifyListeners();
  }

  Future<void> submitProductForm(BuildContext context) async {
    // Currently just a mockup action
    Navigator.pop(context);
    clearForm();
  }

  List<SuperAdminProduct> _allProducts = [];

  List<SuperAdminProduct> get filteredProducts {
    return _allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            product.id.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = categoryFilter == 'All' || 
                              product.categoryName?.toLowerCase() == categoryFilter.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    
    try {
      final token = await _sessionService.getToken(role: 'super_admin');
      if (token != null) {
        final response = await _repository.getProducts(token);
        if (response.success) {
          _allProducts = response.products;
        }
      }
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    categoryFilter = category;
    notifyListeners();
  }

  void deleteProduct(String id) {
    _allProducts.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
