// ─── branch_catalog_view_model.dart ──────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../../data/network/api_response.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';

class BranchCatalogViewModel extends ChangeNotifier {
  final CatalogRepository _repo;
  final SessionService _sessionService;
  final OwnerDataService? _ownerData;

  String? _token;
  String? _workshopId;
  String? _branchId;
  String? _lastSyncedBranchKey;

  BranchCatalogViewModel({
    required CatalogRepository repository,
    required SessionService sessionService,
    OwnerDataService? ownerDataService,
    bool initialLowStock = false,
  })  : _repo = repository,
        _sessionService = sessionService,
        _ownerData = ownerDataService,
        _lowStockOnly = initialLowStock {
    final globalId = _ownerData?.selectedBranchId;
    _selectedBranchId =
        (globalId == null || globalId.isEmpty) ? 'all' : globalId;
    _lastSyncedBranchKey = _selectedBranchId;
    _ownerData?.addListener(_onOwnerDataChanged);
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final globalId = _ownerData?.selectedBranchId;
    final next = (globalId == null || globalId.isEmpty) ? 'all' : globalId;
    if (!force && next == _lastSyncedBranchKey) return;
    _lastSyncedBranchKey = next;
    selectBranch(next);
  }

  // ─── Raw API state ────────────────────────────────────────────────────────

  ApiResponse<List<CatalogBranch>> branchesState = ApiResponse.loading();
  ApiResponse<List<CatalogDepartmentModel>> departmentsState = ApiResponse.loading();
  ApiResponse<List<CatalogCategoryModel>> categoriesState = ApiResponse.loading();
  ApiResponse<ProductsResponse> productsState = ApiResponse.loading();
  ApiResponse<ServicesResponse> servicesState = ApiResponse.loading();
  ApiResponse<ProductUnitsResponse> productUnitsState = ApiResponse.loading();

  ApiResponse<MasterDepartmentsResponse> masterDepartmentsState = ApiResponse.loading();
  final Map<String, ApiResponse<MasterCategoriesResponse>> masterCategoriesCache = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isCreatingDepartment = false;
  bool get isCreatingDepartment => _isCreatingDepartment;

  bool _isCreatingCategory = false;
  bool get isCreatingCategory => _isCreatingCategory;

  bool _isCreatingProduct = false;
  bool get isCreatingProduct => _isCreatingProduct;

  bool _isDeletingProduct = false;
  bool get isDeletingProduct => _isDeletingProduct;

  bool _isSubmittingProductRequest = false;
  bool get isSubmittingProductRequest => _isSubmittingProductRequest;

  bool _isCreatingService = false;
  bool get isCreatingService => _isCreatingService;

  // ─── Per-department toggle loading tracking ───────────────────────────────
  // Tracks which department IDs are currently being toggled active/inactive
  // so each card can show its own inline spinner independently.
  final Set<String> _togglingDeptIds = {};

  /// Returns true while the active/inactive API call is in-flight for [deptId].
  bool isTogglingDepartment(String deptId) => _togglingDeptIds.contains(deptId);

  // ─── Cache ────────────────────────────────────────────────────────────────

  final Map<String?, ProductsResponse> _productsCache = {};
  final Map<String?, ServicesResponse> _servicesCache = {};

  // ─── Branch selector ──────────────────────────────────────────────────────
  // Branch is now chosen from the side menu, not the top header.
  // _selectedBranchId still drives filtering but is set externally.

  String _selectedBranchId = 'all';
  String get selectedBranchId => _selectedBranchId;

  bool get isAllBranches => _selectedBranchId == 'all';

  List<CatalogBranch> get branchPickerOptions => branchesState.data ?? [];

  CatalogBranch? get selectedBranch {
    if (isAllBranches) return null;
    final data = branchesState.data;
    if (data == null || data.isEmpty) return null;
    return data.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => data.first,
    );
  }

  void selectBranch(String branchId) {
    if (_selectedBranchId == branchId) return;
    _selectedBranchId = branchId;
    _lastSyncedBranchKey = branchId;
    final cacheKey = isAllBranches ? null : _selectedBranchId;
    if (_productsCache.containsKey(cacheKey)) {
      productsState = ApiResponse.completed(_productsCache[cacheKey]!);
    }
    if (_servicesCache.containsKey(cacheKey)) {
      servicesState = ApiResponse.completed(_servicesCache[cacheKey]!);
    }
    // PERF: single notifyListeners then fetch — avoids double rebuild
    notifyListeners();
    _fetchProductsAndServices();
  }

  // ─── Dept filter ──────────────────────────────────────────────────────────

  String? _productDeptFilter;
  String? get productDeptFilter => _productDeptFilter;

  String? _serviceDeptFilter;
  String? get serviceDeptFilter => _serviceDeptFilter;

  void setProductDeptFilter(String? deptId) {
    if (_productDeptFilter == deptId) return;
    _productDeptFilter = deptId;
    notifyListeners();
  }

  void setServiceDeptFilter(String? deptId) {
    if (_serviceDeptFilter == deptId) return;
    _serviceDeptFilter = deptId;
    notifyListeners();
  }

  // ─── Low-stock toggle ─────────────────────────────────────────────────────

  bool _lowStockOnly = false;
  bool get lowStockOnly => _lowStockOnly;

  void toggleLowStock(bool v) {
    if (_lowStockOnly == v) return;
    _lowStockOnly = v;
    notifyListeners();
  }

  // ─── Selection sets ───────────────────────────────────────────────────────

  final Set<String> selectedProductIds = {};
  final Set<String> selectedServiceIds = {};

  void toggleProductSelection(String id, bool selected) {
    selected ? selectedProductIds.add(id) : selectedProductIds.remove(id);
    notifyListeners();
  }

  void toggleServiceSelection(String id, bool selected) {
    selected ? selectedServiceIds.add(id) : selectedServiceIds.remove(id);
    notifyListeners();
  }

  // ─── Computed / filtered lists ────────────────────────────────────────────

  List<CatalogDepartmentModel>? _cachedDepts;
  String? _cachedDeptsKey;

  List<CatalogDepartmentModel> get filteredDepartments {
    final key = _selectedBranchId;
    if (key == _cachedDeptsKey && _cachedDepts != null) return _cachedDepts!;
    final all = departmentsState.data ?? [];
    _cachedDepts = isAllBranches
        ? all
        : all.where((d) => d.branchNames.contains(selectedBranch?.name ?? '')).toList();
    _cachedDeptsKey = key;
    return _cachedDepts!;
  }

  List<CatalogCategoryModel>? _cachedCats;
  String? _cachedCatsKey;

  List<CatalogCategoryModel> get filteredCategories {
    final key = _selectedBranchId;
    if (key == _cachedCatsKey && _cachedCats != null) return _cachedCats!;
    final all = categoriesState.data ?? [];
    _cachedCats = isAllBranches
        ? all
        : all.where((c) => c.branchNames.contains(selectedBranch?.name ?? '')).toList();
    _cachedCatsKey = key;
    return _cachedCats!;
  }

  List<CatalogProductModel> get filteredProducts {
    final all = productsState.data?.allProducts ?? [];
    if (_productDeptFilter == null && !_lowStockOnly) return all;
    return all.where((p) {
      if (_productDeptFilter != null && p.departmentId != _productDeptFilter) return false;
      if (_lowStockOnly && !p.isLowStock) return false;
      return true;
    }).toList();
  }

  List<CatalogServiceModel> get filteredServices {
    final all = servicesState.data?.allServices ?? [];
    if (_serviceDeptFilter == null) return all;
    return all.where((s) => s.departmentId == _serviceDeptFilter).toList();
  }

  List<String> get productUnits => productUnitsState.data?.units ?? [];
  String get defaultProductUnit => productUnitsState.data?.defaultUnit ?? 'pcs';

  // ─── Tab counts (for tab badge display) ──────────────────────────────────

  int get departmentsCount => filteredDepartments.length;
  int get productsCount => productsState.data?.allProducts.length ?? 0;
  int get servicesCount => servicesState.data?.allServices.length ?? 0;
  int get categoriesCount => filteredCategories.length;

  // ─── Init / Refresh ───────────────────────────────────────────────────────

  Future<void> init() => _fetchAll();

  Future<void> refresh() {
    _productsCache.clear();
    _servicesCache.clear();
    masterCategoriesCache.clear();
    _cachedDepts = null;
    _cachedCats = null;
    return _fetchAll();
  }

  Future<void> _fetchAll() async {
    _token = await _sessionService.getToken(role: 'owner');
    if (_token == null) {
      _error = 'Not authenticated. Please log in again.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // PRE-LOAD STRATEGY: All six fetches run in parallel.
    // branches + departments + categories are shared lookup data used in every
    // tab's dropdowns and filters — fetched once here, reused everywhere.
    // products + services + productUnits cover the other three tabs so they
    // are ready the moment the user swipes to them (zero wait).
    // masterDepartments is needed for the "Request Product" sheet.
    await Future.wait([
      _fetchBranches(),
      _fetchDepartments(),
      _fetchCategories(),
      _fetchProductsAndServices(),
      _fetchProductUnits(),
      _fetchMasterDepartments(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // ─── Fetchers ─────────────────────────────────────────────────────────────

  Future<void> _fetchBranches() async {
    try {
      final data = await _repo.getBranches(_token!);
      branchesState = ApiResponse.completed(data.branches);
      if (data.branches.isNotEmpty) {
        _workshopId = data.branches.first.workshopId;
        _branchId ??= data.branches.first.id;
      }
      _cachedDepts = null;
      _cachedCats = null;
    } catch (e) {
      branchesState = ApiResponse.error(e.toString());
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final data = await _repo.getCatalogDepartments(_token!);
      departmentsState = ApiResponse.completed(data.departments);
      _cachedDepts = null;
    } catch (e) {
      departmentsState = ApiResponse.error(e.toString());
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await _repo.getCatalogCategories(_token!);
      categoriesState = ApiResponse.completed(data.categories);
      _cachedCats = null;
    } catch (e) {
      categoriesState = ApiResponse.error(e.toString());
    }
  }

  Future<void> _fetchProductsAndServices() async {
    final branchId = isAllBranches ? null : _selectedBranchId;
    await Future.wait([
      _fetchProducts(branchId: branchId),
      _fetchServices(branchId: branchId),
    ]);
  }

  Future<void> _fetchProducts({String? branchId}) async {
    try {
      // PERF: Removed the extra notifyListeners() on loading state — it was
      // causing a full widget rebuild just to show a spinner that the outer
      // _isLoading LinearProgressIndicator already handles.
      // Only notify once at the end (done by _fetchAll's final notifyListeners).
      productsState = ApiResponse.loading();
      final data = await _repo.getCatalogProducts(
        _token!,
        allBranches: branchId == null,
        branchId: branchId,
      );
      _productsCache[branchId] = data;
      productsState = ApiResponse.completed(data);
    } catch (e) {
      productsState = ApiResponse.error(e.toString());
    }
  }

  Future<void> _fetchServices({String? branchId}) async {
    try {
      // PERF: Same as above — removed intermediate notifyListeners().
      servicesState = ApiResponse.loading();
      final data = await _repo.getCatalogServices(
        _token!,
        allBranches: branchId == null,
        branchId: branchId,
      );
      _servicesCache[branchId] = data;
      servicesState = ApiResponse.completed(data);
    } catch (e) {
      servicesState = ApiResponse.error(e.toString());
    }
  }

  Future<void> _fetchProductUnits() async {
    try {
      final data = await _repo.getProductUnits(_token!);
      productUnitsState = ApiResponse.completed(data);
    } catch (e) {
      productUnitsState = ApiResponse.error(e.toString());
    }
  }

  Future<void> _fetchMasterDepartments() async {
    try {
      final data = await _repo.getMasterDepartments(_token!);
      masterDepartmentsState = ApiResponse.completed(data);
    } catch (e) {
      masterDepartmentsState = ApiResponse.error(e.toString());
    }
  }

  Future<List<MasterCategoryItem>> fetchMasterCategories(
    String departmentId, {
    String type = 'product',
  }) async {
    final cacheKey = '$departmentId:$type';
    final cached = masterCategoriesCache[cacheKey];
    if (cached?.status == Status.completed) {
      return cached!.data!.categories;
    }

    masterCategoriesCache[cacheKey] = ApiResponse.loading();
    notifyListeners();

    try {
      final data = await _repo.getMasterCategories(
        _token!,
        departmentId: departmentId,
        type: type,
      );
      masterCategoriesCache[cacheKey] = ApiResponse.completed(data);
      notifyListeners();
      return data.categories;
    } catch (e) {
      masterCategoriesCache[cacheKey] = ApiResponse.error(e.toString());
      notifyListeners();
      return [];
    }
  }

  // ─── Toggle department active ─────────────────────────────────────────────

  Future<ToggleDepartmentActiveResponse?> toggleDepartmentActive(
    BuildContext context,
    String departmentId,
    bool isActive,
  ) async {
    // Mark this specific department as loading so its card shows a spinner
    _togglingDeptIds.add(departmentId);
    notifyListeners();

    try {
      final result = await _repo.toggleDepartmentActive(
        _token!,
        departmentId: departmentId,
        isActive: isActive,
      );
      if (result.success) {
        await _fetchDepartments();
        notifyListeners();
      }
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      // Always clear the loading indicator, success or failure
      _togglingDeptIds.remove(departmentId);
      notifyListeners();
    }
  }

  // ─── Create department ────────────────────────────────────────────────────

  Future<CreatedDepartment?> createDepartment(
    BuildContext context, {
    required String name,
    bool isActive = true,
    String? branchId,
  }) async {
    _isCreatingDepartment = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.createDepartment2(
        _token!,
        name: name,
        isActive: isActive,
        branchId: branchId,
      );
      if (result.success && result.department != null) {
        await _fetchDepartments();
        await _fetchMasterDepartments();
        return result.department;
      }
      _error = result.message.isNotEmpty ? result.message : 'Failed to create department';
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isCreatingDepartment = false;
      notifyListeners();
    }
  }

  // ─── Create category ──────────────────────────────────────────────────────

  Future<CreatedCategory?> createCategory(
    BuildContext context, {
    required String name,
    required String type,
    required String departmentId,
    bool isActive = true,
  }) async {
    _isCreatingCategory = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.createCatalogCategory(
        _token!,
        name: name,
        type: type,
        departmentId: departmentId,
        isActive: isActive,
      );
      if (result.success && result.category != null) {
        await _fetchCategories();
        masterCategoriesCache.remove('$departmentId:$type');
        return result.category;
      }
      _error = result.message.isNotEmpty ? result.message : 'Failed to create category';
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isCreatingCategory = false;
      notifyListeners();
    }
  }

  // ─── Create product ───────────────────────────────────────────────────────

  Future<bool> createProduct(
    BuildContext context,
    CreateProductRequest request,
  ) async {
    if (productUnits.isNotEmpty && !productUnits.contains(request.unit)) {
      _error = 'Invalid unit "${request.unit}". Must be one of: ${productUnits.join(", ")}';
      notifyListeners();
      return false;
    }

    _isCreatingProduct = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.createCatalogProduct(_token!, request);
      if (result.success) {
        _productsCache.remove(request.branchId);
        _productsCache.remove(null);
        await _fetchProducts(branchId: isAllBranches ? null : _selectedBranchId);
        return true;
      }
      _error = result.message.isNotEmpty ? result.message : 'Failed to create product';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isCreatingProduct = false;
      notifyListeners();
    }
  }

  // ─── Remove from workshop (all branches) — admin web parity ───────────────

  Future<(bool wasRemoved, String? blockReason)> removeWorkshopProduct(
    BuildContext context,
    String productId,
  ) async {
    _isDeletingProduct = true;
    _error = null;
    notifyListeners();

    try {
      final result =
          await _repo.removeWorkshopProduct(_token!, productId);
      if (result.wasRemoved) {
        _productsCache.clear();
        await _fetchProducts(branchId: isAllBranches ? null : _selectedBranchId);
        selectedProductIds.remove(productId);
      }
      return (result.wasRemoved, result.blockReason);
    } catch (e) {
      _error = e.toString();
      return (false, e.toString());
    } finally {
      _isDeletingProduct = false;
      notifyListeners();
    }
  }

  Future<(bool wasRemoved, String? blockReason)> removeWorkshopService(
    BuildContext context,
    String serviceId,
  ) async {
    _error = null;
    notifyListeners();
    try {
      final result =
          await _repo.removeWorkshopService(_token!, serviceId);
      if (result.wasRemoved) {
        _servicesCache.clear();
        await _fetchServices(branchId: isAllBranches ? null : _selectedBranchId);
        selectedServiceIds.remove(serviceId);
      }
      return (result.wasRemoved, result.blockReason);
    } catch (e) {
      _error = e.toString();
      return (false, e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<(int removed, String? error)> removeSelectedWorkshopProducts(
    BuildContext context,
  ) async {
    final ids = selectedProductIds.toList();
    if (ids.isEmpty) return (0, 'No products selected');
    try {
      final result =
          await _repo.removeWorkshopProductsBulk(_token!, ids);
      _productsCache.clear();
      await _fetchProducts(branchId: isAllBranches ? null : _selectedBranchId);
      selectedProductIds.removeWhere((id) => result.removedIds.contains(id));
      notifyListeners();
      if (result.failed.isNotEmpty) {
        return (
          result.removedIds.length,
          result.failed.first.reason,
        );
      }
      return (result.removedIds.length, null);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return (0, e.toString());
    }
  }

  Future<(int removed, String? error)> removeSelectedWorkshopServices(
    BuildContext context,
  ) async {
    final ids = selectedServiceIds.toList();
    if (ids.isEmpty) return (0, 'No services selected');
    try {
      if (isAllBranches) {
        final result =
            await _repo.removeWorkshopServicesBulk(_token!, ids);
        _servicesCache.clear();
        await _fetchServices(branchId: null);
        selectedServiceIds.removeWhere((id) => result.removedIds.contains(id));
        notifyListeners();
        if (result.failed.isNotEmpty) {
          return (result.removedIds.length, result.failed.first.reason);
        }
        return (result.removedIds.length, null);
      }
      // Branch scope: remove each from the selected branch
      var removed = 0;
      String? lastError;
      for (final id in ids) {
        final ok = await removeServiceFromBranch(context, id);
        if (ok) {
          removed++;
        } else {
          lastError = _error;
        }
      }
      return (removed, lastError);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return (0, e.toString());
    }
  }

  @Deprecated('Use removeWorkshopProduct')
  Future<(bool wasRemoved, String? blockReason)> deleteWorkshopProduct(
    BuildContext context,
    String workshopProductId,
  ) =>
      removeWorkshopProduct(context, workshopProductId);

  // ─── Submit product catalog request ───────────────────────────────────────

  Future<CatalogProductRequestResponse?> submitProductRequest(
    BuildContext context, {
    required String name,
    required String brandName,
    required String unit,
    required double salePriceInclusiveVat,
    required String masterDepartmentId,
    required String masterCategoryId,
  }) async {
    if (_workshopId == null || _branchId == null) {
      _error = 'Workshop/branch context not loaded yet.';
      notifyListeners();
      return null;
    }

    _isSubmittingProductRequest = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.submitProductRequest(
        _token!,
        CatalogProductRequest(
          workshopId: _workshopId!,
          branchId: _branchId!,
          name: name,
          brandName: brandName,
          unit: unit,
          salePriceInclusiveVat: salePriceInclusiveVat,
          masterDepartmentId: masterDepartmentId,
          masterCategoryId: masterCategoryId,
        ),
      );
      if (!result.success) {
        _error = 'Product request failed';
      }
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmittingProductRequest = false;
      notifyListeners();
    }
  }

  // ─── Create service ───────────────────────────────────────────────────────

  Future<bool> createService(
    BuildContext context,
    CreateServiceRequest request,
  ) async {
    if (_workshopId == null || _branchId == null) {
      _error = 'Workshop/branch context not loaded yet.';
      notifyListeners();
      return false;
    }

    _isCreatingService = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.createCatalogService(_token!, request);
      if (result.success) {
        // Invalidate services cache so list refreshes
        _servicesCache.remove(request.branchId);
        _servicesCache.remove(null);
        await _fetchServices(branchId: isAllBranches ? null : _selectedBranchId);
        return true;
      }
      _error = result.message.isNotEmpty ? result.message : 'Failed to create service';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isCreatingService = false;
      notifyListeners();
    }
  }

  // ─── Remove from branch ───────────────────────────────────────────────────

  Future<bool> removeProductFromBranch(BuildContext context, String productId) async {
    if (isAllBranches) return false;
    try {
      await _repo.removeFromBranch(_token!, branchId: _selectedBranchId, type: 'product', itemId: productId);
      _productsCache.remove(_selectedBranchId);
      await _fetchProducts(branchId: _selectedBranchId);
      selectedProductIds.remove(productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeServiceFromBranch(BuildContext context, String serviceId) async {
    if (isAllBranches) return false;
    try {
      await _repo.removeFromBranch(_token!, branchId: _selectedBranchId, type: 'service', itemId: serviceId);
      _servicesCache.remove(_selectedBranchId);
      await _fetchServices(branchId: _selectedBranchId);
      selectedServiceIds.remove(serviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeDepartmentFromBranch(BuildContext context, String deptId) async {
    if (isAllBranches) return false;
    try {
      await _repo.removeFromBranch(_token!, branchId: _selectedBranchId, type: 'department', itemId: deptId);
      await _fetchDepartments();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCategoryFromBranch(BuildContext context, String categoryId) async {
    if (isAllBranches) return false;
    try {
      await _repo.removeFromBranch(_token!, branchId: _selectedBranchId, type: 'category', itemId: categoryId);
      await _fetchCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _ownerData?.removeListener(_onOwnerDataChanged);
    _productsCache.clear();
    _servicesCache.clear();
    masterCategoriesCache.clear();
    super.dispose();
  }
}
