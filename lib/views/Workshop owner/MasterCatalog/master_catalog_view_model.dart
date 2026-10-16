// ─── master_catalog_view_model.dart ──────────────────────────────────────────
// ChangeNotifier ViewModel — Master Catalog (all four tabs).
//
// Fetch strategy (lazy):
//   On open:  branches + departments + categories only.
//   Products / Services tabs: full paginated lists load the first time that
//   tab is opened (and are refreshed after add-to-branch if already loaded).
//
// Branches and departments fetched here are REUSED by all tabs — no duplicate
// API calls from Products or Services tabs.
//
// All filtering is client-side (no extra round-trips on filter change).

import 'package:flutter/material.dart';
import 'dart:async' show unawaited;
import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import 'master_catalog_shared.dart';

// ─── Supporting enums / classes ───────────────────────────────────────────────

enum BranchScope { all, specific }
enum CategoryMode { all, pick, none }

class DeptCategorySelection {
  CategoryMode mode;
  Set<String> pickedCategoryIds;
  DeptCategorySelection({
    this.mode = CategoryMode.all,
    Set<String>? pickedCategoryIds,
  }) : pickedCategoryIds = pickedCategoryIds ?? {};
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class MasterCatalogViewModel extends ChangeNotifier {
  final CatalogRepository _repo;
  final SessionService _sessionService;
  final OwnerDataService? _ownerData;
  String? _lastSyncedBranchId;

  String? _token;
  bool _initialized = false;
  bool _productsLoaded = false;
  bool _servicesLoaded = false;
  Future<void>? _productsLoadFuture;
  Future<void>? _servicesLoadFuture;

  MasterCatalogViewModel({
    required CatalogRepository repository,
    required SessionService sessionService,
    OwnerDataService? ownerDataService,
  })  : _repo = repository,
        _sessionService = sessionService,
        _ownerData = ownerDataService {
    _globalBranchId = _ownerData?.selectedBranchId;
    _deptRequestBranchId = _ownerData?.selectedBranchId;
    _lastSyncedBranchId = _ownerData?.selectedBranchId;
    _ownerData?.addListener(_onOwnerDataChanged);
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerData?.selectedBranchId;
    if (!force && next == _lastSyncedBranchId) return;
    _lastSyncedBranchId = next;
    _globalBranchId = next;
    _deptRequestBranchId = next;
    notifyListeners();
    if (_initialized) await _refreshLoaded(silent: true);
  }

  @override
  void dispose() {
    _ownerData?.removeListener(_onOwnerDataChanged);
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  List<MasterBranch> branches = [];
  List<MasterDepartment> departments = [];
  List<MasterCategory> categories = [];
  List<MasterProduct> products = [];
  List<MasterService> services = [];

  // ── Loading ───────────────────────────────────────────────────────────────

  /// True while Phase 1 (branches/depts/categories) is loading.
  /// Drives the global LinearProgressIndicator in the AppBar area.
  bool isLoading = false;

  /// True while paginated products are still being fetched (Phase 2).
  /// Products tab shows its own spinner based on this flag.
  bool isLoadingProducts = false;

  /// True while paginated services are still being fetched (Phase 2).
  bool isLoadingServices = false;

  String? error;

  // ── Global branch filter ──────────────────────────────────────────────────

  String? _globalBranchId;
  String? get globalBranchId => _globalBranchId;

  void setGlobalBranchId(String? v) {
    if (_globalBranchId == v) return;
    _globalBranchId = v;
    notifyListeners();
  }

  // ── Dept-request branch ───────────────────────────────────────────────────

  String? _deptRequestBranchId;
  String? get deptRequestBranchId => _deptRequestBranchId;

  void setDeptRequestBranchId(String? v) {
    if (_deptRequestBranchId == v) return;
    _deptRequestBranchId = v;
    notifyListeners();
  }

  // ── Per-tab added/not-added toggle ────────────────────────────────────────

  bool _deptShowAdded = false;
  bool get deptShowAdded => _deptShowAdded;
  void setDeptShowAdded(bool v) {
    if (_deptShowAdded == v) return;
    _deptShowAdded = v;
    clearDeptSelections();
  }

  bool _categoryShowAdded = false;
  bool get categoryShowAdded => _categoryShowAdded;
  void setCategoryShowAdded(bool v) {
    if (_categoryShowAdded == v) return;
    _categoryShowAdded = v;
    clearCategorySelections();
  }

  // ── Result banner ─────────────────────────────────────────────────────────

  AddToBranchResult? lastResult;
  void clearResult() {
    lastResult = null;
    notifyListeners();
  }

  // ── Dependency preview (products & services) ───────────────────────────────
  // Populated by previewProductDeps / previewServiceDeps before the sheet opens.
  // The sheet reads these to show the yellow "also adding" banner immediately.

  List<String> productDepsMissingDepts = [];
  List<String> productDepsMissingCats = [];
  List<String> serviceDepsMissingDepts = [];
  List<String> serviceDepsMissingCats = [];

  bool isPreviewingDeps = false;

  /// Call before opening the AddToBranchesSheet for products.
  /// Resolves missing department / category names from the already-loaded lists.
  Future<void> previewProductDeps() async {
    if (selectedProductIds.isEmpty || _token == null) return;
    isPreviewingDeps = true;
    notifyListeners();
    try {
      final result = await _repo.previewProductDependencies(
        _token!,
        productIds: selectedProductIds.toList(),
      );
      final missing = (result['missing'] as Map<String, dynamic>?) ?? {};
      final missingDeptIds = ((missing['departments'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet();
      final missingCatIds = ((missing['categories'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet();

      productDepsMissingDepts = departments
          .where((d) => missingDeptIds.contains(d.id))
          .map((d) => d.name)
          .toList();
      productDepsMissingCats = categories
          .where((c) => missingCatIds.contains(c.id))
          .map((c) => c.name)
          .toList();
    } catch (e) {
      debugPrint('[MasterCatalogVM] previewProductDeps: $e');
      productDepsMissingDepts = [];
      productDepsMissingCats = [];
    } finally {
      isPreviewingDeps = false;
      notifyListeners();
    }
  }

  /// Call before opening the AddToBranchesSheet for services.
  Future<void> previewServiceDeps() async {
    if (selectedServiceIds.isEmpty || _token == null) return;
    isPreviewingDeps = true;
    notifyListeners();
    try {
      final result = await _repo.previewServiceDependencies(
        _token!,
        serviceIds: selectedServiceIds.toList(),
      );
      final missing = (result['missing'] as Map<String, dynamic>?) ?? {};
      final missingDeptIds = ((missing['departments'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet();
      final missingCatIds = ((missing['categories'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet();

      serviceDepsMissingDepts = departments
          .where((d) => missingDeptIds.contains(d.id))
          .map((d) => d.name)
          .toList();
      serviceDepsMissingCats = categories
          .where((c) => missingCatIds.contains(c.id))
          .map((c) => c.name)
          .toList();
    } catch (e) {
      debugPrint('[MasterCatalogVM] previewServiceDeps: $e');
      serviceDepsMissingDepts = [];
      serviceDepsMissingCats = [];
    } finally {
      isPreviewingDeps = false;
      notifyListeners();
    }
  }

  void clearProductDeps() {
    productDepsMissingDepts = [];
    productDepsMissingCats = [];
  }

  void clearServiceDeps() {
    serviceDepsMissingDepts = [];
    serviceDepsMissingCats = [];
  }

  // ── Fetch categories per department (for dept sheet live picker) ───────────
  // Cached so repeated opens don't re-fetch.

  final Map<String, List<MasterCategory>> _deptCatsCache = {};
  bool _isFetchingDeptCats = false;
  bool get isFetchingDeptCats => _isFetchingDeptCats;

  Future<List<MasterCategory>> fetchCategoriesForDept(String deptId) async {
    if (_deptCatsCache.containsKey(deptId)) return _deptCatsCache[deptId]!;
    if (_token == null) return [];
    _isFetchingDeptCats = true;
    notifyListeners();
    try {
      final raw = await _repo.fetchCategoriesByDept(_token!, departmentId: deptId);
      final cats = raw
          .map((c) => MasterCategory(
        id: c['id']?.toString() ?? '',
        name: (c['name'] as String?) ?? '',
        type: (c['type'] as String?) ?? 'product',
        departmentId: c['departmentId']?.toString() ?? '',
        departmentName: (c['departmentName'] as String?) ?? '',
        isAddedToCurrentBranch: c['inWorkshop'] == true,
      ))
          .where((c) => c.id.isNotEmpty)
          .toList();
      _deptCatsCache[deptId] = cats;
      return cats;
    } catch (e) {
      debugPrint('[MasterCatalogVM] fetchCategoriesForDept: $e');
      return [];
    } finally {
      _isFetchingDeptCats = false;
      notifyListeners();
    }
  }

  // ── Selection sets ────────────────────────────────────────────────────────

  final Set<String> selectedDeptIds = {};
  final Set<String> selectedCategoryIds = {};
  final Set<String> selectedProductIds = {};
  final Set<String> selectedServiceIds = {};

  void toggleDept(String id) {
    selectedDeptIds.contains(id) ? selectedDeptIds.remove(id) : selectedDeptIds.add(id);
    notifyListeners();
  }

  void toggleCategory(String id) {
    selectedCategoryIds.contains(id) ? selectedCategoryIds.remove(id) : selectedCategoryIds.add(id);
    notifyListeners();
  }

  void toggleProduct(String id) {
    selectedProductIds.contains(id) ? selectedProductIds.remove(id) : selectedProductIds.add(id);
    notifyListeners();
  }

  void toggleService(String id) {
    selectedServiceIds.contains(id) ? selectedServiceIds.remove(id) : selectedServiceIds.add(id);
    notifyListeners();
  }

  void clearAllSelections() {
    selectedDeptIds.clear();
    selectedCategoryIds.clear();
    selectedProductIds.clear();
    selectedServiceIds.clear();
    notifyListeners();
  }

  void clearDeptSelections() { selectedDeptIds.clear(); notifyListeners(); }
  void clearCategorySelections() { selectedCategoryIds.clear(); notifyListeners(); }
  void clearProductSelections() { selectedProductIds.clear(); notifyListeners(); }
  void clearServiceSelections() { selectedServiceIds.clear(); notifyListeners(); }

  // ── Toggle department active/inactive ─────────────────────────────────────

  Future<void> toggleDeptActive(String id) async {
    final idx = departments.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    final d = departments[idx];
    departments[idx] = MasterDepartment(
      id: d.id, name: d.name, parentLabel: d.parentLabel,
      isAddedToCurrentBranch: d.isAddedToCurrentBranch,
      isActive: !d.isActive,
    );
    notifyListeners();
    // TODO: PATCH /workshop-catalog/departments/{id}/active
  }

  // ── Category filters ──────────────────────────────────────────────────────

  String? _categoryDeptFilter;
  String? get categoryDeptFilter => _categoryDeptFilter;

  String? _categoryTypeFilter;
  String? get categoryTypeFilter => _categoryTypeFilter;

  void setCategoryDeptFilter(String? v) {
    if (_categoryDeptFilter == v) return;
    _categoryDeptFilter = v;
    notifyListeners();
  }

  void setCategoryTypeFilter(String? v) {
    if (_categoryTypeFilter == v) return;
    _categoryTypeFilter = v;
    notifyListeners();
  }

  // ── Product / Service dept filters ────────────────────────────────────────

  String? _productDeptFilter;
  String? get productDeptFilter => _productDeptFilter;

  void setProductDeptFilter(String? v) {
    if (_productDeptFilter == v) return;
    _productDeptFilter = v;
    notifyListeners();
  }

  String? _serviceDeptFilter;
  String? get serviceDeptFilter => _serviceDeptFilter;

  void setServiceDeptFilter(String? v) {
    if (_serviceDeptFilter == v) return;
    _serviceDeptFilter = v;
    notifyListeners();
  }

  // ── Filtered lists (all client-side, O(n), no extra calls) ───────────────

  List<MasterDepartment> get filteredDepartments => departments
      .where((d) => _deptShowAdded ? d.isAddedToCurrentBranch : !d.isAddedToCurrentBranch)
      .toList();

  List<MasterCategory> get filteredCategories {
    var list = categories
        .where((c) => _categoryShowAdded ? c.isAddedToCurrentBranch : !c.isAddedToCurrentBranch)
        .toList();
    if (_categoryDeptFilter != null) {
      list = list.where((c) => c.departmentId == _categoryDeptFilter).toList();
    }
    if (_categoryTypeFilter != null) {
      list = list.where((c) => c.type == _categoryTypeFilter).toList();
    }
    return list;
  }

  /// Filter by departmentId — precise, no name matching.
  List<MasterProduct> get filteredProducts {
    if (_productDeptFilter == null) return products;
    return products.where((p) => p.departmentId == _productDeptFilter).toList();
  }

  /// Filter by departmentId — precise, no name matching.
  List<MasterService> get filteredServices {
    if (_serviceDeptFilter == null) return services;
    return services.where((s) => s.departmentId == _serviceDeptFilter).toList();
  }

  // ── Init / Refresh ────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    await _fetchCore();
  }

  /// Load data for the visible tab only.
  /// 0 = Departments, 1 = Categories → core only (already in [init]).
  /// 2 = Products, 3 = Services → heavy lists on demand.
  Future<void> ensureTabData(int tabIndex) async {
    if (!_initialized) await init();
    if (tabIndex == 2) {
      await ensureProductsLoaded();
    } else if (tabIndex == 3) {
      await ensureServicesLoaded();
    }
  }

  Future<void> ensureProductsLoaded() async {
    if (_productsLoaded) return;
    if (_productsLoadFuture != null) return _productsLoadFuture;
    _productsLoadFuture = _loadProducts();
    try {
      await _productsLoadFuture;
    } finally {
      _productsLoadFuture = null;
    }
  }

  Future<void> ensureServicesLoaded() async {
    if (_servicesLoaded) return;
    if (_servicesLoadFuture != null) return _servicesLoadFuture;
    _servicesLoadFuture = _loadServices();
    try {
      await _servicesLoadFuture;
    } finally {
      _servicesLoadFuture = null;
    }
  }

  Future<void> _loadProducts() async {
    _token ??= await _sessionService.getToken(role: 'owner');
    if (_token == null) return;
    isLoadingProducts = true;
    notifyListeners();
    await _fetchProducts();
    _productsLoaded = true;
  }

  Future<void> _loadServices() async {
    _token ??= await _sessionService.getToken(role: 'owner');
    if (_token == null) return;
    isLoadingServices = true;
    notifyListeners();
    await _fetchServices();
    _servicesLoaded = true;
  }

  Future<void> refresh() async {
    _initialized = false;
    _productsLoaded = false;
    _servicesLoaded = false;
    products = [];
    services = [];
    clearAllSelections();
    lastResult = null;
    await _fetchCore();
  }

  /// Phase 1 only — branches + departments + categories.
  Future<void> _fetchCore({bool silent = false}) async {
    _token = await _sessionService.getToken(role: 'owner');
    if (_token == null) {
      error = 'Not authenticated. Please log in again.';
      notifyListeners();
      return;
    }

    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    await Future.wait([
      _fetchBranches(),
      _fetchDepartments(),
      _fetchCategories(),
    ]);

    if (!silent) {
      isLoading = false;
    }
    _initialized = true;
    notifyListeners();
  }

  /// Refresh core + any tabs that were already loaded (after add / branch sync).
  Future<void> _refreshLoaded({bool silent = true}) async {
    await _fetchCore(silent: silent);
    final futures = <Future<void>>[];
    if (_productsLoaded) {
      isLoadingProducts = true;
      notifyListeners();
      futures.add(_fetchProducts());
    }
    if (_servicesLoaded) {
      isLoadingServices = true;
      notifyListeners();
      futures.add(_fetchServices());
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  // ── Individual fetchers ───────────────────────────────────────────────────

  Future<void> _fetchBranches() async {
    try {
      final raw = await _repo.fetchBranchesList(_token!);
      final seen = <String>{};
      branches = raw
          .map((b) => MasterBranch(
                id: b['id']?.toString() ?? '',
                name: (b['name'] as String?) ?? '',
              ))
          .where((b) => b.id.isNotEmpty && seen.add(b.id))
          .toList();
    } catch (_) {
      // Non-critical — swallow so remaining tabs still load.
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final raw = await _repo.fetchMasterDeptsList(_token!);
      departments = raw
          .map((d) => MasterDepartment(
        id: d['id']?.toString() ?? '',
        name: (d['name'] as String?) ?? '',
        isActive: d['isActive'] != false,
        isAddedToCurrentBranch: d['inWorkshop'] == true,
      ))
          .where((d) => d.id.isNotEmpty)
          .toList();
    } catch (e) {
      error = 'Failed to load departments';
      debugPrint('[MasterCatalogVM] _fetchDepartments: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final raw = await _repo.fetchAllMasterCategoriesList(_token!);
      categories = raw
          .map((c) => MasterCategory(
        id: c['id']?.toString() ?? '',
        name: (c['name'] as String?) ?? '',
        type: (c['type'] as String?) ?? 'product',
        departmentId: c['departmentId']?.toString() ?? '',
        departmentName: (c['departmentName'] as String?) ?? '',
        isAddedToCurrentBranch: c['inWorkshop'] == true,
      ))
          .where((c) => c.id.isNotEmpty)
          .toList();
    } catch (e) {
      error = 'Failed to load categories';
      debugPrint('[MasterCatalogVM] _fetchCategories: $e');
    }
  }

  /// Fetches ALL master products (all pages) + already-added IDs in parallel,
  /// then merges them so isAddedToCurrentBranch is correct on every card.
  Future<void> _fetchProducts() async {
    try {
      final results = await Future.wait([
        _repo.fetchAllMasterProductsList(_token!),
        _repo.fetchMyProductIds(_token!),
      ]);

      final raw = results[0] as List<Map<String, dynamic>>;
      final addedIds = results[1] as Set<String>;

      products = raw
          .map((p) => MasterProduct(
        id: p['id']?.toString() ?? '',
        name: (p['name'] as String?) ?? '',
        sku: (p['sku'] as String?) ?? '',
        brandName: (p['brandName'] as String?) ?? '',
        departmentId: p['departmentId']?.toString() ?? '',
        departmentName: (p['departmentName'] as String?) ?? '',
        categoryName: (p['categoryName'] as String?) ?? '',
        unit: (p['unit'] as String?) ?? '',
        salePrice: _num(p['salePrice']),
        isAddedToCurrentBranch:
        addedIds.contains(p['id']?.toString() ?? ''),
      ))
          .where((p) => p.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[MasterCatalogVM] _fetchProducts: $e');
    } finally {
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Same pattern as _fetchProducts but for services.
  Future<void> _fetchServices() async {
    try {
      final results = await Future.wait([
        _repo.fetchAllMasterServicesList(_token!),
        _repo.fetchMyServiceIds(_token!),
      ]);

      final raw = results[0] as List<Map<String, dynamic>>;
      final addedIds = results[1] as Set<String>;

      services = raw
          .map((s) => MasterService(
        id: s['id']?.toString() ?? '',
        name: (s['name'] as String?) ?? '',
        departmentId: s['departmentId']?.toString() ?? '',
        departmentName: (s['departmentName'] as String?) ?? '',
        categoryName: (s['categoryName'] as String?) ?? '',
        salePrice: s['sellingPrice'] != null
            ? _num(s['sellingPrice'])
            : null,
        isAddedToCurrentBranch:
        addedIds.contains(s['id']?.toString() ?? ''),
      ))
          .where((s) => s.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[MasterCatalogVM] _fetchServices: $e');
    } finally {
      isLoadingServices = false;
      notifyListeners();
    }
  }

  // ── Add-to-branches actions (optimistic) ─────────────────────────────────

  Future<AddToBranchResult> addDeptsToWorkshop({
    required BranchScope scope,
    required List<String> branchIds,
    required Map<String, DeptCategorySelection> deptCategoryMap,
  }) async {
    if (_token == null) {
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Not authenticated']);
      notifyListeners();
      return lastResult!;
    }

    final targetBranchIds = scope == BranchScope.all
        ? branches.map((b) => b.id).toList()
        : branchIds;

    // Build categorySelections payload from DeptCategorySelection map
    final categorySelections = deptCategoryMap.entries.map((e) {
      final sel = e.value;
      dynamic catIds;
      switch (sel.mode) {
        case CategoryMode.all:
          catIds = 'all';
          break;
        case CategoryMode.none:
          catIds = <String>[];
          break;
        case CategoryMode.pick:
          catIds = sel.pickedCategoryIds.toList();
          break;
      }
      return <String, dynamic>{'departmentId': e.key, 'categoryIds': catIds};
    }).toList();

    try {
      final raw = await _repo.addDepartmentsToBranches(
        _token!,
        departmentIds: selectedDeptIds.toList(),
        categorySelections: categorySelections,
        branchIds: targetBranchIds,
      );

      final addedData   = (raw['added']   as Map<String, dynamic>?) ?? {};
      final addedDepts  = ((addedData['departments'] as List?) ?? []).cast<Map<String, dynamic>>();
      final addedCats   = ((addedData['categories']  as List?) ?? []).cast<Map<String, dynamic>>();
      final skippedList = ((raw['skipped'] as List?) ?? []).cast<Map<String, dynamic>>();

      final addedDeptIds = addedDepts.map((d) => d['itemId']?.toString() ?? '').toSet();
      final addedCatIds  = addedCats.map((c)  => c['itemId']?.toString() ?? '').toSet();
      final skippedCount = skippedList.where((s) => s['kind'] == 'department').length;

      for (int i = 0; i < departments.length; i++) {
        if (addedDeptIds.contains(departments[i].id)) {
          final d = departments[i];
          departments[i] = MasterDepartment(
            id: d.id, name: d.name, parentLabel: d.parentLabel,
            isActive: d.isActive, isAddedToCurrentBranch: true,
          );
        }
      }
      for (int i = 0; i < categories.length; i++) {
        if (addedCatIds.contains(categories[i].id)) {
          final c = categories[i];
          categories[i] = MasterCategory(
            id: c.id, name: c.name, type: c.type,
            departmentId: c.departmentId, departmentName: c.departmentName,
            isAddedToCurrentBranch: true,
          );
        }
      }

      final branchNames = scope == BranchScope.all
          ? 'All branches'
          : branches.where((b) => targetBranchIds.contains(b.id)).map((b) => b.name).join(', ');

      final details = <String>[];
      if (addedDepts.isNotEmpty) {
        details.add('$branchNames: ${addedDepts.length} department${addedDepts.length != 1 ? "s" : ""} added');
      }
      if (addedCats.isNotEmpty) {
        details.add('${addedCats.length} categor${addedCats.length != 1 ? "ies" : "y"} also added');
      }

      selectedDeptIds.clear();
      lastResult = AddToBranchResult(
          added: addedDepts.length, skipped: skippedCount, details: details);
      notifyListeners();
      // Refresh all tabs so isAddedToCurrentBranch is up-to-date everywhere
      unawaited(_refreshLoaded(silent: true));
      return lastResult!;
    } catch (e) {
      debugPrint('[MasterCatalogVM] addDeptsToWorkshop: $e');
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Failed: $e']);
      notifyListeners();
      return lastResult!;
    }
  }

  Future<AddToBranchResult> addCategoriesToWorkshop({
    required BranchScope scope,
    required List<String> branchIds,
  }) async {
    if (_token == null) {
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Not authenticated']);
      notifyListeners();
      return lastResult!;
    }

    final targetBranchIds = scope == BranchScope.all
        ? branches.map((b) => b.id).toList()
        : branchIds;

    try {
      final raw = await _repo.addCategoriesToBranches(
        _token!,
        categoryIds: selectedCategoryIds.toList(),
        branchIds: targetBranchIds,
      );

      final addedData   = (raw['added']   as Map<String, dynamic>?) ?? {};
      final addedCats   = ((addedData['categories'] as List?) ?? []).cast<Map<String, dynamic>>();
      final skippedList = ((raw['skipped'] as List?) ?? []).cast<Map<String, dynamic>>();

      final addedCatIds  = addedCats.map((c) => c['itemId']?.toString() ?? '').toSet();
      final skippedCount = skippedList.where((s) => s['kind'] == 'category').length;

      for (int i = 0; i < categories.length; i++) {
        if (addedCatIds.contains(categories[i].id)) {
          final c = categories[i];
          categories[i] = MasterCategory(
            id: c.id, name: c.name, type: c.type,
            departmentId: c.departmentId, departmentName: c.departmentName,
            isAddedToCurrentBranch: true,
          );
        }
      }

      final branchNames = scope == BranchScope.all
          ? 'All branches'
          : branches.where((b) => targetBranchIds.contains(b.id)).map((b) => b.name).join(', ');

      final details = <String>[];
      if (addedCats.isNotEmpty) {
        details.add('$branchNames: ${addedCats.length} categor${addedCats.length != 1 ? "ies" : "y"} added');
      }

      selectedCategoryIds.clear();
      lastResult = AddToBranchResult(
          added: addedCats.length, skipped: skippedCount, details: details);
      notifyListeners();
      // Refresh all tabs so isAddedToCurrentBranch is up-to-date everywhere
      unawaited(_refreshLoaded(silent: true));
      return lastResult!;
    } catch (e) {
      debugPrint('[MasterCatalogVM] addCategoriesToWorkshop: $e');
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Failed: $e']);
      notifyListeners();
      return lastResult!;
    }
  }


  Future<AddToBranchResult> addProductsToWorkshop({
    required BranchScope scope,
    required List<String> branchIds,
    required Map<String, int> criticalStockMap,
    required Map<String, int> openingQtyMap,
  }) async {
    if (_token == null) {
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Not authenticated']);
      notifyListeners();
      return lastResult!;
    }

    // Resolve branch IDs: if scope=all use all branch ids
    final targetBranchIds = scope == BranchScope.all
        ? branches.map((b) => b.id).toList()
        : branchIds;

    // Build items list with critical stock + opening qty
    final items = selectedProductIds.map((pid) => {
      'productId': pid,
      'openingQty': openingQtyMap[pid] ?? 0,
      'criticalStockPoint': criticalStockMap[pid] ?? 0,
    }).toList();

    try {
      final raw = await _repo.addProductsToBranches(
        _token!,
        items: items,
        branchIds: targetBranchIds,
      );

      final addedData = (raw['added'] as Map<String, dynamic>?) ?? {};
      final addedProducts = ((addedData['products'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
      final skippedList = ((raw['skipped'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

      final int addedCount = addedProducts.length;
      final int skippedCount = skippedList
          .where((s) => s['kind'] == 'product')
          .length;

      // Optimistically mark products as added in the local list
      final addedIds = addedProducts
          .map((p) => p['itemId']?.toString() ?? '')
          .toSet();
      for (int i = 0; i < products.length; i++) {
        if (addedIds.contains(products[i].id)) {
          final p = products[i];
          products[i] = MasterProduct(
            id: p.id, name: p.name, sku: p.sku, brandName: p.brandName,
            departmentId: p.departmentId, departmentName: p.departmentName,
            categoryName: p.categoryName, unit: p.unit, salePrice: p.salePrice,
            isAddedToCurrentBranch: true,
          );
        }
      }

      final branchNames = scope == BranchScope.all
          ? 'All branches'
          : branches.where((b) => targetBranchIds.contains(b.id)).map((b) => b.name).join(', ');

      final details = <String>[];
      if (addedCount > 0) {
        details.add('$branchNames: $addedCount product${addedCount != 1 ? 's' : ''} added');
      }

      selectedProductIds.clear();
      clearProductDeps();
      lastResult = AddToBranchResult(added: addedCount, skipped: skippedCount, details: details);
      notifyListeners();
      // Refresh all tabs so isAddedToCurrentBranch is up-to-date everywhere
      unawaited(_refreshLoaded(silent: true));
      return lastResult!;
    } catch (e) {
      debugPrint('[MasterCatalogVM] addProductsToWorkshop: $e');
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Failed: ${e.toString()}']);
      notifyListeners();
      return lastResult!;
    }
  }

  Future<AddToBranchResult> addServicesToWorkshop({
    required BranchScope scope,
    required List<String> branchIds,
  }) async {
    if (_token == null) {
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Not authenticated']);
      notifyListeners();
      return lastResult!;
    }

    final targetBranchIds = scope == BranchScope.all
        ? branches.map((b) => b.id).toList()
        : branchIds;

    try {
      final raw = await _repo.addServicesToBranches(
        _token!,
        serviceIds: selectedServiceIds.toList(),
        branchIds: targetBranchIds,
      );

      final addedData = (raw['added'] as Map<String, dynamic>?) ?? {};
      final addedServices = ((addedData['services'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
      final skippedList = ((raw['skipped'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

      final int addedCount = addedServices.length;
      final int skippedCount = skippedList
          .where((s) => s['kind'] == 'service')
          .length;

      // Optimistically mark services as added in the local list
      final addedIds = addedServices
          .map((s) => s['itemId']?.toString() ?? '')
          .toSet();
      for (int i = 0; i < services.length; i++) {
        if (addedIds.contains(services[i].id)) {
          final s = services[i];
          services[i] = MasterService(
            id: s.id, name: s.name, departmentId: s.departmentId,
            departmentName: s.departmentName, categoryName: s.categoryName,
            salePrice: s.salePrice, isAddedToCurrentBranch: true,
          );
        }
      }

      final branchNames = scope == BranchScope.all
          ? 'All branches'
          : branches.where((b) => targetBranchIds.contains(b.id)).map((b) => b.name).join(', ');

      final details = <String>[];
      if (addedCount > 0) {
        details.add('$branchNames: $addedCount service${addedCount != 1 ? 's' : ''} added');
      }

      selectedServiceIds.clear();
      clearServiceDeps();
      lastResult = AddToBranchResult(added: addedCount, skipped: skippedCount, details: details);
      notifyListeners();
      // Refresh all tabs so isAddedToCurrentBranch is up-to-date everywhere
      unawaited(_refreshLoaded(silent: true));
      return lastResult!;
    } catch (e) {
      debugPrint('[MasterCatalogVM] addServicesToWorkshop: $e');
      lastResult = AddToBranchResult(added: 0, skipped: 0, details: ['Failed: ${e.toString()}']);
      notifyListeners();
      return lastResult!;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}