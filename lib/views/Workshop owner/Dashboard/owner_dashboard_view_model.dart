import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/workshop_owner_models.dart';
import '../../../services/session_service.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

class OwnerDashboardViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  final SettingsViewModel? settingsViewModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading || ownerDataService.isLoadingBranches;

  /// Cache of translated branches keyed by branch id — overlays the raw
  /// branches from [ownerDataService] without mutating them.
  final Map<String, Branch> _translatedBranchCache = {};

  List<Branch> get branches => ownerDataService.branches
      .map((b) => _translatedBranchCache[b.id] ?? b)
      .toList();

  Branch? get selectedBranch => ownerDataService.selectedBranch;

  List<OwnerEmployee> _employees = [];
  List<OwnerEmployee> get employees => _employees;

  String _ownerName = 'Admin';
  String? _translatedOwnerName;
  String get ownerName => _translatedOwnerName ?? _ownerName;

  // ── Legacy dashboard data (kept for backward-compat) ──────────────────────
  OwnerDashboardResponse? _dashboardData;
  OwnerDashboardResponse? get dashboardData => _dashboardData;

  // ── Mobile dashboard data (new endpoint) ──────────────────────────────────
  MobileDashboardResponse? _mobileDashboard;
  MobileDashboardResponse? get mobileDashboard => _mobileDashboard;

  String _currency = 'SAR';
  String get currency => _currency;

  // ── Date / time range — app-wide via [OwnerDataService] ───────────────────
  DateTime get filterFrom => ownerDataService.filterFrom;
  DateTime get filterTo => ownerDataService.filterTo;

  // ── Petty cash ────────────────────────────────────────────────────────────
  List<PettyCashRequestItem> _pendingPettyCashRequests = [];
  List<PettyCashRequestItem> get pendingPettyCashRequests =>
      _pendingPettyCashRequests;
  String _pettyCashCurrency = 'SAR';
  String get pettyCashCurrency => _pettyCashCurrency;
  String? _approvingRequestId;
  String? _rejectingRequestId;
  bool get hasApprovalActionInFlight =>
      _approvingRequestId != null || _rejectingRequestId != null;
  bool isApprovingRequest(String id) => _approvingRequestId == id;
  bool isRejectingRequest(String id) => _rejectingRequestId == id;

  // ── Supplier Sales Invoices ───────────────────────────────────────────────
  int _supplierInvoicesTotal = 0;
  int get supplierInvoicesTotal => _supplierInvoicesTotal;
  String _supplierInvoicesCurrency = 'SAR';
  String get supplierInvoicesCurrency => _supplierInvoicesCurrency;

  // ── Active Technicians (from /technicians?isActive=true) ─────────────────
  List<ActiveTechnicianItem> _activeTechnicians = [];
  final Map<String, ActiveTechnicianItem> _translatedTechCache = {};
  final Map<String, DashboardTechnician> _translatedDashboardTechCache = {};
  List<ActiveTechnicianItem> get activeTechnicians => _activeTechnicians
      .map((t) => _translatedTechCache[t.id] ?? t)
      .toList();
  int get activeTechniciansCount => _activeTechnicians.length;

  final RealtimeService _realtimeService = RealtimeService();
  bool _realtimeBound = false;
  String? _lastSyncedBranchId;
  int _lastSyncedDateGeneration = -1;

  OwnerDashboardViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    this.settingsViewModel,
  }) {
    _lastSyncedBranchId = ownerDataService.selectedBranchId;
    _lastSyncedDateGeneration = ownerDataService.dateGeneration;
    ownerDataService.addListener(_onOwnerDataChanged);
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
    Future.microtask(() => init());
  }

  void _onOwnerDataChanged() {
    // Branch list / selection UI only — API reload is owned by the visible tab.
    notifyListeners();
  }

  // ── Locale re-translation ─────────────────────────────────────────────────

  Future<void> retranslate() async {
    await _applyDashboardTranslations();
    notifyListeners();
  }

  Future<void> _applyDashboardTranslations() async {
    _translatedOwnerName = await t(_ownerName);

    final translatedBranches =
        await Future.wait(ownerDataService.branches.map(translateBranch));
    _translatedBranchCache
      ..clear()
      ..addEntries(translatedBranches.map((b) => MapEntry(b.id, b)));

    final translatedLowStock =
        await Future.wait(_lowStockItems.map(_translateLowStockItem));
    _lowStockItems = translatedLowStock;

    final perfSource = _mobileDashboard?.branchPerformance.isNotEmpty == true
        ? _mobileDashboard!.branchPerformance
        : (_dashboardData?.branchPerformance ?? [])
            .map((b) => DashboardBranchPerformanceItem(
                  id: b.id,
                  name: b.name,
                  address: b.address,
                  monthlySales: b.monthlySales,
                ))
            .toList();
    final translatedPerf =
        await Future.wait(perfSource.map(_translateBranchPerfItem));
    _translatedBranchPerfCache
      ..clear()
      ..addEntries(translatedPerf.map((p) => MapEntry(p.id, p)));

    final translatedTechs =
        await Future.wait(_activeTechnicians.map(_translateTechnician));
    _translatedTechCache
      ..clear()
      ..addEntries(translatedTechs.map((t) => MapEntry(t.id, t)));

    final mobileTechs = _mobileDashboard?.technicians.items ?? const [];
    if (mobileTechs.isNotEmpty) {
      final translatedDashTechs =
          await Future.wait(mobileTechs.map(_translateDashboardTechnician));
      _translatedDashboardTechCache
        ..clear()
        ..addEntries(translatedDashTechs.map((t) => MapEntry(t.id, t)));
    } else {
      _translatedDashboardTechCache.clear();
    }
  }

  Future<DashboardTechnician> _translateDashboardTechnician(
      DashboardTechnician tech) async {
    final translatedDepts = await Future.wait(tech.departments.map(
      (d) async => d.copyWith(translatedName: await t(d.name)),
    ));
    return tech.copyWith(
      translatedName: await tPerson(tech.name),
      translatedBranchName: await tBranch(tech.branchName),
      departments: translatedDepts,
    );
  }

  Future<DashboardLowStockItem> _translateLowStockItem(
      DashboardLowStockItem item) async {
    return item.copyWith(
      translatedName: await t(item.name),
      translatedBranchName: item.branchName != null
          ? await tBranch(item.branchName!)
          : null,
    );
  }

  Future<DashboardBranchPerformanceItem> _translateBranchPerfItem(
      DashboardBranchPerformanceItem item) async {
    return item.copyWith(
      translatedName: await tBranch(item.name),
      translatedAddress: await t(item.address),
    );
  }

  Future<ActiveTechnicianItem> _translateTechnician(
      ActiveTechnicianItem tech) async {
    final translatedDepts = await Future.wait(tech.departments.map(
      (d) async => d.copyWith(translatedName: await t(d.name)),
    ));
    return tech.copyWith(
      translatedName: await tPerson(tech.name),
      translatedBranchName: await tBranch(tech.branchName),
      departments: translatedDepts,
    );
  }

  /// Reload dashboard APIs when this tab is visible and branch/date scope changed.
  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final nextId = ownerDataService.selectedBranchId;
    final nextDateGen = ownerDataService.dateGeneration;
    if (!force &&
        nextId == _lastSyncedBranchId &&
        nextDateGen == _lastSyncedDateGeneration) {
      return;
    }
    _lastSyncedBranchId = nextId;
    _lastSyncedDateGeneration = nextDateGen;
    await _refreshBranchScopedData();
  }

  Future<void> _refreshBranchScopedData() async {
    final token = await sessionService.getToken(role: 'owner');
    if (token == null) {
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      () async {
        await _fetchMobileDashboard(token);
        await _fetchDashboardData(token);
      }(),
      _fetchLowStockProducts(token),
      _fetchPendingPettyCashRequests(token),
      _fetchSupplierSalesInvoices(token),
      _fetchActiveTechnicians(token),
    ]);
    await _applyDashboardTranslations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final user = await sessionService.getUser(role: 'owner');
    if (user != null && user.name != null) {
      _ownerName = user.name ?? 'Admin';
    }

    final token = await sessionService.getToken(role: 'owner');
    if (token != null) {
      if (branches.isEmpty) {
        await ownerDataService.fetchBranches();
      }
      await Future.wait([
        () async {
          await _fetchMobileDashboard(token);
          await _fetchDashboardData(token);
        }(),
        _fetchLowStockProducts(token),
        _fetchPendingPettyCashRequests(token),
        _fetchSupplierSalesInvoices(token),
        _fetchActiveTechnicians(token),
        _bindRealtime(token),
      ]);
    }

    // Mocked employees fallback
    _employees = [
      OwnerEmployee(
          id: '1',
          name: 'Ahmed Khan',
          mobile: '0501234567',
          branchId: '1',
          role: 'Technician',
          departmentIds: ['AC', 'Oil'],
          commissionPercent: 5.0,
          isAvailable: true),
      OwnerEmployee(
          id: '2',
          name: 'Mohamed Ali',
          mobile: '0507654321',
          branchId: '2',
          role: 'Cashier',
          departmentIds: [],
          commissionPercent: 0.0),
      OwnerEmployee(
          id: '3',
          name: 'Saeed Omar',
          mobile: '0509988776',
          branchId: '1',
          role: 'Manager',
          departmentIds: [],
          commissionPercent: 2.0),
    ];

    await _applyDashboardTranslations();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchMobileDashboard(String token) async {
    try {
      final response = await ownerRepository.getMobileDashboard(
        token,
        branchId: selectedBranch?.id,
        startDate: filterFrom,
        endDate: filterTo,
        technicianLimit: 5,
        lowStockLimit: 10,
      );
      if (response != null && response['success'] == true) {
        _mobileDashboard =
            MobileDashboardResponse.fromJson(response as Map<String, dynamic>);
        _currency = _mobileDashboard?.currency ?? 'SAR';
      }
    } catch (e) {
      debugPrint('[OwnerDashboardVM] _fetchMobileDashboard error: $e');
    }
  }

  Future<void> _fetchDashboardData(String token) async {
    try {
      final response = await ownerRepository.getDashboardData(
        token,
        branchId: selectedBranch?.id,
        startDate: filterFrom,
        endDate: filterTo,
      );
      if (response != null && response['success'] == true) {
        _dashboardData = OwnerDashboardResponse.fromJson(
          Map<String, dynamic>.from(response as Map),
        );
        // When mobile-dashboard is unavailable, mirror KPI sales into the
        // mobile summary shape so the UI still reflects the selected range.
        if (_mobileDashboard == null) {
          _mobileDashboard = MobileDashboardResponse(
            success: true,
            currency: _currency,
            dataScope: _dashboardData!.dataScope,
            dataScopeLabel: _dashboardData!.dataScopeLabel,
            branchId: _dashboardData!.branchId,
            summary: MobileDashboardSummary(
              totalSalesToday: _dashboardData!.totalSalesToday,
              purchaseCostToday: _dashboardData!.purchaseCostToday,
              grossMarginProfit: _dashboardData!.grossMarginProfit,
              totalSalesThisMonth: _dashboardData!.totalSalesThisMonth,
              pendingInvoicesCount: _dashboardData!.pendingInvoicesCount,
              lowStockAlertsCount: _dashboardData!.lowStockAlertsCount,
              pendingApprovalsCount: 0,
            ),
            technicians: const DashboardTechniciansSection(
              total: 0,
              showing: 0,
              items: [],
            ),
            lowStock: const DashboardLowStockSection(
              total: 0,
              showing: 0,
              items: [],
            ),
            branchPerformance: _dashboardData!.branchPerformance
                .map(
                  (b) => DashboardBranchPerformanceItem(
                    id: b.id,
                    name: b.name,
                    address: b.address,
                    monthlySales: b.monthlySales,
                  ),
                )
                .toList(),
          );
        } else {
          // Keep technicians / low-stock from mobile; refresh sales KPIs from
          // the dated dashboard endpoint (source of truth for the range).
          _mobileDashboard = MobileDashboardResponse(
            success: _mobileDashboard!.success,
            currency: _mobileDashboard!.currency,
            dataScope: _dashboardData!.dataScope,
            dataScopeLabel: _dashboardData!.dataScopeLabel,
            branchId: _dashboardData!.branchId,
            summary: _mobileDashboard!.summary.copyWith(
              totalSalesToday: _dashboardData!.totalSalesToday,
              purchaseCostToday: _dashboardData!.purchaseCostToday,
              grossMarginProfit: _dashboardData!.grossMarginProfit,
              totalSalesThisMonth: _dashboardData!.totalSalesThisMonth,
              pendingInvoicesCount: _dashboardData!.pendingInvoicesCount,
              lowStockAlertsCount: _dashboardData!.lowStockAlertsCount,
            ),
            technicians: _mobileDashboard!.technicians,
            lowStock: _mobileDashboard!.lowStock,
            branchPerformance: _dashboardData!.branchPerformance
                .map(
                  (b) => DashboardBranchPerformanceItem(
                    id: b.id,
                    name: b.name,
                    address: b.address,
                    monthlySales: b.monthlySales,
                  ),
                )
                .toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('[OwnerDashboardVM] _fetchDashboardData error: $e');
    }
  }

  Future<void> _fetchPendingPettyCashRequests(String token) async {
    try {
      final response = await ownerRepository.getPettyCashRequests(
        token,
        queue: 'all',
        status: 'pending',
        branchId: selectedBranch?.id,
        limit: 20,
        offset: 0,
      );
      _pendingPettyCashRequests = response.requests;
      _pettyCashCurrency = response.currency;
    } catch (e) {
      debugPrint('[OwnerDashboardVM] _fetchPendingPettyCashRequests error: $e');
      _pendingPettyCashRequests = [];
    }
  }

  /// GET /workshop-staff/supplier-sales-invoices?limit=1&offset=0
  /// Used to show the total supplier invoice count on the dashboard.
  Future<void> _fetchSupplierSalesInvoices(String token) async {
    try {
      final response = await ownerRepository.getSupplierSalesInvoices(
        token,
        branchId: selectedBranch?.id,
        limit: 1,
        offset: 0,
      );
      if (response != null && response['success'] == true) {
        _supplierInvoicesTotal =
            int.tryParse(response['total']?.toString() ?? '0') ?? 0;
        _supplierInvoicesCurrency =
            response['currency']?.toString() ?? 'SAR';
      }
    } catch (e) {
      debugPrint('[OwnerDashboardVM] _fetchSupplierSalesInvoices error: $e');
      _supplierInvoicesTotal = 0;
    }
  }

  /// GET /workshop-staff/technicians?isActive=true
  /// Fetches live active technician list for the dashboard.
  Future<void> _fetchActiveTechnicians(String token) async {
    try {
      final response = await ownerRepository.getActiveTechnicians(
        token,
        branchId: selectedBranch?.id,
      );
      if (response.success) {
        _activeTechnicians = response.technicians;
      }
    } catch (e) {
      debugPrint('[OwnerDashboardVM] _fetchActiveTechnicians error: $e');
      _activeTechnicians = [];
    }
  }

  /// Low-stock list:
  /// - One branch → staff branch products (same as web / inventory).
  /// - All branches → **per-branch** scan (not workshop union). Union sums qty
  ///   across branches so a SKU low at one site can disappear when others have
  ///   stock; we count each branch alert separately (matches dashboard SQL).
  Future<void> _fetchLowStockProducts(String token) async {
    try {
      final branchId = selectedBranch?.id;
      final items = <DashboardLowStockItem>[];

      if (branchId == null || branchId.isEmpty) {
        final branchList = branches.isNotEmpty
            ? branches
            : await _ensureBranchesLoaded();
        if (branchList.isEmpty) {
          _lowStockItems = [];
          return;
        }
        final perBranch = await Future.wait(
          branchList.map((b) => _lowStockForBranch(token, b)),
        );
        for (final list in perBranch) {
          items.addAll(list);
        }
      } else {
        final b = selectedBranch;
        if (b != null) {
          items.addAll(await _lowStockForBranch(token, b));
        }
      }

      items.sort((a, b) {
        if (a.stockQty <= 0 && b.stockQty > 0) return -1;
        if (b.stockQty <= 0 && a.stockQty > 0) return 1;
        return (b.criticalLevel - b.stockQty)
            .compareTo(a.criticalLevel - a.stockQty);
      });
      _lowStockItems = items;
    } catch (e) {
      debugPrint('[OwnerDashboardVM] _fetchLowStockProducts error: $e');
      _lowStockItems = [];
    }
  }

  Future<List<Branch>> _ensureBranchesLoaded() async {
    if (branches.isNotEmpty) return branches;
    try {
      await ownerDataService.fetchBranches();
    } catch (_) {}
    return branches;
  }

  Future<List<DashboardLowStockItem>> _lowStockForBranch(
    String token,
    Branch branch,
  ) async {
    final bid = branch.id.trim();
    if (bid.isEmpty) return const [];

    List<Map<String, dynamic>> raw = [];
    try {
      final res = await ownerRepository.getWorkshopStaffBranchProducts(
        token,
        bid,
      );
      raw = _extractProductMaps(res);
    } catch (_) {}
    if (raw.isEmpty) {
      try {
        final catalog = await ownerRepository.getBranchProducts(token, bid);
        raw = _extractProductMaps(catalog);
      } catch (_) {}
    }

    final out = <DashboardLowStockItem>[];
    for (final row in raw) {
      final inv = InvProduct.fromBranchJson(row);
      if (inv.id.isEmpty) continue;
      if (row['isInfiniteQty'] == true || row['is_infinite_qty'] == true) {
        continue;
      }
      if (!inv.isLowStock) continue;
      out.add(
        DashboardLowStockItem(
          // Unique per branch so the same SKU low at 2 sites counts twice.
          id: '${inv.id}::$bid',
          name: inv.name,
          stockQty: inv.currentStock.toDouble(),
          criticalLevel: inv.criticalStock.toDouble(),
          unit: inv.unit,
          branchName: branch.name,
        ),
      );
    }
    return out;
  }

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

  Future<void> setSelectedBranch(Branch? branch) async {
    ownerDataService.setSelectedBranch(branch);
  }

  // ── KPI getters — prefer mobile dashboard, fall back to legacy ────────────

  double get totalSalesToday =>
      _mobileDashboard?.summary.totalSalesToday ??
          _dashboardData?.totalSalesToday ??
          0.0;

  double get purchaseCostToday =>
      _mobileDashboard?.summary.purchaseCostToday ??
          _dashboardData?.purchaseCostToday ??
          0.0;

  /// Gross margin for the selected date filter (period sales − period COGS).
  /// Prefer API value; do not derive from calendar-today sales (often 0 overnight).
  double get grossMarginProfit =>
      _mobileDashboard?.summary.grossMarginProfit ??
          _dashboardData?.grossMarginProfit ??
          0.0;

  double get totalSalesMonth =>
      _mobileDashboard?.summary.totalSalesThisMonth ??
          _dashboardData?.totalSalesThisMonth ??
          0.0;

  int get pendingInvoices =>
      _mobileDashboard?.summary.pendingInvoicesCount ??
          _dashboardData?.pendingInvoicesCount ??
          0;

  int get lowStockAlerts => lowStockDisplayCount;

  // NOTE: pendingApprovals intentionally kept for other parts of the app that
  // still reference this getter; the dashboard no longer shows the approvals
  // section (removed per requirements).
  int get pendingApprovals =>
      _mobileDashboard?.summary.pendingApprovalsCount ??
          _pendingPettyCashRequests.length;

  // ── Technicians section ───────────────────────────────────────────────────

  DashboardTechniciansSection? get technicianSection =>
      _mobileDashboard?.technicians;

  /// Returns technicians sourced from the mobile-dashboard endpoint.
  /// Falls back to the dedicated /technicians?isActive=true list if empty.
  List<DashboardTechnician> get dashboardTechnicians {
    final fromMobile = _mobileDashboard?.technicians.items ?? [];
    if (fromMobile.isNotEmpty) {
      return fromMobile
          .map((t) => _translatedDashboardTechCache[t.id] ?? t)
          .toList();
    }
    // Fallback: convert ActiveTechnicianItem → DashboardTechnician shape
    return activeTechnicians.map((t) => t.toDashboardTechnician()).toList();
  }

  int get totalTechnicians {
    final mobileTotal = _mobileDashboard?.technicians.total ?? 0;
    if (mobileTotal > 0) return mobileTotal;
    return _activeTechnicians.length;
  }

  // ── Low-stock section (same source as web dashboard product filter) ───────
  List<DashboardLowStockItem> _lowStockItems = [];

  DashboardLowStockSection? get lowStockSection => DashboardLowStockSection(
        total: _lowStockItems.length,
        showing: _lowStockItems.length.clamp(0, 10),
        items: _lowStockItems.take(10).toList(),
      );

  List<DashboardLowStockItem> get dashboardLowStockItems => _lowStockItems;

  int get lowStockDisplayCount => _lowStockItems.length;

  // ── Branch performance (from mobile dashboard, falling back to legacy) ────

  final Map<String, DashboardBranchPerformanceItem> _translatedBranchPerfCache =
      {};

  List<DashboardBranchPerformanceItem> get mobileBranchPerformance {
    final fromMobile = _mobileDashboard?.branchPerformance ?? [];
    final raw = fromMobile.isNotEmpty
        ? fromMobile
        : (_dashboardData?.branchPerformance
                .map((b) => DashboardBranchPerformanceItem(
                      id: b.id,
                      name: b.name,
                      address: b.address,
                      monthlySales: b.monthlySales,
                    ))
                .toList() ??
            []);
    return raw.map((p) => _translatedBranchPerfCache[p.id] ?? p).toList();
  }

  /// Branches with monthly sales filled from dashboard `branchPerformance`.
  /// Catalog `/branches` does not include sales; UI was showing `salesMTD: 0`.
  List<Branch> get branchesWithPerformance {
    final perf = mobileBranchPerformance;
    final salesById = {
      for (final p in perf) p.id: p.monthlySales,
    };
    final nameById = {
      for (final p in perf) p.id: p.name,
    };
    final addressById = {
      for (final p in perf) p.id: p.address,
    };

    if (branches.isNotEmpty) {
      return branches
          .map((b) {
            final sales = salesById[b.id];
            final perfName = _translatedBranchPerfCache[b.id]?.translatedName;
            final perfAddr = _translatedBranchPerfCache[b.id]?.translatedAddress;
            return b.copyWith(
              salesMTD: sales ?? b.salesMTD,
              translatedName: perfName ?? b.translatedName,
              translatedLocation: perfAddr ?? b.translatedLocation,
            );
          })
          .toList();
    }

    return perf
        .map(
          (p) => Branch(
            id: p.id,
            name: nameById[p.id] ?? p.name,
            location: addressById[p.id] ?? p.address,
            vat: '',
            cr: '',
            status: 'Active',
            salesMTD: p.monthlySales,
            translatedName: p.translatedName,
            translatedLocation: p.translatedAddress,
          ),
        )
        .toList();
  }

  /// Period total for the selected date filter (or calendar month).
  /// Used by the Total Sales banner — not the same as [totalSalesToday].
  double get totalSalesPeriod =>
      _mobileDashboard?.summary.totalSalesThisMonth ??
          _dashboardData?.totalSalesThisMonth ??
          combinedBranchSales;

  /// Sum of each branch's sales (from branch performance / salesMTD).
  double get combinedBranchSales {
    final list = branchesWithPerformance;
    if (list.isEmpty) {
      return mobileBranchPerformance.fold<double>(
        0,
        (sum, p) => sum + p.monthlySales,
      );
    }
    return list.fold<double>(0, (sum, b) => sum + b.salesMTD);
  }

  int get branchPerformanceCount => branchesWithPerformance.length;

  // ── Derived ───────────────────────────────────────────────────────────────

  int get activeOrders => selectedBranch != null ? 14 : 0;
  double get technicianWorkload => selectedBranch != null ? 0.85 : 0.0;

  // ── Realtime ──────────────────────────────────────────────────────────────

  Future<void> _bindRealtime(String token) async {
    if (_realtimeBound) return;
    _realtimeService.connect(token);
    _realtimeService.on(
      RealtimeService.eventWorkshopPettyCashUpdated,
      _onWorkshopPettyCashUpdated,
    );
    _realtimeBound = true;
  }

  void _unbindRealtime() {
    if (!_realtimeBound) return;
    _realtimeService.off(
      RealtimeService.eventWorkshopPettyCashUpdated,
      _onWorkshopPettyCashUpdated,
    );
    _realtimeService.disconnect();
    _realtimeBound = false;
  }

  void _onWorkshopPettyCashUpdated(Map<String, dynamic> _) async {
    final token = await sessionService.getToken(role: 'owner');
    if (token == null) return;
    await _fetchPendingPettyCashRequests(token);
    notifyListeners();
  }

  // ── Petty cash actions ────────────────────────────────────────────────────

  Future<bool> approvePettyCashRequest(String requestId) async {
    _approvingRequestId = requestId;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return false;
      final ok =
      await ownerRepository.approvePettyCashRequest(token, requestId);
      if (ok) {
        await _fetchPendingPettyCashRequests(token);
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      _approvingRequestId = null;
      notifyListeners();
    }
  }

  Future<bool> rejectPettyCashRequest(
      String requestId,
      String rejectionReason,
      ) async {
    _rejectingRequestId = requestId;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return false;
      final ok = await ownerRepository.rejectPettyCashRequest(
        token,
        requestId,
        rejectionReason,
      );
      if (ok) {
        await _fetchPendingPettyCashRequests(token);
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      _rejectingRequestId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _unbindRealtime();
    ownerDataService.removeListener(_onOwnerDataChanged);
    unbindLocaleRetranslation();
    super.dispose();
  }
}