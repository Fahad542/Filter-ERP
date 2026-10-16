import 'package:flutter/foundation.dart';

import '../data/repositories/pos_repository.dart';
import '../models/department_model.dart';
import '../models/pos_product_model.dart';
import '../models/takeaway_models.dart';
import 'catalog_local_database.dart';
import 'session_service.dart';

/// Result of a catalog sync (departments and/or products from API → SQLite).
class CatalogSyncResult {
  final bool success;
  final String message;
  final int departmentsCount;
  final int productsCount;
  final DateTime? syncedAt;

  const CatalogSyncResult({
    required this.success,
    required this.message,
    this.departmentsCount = 0,
    this.productsCount = 0,
    this.syncedAt,
  });
}

/// Fetches departments + branch catalog from API and persists to [CatalogLocalDatabase].
class CatalogSyncService extends ChangeNotifier {
  CatalogSyncService({
    required PosRepository posRepository,
    required SessionService sessionService,
    CatalogLocalDatabase? database,
  })  : _posRepository = posRepository,
        _sessionService = sessionService,
        _db = database ?? CatalogLocalDatabase.instance;

  final PosRepository _posRepository;
  final SessionService _sessionService;
  final CatalogLocalDatabase _db;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  void _setSyncing(bool value) {
    if (_isSyncing == value) return;
    _isSyncing = value;
    // Defer so listeners in app bars being torn down (IndexedStack / store
    // closing reconcile) are not rebuilt mid-deactivation.
    Future.microtask(() {
      if (hasListeners) notifyListeners();
    });
  }

  Future<({String workshopId, String branchId, String token})?> _sessionScope() async {
    final token = await _sessionService.getToken();
    final user = await _sessionService.getUser();
    if (token == null || user == null || user.workshopId == null) {
      return null;
    }
    return (
      workshopId: user.workshopId!,
      branchId: user.branchId?.trim() ?? '',
      token: token,
    );
  }

  /// Departments + full products/services catalog (no department filter).
  Future<CatalogSyncResult> syncAll() async {
    if (_isSyncing) {
      return const CatalogSyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }
    _setSyncing(true);
    try {
      final dept = await syncDepartments();
      if (!dept.success) return dept;
      final prod = await syncProducts();
      if (!prod.success) return prod;
      return CatalogSyncResult(
        success: true,
        message: 'Catalog synced',
        departmentsCount: dept.departmentsCount,
        productsCount: prod.productsCount,
        syncedAt: prod.syncedAt,
      );
    } finally {
      _setSyncing(false);
    }
  }

  Future<CatalogSyncResult> syncDepartments() async {
    final scope = await _sessionScope();
    if (scope == null) {
      return const CatalogSyncResult(
        success: false,
        message: 'Not signed in',
      );
    }
    try {
      final response = await _posRepository.getDepartments(scope.token);
      if (!response.success) {
        return const CatalogSyncResult(
          success: false,
          message: 'Failed to load departments from server',
        );
      }
      await _db.saveDepartments(
        workshopId: scope.workshopId,
        branchId: scope.branchId,
        departments: response.departments,
      );
      return CatalogSyncResult(
        success: true,
        message: 'Departments saved',
        departmentsCount: response.departments.length,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return CatalogSyncResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Full branch catalog — updates stock after invoice.
  Future<CatalogSyncResult> syncProducts() async {
    final scope = await _sessionScope();
    if (scope == null) {
      return const CatalogSyncResult(
        success: false,
        message: 'Not signed in',
      );
    }
    try {
      final response = await _posRepository.getProducts(
        scope.workshopId,
        scope.token,
        branchId: scope.branchId.isNotEmpty ? scope.branchId : null,
      );
      if (!response.success) {
        return const CatalogSyncResult(
          success: false,
          message: 'Failed to load products from server',
        );
      }
      await _db.saveProductsCatalog(
        workshopId: scope.workshopId,
        branchId: scope.branchId,
        response: response,
      );
      final snapshot = LocalCatalogSnapshot.fromResponse(response);
      return CatalogSyncResult(
        success: true,
        message: 'Products & services saved',
        productsCount: snapshot.products.length,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return CatalogSyncResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<List<Department>> loadDepartmentsLocal() async {
    final scope = await _sessionScope();
    if (scope == null) return const [];
    return _db.loadDepartments(
      workshopId: scope.workshopId,
      branchId: scope.branchId,
    );
  }

  Future<LocalCatalogSnapshot?> loadProductsLocal({String? departmentId}) async {
    final scope = await _sessionScope();
    if (scope == null) return null;
    final cached = await _db.loadProductsCatalog(
      workshopId: scope.workshopId,
      branchId: scope.branchId,
    );
    if (cached == null) return null;
    return LocalCatalogSnapshot.fromResponse(
      cached,
      departmentId: departmentId,
    );
  }

  Future<void> clearLocalCache() async {
    await _db.clearAll();
  }

  /// Build takeaway catalog UI model from SQLite (same data as inventory sync).
  /// Takeaway sells physical inventory only — services are excluded (same rule as PO).
  Future<TakeawayCatalogData?> buildTakeawayCatalogFromLocal() async {
    final departments = await loadDepartmentsLocal();
    final snap = await loadProductsLocal();
    if (snap == null || snap.products.isEmpty) return null;

    final productRows =
        snap.products.where((p) => !p.isServiceType).toList();
    if (productRows.isEmpty) return null;

    final deptNames = <String, String>{
      for (final d in departments) d.id: d.name,
    };

    final byCategory = <String, List<TakeawayProduct>>{};
    final uncategorized = <TakeawayProduct>[];
    final deptIdsWithProducts = <String>{};

    for (final p in productRows) {
      final tp = _takeawayProductFromPos(p, deptNames);
      final deptId = tp.department.id;
      if (deptId.isNotEmpty) deptIdsWithProducts.add(deptId);
      final cat = p.categoryName?.trim() ?? '';
      if (cat.isNotEmpty) {
        byCategory.putIfAbsent(cat, () => []).add(tp);
      } else {
        uncategorized.add(tp);
      }
    }

    final categories = byCategory.entries
        .map(
          (e) => TakeawayCategoryGroup(
            id: e.key,
            name: e.key,
            products: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final takeawayDepts = departments
        .where((d) => deptIdsWithProducts.contains(d.id))
        .map((d) => TakeawayDepartment(id: d.id, name: d.name))
        .toList();

    return TakeawayCatalogData(
      currency: 'SAR',
      vatPercentDefault: 15,
      departments: takeawayDepts,
      categories: categories,
      uncategorizedProducts: uncategorized,
    );
  }

  static TakeawayProduct _takeawayProductFromPos(
    PosProduct p,
    Map<String, String> deptNames,
  ) {
    final deptId = p.departmentId?.trim() ?? '';
    final deptName = p.departmentName?.trim().isNotEmpty == true
        ? p.departmentName!.trim()
        : (deptNames[deptId] ?? '');
    final catName = p.categoryName?.trim();
    return TakeawayProduct(
      id: p.id,
      name: p.name,
      nameArabic: p.productNameArabic,
      unit: p.unit,
      salePrice: p.priceInclVat,
      salePriceBeforeVat: p.priceBeforeVat,
      purchasePrice: p.purchasePrice ?? 0,
      allowDecimalQty: p.allowDecimalQty,
      allowMinusQty: p.allowMinusQty,
      isPriceEditable: p.isPriceEditable,
      minPriceEditable: p.minPriceEditable,
      isActive: true,
      qtyOnHand: p.stock.toDouble(),
      department: TakeawayRef(id: deptId, name: deptName),
      category: catName != null && catName.isNotEmpty
          ? TakeawayRef(id: catName, name: catName)
          : null,
    );
  }
}
