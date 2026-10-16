import 'package:flutter/material.dart';
import '../../../models/pos_product_model.dart';
import '../../../services/locker_translation_mixin.dart';

class ProductGridViewModel extends ChangeNotifier with TranslatableMixin {
  static const String allFilter = 'All';
  static const int productPageSize = 12;

  String _selectedDepartment = allFilter;
  String _selectedCategory = allFilter;
  String _selectedSubCategory = allFilter;
  String _searchQuery = '';
  int _visibleProductLimit = productPageSize;
  final TextEditingController searchController = TextEditingController();

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  String get selectedDepartment => _selectedDepartment;
  String get selectedCategory => _selectedCategory;
  String get selectedSubCategory => _selectedSubCategory;
  String get searchQuery => _searchQuery;
  int get visibleProductLimit => _visibleProductLimit;

  void resetVisibleProducts({bool notify = true}) {
    _visibleProductLimit = productPageSize;
    if (notify) notifyListeners();
  }

  void loadMoreProducts() {
    _visibleProductLimit += productPageSize;
    notifyListeners();
  }

  void setDepartment(String department) {
    _selectedDepartment = department;
    _selectedCategory = allFilter;
    _selectedSubCategory = allFilter;
    resetVisibleProducts(notify: false);
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _selectedSubCategory = allFilter; // Reset subcategory when category changes
    resetVisibleProducts(notify: false);
    notifyListeners();
  }

  void setSubCategory(String subCategory) {
    _selectedSubCategory = subCategory;
    resetVisibleProducts(notify: false);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // So search runs across every category inside the current department, not only
    // the selected chip (e.g. "Other Oils" vs "Benzol Oil").
    if (query.trim().isNotEmpty) {
      _selectedCategory = allFilter;
    }
    resetVisibleProducts(notify: false);
    notifyListeners();
  }

  void clearSearch({bool notify = true}) {
    searchController.clear();
    _searchQuery = '';
    resetVisibleProducts(notify: false);
    if (notify) notifyListeners();
  }

  List<PosProduct> getFilteredProducts(List<PosProduct> allProducts) {
    return allProducts.where((p) {
      final matchesCategory = _selectedCategory == allFilter || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> getUniqueCategories(List<PosProduct> allProducts) {
    final cats = allProducts.map((p) => p.category).toSet().toList();
    cats.sort();
    return [allFilter, ...cats];
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    searchController.dispose();
    super.dispose();
  }
}
