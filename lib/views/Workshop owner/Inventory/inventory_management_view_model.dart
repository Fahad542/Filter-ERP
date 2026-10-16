import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/toast_service.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';
import 'dart:async';

class InventoryManagementViewModel extends ChangeNotifier
    with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  final SettingsViewModel? settingsViewModel;
  

  final TextEditingController nameController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController categoryIdController = TextEditingController();
  final TextEditingController subCategoryIdController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController openingQtyController = TextEditingController();
  final TextEditingController criticalStockPointController = TextEditingController();
  final TextEditingController kmTypeValueController = TextEditingController();
  final TextEditingController minCorporatePriceController = TextEditingController();
  final TextEditingController maxCorporatePriceController = TextEditingController();
  bool allowDecimalQty = true;
  bool isActive = true;
  bool isPriceEditable = false;
  String vatMode = 'inclusive';
  List<OwnerSubCategory> _productCategories = [];
  List<OwnerSubCategory> _serviceCategories = [];
  List<String> _productUnits = [];
  List<String> get productUnits => _productUnits;

  String? _editingProductId;
  String? _editingServiceId;
  String? _editingCategoryId;
  String? _editingSubCategoryId;
  String? _editingCategoryName;
  String? _editingSubCategoryName;
  String? _editingCategoryDepartmentId;

  bool get isEditingProduct => _editingProductId != null;
  bool get isEditingService => _editingServiceId != null;
  bool get isEditingCategory => _editingCategoryId != null;
  bool get isEditingSubCategory => _editingSubCategoryId != null;
  String? get editingCategoryName => _editingCategoryName;
  String? get editingSubCategoryName => _editingSubCategoryName;
  String? get editingCategoryDepartmentId => _editingCategoryDepartmentId;

  // Category controllers
  final TextEditingController categoryNameController = TextEditingController();
  final TextEditingController categoryTypeController = TextEditingController(); // typically 'product' or 'expense'

  bool _isLoading = false;
  bool get isLoading => _isLoading || ownerDataService.isLoadingDepartments;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  bool _isSubCategoriesLoading = false;
  bool get isSubCategoriesLoading => _isSubCategoriesLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Translated overlays keyed by id — raw lists below are never mutated so
  /// create/update/delete API calls keep using English values.
  final Map<String, OwnerProduct> _translatedProductCache = {};
  final Map<String, OwnerProduct> _translatedServiceCache = {};
  final Map<String, OwnerCategory> _translatedCategoryCache = {};
  final Map<String, OwnerSubCategory> _translatedSubCategoryCache = {};

  List<OwnerProduct> _products = [];
  List<OwnerProduct> get products {
    final list = _products.map((p) => _translatedProductCache[p.id] ?? p);
    if (_searchQuery.isEmpty) return list.toList();
    return list.where((p) => 
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (p.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (p.departmentName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  List<OwnerProduct> _services = [];
  List<OwnerProduct> get services {
    final list = _services.map((p) => _translatedServiceCache[p.id] ?? p);
    if (_searchQuery.isEmpty) return list.toList();
    return list.where((p) => 
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (p.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (p.departmentName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  List<OwnerCategory> _categories = [];
  List<OwnerCategory> get categories {
    final list = _categories.map((c) => _translatedCategoryCache[c.id] ?? c);
    if (_searchQuery.isEmpty) return list.toList();
    return list.where((c) => 
      c.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  int _selectedInnerTab = 0;
  int get selectedInnerTab => _selectedInnerTab;

  void setInnerTab(int index) {
    _selectedInnerTab = index;
    fetchProductCategoriesForTab();
    notifyListeners();
  }

  List<OwnerSubCategory> _displayedSubCategories = [];
  List<OwnerSubCategory> get productCategories =>
      _productCategories.map(_overlaySubCategory).toList();
  List<OwnerSubCategory> get serviceCategories =>
      _serviceCategories.map(_overlaySubCategory).toList();
  List<OwnerSubCategory> get displayedSubCategories {
    final list = _displayedSubCategories.map(_overlaySubCategory);
    if (_searchQuery.isEmpty) return list.toList();
    return list.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  OwnerSubCategory _overlaySubCategory(OwnerSubCategory s) =>
      _translatedSubCategoryCache[s.id] ?? s;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Branch> get branches => ownerDataService.branches;

  InventoryManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    this.settingsViewModel,
  }) {
    ownerDataService.addListener(notifyListeners);
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
    Future.microtask(() => _init());
  }

  // ── Locale re-translation ─────────────────────────────────────────────────

  Future<void> retranslate() async {
    await Future.wait([
      _applyProductTranslations(),
      _applyServiceTranslations(),
      _applyCategoryTranslations(),
      _applySubCategoryTranslations(),
    ]);
    notifyListeners();
  }

  Future<void> _applyProductTranslations() async {
    final translated = await Future.wait(_products.map(_translateProduct));
    _translatedProductCache
      ..clear()
      ..addEntries(translated.map((p) => MapEntry(p.id, p)));
  }

  Future<void> _applyServiceTranslations() async {
    final translated = await Future.wait(_services.map(_translateProduct));
    _translatedServiceCache
      ..clear()
      ..addEntries(translated.map((p) => MapEntry(p.id, p)));
  }

  Future<OwnerProduct> _translateProduct(OwnerProduct p) async {
    return p.copyWith(
      translatedName: await t(p.name),
      translatedCategory: p.category != null ? await t(p.category!) : null,
      translatedSubCategoryName: p.subCategoryName != null
          ? await t(p.subCategoryName!)
          : null,
      translatedDepartmentName: p.departmentName != null
          ? await t(p.departmentName!)
          : null,
    );
  }

  Future<void> _applyCategoryTranslations() async {
    final translated = await Future.wait(_categories.map(_translateCategory));
    _translatedCategoryCache
      ..clear()
      ..addEntries(translated.map((c) => MapEntry(c.id, c)));
  }

  Future<OwnerCategory> _translateCategory(OwnerCategory c) async {
    return c.copyWith(translatedName: await t(c.name));
  }

  Future<void> _applySubCategoryTranslations() async {
    final all = <String, OwnerSubCategory>{};
    for (final s in [..._productCategories, ..._serviceCategories]) {
      all[s.id] = s;
    }
    final translated = await Future.wait(all.values.map(_translateSubCategory));
    _translatedSubCategoryCache
      ..clear()
      ..addEntries(translated.map((s) => MapEntry(s.id, s)));
  }

  Future<OwnerSubCategory> _translateSubCategory(OwnerSubCategory s) async {
    return s.copyWith(
      translatedName: await t(s.name),
      translatedDepartmentName:
          s.departmentName != null ? await t(s.departmentName!) : null,
    );
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Initial screen is Products tab; fetch only essentials first for faster first paint.
      await Future.wait([
        fetchProducts(silent: true),
        fetchProductUnits(silent: true),
      ]);

      if (ownerDataService.departments.isEmpty) {
        await ownerDataService.fetchDepartments(silent: true);
      }
      if (ownerDataService.branches.isEmpty) {
        await ownerDataService.fetchBranches(silent: true);
      }

      // Prefetch secondary data in background (do not block UI).
      unawaited(fetchServices(silent: true));
      unawaited(fetchCategories(silent: true));
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onTabChanged(int index) async {
    // 0 = Products, 1 = Services, 2 = Category
    if (index == 1 && _services.isEmpty) {
      await fetchServices();
      return;
    }

    if (index == 2) {
      if (_categories.isEmpty) {
        await fetchCategories();
      }
      await fetchProductCategoriesForTab(silent: false);
    }
  }

  Future<void> fetchCategories({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      final response = await ownerRepository.getCategories(token);
      if (response != null && response['success'] == true && response['categories'] != null) {
        _categories = (response['categories'] as List)
            .map((c) => OwnerCategory.fromJson(c))
            .toList();
        await _applyCategoryTranslations();
        notifyListeners();
      }
    } catch (e) {
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchProductCategoriesForTab({String? typeOverride, bool forceRefresh = false, bool silent = false}) async {
    final typeStr = typeOverride ?? (_selectedInnerTab == 0 ? 'product' : 'service');
    
    // Check cache
    if (!forceRefresh) {
      if (typeStr == 'product' && _productCategories.isNotEmpty) {
        _displayedSubCategories = _productCategories;
        if (!silent) notifyListeners();
        return;
      } else if (typeStr == 'service' && _serviceCategories.isNotEmpty) {
        _displayedSubCategories = _serviceCategories;
        if (!silent) notifyListeners();
        return;
      }
    }

    if (!silent) {
      _isSubCategoriesLoading = true;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      final response = await ownerRepository.getProductsCategories(token, typeStr);
      if (response != null && response['success'] == true && response['categories'] != null) {
        List<OwnerSubCategory> flatSubs = [];
        for (var c in response['categories']) {
          if (c['subCategories'] != null && (c['subCategories'] as List).isNotEmpty) {
            flatSubs.addAll((c['subCategories'] as List)
                .map((s) => OwnerSubCategory.fromJson(s)));
          } else {
            // If no subcategories, use the category itself as a subcategory for display
            flatSubs.add(OwnerSubCategory(
              id: c['id']?.toString() ?? '',
              name: c['name'] ?? '',
              departmentId: c['departmentId']?.toString(),
              departmentName: c['departmentName']?.toString(),
            ));
          }
        }
        _displayedSubCategories = flatSubs;
        if (typeStr == 'product') {
          _productCategories = flatSubs;
        } else {
          _serviceCategories = flatSubs;
        }
        await _applySubCategoryTranslations();
      } else {
        _displayedSubCategories = [];
      }
    } catch (e) {
      _displayedSubCategories = [];
    } finally {
      if (!silent) {
        _isSubCategoriesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchProducts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final token = await sessionService.getToken(role: 'owner');
      final user = await sessionService.getUser(role: 'owner');
      if (token == null) throw Exception('No token found');
      final workshopId = user?.workshopId ?? '3';

      final response = await ownerRepository.getProducts(token, workshopId);
      
      if (response != null && response['success'] == true) {
        List<OwnerProduct> allProducts = [];
        
        if (response['categories'] != null) {
          for (var cat in response['categories']) {
            if (cat['subCategories'] != null) {
              for (var sub in cat['subCategories']) {
                if (sub['products'] != null) {
                  for (var prod in sub['products']) {
                    allProducts.add(OwnerProduct.fromJson(prod));
                  }
                }
              }
            }
            if (cat['productsWithoutSub'] != null || cat['products'] != null) {
              final productList = cat['productsWithoutSub'] ?? cat['products'];
              for (var prod in productList) {
                allProducts.add(OwnerProduct.fromJson(prod));
              }
            }
            if (cat['services'] != null) {
              for (var serv in cat['services']) {
                 final op = OwnerProduct.fromJson(serv);
                 // OwnerProduct doesn't have an explicit isService, but it's used in _services list usually
                 allProducts.add(op);
              }
            }
          }
        }
        
        if (response['uncategorizedProducts'] != null) {
          for (var prod in response['uncategorizedProducts']) {
            allProducts.add(OwnerProduct.fromJson(prod));
          }
        }

        _products = allProducts;
        await _applyProductTranslations();
      }
    } catch (e) {
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchProductUnits({bool silent = false}) async {
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      final response = await ownerRepository.getProductUnits(token);
      if (response != null && response['success'] == true && response['units'] is List) {
        _productUnits = (response['units'] as List)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
    } catch (e) {
    } finally {
      if (_productUnits.isEmpty) {
        _productUnits = ['pcs'];
      }
      if (unitController.text.trim().isEmpty) {
        unitController.text = _productUnits.first;
      }
      if (!silent) {
        notifyListeners();
      }
    }
  }

  Future<void> fetchServices({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final response = await ownerRepository.getWorkshopServices(token);
      
      if (response != null && response['success'] == true && response['services'] != null) {
        _services = (response['services'] as List)
            .map((s) => OwnerProduct.fromJson(s))
            .toList();
        await _applyServiceTranslations();
      }
    } catch (e) {
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void toggleAllowDecimal(bool value) {
    allowDecimalQty = value;
    notifyListeners();
  }

  void toggleIsActive(bool value) {
    isActive = value;
    notifyListeners();
  }

  void clearForm() {
    nameController.clear();
    unitController.text = _productUnits.isNotEmpty ? _productUnits.first : 'pcs';
    categoryIdController.clear();
    subCategoryIdController.clear();
    purchasePriceController.clear();
    salePriceController.clear();
    minCorporatePriceController.clear();
    maxCorporatePriceController.clear();
    openingQtyController.clear();
    criticalStockPointController.clear();
    kmTypeValueController.clear();
    allowDecimalQty = true;
    isActive = true;
    _editingCategoryName = null;
    _editingSubCategoryName = null;
    _editingCategoryDepartmentId = null;
    
    categoryNameController.clear();
    categoryTypeController.text = 'product';
    isPriceEditable = false;
    vatMode = 'inclusive';
  }

  void setEditProduct(OwnerProduct? p) {
    if (p == null) {
      _editingProductId = null;
      clearForm();
    } else {
      _editingProductId = p.id;
      _editingCategoryName = p.category;
      _editingSubCategoryName = p.subCategoryName;
      nameController.text = p.name;
      unitController.text = p.unit ?? 'pcs';
      purchasePriceController.text = p.purchasePrice.toString();
      salePriceController.text = p.salePrice.toString();
      openingQtyController.text = p.stock.toString();
      criticalStockPointController.text = p.criticalStockPoint.toString();
      kmTypeValueController.text = p.kmTypeValue.toString();
      minCorporatePriceController.text = p.minPriceCorporate?.toString() ?? '0.0';
      maxCorporatePriceController.text = p.maxPriceCorporate?.toString() ?? '0.0';
      allowDecimalQty = p.allowDecimalQty;
      isActive = p.isActive;
      isPriceEditable = p.isPriceEditable;
      // Note: category and department will need to be selected in the UI
    }
    fetchProductCategoriesForTab(typeOverride: 'product');
    notifyListeners();
  }

  void setEditService(OwnerProduct? s) {
    if (s == null) {
      _editingServiceId = null;
      clearForm();
    } else {
      _editingServiceId = s.id;
      _editingCategoryName = s.category;
      _editingSubCategoryName = s.subCategoryName;
      nameController.text = s.name;
      purchasePriceController.text = s.purchasePrice.toString();
      salePriceController.text = s.salePrice.toString();
      minCorporatePriceController.text = s.minPriceCorporate?.toString() ?? '0.0';
      maxCorporatePriceController.text = s.maxPriceCorporate?.toString() ?? '0.0';
      isPriceEditable = s.isPriceEditable;
      isActive = s.isActive;
    }
    fetchProductCategoriesForTab(typeOverride: 'service');
    notifyListeners();
  }

  void setEditCategory(OwnerCategory? c, {String? departmentId}) {
    if (c == null) {
      _editingCategoryId = null;
      _editingCategoryDepartmentId = null;
      categoryNameController.clear();
    } else {
      _editingCategoryId = c.id;
      _editingCategoryDepartmentId = departmentId;
      categoryNameController.text = c.name;
      categoryTypeController.text = c.type;
    }
    notifyListeners();
  }

  void setEditSubCategory(OwnerSubCategory? s) {
    if (s == null) {
      _editingSubCategoryId = null;
      categoryNameController.clear();
    } else {
      _editingSubCategoryId = s.id;
      categoryNameController.text = s.name;
    }
    notifyListeners();
  }

  Future<void> submitProductForm(
    BuildContext context, {
    required String? departmentId,
    required String? categoryId,
    required String? subCategoryId,
    required String? branchId,
  }) async {
    if (nameController.text.trim().isEmpty || 
        purchasePriceController.text.trim().isEmpty ||
        salePriceController.text.trim().isEmpty ||
        openingQtyController.text.trim().isEmpty) {
      ToastService.showError(context, 'Please fill in all required fields.');
      return;
    }

    if (departmentId == null) {
      ToastService.showError(context, 'Please select a department.');
      return;
    }

    if (categoryId == null) {
      ToastService.showError(context, 'Please create a category first.');
      return;
    }

    if (branchId == null) {
      ToastService.showError(context, 'Please select a branch.');
      return;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      final user = await sessionService.getUser(role: 'owner');
      if (token == null) throw Exception('No token found');

      final workshopId = user?.workshopId ?? '3';

      String finalSubCategoryId = subCategoryIdController.text.trim().isEmpty ? (subCategoryId ?? '') : subCategoryIdController.text.trim();

      final Map<String, dynamic> data;

      if (_editingProductId == null) {
        // Create: full body including workshopId, branchId, departmentId, type
        data = {
          "workshopId": workshopId,
          "branchId": branchId,
          "name": nameController.text.trim(),
          "departmentId": departmentId,
          "categoryId": categoryIdController.text.trim().isEmpty ? categoryId : categoryIdController.text.trim(),
          if (finalSubCategoryId.isNotEmpty)
            "subCategoryId": finalSubCategoryId,
          "unit": unitController.text.trim().isEmpty ? "pcs" : unitController.text.trim(),
          "purchasePrice": double.tryParse(purchasePriceController.text.trim()) ?? 0.0,
          "salePrice": double.tryParse(salePriceController.text.trim()) ?? 0.0,
          "openingQty": double.tryParse(openingQtyController.text.trim()) ?? 0,
          "minPriceCorporate": double.tryParse(minCorporatePriceController.text.trim()) ?? 0.0,
          "maxPriceCorporate": double.tryParse(maxCorporatePriceController.text.trim()) ?? 0.0,
          "criticalStockPoint": double.tryParse(criticalStockPointController.text.trim()) ?? 5,
          "kmTypeValue": int.tryParse(kmTypeValueController.text.trim()) ?? 5000,
          "allowDecimalQty": allowDecimalQty,
          "type": "product",
          "isActive": isActive,
        };
      } else {
        // Update: only product-specific fields per PATCH /workshop-staff/product/{id}
        data = {
          "name": nameController.text.trim(),
          "unit": unitController.text.trim().isEmpty ? "pcs" : unitController.text.trim(),
          "purchasePrice": double.tryParse(purchasePriceController.text.trim()) ?? 0.0,
          "salePrice": double.tryParse(salePriceController.text.trim()) ?? 0.0,
          "openingQty": double.tryParse(openingQtyController.text.trim()) ?? 0,
          "criticalStockPoint": double.tryParse(criticalStockPointController.text.trim()) ?? 5,
          "categoryId": categoryIdController.text.trim().isEmpty ? categoryId : categoryIdController.text.trim(),
          "allowDecimalQty": allowDecimalQty,
          "minPriceCorporate": double.tryParse(minCorporatePriceController.text.trim()) ?? 0.0,
          "maxPriceCorporate": double.tryParse(maxCorporatePriceController.text.trim()) ?? 0.0,
          "isActive": isActive,
        };
      }

      final response = _editingProductId == null
          ? await ownerRepository.createProduct(data, token)
          : await ownerRepository.updateProduct(token, _editingProductId!, data);

      if (context.mounted) {
        ToastService.showSuccess(context, _editingProductId == null ? 'Product Created Successfully' : 'Product Updated Successfully');
        setEditProduct(null);
        Navigator.pop(context); // Close the sheet
        await fetchProducts(silent: true); // Refresh the list
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create product');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitServiceForm(
    BuildContext context, {
    required String? departmentId,
    required String? categoryId,
    required String? subCategoryId,
    required String? branchId,
  }) async {
    if (nameController.text.trim().isEmpty || 
        salePriceController.text.trim().isEmpty) {
      ToastService.showError(context, 'Please fill in required fields.');
      return;
    }

    if (departmentId == null) {
      ToastService.showError(context, 'Please select a department.');
      return;
    }

    if (categoryId == null) {
      ToastService.showError(context, 'Please create a category first.');
      return;
    }

    if (branchId == null) {
      ToastService.showError(context, 'Please select a branch.');
      return;
    }

    _isActionLoading = true; // Changed from _isLoading
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      final user = await sessionService.getUser(role: 'owner');
      if (token == null) throw Exception('No token found');

      final workshopId = user?.workshopId ?? '3';

      String finalSubCategoryId = subCategoryIdController.text.trim().isEmpty ? (subCategoryId ?? '') : subCategoryIdController.text.trim();
      
      final Map<String, dynamic> data;
      if (_editingServiceId == null) {
        data = {
          "workshopId": workshopId,
          "departmentId": departmentId,
          "branchId": branchId,
          "categoryId": categoryIdController.text.trim().isEmpty ? categoryId : categoryIdController.text.trim(),
          if (finalSubCategoryId.isNotEmpty)
            "subCategoryId": finalSubCategoryId,
          "name": nameController.text.trim(),
          "sellingPrice": double.tryParse(salePriceController.text.trim()) ?? 0.0,
          "isPriceEditable": isPriceEditable,
          "vatMode": vatMode,
          "minPriceCorporate": double.tryParse(minCorporatePriceController.text.trim()) ?? 0.0,
          "maxPriceCorporate": double.tryParse(maxCorporatePriceController.text.trim()) ?? 0.0,
          "type": "service",
          "isActive": isActive,
        };
      } else {
        data = {
          "name": nameController.text.trim(),
          "sellingPrice": double.tryParse(salePriceController.text.trim()) ?? 0.0,
          "categoryId": categoryIdController.text.trim().isEmpty
              ? categoryId
              : categoryIdController.text.trim(),
          "isPriceEditable": isPriceEditable,
          "vatMode": vatMode,
          "minPriceCorporate": double.tryParse(minCorporatePriceController.text.trim()) ?? 0.0,
          "maxPriceCorporate": double.tryParse(maxCorporatePriceController.text.trim()) ?? 0.0,
          "isActive": isActive,
        };
      }

      final response = _editingServiceId == null
          ? await ownerRepository.createWorkshopService(data, token)
          : await ownerRepository.updateService(token, _editingServiceId!, data);

      if (context.mounted) {
        ToastService.showSuccess(context, _editingServiceId == null ? 'Service Created Successfully' : 'Service Updated Successfully');
        setEditService(null);
        Navigator.pop(context); // Close the sheet
        await fetchServices(silent: true); // Refresh the services list
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create service');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  void toggleIsPriceEditable(bool val) {
    isPriceEditable = val;
    notifyListeners();
  }

  void setVatMode(String val) {
    vatMode = val;
    notifyListeners();
  }

  Future<void> submitCategoryForm(
    BuildContext context, {
    required String? departmentId,
  }) async {
    if (categoryNameController.text.trim().isEmpty) {
      ToastService.showError(context, 'Please fill in all required fields.');
      return;
    }
    if (departmentId == null || departmentId.isEmpty) {
      ToastService.showError(context, 'Please select a department.');
      return;
    }

    _isActionLoading = true; // Changed from _isLoading
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        "name": categoryNameController.text.trim(),
        "type": _selectedInnerTab == 0 ? 'product' : 'service',
        "departmentId": departmentId,
        "isActive": true,
      };

      final response = _editingCategoryId == null
          ? await ownerRepository.createCategory(data, token)
          : await ownerRepository.updateCategory(token, _editingCategoryId!, data);

      if (context.mounted) {
        ToastService.showSuccess(context, _editingCategoryId == null ? 'Category Created Successfully' : 'Category Updated Successfully');
        setEditCategory(null);
        Navigator.pop(context); // Close the sheet
        await fetchCategories(silent: true);
        await fetchProductCategoriesForTab(forceRefresh: true, silent: true);
        if (_selectedInnerTab == 0) {
          await fetchProducts(silent: true);
        } else {
          await fetchServices(silent: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create category');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitSubCategoryForm(BuildContext context, {required String categoryId}) async {
    if (categoryNameController.text.trim().isEmpty) {
      ToastService.showError(context, 'Please fill in all required fields.');
      return;
    }

    _isActionLoading = true; // Changed from _isLoading
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');

      final data = {
        "name": categoryNameController.text.trim(),
        "categoryId": categoryId,
        "isActive": true,
      };

      final response = _editingSubCategoryId == null
          ? await ownerRepository.createSubCategory(data, token)
          : await ownerRepository.updateSubCategory(token, _editingSubCategoryId!, data);

      if (context.mounted) {
        ToastService.showSuccess(context, _editingSubCategoryId == null ? 'Sub Category Created Successfully' : 'Sub Category Updated Successfully');
        setEditSubCategory(null);
        Navigator.pop(context); // Close the sheet
        await fetchCategories(silent: true); // Refresh
        await fetchProductCategoriesForTab(forceRefresh: true, silent: true); // Refresh
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, 'Failed to create sub category');
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }


  Future<void> deleteProduct(BuildContext context, String id) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;
      await ownerRepository.deleteProduct(token, id);
      if (context.mounted) {
        ToastService.showSuccess(context, 'Product Deleted Successfully');
        await fetchProducts(silent: true);
      }
    } catch (e) {
      if (context.mounted) ToastService.showError(context, 'Failed to delete product');
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteService(BuildContext context, String id) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;
      await ownerRepository.deleteService(token, id);
      if (context.mounted) {
        ToastService.showSuccess(context, 'Service Deleted Successfully');
        await fetchServices(silent: true);
      }
    } catch (e) {
      if (context.mounted) ToastService.showError(context, 'Failed to delete service');
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(BuildContext context, String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;
      await ownerRepository.deleteCategory(token, id);
      if (context.mounted) {
        ToastService.showSuccess(context, 'Category Deleted Successfully');
        await fetchCategories(silent: true);
        await fetchProductCategoriesForTab(forceRefresh: true, silent: true);
      }
    } catch (e) {
      if (context.mounted) ToastService.showError(context, 'Failed to delete category');
    } finally {
      _isLoading = false;
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSubCategory(BuildContext context, String id) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;
      await ownerRepository.deleteSubCategory(token, id);
      if (context.mounted) {
        ToastService.showSuccess(context, 'Sub Category Deleted Successfully');
        await fetchCategories(silent: true);
        await fetchProductCategoriesForTab(forceRefresh: true, silent: true);
      }
    } catch (e) {
      if (context.mounted) ToastService.showError(context, 'Failed to delete sub category');
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ownerDataService.removeListener(notifyListeners);
    unbindLocaleRetranslation();
    nameController.dispose();
    unitController.dispose();
    categoryIdController.dispose();
    subCategoryIdController.dispose();
    purchasePriceController.dispose();
    salePriceController.dispose();
    minCorporatePriceController.dispose();
    maxCorporatePriceController.dispose();
    openingQtyController.dispose();
    criticalStockPointController.dispose();
    kmTypeValueController.dispose();
    categoryNameController.dispose();
    categoryTypeController.dispose();
    super.dispose();
  }
}
