import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../models/create_invoice_model.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

// ─── Error types ──────────────────────────────────────────────────────────────

enum ReportsErrorType { network, auth, server, unknown }

class ReportsError {
  final ReportsErrorType type;
  final String message;
  const ReportsError({required this.type, required this.message});

  bool get isRetryable =>
      type == ReportsErrorType.network || type == ReportsErrorType.server;

  String get userFriendlyMessage {
    switch (type) {
      case ReportsErrorType.network:
        return 'No internet connection. Check your network and try again.';
      case ReportsErrorType.auth:
        return 'Session expired. Please log in again.';
      case ReportsErrorType.server:
        return 'Server error. Please try again in a moment.';
      case ReportsErrorType.unknown:
        return message;
    }
  }
}

// ─── View-Model ───────────────────────────────────────────────────────────────

class ReportsManagementViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  final SettingsViewModel? settingsViewModel;

  // ── Branch scope ───────────────────────────────────────────────────────────
  /// null  → allBranches=true
  /// non-null → branchId=X
  String? _selectedBranchId;
  String? get selectedBranchId => _selectedBranchId;
  String? _lastSyncedBranchId;

  /// Called from the shell/dashboard when the user switches branches.
  Future<void> setSelectedBranch(String? branchId) async {
    if (_selectedBranchId == branchId) return;
    _selectedBranchId = branchId;
    _lastSyncedBranchId = branchId;
    await fetchAll();
  }

  // ── Date range filter — app-wide via [OwnerDataService] ─────────────────────
  int _lastSyncedDateGeneration = -1;

  DateTime get fromDate => ownerDataService.filterFrom;
  DateTime get toDate => ownerDataService.filterTo;

  /// Updates the global range (visible tab reload is owned by [OwnerShell]).
  Future<void> setDateRange(DateTime from, DateTime to) async {
    ownerDataService.setFilterRange(from, to);
  }

  /// Inclusive local end of the selected minute (matches API end bound).
  DateTime get _toDateInclusive => DateTime(
        toDate.year,
        toDate.month,
        toDate.day,
        toDate.hour,
        toDate.minute,
        59,
        999,
      );

  bool _orderInSelectedRange(RecentOrder o) {
    final raw =
        o.issuedAt.trim().isNotEmpty ? o.issuedAt.trim() : o.invoiceDate.trim();
    if (raw.isEmpty) return true;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return true;
    final local = parsed.toLocal();
    if (local.isBefore(fromDate)) return false;
    if (local.isAfter(_toDateInclusive)) return false;
    return true;
  }

  // ── Completed orders count ─────────────────────────────────────────────────
  int _completedOrdersCount = 0;
  int get completedOrdersCount => _completedOrdersCount;

  // ── Loading / error state ──────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  ReportsError? _error;
  ReportsError? get error => _error;

  bool get hasError => _error != null;

  // ── Combined analytics data ────────────────────────────────────────────────
  ReportsAnalyticsResponseV2? _reportsData;
  ReportsAnalyticsResponseV2? get reportsData => _reportsData;

  // ── Recent orders (Orders tab) ─────────────────────────────────────────────
  List<RecentOrder> _recentOrders = [];
  List<RecentOrder> get recentOrders => _recentOrders;

  bool _ordersLoading = false;
  bool get ordersLoading => _ordersLoading;

  /// API payment filter for Orders tab (`cash` / `card` / `bank`). null = all.
  String? _ordersPaymentMethod;
  String? get ordersPaymentMethod => _ordersPaymentMethod;

  // ── Retry bookkeeping ──────────────────────────────────────────────────────
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;

  // ── Constructor ───────────────────────────────────────────────────────────
  ReportsManagementViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    this.settingsViewModel,
  }) {
    _selectedBranchId = ownerDataService.selectedBranchId;
    _lastSyncedBranchId = _selectedBranchId;
    _lastSyncedDateGeneration = ownerDataService.dateGeneration;
    ownerDataService.addListener(_onOwnerDataChanged);
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
    fetchAll();
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  // ── Locale re-translation ──────────────────────────────────────────────────
  Future<void> retranslate() async {
    await _applyReportTranslations();
    notifyListeners();
  }

  Future<void> _applyReportTranslations() async {
    final data = _reportsData;
    if (data != null) {
      _reportsData = ReportsAnalyticsResponseV2(
        financialOverview: data.financialOverview,
        operationalPerformance: data.operationalPerformance,
        inventoryValuation: data.inventoryValuation,
        byTechnician: await Future.wait(
            data.byTechnician.map((r) async => r.copyWith(
                translatedName: await tPerson(r.name)))),
        byCustomer: await Future.wait(
            data.byCustomer.map((r) async => r.copyWith(
                translatedCustomerName: await tPerson(r.customerName)))),
        byProduct: await Future.wait(
            data.byProduct.map((r) async => r.copyWith(
                translatedProductName: await t(r.productName)))),
        byDepartment: await Future.wait(
            data.byDepartment.map((r) async => r.copyWith(
                translatedDepartmentName: await t(r.departmentName)))),
        byBranch: await Future.wait(
            data.byBranch.map((r) async => r.copyWith(
                translatedBranchName: await tBranch(r.branchName)))),
        byCashier: await Future.wait(
            data.byCashier.map((r) async => r.copyWith(
                translatedName: await tPerson(r.name)))),
      );
    }
    _recentOrders = await Future.wait(
        _recentOrders.map((o) async => o.copyWith(
            translatedCustomerName: await tPerson(o.customerName))));
  }

  /// Reload reports for the global branch/date when this tab is (or becomes) visible.
  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = ownerDataService.selectedBranchId;
    final nextDateGen = ownerDataService.dateGeneration;
    if (!force &&
        next == _lastSyncedBranchId &&
        nextDateGen == _lastSyncedDateGeneration) {
      return;
    }
    _lastSyncedBranchId = next;
    _lastSyncedDateGeneration = nextDateGen;
    _selectedBranchId = next;
    _reportsData = null;
    _recentOrders = [];
    _completedOrdersCount = 0;
    await fetchAll();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    ownerDataService.removeListener(_onOwnerDataChanged);
    unbindLocaleRetranslation();
    super.dispose();
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Full initial or manual refresh – fetches analytics + orders in parallel.
  Future<void> fetchAll({bool silent = false}) async {
    if (!silent) {
      _isLoading = _reportsData == null;
      _isRefreshing = _reportsData != null;
      _error = null;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      // Run sequentially so both heavy DB queries don't contend on one Nest
      // instance (parallel often pushes analytics past the client timeout).
      await _fetchAnalytics(token, branchId: _selectedBranchId);
      await _fetchRecentOrders(token, branchId: _selectedBranchId);
      await _applyReportTranslations();
      _retryCount = 0;
      _error = null;
    } catch (e) {
      _error = _classify(e);
      debugPrint('[ReportsVM] fetchAll error: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Soft refresh – shows spinner only if no data yet.
  Future<void> refresh() => fetchAll(silent: _reportsData != null);

  /// Orders payment tab (`cash` / `card` / `bank` / null for All) — refetch list only.
  Future<void> setOrdersPaymentMethod(String? apiValue) async {
    final next = (apiValue == null || apiValue.trim().isEmpty)
        ? null
        : apiValue.trim().toLowerCase();
    if (_ordersPaymentMethod == next) return;
    _ordersPaymentMethod = next;
    _ordersLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      await _fetchRecentOrders(token, branchId: _selectedBranchId);
      _recentOrders = await Future.wait(
          _recentOrders.map((o) async => o.copyWith(
              translatedCustomerName: await tPerson(o.customerName))));
    } catch (e) {
      debugPrint('[ReportsVM] setOrdersPaymentMethod error: $e');
    } finally {
      _ordersLoading = false;
      notifyListeners();
    }
  }

  /// Loads full invoice payload for the Simplified Tax Invoice dialog (same as web).
  Future<Invoice?> fetchRecentOrderInvoice(String invoiceId) async {
    final id = invoiceId.trim();
    if (id.isEmpty) return null;
    final token = await _getToken();
    final raw = await ownerRepository
        .getRecentOrderInvoicePdf(
      token,
      id,
      branchId: _selectedBranchId,
      allBranches: _selectedBranchId == null,
      startDate: fromDate,
      endDate: toDate,
    )
        .timeout(const Duration(seconds: 30));
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    final invoiceRaw = map['invoice'];
    if (invoiceRaw is! Map) return null;
    return Invoice.fromJson(Map<String, dynamic>.from(invoiceRaw));
  }

  /// Auto-retry with back-off (used from UI retry button).
  Future<void> retryFetch() async {
    if (_retryCount >= _maxRetries) {
      _retryCount = 0; // reset so user can try again after max reached
    }
    _retryCount++;
    final delay = Duration(seconds: _retryCount * 2); // 2 s, 4 s, 6 s
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => fetchAll());
    notifyListeners(); // triggers a possible "retrying in X s" UI hint
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Future<String> _getToken() async {
    final token = await sessionService.getToken(role: 'owner');
    if (token == null || token.isEmpty) {
      throw _AuthException('No auth token found');
    }
    return token;
  }

  Future<void> _fetchAnalytics(String token, {String? branchId}) async {
    try {
      final raw = await ownerRepository
          .getReportsAnalytics(
        token,
        branchId: branchId,
        allBranches: branchId == null,
        startDate: fromDate,
        endDate: toDate,
      )
          .timeout(const Duration(seconds: 90));

      if (raw != null && raw['success'] == true) {
        _reportsData = ReportsAnalyticsResponseV2.fromJson(
            raw as Map<String, dynamic>);
      } else {
        debugPrint('[ReportsVM] Analytics returned success=false');
      }
    } catch (e) {
      // Don't swallow – let parent handle
      rethrow;
    }
  }

  Future<void> _fetchRecentOrders(String token, {String? branchId}) async {
    _ordersLoading = true;
    try {
      final raw = await ownerRepository
          .getRecentOrders(
        token,
        branchId: branchId,
        allBranches: branchId == null,
        startDate: fromDate,
        endDate: toDate,
        paymentMethod: _ordersPaymentMethod,
        limit: 100,
      )
          .timeout(const Duration(seconds: 60));

      if (raw != null && raw['success'] == true) {
        final resp = RecentOrdersResponse.fromJson(raw as Map<String, dynamic>);
        // Orders tab only shows invoiced rows (same as web invoice preview flow).
        _recentOrders = resp.rows.where((o) {
          if (o.listingKind.toLowerCase() == 'open') return false;
          if (o.invoiceId.trim().isEmpty) return false;
          final status = o.orderStatus.trim().toLowerCase();
          if (status == 'draft' || status == 'open' || status == 'pending') {
            return false;
          }
          // Enforce selected date+time window client-side (issuedAt / invoiceDate).
          if (!_orderInSelectedRange(o)) return false;
          return true;
        }).toList();
        _completedOrdersCount = _recentOrders.length;
      }
    } catch (e) {
      debugPrint('[ReportsVM] getRecentOrders error: $e');
      // Non-fatal – orders tab will show empty state, main analytics still shows
    } finally {
      _ordersLoading = false;
    }
  }

  ReportsError _classify(Object e) {
    if (e is SocketException || e is TimeoutException) {
      return const ReportsError(
          type: ReportsErrorType.network,
          message: 'Network request failed');
    }
    if (e is _AuthException) {
      return ReportsError(
          type: ReportsErrorType.auth, message: e.message);
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('500') || msg.contains('503') || msg.contains('502')) {
      return ReportsError(
          type: ReportsErrorType.server, message: e.toString());
    }
    if (msg.contains('401') || msg.contains('403')) {
      return const ReportsError(
          type: ReportsErrorType.auth, message: 'Unauthorized');
    }
    return ReportsError(
        type: ReportsErrorType.unknown, message: e.toString());
  }
}

class _AuthException implements Exception {
  final String message;
  _AuthException(this.message);
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS — add these to workshop_owner_models.dart or keep here and import
// ─────────────────────────────────────────────────────────────────────────────

// ── RecentOrder ───────────────────────────────────────────────────────────────
class RecentOrder {
  final String listingKind;
  final String invoiceId;
  final String salesOrderId;
  final String invoiceNo;
  final String invoiceDate;
  final String issuedAt;
  final String orderSource;
  final String orderStatus;
  final String customerName;
  final String customerMobile;
  final String plateNo;
  final double invoiceTotal;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedCustomerName;

  String get displayCustomerName => translatedCustomerName ?? customerName;

  const RecentOrder({
    required this.listingKind,
    required this.invoiceId,
    required this.salesOrderId,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.issuedAt,
    required this.orderSource,
    required this.orderStatus,
    required this.customerName,
    required this.customerMobile,
    required this.plateNo,
    required this.invoiceTotal,
    this.translatedCustomerName,
  });

  RecentOrder copyWith({
    String? listingKind,
    String? invoiceId,
    String? salesOrderId,
    String? invoiceNo,
    String? invoiceDate,
    String? issuedAt,
    String? orderSource,
    String? orderStatus,
    String? customerName,
    String? customerMobile,
    String? plateNo,
    double? invoiceTotal,
    String? translatedCustomerName,
  }) {
    return RecentOrder(
      listingKind: listingKind ?? this.listingKind,
      invoiceId: invoiceId ?? this.invoiceId,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      issuedAt: issuedAt ?? this.issuedAt,
      orderSource: orderSource ?? this.orderSource,
      orderStatus: orderStatus ?? this.orderStatus,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      plateNo: plateNo ?? this.plateNo,
      invoiceTotal: invoiceTotal ?? this.invoiceTotal,
      translatedCustomerName:
          translatedCustomerName ?? this.translatedCustomerName,
    );
  }

  factory RecentOrder.fromJson(Map<String, dynamic> j) => RecentOrder(
    listingKind: j['listingKind'] ?? '',
    invoiceId: j['invoiceId']?.toString() ?? '',
    salesOrderId: j['salesOrderId']?.toString() ?? '',
    invoiceNo: j['invoiceNo'] ?? '',
    invoiceDate: j['invoiceDate'] ?? '',
    issuedAt: j['issuedAt'] ?? '',
    orderSource: j['orderSource'] ?? '',
    orderStatus: j['orderStatus'] ?? '',
    customerName: j['customerName'] ?? '',
    customerMobile: j['customerMobile'] ?? '',
    plateNo: j['plateNo'] ?? '',
    invoiceTotal:
    double.tryParse(j['invoiceTotal']?.toString() ?? '0') ?? 0.0,
  );
}

class RecentOrdersResponse {
  final bool success;
  final int total;
  final List<RecentOrder> rows;

  const RecentOrdersResponse(
      {required this.success, required this.total, required this.rows});

  factory RecentOrdersResponse.fromJson(Map<String, dynamic> j) =>
      RecentOrdersResponse(
        success: j['success'] ?? false,
        total: int.tryParse(j['total']?.toString() ?? '0') ?? 0,
        rows: (j['rows'] as List?)
            ?.map((e) => RecentOrder.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
      );
}

// ── TechnicianReportRow ───────────────────────────────────────────────────────
class TechnicianReportRow {
  final String technicianId;
  final String name;
  final int completedJobs;
  final double commissionSar;
  final double revenueSar;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;

  String get displayName => translatedName ?? name;

  const TechnicianReportRow({
    required this.technicianId,
    required this.name,
    required this.completedJobs,
    required this.commissionSar,
    required this.revenueSar,
    this.translatedName,
  });

  TechnicianReportRow copyWith({
    String? technicianId,
    String? name,
    int? completedJobs,
    double? commissionSar,
    double? revenueSar,
    String? translatedName,
  }) {
    return TechnicianReportRow(
      technicianId: technicianId ?? this.technicianId,
      name: name ?? this.name,
      completedJobs: completedJobs ?? this.completedJobs,
      commissionSar: commissionSar ?? this.commissionSar,
      revenueSar: revenueSar ?? this.revenueSar,
      translatedName: translatedName ?? this.translatedName,
    );
  }

  factory TechnicianReportRow.fromJson(Map<String, dynamic> j) =>
      TechnicianReportRow(
        technicianId: j['technician_id']?.toString() ?? '',
        name: j['name'] ?? '',
        completedJobs:
        int.tryParse(j['completed_jobs']?.toString() ?? '0') ?? 0,
        commissionSar:
        double.tryParse(j['commission_sar']?.toString() ?? '0') ?? 0.0,
        revenueSar:
        double.tryParse(j['revenue_sar']?.toString() ?? '0') ?? 0.0,
      );
}

// ── CustomerReportRow ─────────────────────────────────────────────────────────
class CustomerReportRow {
  final String customerId;
  final String customerName;
  final String phone;
  final int ordersCount;
  final double revenueSar;
  final List<String> plateNumbers;
  final String plateNo;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedCustomerName;

  String get displayCustomerName => translatedCustomerName ?? customerName;

  const CustomerReportRow({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.ordersCount,
    required this.revenueSar,
    required this.plateNumbers,
    required this.plateNo,
    this.translatedCustomerName,
  });

  CustomerReportRow copyWith({
    String? customerId,
    String? customerName,
    String? phone,
    int? ordersCount,
    double? revenueSar,
    List<String>? plateNumbers,
    String? plateNo,
    String? translatedCustomerName,
  }) {
    return CustomerReportRow(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      ordersCount: ordersCount ?? this.ordersCount,
      revenueSar: revenueSar ?? this.revenueSar,
      plateNumbers: plateNumbers ?? this.plateNumbers,
      plateNo: plateNo ?? this.plateNo,
      translatedCustomerName:
          translatedCustomerName ?? this.translatedCustomerName,
    );
  }

  factory CustomerReportRow.fromJson(Map<String, dynamic> j) =>
      CustomerReportRow(
        customerId: (j['customer_id'] ?? j['customerId'])?.toString() ?? '',
        customerName: j['customer_name'] ?? j['customerName'] ?? '',
        phone: j['phone'] ??
            j['customer_mobile'] ??
            j['customerMobile'] ??
            '',
        ordersCount: int.tryParse(
                (j['orders_count'] ?? j['ordersCount'])?.toString() ?? '0') ??
            0,
        revenueSar: double.tryParse(
                (j['revenue_sar'] ?? j['revenueSar'])?.toString() ?? '0') ??
            0.0,
        plateNumbers: (j['plate_numbers'] as List? ??
                j['plateNumbers'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
            [],
        plateNo: j['plate_no'] ?? j['plateNo'] ?? '',
      );
}

// ── ProductReportRow ──────────────────────────────────────────────────────────
class ProductReportRow {
  final String productId;
  final String productName;
  final String itemType;
  final int qtySold;
  final double revenueSar;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedProductName;

  String get displayProductName => translatedProductName ?? productName;

  const ProductReportRow({
    required this.productId,
    required this.productName,
    required this.itemType,
    required this.qtySold,
    required this.revenueSar,
    this.translatedProductName,
  });

  ProductReportRow copyWith({
    String? productId,
    String? productName,
    String? itemType,
    int? qtySold,
    double? revenueSar,
    String? translatedProductName,
  }) {
    return ProductReportRow(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      itemType: itemType ?? this.itemType,
      qtySold: qtySold ?? this.qtySold,
      revenueSar: revenueSar ?? this.revenueSar,
      translatedProductName:
          translatedProductName ?? this.translatedProductName,
    );
  }

  factory ProductReportRow.fromJson(Map<String, dynamic> j) =>
      ProductReportRow(
        productId: (j['product_id'] ?? j['productId'])?.toString() ?? '',
        productName: j['product_name'] ?? j['productName'] ?? '',
        itemType: j['item_type'] ?? j['itemType'] ?? '',
        qtySold: (double.tryParse(
                    (j['qty_sold'] ?? j['qtySold'])?.toString() ?? '0') ??
                0.0)
            .round(),
        revenueSar: double.tryParse(
                (j['revenue_sar'] ?? j['revenueSar'])?.toString() ?? '0') ??
            0.0,
      );
}

// ── DepartmentReportRow ───────────────────────────────────────────────────────
class DepartmentReportRow {
  final String departmentId;
  final String departmentName;
  final double revenueSar;
  final int ordersCount;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedDepartmentName;

  String get displayDepartmentName =>
      translatedDepartmentName ?? departmentName;

  const DepartmentReportRow({
    required this.departmentId,
    required this.departmentName,
    required this.revenueSar,
    required this.ordersCount,
    this.translatedDepartmentName,
  });

  DepartmentReportRow copyWith({
    String? departmentId,
    String? departmentName,
    double? revenueSar,
    int? ordersCount,
    String? translatedDepartmentName,
  }) {
    return DepartmentReportRow(
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      revenueSar: revenueSar ?? this.revenueSar,
      ordersCount: ordersCount ?? this.ordersCount,
      translatedDepartmentName:
          translatedDepartmentName ?? this.translatedDepartmentName,
    );
  }

  factory DepartmentReportRow.fromJson(Map<String, dynamic> j) =>
      DepartmentReportRow(
        departmentId:
            (j['department_id'] ?? j['departmentId'])?.toString() ?? '',
        departmentName: j['department_name'] ?? j['departmentName'] ?? '',
        revenueSar: double.tryParse(
                (j['revenue_sar'] ?? j['revenueSar'])?.toString() ?? '0') ??
            0.0,
        ordersCount: int.tryParse(
                (j['orders_count'] ?? j['ordersCount'])?.toString() ?? '0') ??
            0,
      );
}

// ── BranchReportRow ───────────────────────────────────────────────────────────
class BranchReportRow {
  final String branchId;
  final String branchName;
  final double revenueSar;
  final int completedOrders;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedBranchName;

  String get displayBranchName => translatedBranchName ?? branchName;

  const BranchReportRow({
    required this.branchId,
    required this.branchName,
    required this.revenueSar,
    required this.completedOrders,
    this.translatedBranchName,
  });

  BranchReportRow copyWith({
    String? branchId,
    String? branchName,
    double? revenueSar,
    int? completedOrders,
    String? translatedBranchName,
  }) {
    return BranchReportRow(
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      revenueSar: revenueSar ?? this.revenueSar,
      completedOrders: completedOrders ?? this.completedOrders,
      translatedBranchName:
          translatedBranchName ?? this.translatedBranchName,
    );
  }

  factory BranchReportRow.fromJson(Map<String, dynamic> j) => BranchReportRow(
        branchId: (j['branch_id'] ?? j['branchId'])?.toString() ?? '',
        branchName: j['branch_name'] ?? j['branchName'] ?? '',
        revenueSar: double.tryParse(
                (j['revenue_sar'] ?? j['revenueSar'])?.toString() ?? '0') ??
            0.0,
        completedOrders: int.tryParse((j['completed_orders'] ??
                    j['completedOrders'] ??
                    j['orders_count'] ??
                    j['ordersCount'])
                ?.toString() ??
            '0') ??
            0,
      );
}

// ── CashierReportRow ──────────────────────────────────────────────────────────
class CashierReportRow {
  final String cashierId;
  final String userId;
  final String name;
  final int ordersCount;
  final double revenueSar;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;

  String get displayName => translatedName ?? name;

  const CashierReportRow({
    required this.cashierId,
    required this.userId,
    required this.name,
    required this.ordersCount,
    required this.revenueSar,
    this.translatedName,
  });

  CashierReportRow copyWith({
    String? cashierId,
    String? userId,
    String? name,
    int? ordersCount,
    double? revenueSar,
    String? translatedName,
  }) {
    return CashierReportRow(
      cashierId: cashierId ?? this.cashierId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      ordersCount: ordersCount ?? this.ordersCount,
      revenueSar: revenueSar ?? this.revenueSar,
      translatedName: translatedName ?? this.translatedName,
    );
  }

  factory CashierReportRow.fromJson(Map<String, dynamic> j) => CashierReportRow(
        cashierId: (j['cashier_id'] ?? j['cashierId'])?.toString() ?? '',
        userId: (j['user_id'] ?? j['userId'])?.toString() ?? '',
        name: j['name'] ?? j['cashier_name'] ?? j['cashierName'] ?? '',
        ordersCount: int.tryParse(
                (j['orders_count'] ?? j['ordersCount'])?.toString() ?? '0') ??
            0,
        revenueSar: double.tryParse(
                (j['revenue_sar'] ?? j['revenueSar'])?.toString() ?? '0') ??
            0.0,
      );
}

// ── ReportsAnalyticsResponseV2 ────────────────────────────────────────────────
class ReportsAnalyticsResponseV2 {
  final FinancialOverview financialOverview;
  final List<OperationalPerformance> operationalPerformance;
  final InventoryValuation inventoryValuation;
  final List<TechnicianReportRow> byTechnician;
  final List<CustomerReportRow> byCustomer;
  final List<ProductReportRow> byProduct;
  final List<DepartmentReportRow> byDepartment;
  final List<BranchReportRow> byBranch;
  final List<CashierReportRow> byCashier;

  const ReportsAnalyticsResponseV2({
    required this.financialOverview,
    required this.operationalPerformance,
    required this.inventoryValuation,
    required this.byTechnician,
    required this.byCustomer,
    required this.byProduct,
    required this.byDepartment,
    required this.byBranch,
    required this.byCashier,
  });

  factory ReportsAnalyticsResponseV2.fromJson(Map<String, dynamic> j) =>
      ReportsAnalyticsResponseV2(
        financialOverview:
        FinancialOverview.fromJson(j['financialOverview'] ?? {}),
        operationalPerformance: (j['operationalPerformance'] as List?)
            ?.map((e) => OperationalPerformance.fromJson(
            e as Map<String, dynamic>))
            .toList() ??
            [],
        inventoryValuation:
        InventoryValuation.fromJson(j['inventoryValuation'] ?? {}),
        byTechnician: (j['by_technician'] as List? ?? j['byTechnician'] as List?)
            ?.map((e) => TechnicianReportRow.fromJson(
                e as Map<String, dynamic>))
            .toList() ??
            [],
        byCustomer: (j['by_customer'] as List? ?? j['byCustomer'] as List?)
            ?.map((e) =>
                CustomerReportRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        byProduct: (j['by_product'] as List? ?? j['byProduct'] as List?)
            ?.map((e) =>
                ProductReportRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        byDepartment:
            (j['by_department'] as List? ?? j['byDepartment'] as List?)
                ?.map((e) =>
                    DepartmentReportRow.fromJson(e as Map<String, dynamic>))
                .toList() ??
                [],
        byBranch: (j['by_branch'] as List? ?? j['byBranch'] as List?)
            ?.map((e) =>
                BranchReportRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        byCashier: (j['by_cashier'] as List? ?? j['byCashier'] as List?)
            ?.map((e) =>
                CashierReportRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
      );
}