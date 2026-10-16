// ─── inventory_management_v2.dart ────────────────────────────────────────────
// Complete Inventory Management screen — Flutter
// Matches web panel UX: KPI cards, Stock table, UOM Profiles tab, all dialogs.
// Self-contained: dummy data + ViewModel + full UI.
// Requires: provider package in pubspec.yaml
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_branch_reload_registrar.dart';
import '../owner_shell.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../widgets/owner_shimmer.dart';
import 'inventory_stock_tab.dart';
import 'inventory_uom_profiles_tab.dart';
import 'inventory_value_tab.dart';


// ─── Dummy Data ───────────────────────────────────────────────────────────────

const kInventoryUnits = ['pcs', 'Liter', 'liter', 'kg', 'ml', 'Set', 'piece', 'Box'];

final kInventoryProducts = <InvProduct>[
  InvProduct(id: 'p01', name: 'Oil Filter Changan Original 1012010', sku: 'CHI-014', department: 'Oil Change Department', departmentId: 'd1', category: 'Chinese Filters', openingStock: 1111, currentStock: 1111, criticalStock: 0, unit: 'pcs', warehouseUnit: 'pcs', conversionFactor: 1, salePrice: 30, purchasePrice: 26.09, isActive: true),
  InvProduct(id: 'p02', name: 'OIL FILTER ISUZU 71 DIESEL corner', sku: 'FLT-478', department: 'Oil Change Department', departmentId: 'd1', category: 'Other Oil Filters', openingStock: 1111, currentStock: 1111, criticalStock: 0, unit: 'pcs', warehouseUnit: 'pcs', conversionFactor: 1, salePrice: 25, purchasePrice: 21.74, isActive: true),
  InvProduct(id: 'p03', name: 'Petromin Diesel Bermil 20W50', sku: 'PTM-001', department: 'Oil Change Department', departmentId: 'd1', category: 'Petromin Oil', openingStock: 1111, currentStock: 1111, criticalStock: 0, unit: 'Liter', warehouseUnit: 'Box', conversionFactor: 12, salePrice: 13, purchasePrice: 10, isActive: true, uomProfileId: 'u1'),
  InvProduct(id: 'p04', name: 'OIL FILTER Land cruiser Diesel 30002-8T', sku: 'FIL-001', department: 'Oil Change Department', departmentId: 'd1', category: 'TOYOTA Oil', openingStock: 1111, currentStock: 1111, criticalStock: 0, unit: 'pcs', warehouseUnit: 'pcs', conversionFactor: 1, salePrice: 65, purchasePrice: 47, isActive: true),
  InvProduct(id: 'p05', name: 'Engine Oil 5W30 Full Synthetic', sku: 'ENG-005', department: 'Oil Change Department', departmentId: 'd1', category: 'Other Oils', openingStock: 500, currentStock: 8, criticalStock: 10, unit: 'Liter', warehouseUnit: 'Liter', conversionFactor: 1, salePrice: 45, purchasePrice: 30, isActive: true),
  InvProduct(id: 'p06', name: 'Air Filter Premium Grade', sku: 'AIR-002', department: 'LIQUIDATION SERVICES DEPARTMENT', departmentId: 'd2', category: 'Misc Products', openingStock: 200, currentStock: 3, criticalStock: 5, unit: 'pcs', warehouseUnit: 'pcs', conversionFactor: 1, salePrice: 22, purchasePrice: 14, isActive: false),
  InvProduct(id: 'p07', name: 'Gear Oil SAE 90', sku: 'GER-011', department: 'Oil Change Department', departmentId: 'd1', category: 'Gear Oil', openingStock: 300, currentStock: 120, criticalStock: 20, unit: 'Liter', warehouseUnit: 'Liter', conversionFactor: 1, salePrice: 18, purchasePrice: 11, isActive: true),
  InvProduct(id: 'p08', name: 'AC DELCO 0W20', sku: 'OIL-125', department: 'Oil Change Department', departmentId: 'd1', category: 'Other Oils', openingStock: 1111, currentStock: 1111, criticalStock: 0, unit: 'Liter', warehouseUnit: 'Box', conversionFactor: 12, salePrice: 35, purchasePrice: 28.75, isActive: true, uomProfileId: 'u1'),
  InvProduct(id: 'p09', name: 'TOYOTA OIL Diesel 5W30', sku: 'OIL-120', department: 'Oil Change Department', departmentId: 'd1', category: 'TOYOTA Oil', openingStock: 1111, currentStock: 1111, criticalStock: 0, unit: 'Liter', warehouseUnit: 'Box', conversionFactor: 12, salePrice: 35, purchasePrice: 28.75, isActive: true, uomProfileId: 'u1'),
  InvProduct(id: 'p10', name: 'Brake Fluid DOT 4', sku: 'BRK-003', department: 'LIQUIDATION SERVICES DEPARTMENT', departmentId: 'd2', category: 'Misc Products', openingStock: 50, currentStock: 50, criticalStock: 5, unit: 'ml', warehouseUnit: 'ml', conversionFactor: 1, salePrice: 12, purchasePrice: 8, isActive: true),
];

final kInventoryUomProfiles = <UomProfile>[
  UomProfile(id: 'u1', name: '1 box to 12 liters', warehouseUnit: 'Box', workshopUnit: 'Liter', factor: 12, notes: 'Standard oil boxes', linkedProductIds: ['p03', 'p08', 'p09']),
];

const kInventoryDepartments = [
  {'id': 'd1', 'name': 'Oil Change Department'},
  {'id': 'd2', 'name': 'LIQUIDATION SERVICES DEPARTMENT'},
  {'id': 'd3', 'name': 'Tea & Refreshment Department'},
];

// ─── View Model ───────────────────────────────────────────────────────────────

class InventoryV2ViewModel extends ChangeNotifier {
  final OwnerRepository _repo;
  final SessionService _session;
  final OwnerDataService? _ownerData;
  String? _lastSyncedBranchId;

  InventoryV2ViewModel({
    OwnerRepository? repo,
    SessionService? session,
    OwnerDataService? ownerDataService,
  })  : _repo = repo ?? OwnerRepository(),
        _session = session ?? SessionService(),
        _ownerData = ownerDataService {
    _selectedBranchId = _ownerData?.selectedBranchId;
    _lastSyncedBranchId = _selectedBranchId;
    _ownerData?.addListener(_onOwnerDataChanged);
    _init();
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerData?.selectedBranchId; // null = All Branches
    if (!force && next == _lastSyncedBranchId) return;
    _lastSyncedBranchId = next;
    _selectedBranchId = next;
    _selectedIds.clear();
    _allProducts.clear();
    notifyListeners();
    await _fetchBranchProducts();
  }

  // ── Session helpers ───────────────────────────────────────────────────────
  String? _workshopId;
  String? _token;

  Future<bool> _ensureSession() async {
    _token ??= await _session.getToken(role: 'owner');
    if (_workshopId == null) {
      final user = await _session.getUser(role: 'owner');
      _workshopId = user?.workshopId ?? '8';
    }
    return _token != null;
  }

  // ── Branch ────────────────────────────────────────────────────────────────
  List<Map<String, String>> _branches = [];
  List<Map<String, String>> get branches => _branches;

  String? _selectedBranchId;
  String get selectedBranchId => _selectedBranchId ?? '';
  bool get isAllBranches =>
      _selectedBranchId == null || _selectedBranchId!.trim().isEmpty;

  void selectBranch(String id) {
    if (_selectedBranchId == id) return;
    _selectedBranchId = id;
    _lastSyncedBranchId = id;
    _selectedIds.clear();
    _allProducts.clear();
    _lowStockBranchAlerts = [];
    notifyListeners();
    _fetchBranchProducts();
  }

  void selectAllBranches() {
    if (_selectedBranchId == null) {
      _fetchBranchProducts();
      return;
    }
    _selectedBranchId = null;
    _lastSyncedBranchId = null;
    _selectedIds.clear();
    _allProducts.clear();
    _lowStockBranchAlerts = [];
    notifyListeners();
    _fetchBranchProducts();
  }

  // ── Loading states ────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _ensureSession();
      await _loadBranches();
      await _fetchBranchProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBranches() async {
    try {
      final res = await _repo.getBranches(_token!);
      if (res != null && res['success'] == true && res['branches'] != null) {
        final list = (res['branches'] as List).map<Map<String, String>>((b) => {
          'id': b['id']?.toString() ?? '',
          'name': b['name']?.toString() ?? '',
        }).where((b) => b['id']!.isNotEmpty).toList();
        _branches = list;
        final globalId = _ownerData?.selectedBranchId;
        if (globalId != null &&
            globalId.isNotEmpty &&
            list.any((b) => b['id'] == globalId)) {
          _selectedBranchId = globalId;
          _lastSyncedBranchId = globalId;
        } else {
          // Header "All Branches" → keep null and load workshop-wide sum.
          _selectedBranchId = null;
          _lastSyncedBranchId = null;
        }
      }
    } catch (_) {}
  }

  // ── Products ──────────────────────────────────────────────────────────────
  List<InvProduct> _allProducts = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearch(String v) {
    _searchQuery = v.toLowerCase().trim();
    _selectedIds.clear();
    notifyListeners();
  }

  String? _deptFilter;
  String? get deptFilter => _deptFilter;
  void setDeptFilter(String? v) {
    _deptFilter = v;
    _selectedIds.clear();
    notifyListeners();
  }

  // Expose full unfiltered list for dept dropdown
  List<InvProduct> get allProducts => List.unmodifiable(_allProducts);

  /// Per-branch low-stock alerts when viewing All Branches (union list under-counts).
  List<InvProduct> _lowStockBranchAlerts = [];

  bool _lowStockOnly = false;
  bool get lowStockOnly => _lowStockOnly;
  void toggleLowStock(bool v) {
    _lowStockOnly = v;
    _selectedIds.clear();
    notifyListeners();
  }

  /// Products that count toward Low Stock KPI (per-branch when All Branches).
  List<InvProduct> get lowStockProducts => isAllBranches
      ? List<InvProduct>.unmodifiable(_lowStockBranchAlerts)
      : _allProducts.where((p) => p.isLowStock).toList();

  List<InvProduct> get filteredProducts {
    // All Branches + Low Stock → per-branch alerts (union under-counts).
    var list = (isAllBranches && _lowStockOnly)
        ? List<InvProduct>.from(_lowStockBranchAlerts)
        : List<InvProduct>.from(_allProducts);

    if (_deptFilter != null) {
      list = list.where((p) => p.departmentId == _deptFilter).toList();
    }
    if (_lowStockOnly && !isAllBranches) {
      list = list.where((p) => p.isLowStock).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
      p.name.toLowerCase().contains(_searchQuery) ||
          p.sku.toLowerCase().contains(_searchQuery) ||
          (p.branchName?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }
    return list;
  }

  /// Fire-and-forget Arabic warmup for visible inventory labels (same as POS).
  void _precacheProductTranslations() {
    final texts = <String>[];
    for (final p in _allProducts) {
      if (p.name.trim().isNotEmpty) texts.add(p.name);
      if (p.department.trim().isNotEmpty) texts.add(p.department);
      if (p.category.trim().isNotEmpty) texts.add(p.category);
    }
    for (final p in _lowStockBranchAlerts) {
      if (p.name.trim().isNotEmpty) texts.add(p.name);
      if (p.branchName != null && p.branchName!.trim().isNotEmpty) {
        texts.add(p.branchName!);
      }
    }
    LocalizedApiText.precache(texts, 'ar');
  }

  String? _resolveBranchId([String? productBranchId]) {
    final fromProduct = productBranchId?.trim();
    if (fromProduct != null && fromProduct.isNotEmpty) return fromProduct;
    final selected = _selectedBranchId?.trim();
    if (selected != null && selected.isNotEmpty) return selected;
    return null;
  }

  /// Flatten nested staff/catalog product payloads (categories / uncategorized).
  static List<Map<String, dynamic>> _extractProductMaps(dynamic res) {
    if (res == null) return const [];
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res is! Map) return const [];
    final map = Map<String, dynamic>.from(res);
    final out = <Map<String, dynamic>>[];

    void addAll(dynamic list) {
      if (list is! List) return;
      for (final e in list) {
        if (e is Map) out.add(Map<String, dynamic>.from(e));
      }
    }

    addAll(map['uncategorizedProducts'] ?? map['uncategorized_products']);
    final categories = map['categories'];
    if (categories is List) {
      for (final c in categories) {
        if (c is! Map) continue;
        final cm = Map<String, dynamic>.from(c);
        final subs = cm['subCategories'] ?? cm['sub_categories'];
        if (subs is List) {
          for (final s in subs) {
            if (s is! Map) continue;
            addAll(Map<String, dynamic>.from(s)['products']);
          }
        }
        addAll(cm['productsWithoutSub'] ?? cm['products_without_sub']);
        addAll(cm['products']);
      }
    }

    if (out.isNotEmpty) return out;

    final data = map['data'];
    if (data is Map) {
      addAll(data['products'] ?? data['items'] ?? data['rows']);
      if (out.isNotEmpty) return out;
    }
    addAll(map['products'] ?? map['items'] ?? map['rows']);
    if (data is List) addAll(data);
    return out;
  }

  // Prefer workshop-staff products (same as web Manage Inventory).
  // All Branches → union for totals + per-branch low-stock alerts for KPI/filter.
  Future<void> _fetchBranchProducts({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final ok = await _ensureSession();
      if (!ok) return;

      List<Map<String, dynamic>> raw = [];

      if (isAllBranches) {
        try {
          final staffRes = await _repo.getWorkshopStaffProducts(
            _token!,
            allBranches: true,
            workshopId: _workshopId,
          );
          raw = _extractProductMaps(staffRes);
        } catch (_) {}
        _allProducts = raw
            .map(InvProduct.fromBranchJson)
            .where((p) => p.id.isNotEmpty)
            .toList();
        _lowStockBranchAlerts = await _scanLowStockAcrossBranches();
        _precacheProductTranslations();
      } else {
        _lowStockBranchAlerts = [];
        try {
          final staffRes = await _repo.getWorkshopStaffBranchProducts(
            _token!,
            _selectedBranchId!,
            workshopId: _workshopId,
          );
          raw = _extractProductMaps(staffRes);
        } catch (_) {}

        if (raw.isEmpty) {
          try {
            final catalogRes =
                await _repo.getBranchProducts(_token!, _selectedBranchId!);
            raw = _extractProductMaps(catalogRes);
          } catch (_) {}
        }

        _allProducts = raw
            .map(InvProduct.fromBranchJson)
            .where((p) => p.id.isNotEmpty)
            .toList();
        _precacheProductTranslations();
      }
    } catch (_) {
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Per-branch low stock (union under-counts when stock is split across sites).
  Future<List<InvProduct>> _scanLowStockAcrossBranches() async {
    if (_branches.isEmpty) return const [];
    final token = _token;
    if (token == null) return const [];

    final perBranch = await Future.wait(_branches.map((b) async {
      final bid = b['id'] ?? '';
      final bname = b['name'] ?? '';
      if (bid.isEmpty) return <InvProduct>[];

      List<Map<String, dynamic>> raw = [];
      try {
        final res = await _repo.getWorkshopStaffBranchProducts(
          token,
          bid,
          workshopId: _workshopId,
        );
        raw = _extractProductMaps(res);
      } catch (_) {}
      if (raw.isEmpty) {
        try {
          raw = _extractProductMaps(await _repo.getBranchProducts(token, bid));
        } catch (_) {}
      }

      return raw
          .map(InvProduct.fromBranchJson)
          .where((p) => p.id.isNotEmpty && p.isLowStock)
          .map((p) => p.copyWithBranch(branchId: bid, branchName: bname))
          .toList();
    }));

    final out = <InvProduct>[];
    for (final list in perBranch) {
      out.addAll(list);
    }
    out.sort((a, b) {
      if (a.currentStock <= 0 && b.currentStock > 0) return -1;
      if (b.currentStock <= 0 && a.currentStock > 0) return 1;
      return (b.criticalStock - b.currentStock)
          .compareTo(a.criticalStock - a.currentStock);
    });
    return out;
  }

  Future<void> refresh() => _fetchBranchProducts();

  // ── Selection ─────────────────────────────────────────────────────────────
  final Set<String> _selectedIds = {};
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(List<InvProduct> products) {
    for (final p in products) _selectedIds.add(p.rowKey);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  // ── UOM Profiles (local — from workshop-catalog/uom-profiles) ─────────────
  final List<UomProfile> uomProfiles = List.from(kInventoryUomProfiles);

  void addUomProfile(UomProfile p) {
    uomProfiles.add(p);
    notifyListeners();
  }

  void deleteUomProfile(String id) {
    uomProfiles.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void linkProfile(String productId, String? profileId) {
    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    for (final prof in uomProfiles) prof.linkedProductIds.remove(productId);
    final old = _allProducts[idx];
    _allProducts[idx] = InvProduct(
      id: old.id, name: old.name, sku: old.sku,
      department: old.department, departmentId: old.departmentId,
      category: old.category, openingStock: old.openingStock,
      currentStock: old.currentStock, criticalStock: old.criticalStock,
      unit: old.unit,
      warehouseUnit: profileId != null
          ? uomProfiles.firstWhere((p) => p.id == profileId).warehouseUnit
          : old.warehouseUnit,
      conversionFactor: profileId != null
          ? uomProfiles.firstWhere((p) => p.id == profileId).factor
          : 1,
      salePrice: old.salePrice, purchasePrice: old.purchasePrice,
      isActive: old.isActive, uomProfileId: profileId,
    );
    if (profileId != null) {
      final prof = uomProfiles.firstWhere((p) => p.id == profileId);
      if (!prof.linkedProductIds.contains(productId)) {
        prof.linkedProductIds.add(productId);
      }
    }
    notifyListeners();
  }

  // ── UOM — real API (PATCH branch product) ─────────────────────────────────
  // Called from _EditUomConversionDialog after user saves
  Future<bool> saveBranchProductUom({
    required BuildContext context,
    required String productId,
    required String warehouseUnit,
    required String workshopUnit,
    required int conversionFactor,
  }) async {
    if (_selectedBranchId == null) return false;
    final ok = await _ensureSession();
    if (!ok) return false;
    try {
      final res = await _repo.patchBranchProduct(
        token: _token!,
        branchId: _selectedBranchId!,
        productId: productId,
        workshopId: _workshopId!,
        data: {
          'warehouseUnit': warehouseUnit,
          'workshopUnit': workshopUnit,
          'conversionFactor': conversionFactor,
        },
      );
      if (res != null && res['success'] == true) {
        // Update locally so UI reflects immediately
        final idx = _allProducts.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          final old = _allProducts[idx];
          _allProducts[idx] = InvProduct(
            id: old.id, name: old.name, sku: old.sku,
            department: old.department, departmentId: old.departmentId,
            category: old.category, openingStock: old.openingStock,
            currentStock: old.currentStock, criticalStock: old.criticalStock,
            unit: workshopUnit, warehouseUnit: warehouseUnit,
            conversionFactor: conversionFactor,
            salePrice: old.salePrice, purchasePrice: old.purchasePrice,
            isActive: old.isActive, uomProfileId: old.uomProfileId,
          );
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // bulkSetUom — local only (Bulk UOM dialog; no branch-level API for bulk yet)
  void bulkSetUom({
    required List<String> productIds,
    required String warehouseUnit,
    required int factor,
    required String workshopUnit,
  }) {
    for (final id in productIds) {
      final idx = _allProducts.indexWhere((p) => p.id == id);
      if (idx == -1) continue;
      final old = _allProducts[idx];
      _allProducts[idx] = InvProduct(
        id: old.id, name: old.name, sku: old.sku,
        department: old.department, departmentId: old.departmentId,
        category: old.category, openingStock: old.openingStock,
        currentStock: old.currentStock, criticalStock: old.criticalStock,
        unit: workshopUnit, warehouseUnit: warehouseUnit,
        conversionFactor: factor,
        salePrice: old.salePrice, purchasePrice: old.purchasePrice,
        isActive: old.isActive,
      );
    }
    _selectedIds.clear();
    notifyListeners();
  }

  void _patchLocalProduct({
    required String productId,
    String? branchId,
    int? currentStock,
    int? criticalStock,
  }) {
    InvProduct update(InvProduct old) => InvProduct(
          id: old.id,
          name: old.name,
          sku: old.sku,
          department: old.department,
          departmentId: old.departmentId,
          category: old.category,
          openingStock: old.openingStock,
          currentStock: currentStock ?? old.currentStock,
          criticalStock: criticalStock ?? old.criticalStock,
          unit: old.unit,
          warehouseUnit: old.warehouseUnit,
          conversionFactor: old.conversionFactor,
          salePrice: old.salePrice,
          purchasePrice: old.purchasePrice,
          isActive: old.isActive,
          uomProfileId: old.uomProfileId,
          branchId: old.branchId,
          branchName: old.branchName,
        );

    final idx = _allProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) _allProducts[idx] = update(_allProducts[idx]);

    final bid = branchId?.trim();
    for (var i = 0; i < _lowStockBranchAlerts.length; i++) {
      final p = _lowStockBranchAlerts[i];
      if (p.id != productId) continue;
      if (bid != null && bid.isNotEmpty && p.branchId != bid) continue;
      _lowStockBranchAlerts[i] = update(p);
    }
    _lowStockBranchAlerts =
        _lowStockBranchAlerts.where((p) => p.isLowStock).toList();
  }

  // ── Critical Stock — real API ─────────────────────────────────────────────
  // PATCH /workshop-catalog/branches/{branchId}/products/{productId}?workshopId=...
  // Body: { "criticalStockPoint": N }
  Future<bool> saveCriticalStock(
    String productId,
    int level, {
    String? branchId,
  }) async {
    final bid = _resolveBranchId(branchId);
    if (bid == null) return false;
    final ok = await _ensureSession();
    if (!ok) return false;
    try {
      final res = await _repo.patchBranchProduct(
        token: _token!,
        branchId: bid,
        productId: productId,
        workshopId: _workshopId!,
        data: {'criticalStockPoint': level},
      );
      if (res != null && res['success'] == true) {
        _patchLocalProduct(
          productId: productId,
          branchId: bid,
          criticalStock: level,
        );
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // kept for compatibility with UOM dialogs that call local version
  void setCriticalStock(String productId, int level, {String? branchId}) {
    _patchLocalProduct(
      productId: productId,
      branchId: branchId,
      criticalStock: level,
    );
    notifyListeners();
  }

  // ── Manual Adjust — real API ──────────────────────────────────────────────
  // POST /workshop-catalog/branches/{branchId}/products/{productId}/inventory-adjustments
  //      ?workshopId=...
  // Body: { newQty, reason, previousQty }
  Future<bool> submitManualAdjustment({
    required String productId,
    required int previousQty,
    required int newQty,
    required String reason,
    String? note,
    String? branchId,
  }) async {
    final bid = _resolveBranchId(branchId);
    if (bid == null) return false;
    final ok = await _ensureSession();
    if (!ok) return false;
    try {
      final res = await _repo.createInventoryAdjustment(
        token: _token!,
        branchId: bid,
        productId: productId,
        workshopId: _workshopId!,
        previousQty: previousQty,
        newQty: newQty,
        reason: reason,
        note: note,
      );
      if (res != null && res['success'] == true) {
        _patchLocalProduct(
          productId: productId,
          branchId: bid,
          currentStock: newQty,
        );
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // local version kept for backward compat
  void manualAdjust(String productId, int newQty, {String? branchId}) {
    _patchLocalProduct(
      productId: productId,
      branchId: branchId,
      currentStock: newQty,
    );
    notifyListeners();
  }

  // ── Timeline — real API ───────────────────────────────────────────────────
  // GET /workshop-catalog/branches/{branchId}/products/{productId}/inventory-adjustments
  //     ?limit=0&offset=0&workshopId=...
  Future<List<StockTimelineEntry>> fetchTimeline(
    String productId, {
    String? branchId,
  }) async {
    final bid = _resolveBranchId(branchId);
    if (bid == null) return [];
    final ok = await _ensureSession();
    if (!ok) return [];
    try {
      final res = await _repo.getInventoryAdjustments(
        token: _token!,
        branchId: bid,
        productId: productId,
        workshopId: _workshopId!,
        limit: 0,
        offset: 0,
      );
      if (res != null && res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final entries = (data['entries'] as List? ?? []);
        return entries.map((e) {
          final createdAt = e['createdAt'] as String? ?? '';
          final when = createdAt.isNotEmpty
              ? DateTime.tryParse(createdAt) ?? DateTime.now()
              : DateTime.now();
          // Map source → display type
          final source = e['source'] as String? ?? '';
          String type;
          if (source.contains('starting_stock') || source.contains('opening')) {
            type = 'OPENING (ADOPTION)';
          } else if (source == 'manual') {
            type = 'MANUAL ADJUST';
          } else if (source.contains('sale')) {
            type = 'SALE';
          } else if (source.contains('purchase')) {
            type = 'PURCHASE';
          } else {
            type = source.toUpperCase();
          }
          final adjustedBy = e['adjustedBy'] as Map<String, dynamic>? ?? {};
          return StockTimelineEntry(
            when: when,
            type: type,
            from: (e['previousQty'] as num? ?? 0).toInt(),
            to: (e['newQty'] as num? ?? 0).toInt(),
            reason: e['reason'] as String? ?? '—',
            sourceRef: e['reference'] as String? ?? source,
            by: adjustedBy['name'] as String? ?? '—',
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── KPI helpers ───────────────────────────────────────────────────────────
  int get totalProducts => _allProducts.length;
  int get lowStockCount => isAllBranches
      ? _lowStockBranchAlerts.length
      : _allProducts.where((p) => p.isLowStock).length;
  double get totalInventoryValue =>
      _allProducts.fold(0.0, (sum, p) => sum + p.currentStock * p.purchasePrice);

  // ── Unique id generator ───────────────────────────────────────────────────
  static int _uid = 100;
  static String nextId() => 'gen${_uid++}';

  @override
  void dispose() {
    _ownerData?.removeListener(_onOwnerDataChanged);
    super.dispose();
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────

class InventoryManagementV2 extends StatelessWidget {
  /// Set before navigating from Home Low Stock so Stock tab opens filtered.
  static bool pendingLowStockOnly = false;

  const InventoryManagementV2({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => InventoryV2ViewModel(
        repo: ctx.read<OwnerRepository>(),
        session: ctx.read<SessionService>(),
        ownerDataService: ctx.read<OwnerDataService>(),
      ),
      child: OwnerBranchReloadRegistrar(
        tabIndex: 19,
        onReload: (ctx) =>
            ctx.read<InventoryV2ViewModel>().syncWithSelectedBranch(),
        child: const _InventoryBody(),
      ),
    );
  }
}

class _InventoryBody extends StatefulWidget {
  const _InventoryBody();

  @override
  State<_InventoryBody> createState() => _InventoryBodyState();
}

class _InventoryBodyState extends State<_InventoryBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InventoryV2ViewModel>();
    if (InventoryManagementV2.pendingLowStockOnly) {
      InventoryManagementV2.pendingLowStockOnly = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<InventoryV2ViewModel>().toggleLowStock(true);
        }
      });
    }
    final showBack = OwnerShell.openedWithBack(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: l10n.ownerInventoryTitle),
        showDrawer: !showBack,
        showBackButton: showBack,
        showNotification: false,
        onMenuPressed: () => OwnerShell.openDrawer(context),
      ),
      body: vm.isLoading && vm.branches.isEmpty
          ? const OwnerListPageShimmer(showKpi: true, showTabs: true)
          : Column(
        children: [
          // ── KPI Cards ───────────────────────────────────────────────
          _KpiRow(vm: vm),

          // ── Tab bar ─────────────────────────────────────────────────
          _TabBar(controller: _tabController),

          // ── Tab content ─────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StockTab(vm: vm),
                UomProfilesTab(vm: vm),
                InventoryValueTab(vm: vm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Branch Selector ──────────────────────────────────────────────────────────

class _BranchSelector extends StatelessWidget {
  final InventoryV2ViewModel vm;
  const _BranchSelector({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: vm.branches.map((b) {
            final sel = vm.selectedBranchId == b['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 10),
              child: GestureDetector(
                onTap: () => vm.selectBranch(b['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.primaryLight : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    b['name']!,
                    style: TextStyle(
                      color: AppColors.secondaryLight,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final InventoryV2ViewModel vm;
  const _KpiRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branchName = vm.branches
        .firstWhere((b) => b['id'] == vm.selectedBranchId,
        orElse: () => {'name': ''})['name']!;

    return Container(
      color: OwnerUi.scaffoldBackground,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ReusableKpiGrid(
        layout: KpiGridLayout.singleRow,
        padding: EdgeInsets.zero,
        showFeatured: false,
        iconOnTop: true,
        mainAxisExtent: 108,
        singleRowCardWidth: 112,
        metrics: [
          ReusableKpiMetric(
            title: l10n.ownerInventoryKpiTotalProducts,
            value: ownerLocalizeDigits(context, '${vm.totalProducts}'),
            icon: Icons.inventory_2_rounded,
            accentColor: AppColors.primaryLight,
          ),
          ReusableKpiMetric(
            title: l10n.ownerInventoryKpiLowStock,
            value: ownerLocalizeDigits(context, '${vm.lowStockCount}'),
            icon: Icons.warning_amber_rounded,
            accentColor: AppColors.primaryLight,
            onTap: () => _showLowStockBreakdown(context, vm, branchName),
          ),
          ReusableKpiMetric(
            title: l10n.ownerInventoryKpiInvValue,
            value: formatKpiAmount(vm.totalInventoryValue, context: context),
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppColors.primaryLight,
            onTap: () => _showValueBreakdown(context, vm, branchName),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool highlightBorder;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.highlightBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlightBorder ? AppColors.errorLight.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1),
            width: highlightBorder ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 12, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (onTap != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 8, color: Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      'tap for breakdown',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 7),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerSegmentedTabs(
      controller: controller,
      tabs: [
        l10n.ownerInventoryTabStock,
        l10n.ownerInventoryTabUomProfiles,
        l10n.ownerInventoryTabValue,
      ],
      layout: PosSegmentedTabLayout.expanded,
    );
  }
}

// Shared dialogs and helper widgets used by the imported inventory tab files.

class BulkUomDialog extends StatefulWidget {
  final List<InvProduct> products;
  const BulkUomDialog({required this.products});

  @override
  State<BulkUomDialog> createState() => BulkUomDialogState();
}

class BulkUomDialogState extends State<BulkUomDialog> {
  String _warehouseUnit = 'Box';
  String _workshopUnit = 'Liter';
  final _factorCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _factorCtrl.dispose();
    super.dispose();
  }

  String get _ruleLabel {
    final f = int.tryParse(_factorCtrl.text.trim()) ?? 1;
    return '1 $_warehouseUnit = $f $_workshopUnit';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InventoryV2ViewModel>();
    final n = widget.products.length;
    final names = widget.products.map((p) => p.name).take(3).join(', ');
    final overflow = n > 3 ? '  +${n - 3} more' : '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('Set UOM for $n products',
                        style: AppTextStyles.h3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.grey.shade400),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder()),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Products preview
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Color(0xFFEBF1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('$names$overflow',
                          style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Warning
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFFFE08A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sync_alt_rounded,
                        size: 16, color: Color(0xFFF39C12)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                          'Same rule applied to every selected product. Quantities stay unchanged.',
                          style: TextStyle(
                              color: Color(0xFFF39C12),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // UOM row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;
                  final fieldWidth = isCompact
                      ? constraints.maxWidth
                      : ((constraints.maxWidth - 88) / 2).clamp(120.0, 220.0).toDouble();

                  return Wrap(
                    spacing: isCompact ? 0 : 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: UomDropdownField(
                          label: 'WAREHOUSE UOM',
                          sublabel: 'Purchase / bulk unit',
                          value: _warehouseUnit,
                          onChanged: (v) => setState(() => _warehouseUnit = v!),
                        ),
                      ),
                      SizedBox(
                        width: isCompact ? 70 : 64,
                        child: FactorField(
                          controller: _factorCtrl,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: UomDropdownField(
                          label: 'WORKSHOP UOM',
                          sublabel: 'Inventory & sales unit',
                          value: _workshopUnit,
                          onChanged: (v) => setState(() => _workshopUnit = v!),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Conversion rule preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONVERSION RULE',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(_ruleLabel,
                        style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        final f =
                            int.tryParse(_factorCtrl.text.trim()) ?? 1;
                        vm.bulkSetUom(
                          productIds:
                          widget.products.map((p) => p.id).toList(),
                          warehouseUnit: _warehouseUnit,
                          factor: f,
                          workshopUnit: _workshopUnit,
                        );
                        Navigator.pop(context);
                      },
                      child: Text('Apply to $n',
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Link UOM Profile Dialog ──────────────────────────────────────────────────

class LinkUomDialog extends StatefulWidget {
  final InvProduct product;
  const LinkUomDialog({required this.product});

  @override
  State<LinkUomDialog> createState() => LinkUomDialogState();
}

class LinkUomDialogState extends State<LinkUomDialog> {
  String? _selectedProfileId; // null = no profile

  @override
  void initState() {
    super.initState();
    _selectedProfileId = widget.product.uomProfileId;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InventoryV2ViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text('Link UOM profile',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.grey.shade400),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder()),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product box
              ProductHeaderBox(
                  name: widget.product.name, sku: widget.product.sku),
              const SizedBox(height: 16),

              // Profile dropdown
              Text('UOM PROFILE',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // No profile option
                    _ProfileOption(
                      label: '— No profile (use product unit) —',
                      isSelected: _selectedProfileId == null,
                      onTap: () =>
                          setState(() => _selectedProfileId = null),
                    ),
                    ...vm.uomProfiles.map((prof) {
                      return Column(
                        children: [
                          Divider(height: 1, color: Colors.grey.shade200),
                          _ProfileOption(
                            label:
                            '${prof.name} — ${prof.ruleLabel}',
                            isSelected: _selectedProfileId == prof.id,
                            onTap: () => setState(
                                    () => _selectedProfileId = prof.id),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        vm.linkProfile(
                            widget.product.id, _selectedProfileId);
                        Navigator.pop(context);
                      },
                      child: const Text('Save link',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected ? Colors.grey.shade100 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              size: 16,
              color: isSelected ? AppColors.secondaryLight : Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── New UOM Profile Dialog ───────────────────────────────────────────────────

class NewProfileDialog extends StatefulWidget {
  const NewProfileDialog();

  @override
  State<NewProfileDialog> createState() => NewProfileDialogState();
}

class NewProfileDialogState extends State<NewProfileDialog> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _factorCtrl = TextEditingController(text: '1');
  String _warehouseUnit = 'Box';
  String _workshopUnit = 'Liter';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _factorCtrl.dispose();
    super.dispose();
  }

  String get _ruleLabel {
    final f = int.tryParse(_factorCtrl.text.trim()) ?? 1;
    return '1 $_warehouseUnit = $f $_workshopUnit';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InventoryV2ViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('New UOM profile',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.grey.shade400),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder()),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Profile name
              FieldLabel('PROFILE NAME *'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.secondaryLight, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Box → Liter (12)',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // UOM row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;
                  final fieldWidth = isCompact
                      ? constraints.maxWidth
                      : ((constraints.maxWidth - 88) / 2).clamp(120.0, 220.0).toDouble();

                  return Wrap(
                    spacing: isCompact ? 0 : 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: UomDropdownField(
                          label: 'WAREHOUSE / PACKING UNIT',
                          sublabel: null,
                          value: _warehouseUnit,
                          onChanged: (v) => setState(() => _warehouseUnit = v!),
                        ),
                      ),
                      SizedBox(
                        width: isCompact ? 70 : 64,
                        child: FactorField(
                          controller: _factorCtrl,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: UomDropdownField(
                          label: 'STOCK / WORKSHOP UNIT',
                          sublabel: null,
                          value: _workshopUnit,
                          onChanged: (v) => setState(() => _workshopUnit = v!),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Rule preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RULE',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(_ruleLabel,
                        style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              FieldLabel('NOTES'),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.secondaryLight, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Optional — e.g. Product A & B use this packing',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        final name = _nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final f =
                            int.tryParse(_factorCtrl.text.trim()) ?? 1;
                        vm.addUomProfile(UomProfile(
                          id: InventoryV2ViewModel.nextId(),
                          name: name,
                          warehouseUnit: _warehouseUnit,
                          workshopUnit: _workshopUnit,
                          factor: f,
                          notes: _notesCtrl.text.trim().isEmpty
                              ? null
                              : _notesCtrl.text.trim(),
                        ));
                        Navigator.pop(context);
                      },
                      child: const Text('Save profile',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Low Stock Breakdown Dialog ───────────────────────────────────────────────

void _showLowStockBreakdown(
    BuildContext context, InventoryV2ViewModel vm, String branchName) {
  showDialog(
    context: context,
    builder: (_) => _LowStockBreakdownDialog(vm: vm, branchName: branchName),
  );
}

class _LowStockBreakdownDialog extends StatelessWidget {
  final InventoryV2ViewModel vm;
  final String branchName;
  const _LowStockBreakdownDialog({required this.vm, required this.branchName});

  @override
  Widget build(BuildContext context) {
    // All Branches: use per-branch alerts (same as LOW STOCK KPI).
    final all = vm.isAllBranches ? vm.lowStockProducts : vm.allProducts;
    final outOfStock =
        all.where((p) => p.criticalStock > 0 && p.currentStock <= 0).length;
    final lowOnly = all
        .where((p) => p.criticalStock > 0 && p.currentStock > 0 && p.isLowStock)
        .length;
    final withCritical = vm.isAllBranches
        ? all.length
        : all.where((p) => p.criticalStock > 0).length;
    final noCritical =
        vm.isAllBranches ? 0 : all.where((p) => p.criticalStock == 0).length;
    final kpiCount = vm.isAllBranches ? all.length : outOfStock + lowOnly;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text('Low stock (SKUs) — breakdown',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder()),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Rule banner ─────────────────────────────────────────
              InfoBanner(
                icon: Icons.info_outline_rounded,
                color: AppColors.secondaryLight,
                bg: Colors.grey.shade50,
                border: Colors.grey.shade200,
                text: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryLight,
                        height: 1.5),
                    children: [
                      const TextSpan(text: 'Rule: a SKU counts as '),
                      const TextSpan(
                          text: 'low stock',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                      const TextSpan(text: ' only when '),
                      const TextSpan(
                          text: 'critical level > 0',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: ' and '),
                      const TextSpan(
                          text: 'current stock ≤ critical level',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(
                          text: '. Products with critical set to 0 are excluded (not monitored for low stock).'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Scope banner ────────────────────────────────────────
              InfoBanner(
                icon: Icons.store_outlined,
                color: AppColors.secondaryLight,
                bg: Colors.grey.shade50,
                border: Colors.grey.shade200,
                text: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryLight,
                        height: 1.5),
                    children: [
                      TextSpan(
                          text: AppLocalizations.of(context)!.ownerInventoryScopeLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: AppLocalizations.of(context)!
                              .ownerInventoryScopeBodyShort(branchName)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── KPI grid ────────────────────────────────────────────
              ReusableMetricCard(
                title: AppLocalizations.of(context)!.ownerInventoryKpiCount,
                value: ownerLocalizeDigits(context, '$kpiCount'),
                icon: Icons.warning_amber_rounded,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 10),
              ReusableKpiGrid(
                showFeatured: false,
                crossAxisCount: 2,
                childAspectRatio: 2.4,
                metrics: [
                  ReusableKpiMetric(
                    title: 'Out of stock',
                    value: '$outOfStock',
                    icon: Icons.remove_circle_outline_rounded,
                  ),
                  ReusableKpiMetric(
                    title: 'Low stock',
                    value: '$lowOnly',
                    icon: Icons.trending_down_rounded,
                  ),
                  ReusableKpiMetric(
                    title: 'With critical',
                    value: '$withCritical',
                    icon: Icons.track_changes_rounded,
                  ),
                  ReusableKpiMetric(
                    title: 'No critical',
                    value: '$noCritical',
                    icon: Icons.block_rounded,
                  ),
                ],
              ),

              if (kpiCount == 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: Color(0xFF27AE60)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No low-stock SKUs — stock is above critical for all monitored items.',
                          style: TextStyle(
                              color: Colors.green.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Total Inventory Value Breakdown Dialog ───────────────────────────────────

void _showValueBreakdown(
    BuildContext context, InventoryV2ViewModel vm, String branchName) {
  showDialog(
    context: context,
    builder: (_) => _ValueBreakdownDialog(vm: vm, branchName: branchName),
  );
}

class _ValueBreakdownDialog extends StatelessWidget {
  final InventoryV2ViewModel vm;
  final String branchName;
  const _ValueBreakdownDialog({required this.vm, required this.branchName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = List<InvProduct>.from(vm.filteredProducts)
      ..sort((a, b) => (b.currentStock * b.purchasePrice)
          .compareTo(a.currentStock * a.purchasePrice));
    final withStock = products.where((p) => p.currentStock > 0).length;
    final withValue = products.where((p) => p.currentStock * p.purchasePrice > 0).length;
    final total = products.fold(0.0, (sum, p) => sum + p.currentStock * p.purchasePrice);
    final rounded = total.round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.68,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.ownerInventoryValueCalcTitle,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder()),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                children: [
                  InfoBanner(
                    icon: Icons.functions_rounded,
                    color: AppColors.secondaryLight,
                    bg: Colors.grey.shade50,
                    border: Colors.grey.shade200,
                    text: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 12,
                            height: 1.5),
                        children: [
                          TextSpan(
                              text: l10n.ownerInventoryFormulaLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(
                              text: l10n.ownerInventoryFormulaBody(
                                  l10n.ownerCurrencySar)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InfoBanner(
                    icon: Icons.store_outlined,
                    color: AppColors.secondaryLight,
                    bg: Colors.grey.shade50,
                    border: Colors.grey.shade200,
                    text: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 12,
                            height: 1.5),
                        children: [
                          TextSpan(
                              text: l10n.ownerInventoryScopeLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(
                              text: l10n.ownerInventoryScopeBody(branchName)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ReusableKpiGrid(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              childAspectRatio: 2.3,
              metrics: [
                ReusableKpiMetric(
                  title: l10n.ownerInventoryTotalExact,
                  value: ownerFormatMoney(context, total),
                  icon: Icons.calculate_outlined,
                ),
                ReusableKpiMetric(
                  title: l10n.ownerInventoryKpiRounded,
                  value: ownerFormatMoney(context, rounded, decimals: 0),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                ReusableKpiMetric(
                  title: l10n.ownerInventorySkusInList,
                  value: ownerLocalizeDigits(context, '${products.length}'),
                  icon: Icons.inventory_2_outlined,
                ),
                ReusableKpiMetric(
                  title: l10n.ownerInventorySkusWithStock,
                  value: ownerLocalizeDigits(context, '$withStock'),
                  icon: Icons.check_circle_outline_rounded,
                ),
                ReusableKpiMetric(
                  title: l10n.ownerInventorySkusWithValue,
                  value: ownerLocalizeDigits(context, '$withValue'),
                  icon: Icons.monetization_on_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stock Timeline Dialog ────────────────────────────────────────────────────





// ─── Stock Timeline Dialog ────────────────────────────────────────────────────

class StockTimelineDialog extends StatefulWidget {
  final InvProduct product;
  final InventoryV2ViewModel vm;

  const StockTimelineDialog({
    required this.product,
    required this.vm,
  });

  @override
  State<StockTimelineDialog> createState() => _StockTimelineDialogState();
}

class _StockTimelineDialogState extends State<StockTimelineDialog> {
  List<StockTimelineEntry>? _entries;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.vm.fetchTimeline(
        widget.product.id,
        branchId: widget.product.branchId,
      );
      if (mounted) setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load timeline'; _loading = false; });
    }
  }

  static String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}, $h:$mi:$s';
  }

  Color _typeColor(String type) {
    if (type.contains('OPENING')) return const Color(0xFFB8860B);
    if (type.contains('SALE')) return AppColors.errorLight;
    if (type.contains('PURCHASE')) return const Color(0xFF2ECC71);
    return const Color(0xFF2563EB);
  }

  Color _typeBg(String type) {
    if (type.contains('OPENING')) return const Color(0xFFFFF9E6);
    if (type.contains('SALE')) return AppColors.errorLight.withValues(alpha: 0.06);
    if (type.contains('PURCHASE')) return const Color(0xFF2ECC71).withValues(alpha: 0.06);
    return const Color(0xFF2563EB).withValues(alpha: 0.06);
  }

  @override
  Widget build(BuildContext context) {
    final branchName = widget.vm.branches.firstWhere(
          (b) => b['id'] == widget.vm.selectedBranchId,
      orElse: () => {'name': 'MAIN BRANCH'},
    )['name']!;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Inventory stock timeline',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  // ── Export buttons ──────────────────────
                  if (!_loading && _entries != null && _entries!.isNotEmpty) ...[
                    _TimelineExportBtn(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'PDF',
                      color: const Color(0xFFE53E3E),
                      onTap: () => _exportPdf(context),
                    ),
                    const SizedBox(width: 6),
                    _TimelineExportBtn(
                      icon: Icons.table_chart_rounded,
                      label: 'Excel',
                      color: const Color(0xFF2E7D32),
                      onTap: () => _exportExcel(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: _loading
                  ? const OwnerFormPageShimmer(fieldCount: 4)
                  : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: Colors.grey.shade500)))
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  _StockProductHeader(
                    product: widget.product,
                    branchName: branchName,
                  ),
                  const SizedBox(height: 16),
                  if (_entries!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'No stock movements yet',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ..._entries!.map((entry) => _StockMovementCard(
                      entry: entry,
                      dateText: _fmtDate(entry.when),
                      typeColor: _typeColor(entry.type),
                      bgColor: _typeBg(entry.type),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportPdf(BuildContext context) {
    // PDF export — integrate with your PDF generation service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Generating PDF for ${widget.product.name}...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportExcel(BuildContext context) {
    // Excel export — integrate with your Excel generation service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Generating Excel for ${widget.product.name}...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Timeline Export Button ───────────────────────────────────────────────────

class _TimelineExportBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TimelineExportBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockProductHeader extends StatelessWidget {
  final InvProduct product;
  final String branchName;

  const _StockProductHeader({
    required this.product,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRODUCT',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          LocalizedApiText(
            product.name,
            style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(
                'SKU: ${product.sku}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _DotText(),
              Text(
                'Opening (adoption):',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF2C9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${product.openingStock}',
                  style: const TextStyle(
                    color: Color(0xFFB7791F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _DotText(),
              Text(
                'Current stock: ${product.currentStock}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _DotText(),
              Text(
                branchName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StockMovementCard extends StatelessWidget {
  final StockTimelineEntry entry;
  final String dateText;
  final Color typeColor;
  final Color bgColor;

  const _StockMovementCard({
    required this.entry,
    required this.dateText,
    required this.typeColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = entry.delta >= 0;
    final deltaColor = isPositive ? const Color(0xFF2ECC71) : AppColors.errorLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact top strip
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: typeColor, width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              entry.type,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                dateText,
                                softWrap: true,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Delta
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Δ ${isPositive ? '+' : ''}${entry.delta}',
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _CompactStockFlow(
                  from: '${entry.from}',
                  to: '${entry.to}',
                ),

                const SizedBox(height: 8),

                _CompactInfoTile(
                  icon: Icons.info_outline_rounded,
                  label: 'REASON',
                  value: entry.reason,
                ),

                const SizedBox(height: 7),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _CompactInfoTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'SOURCE / REF',
                        value: entry.sourceRef,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      flex: 2,
                      child: _CompactInfoTile(
                        icon: Icons.person_outline_rounded,
                        label: 'BY',
                        value: entry.by,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _CompactStockFlow extends StatelessWidget {
  final String from;
  final String to;

  const _CompactStockFlow({
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _MiniInlineValue(label: 'FROM', value: from),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ),
          _MiniInlineValue(label: 'TO', value: to),
        ],
      ),
    );
  }
}

class _MiniInlineValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInlineValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





class _BreakdownKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool fullWidth;

  const _BreakdownKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                color: AppColors.secondaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ProductHeaderBox extends StatelessWidget {
  final String name;
  final String sku;
  const ProductHeaderBox({required this.name, required this.sku});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedApiText(name,
              style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          if (sku.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sku,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}


class FactorField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const FactorField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1 =',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class UomDropdownField extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String value;
  final ValueChanged<String?> onChanged;

  const UomDropdownField({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade500, size: 18),
              items: kInventoryUnits
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 4),
          Text(sublabel!,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 10)),
        ],
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  const FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final Widget text;
  const InfoBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: text),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded,
                size: 36, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 14),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// end of file