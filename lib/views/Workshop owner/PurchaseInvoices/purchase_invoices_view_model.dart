// =============================================================================
// purchase_invoices_view_model.dart
// ViewModel for PurchaseInvoicesView — fully integrated with real APIs.
//
// APIs used on init (parallel):
//   GET /workshop-suppliers/local/purchase-invoices?limit=100&offset=0
//   GET /workshop-staff/supplier-purchase-invoices?limit=100&offset=0
//   GET /workshop-staff/products  (for product search in New Invoice form)
//   GET /workshop-staff/suppliers (for vendor dropdown)
//   GET /workshop-staff/branches  (for branch dropdown)
//
// APIs used on vendor select:
//   GET /workshop-staff/suppliers/{id}/last-purchase-prices?branchId=X
//   GET /workshop-staff/suppliers/{id}/product-uom-rules?branchId=X
//
// API used on form submit:
//   POST /workshop-staff/supplier-purchase-invoices
// =============================================================================

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';

// =============================================================================
// Enums
// =============================================================================

enum PurchaseInvoiceStatus {
  pending,
  approved,
  delivered,
  completed,
  draft,
  rejected;

  String labelFor(AppLocalizations l10n) {
    switch (this) {
      case PurchaseInvoiceStatus.pending:
        return l10n.ownerPurchaseInvoicesStatusPending;
      case PurchaseInvoiceStatus.approved:
        return l10n.ownerPurchaseInvoicesStatusApproved;
      case PurchaseInvoiceStatus.delivered:
        return l10n.ownerPurchaseInvoicesStatusDelivered;
      case PurchaseInvoiceStatus.completed:
        return l10n.ownerPurchaseInvoicesStatusCompleted;
      case PurchaseInvoiceStatus.draft:
        return l10n.ownerPurchaseInvoicesStatusDraft;
      case PurchaseInvoiceStatus.rejected:
        return l10n.ownerPurchaseInvoicesStatusRejected;
    }
  }

  String get label {
    switch (this) {
      case PurchaseInvoiceStatus.pending:   return 'Pending';
      case PurchaseInvoiceStatus.approved:  return 'Approved';
      case PurchaseInvoiceStatus.delivered: return 'Delivered';
      case PurchaseInvoiceStatus.completed: return 'Completed';
      case PurchaseInvoiceStatus.draft:     return 'Draft';
      case PurchaseInvoiceStatus.rejected:  return 'Rejected';
    }
  }
}

enum PurchaseInvoicesTab { invoices, priceReport }
enum DiscountType { fixed, percent }
enum DueDateType { net, eom, custom }

// =============================================================================
// Account code model
// =============================================================================

class AccountCode {
  final String code;
  final String label;

  const AccountCode({required this.code, required this.label});

  String get display => '$code - $label';

  static const List<AccountCode> all = [
    AccountCode(code: '5100', label: 'Cost of Goods Sold'),
    AccountCode(code: '6100', label: 'Rent Expense'),
    AccountCode(code: '6200', label: 'Utilities Expense'),
    AccountCode(code: '1410', label: 'Inventory Asset'),
    AccountCode(code: '4100', label: 'Sales Revenue'),
  ];

  static AccountCode get defaultAccount =>
      all.firstWhere((a) => a.code == '1410');
}

// =============================================================================
// Tax-code model
// =============================================================================

class TaxCode {
  final String code;
  final double rate;
  final String label;

  const TaxCode({required this.code, required this.rate, required this.label});

  static const List<TaxCode> all = [
    TaxCode(code: 'VAT15',  rate: 0.15, label: 'VAT 15%'),
    TaxCode(code: 'EXEMPT', rate: 0.00, label: 'Exempt'),
    TaxCode(code: 'ZERO',   rate: 0.00, label: 'Zero Rated'),
  ];

  static TaxCode get defaultCode =>
      all.firstWhere((t) => t.code == 'VAT15');
}

// =============================================================================
// Supplier last-price + UOM cache models
// =============================================================================

class SupplierProductPrice {
  final String productId;
  final double lastUnitPriceExVat;
  final double lastUnitPriceInclVat;
  final String uom;

  const SupplierProductPrice({
    required this.productId,
    required this.lastUnitPriceExVat,
    required this.lastUnitPriceInclVat,
    required this.uom,
  });

  factory SupplierProductPrice.fromJson(Map<String, dynamic> j) =>
      SupplierProductPrice(
        productId:             j['productId']?.toString() ?? '',
        lastUnitPriceExVat:    _d(j['lastUnitPriceExVat']),
        lastUnitPriceInclVat:  _d(j['lastUnitPriceInclVat']),
        uom:                   j['uom']?.toString() ?? '',
      );

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class SupplierUomRule {
  final String productId;
  final String? supplierProductId;
  final String warehouseUnit;
  final String workshopUnit;
  final double conversionFactor;

  const SupplierUomRule({
    required this.productId,
    this.supplierProductId,
    required this.warehouseUnit,
    required this.workshopUnit,
    required this.conversionFactor,
  });

  factory SupplierUomRule.fromJson(Map<String, dynamic> j) =>
      SupplierUomRule(
        productId:         j['productId']?.toString() ?? '',
        supplierProductId: j['supplierProductId']?.toString(),
        warehouseUnit:     j['warehouseUnit']?.toString() ?? '',
        workshopUnit:      j['workshopUnit']?.toString() ?? '',
        conversionFactor:  _d(j['conversionFactor']),
      );

  static double _d(dynamic v) {
    if (v == null) return 1.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 1.0;
  }
}

// =============================================================================
// Line-item model  (used for saved invoices)
// =============================================================================

class PurchaseInvoiceItem {
  final String productName;
  final String accountCode;
  final String description;
  final double qty;
  final String uom;
  final double unitPrice;
  final String taxCode;
  final double taxRate;
  final double? lastSupplierPrice;

  double get totalExcl => qty * unitPrice;
  double get taxAmt    => totalExcl * taxRate;
  double get totalIncl => totalExcl + taxAmt;

  const PurchaseInvoiceItem({
    required this.productName,
    required this.accountCode,
    required this.description,
    required this.qty,
    required this.uom,
    required this.unitPrice,
    required this.taxCode,
    required this.taxRate,
    this.lastSupplierPrice,
  });
}

// =============================================================================
// Purchase-invoice entity  (the saved record shown in the list)
// =============================================================================

enum InvoiceKind { local, supplier }

class PurchaseInvoiceEntity {
  final String id;
  final String invoiceNo;
  final String vendorName;
  final String vendorId;
  final String branchName;
  final String branchId;
  final String ref;
  final DateTime issueDate;
  final DateTime dueDate;
  final String description;
  final PurchaseInvoiceStatus status;
  final String paymentStatus; // paid | unpaid | partially_paid
  final bool stockUpdated;
  final List<PurchaseInvoiceItem> items;
  final double discount;
  final double freight;
  final InvoiceKind invoiceKind;

  final double _subtotal;
  final double _totalTax;
  final double _grandTotal;
  final double _amountPaid;
  final double _balance;

  double get subtotal   => _subtotal;
  double get totalTax   => _totalTax;
  double get grandTotal => _grandTotal;
  double get amountPaid => _amountPaid;
  double get balance    => _balance;
  bool   get isUnpaid   => paymentStatus != 'paid' && _balance > 0;
  bool   get isPaid     => paymentStatus == 'paid' || _balance <= 0;

  PurchaseInvoiceEntity({
    required this.id,
    required this.invoiceNo,
    required this.vendorName,
    required this.vendorId,
    required this.branchName,
    required this.branchId,
    required this.ref,
    required this.issueDate,
    required this.dueDate,
    required this.description,
    required this.status,
    this.paymentStatus = 'unpaid',
    required this.stockUpdated,
    required this.items,
    this.discount = 0.0,
    this.freight  = 0.0,
    this.invoiceKind = InvoiceKind.supplier,
    double subtotal   = 0.0,
    double totalTax   = 0.0,
    double grandTotal = 0.0,
    double amountPaid = 0.0,
    double balance    = 0.0,
  })  : _subtotal   = subtotal,
        _totalTax   = totalTax,
        _grandTotal = grandTotal,
        _amountPaid = amountPaid,
        _balance    = balance;

  factory PurchaseInvoiceEntity.fromLocalJson(Map<String, dynamic> j) =>
      PurchaseInvoiceEntity._fromApiJson(j, InvoiceKind.local);

  factory PurchaseInvoiceEntity.fromSupplierJson(Map<String, dynamic> j) =>
      PurchaseInvoiceEntity._fromApiJson(j, InvoiceKind.supplier);

  /// Aligns with web `normalizeWorkshopSupplierPurchaseInvoiceRow`.
  factory PurchaseInvoiceEntity._fromApiJson(
    Map<String, dynamic> j,
    InvoiceKind kind,
  ) {
    final kindFromApi = j['_invoiceKind']?.toString() == 'local'
        ? InvoiceKind.local
        : kind;
    final supplier = j['supplier'] is Map
        ? Map<String, dynamic>.from(j['supplier'] as Map)
        : null;
    final branch = j['branch'] is Map
        ? Map<String, dynamic>.from(j['branch'] as Map)
        : null;
    final payload = j['payload'] is Map
        ? Map<String, dynamic>.from(j['payload'] as Map)
        : null;
    final payloadTotals = payload?['totals'] is Map
        ? Map<String, dynamic>.from(payload!['totals'] as Map)
        : null;

    final vendorName = _firstNonEmpty([
          j['vendor_name'],
          j['vendorName'],
          j['supplier_name'],
          j['supplierName'],
          supplier?['name'],
          supplier?['supplierName'],
        ]) ??
        '';

    final statusStr =
        (j['status'] ?? j['state'] ?? 'pending').toString().toLowerCase();
    final status = _parseStatus(statusStr);

    final rawItems = (j['items'] as List?) ?? (j['lines'] as List?) ?? [];
    final items = rawItems.map((i) {
      final m = Map<String, dynamic>.from(i as Map);
      final nested = m['product'] is Map
          ? Map<String, dynamic>.from(m['product'] as Map)
          : null;
      return PurchaseInvoiceItem(
        productName: _firstNonEmpty([
              m['product_name'],
              m['productName'],
              m['itemName'],
              m['item_name'],
              nested?['name'],
              m['description'],
            ]) ??
            '',
        accountCode: '1410',
        description: m['description']?.toString() ?? '',
        qty: _toDouble(m['quantity'] ?? m['qty']),
        uom: _firstNonEmpty([m['unit'], m['uom']]) ?? '',
        unitPrice: _toDouble(m['unit_price'] ?? m['unitPrice']),
        taxCode: 'VAT15',
        taxRate: 0.15,
      );
    }).toList();

    final subtotal = _toDouble(
      j['subtotalExVat'] ??
          j['subtotal_ex_vat'] ??
          j['subtotalExcludingVat'] ??
          j['subtotal'],
    );

    var totalTax = _toDouble(
      (status == PurchaseInvoiceStatus.draft
              ? (payloadTotals?['total_vat'] ?? payloadTotals?['totalVat'])
              : null) ??
          j['taxAmount'] ??
          j['tax_amount'] ??
          j['totalVat'] ??
          j['total_vat'] ??
          j['vatAmount'] ??
          j['vat_amount'],
    );

    final grandTotal = _toDouble(
      (status == PurchaseInvoiceStatus.draft
              ? (payloadTotals?['grand_total'] ?? payloadTotals?['grandTotal'])
              : null) ??
          j['grandTotal'] ??
          j['grand_total'] ??
          j['totalInclVat'] ??
          j['total'],
    );

    final amountPaid = _toDouble(
      j['paidAmount'] ?? j['amountPaid'] ?? j['amount_paid'],
    );

    var balance = _toDouble(
      status == PurchaseInvoiceStatus.draft
          ? null
          : (j['balance'] ?? j['balanceDue'] ?? j['balance_due']),
    );
    if (status == PurchaseInvoiceStatus.draft ||
        (balance == 0 && grandTotal > 0 && !j.containsKey('balance'))) {
      balance = (grandTotal - amountPaid).clamp(0.0, double.infinity);
    }

    final paymentStatus = (j['paymentStatus'] ??
            j['payment_status'] ??
            (amountPaid >= grandTotal && grandTotal > 0
                ? 'paid'
                : balance <= 0 && grandTotal > 0
                    ? 'paid'
                    : amountPaid > 0
                        ? 'partially_paid'
                        : 'unpaid'))
        .toString()
        .toLowerCase();

    final stockUpdated = j['stockAppliedAt'] != null ||
        j['stock_applied_at'] != null ||
        j['stockUpdated'] == true ||
        j['stock_updated'] == true ||
        j['stockReceived'] == true ||
        j['stock_received'] == true;

    final invoiceNo = _firstNonEmpty([
          j['invoiceNumber'],
          j['invoice_number'],
          j['reference'],
          j['ref'],
        ]) ??
        (j['id']?.toString() ?? '');

    final branchId = _firstNonEmpty([
          j['branchId'],
          j['branch_id'],
          branch?['id'],
        ]) ??
        '';
    final branchName = _firstNonEmpty([
          branch?['name'],
          j['branchName'],
          j['branch_name'],
        ]) ??
        (branchId.isNotEmpty ? 'Branch $branchId' : '');

    return PurchaseInvoiceEntity(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      invoiceNo: invoiceNo,
      vendorName: vendorName,
      vendorId: supplier?['id']?.toString() ??
          j['supplierId']?.toString() ??
          j['supplier_id']?.toString() ??
          '',
      branchName: branchName,
      branchId: branchId,
      ref: _firstNonEmpty([
            j['vendorInvoiceRef'],
            j['vendor_invoice_ref'],
            j['vendorRef'],
            j['refNumber'],
            j['ref_number'],
          ]) ??
          '',
      issueDate: _parseDate(_firstNonEmpty([
            j['issueDate'],
            j['issue_date'],
            j['createdAt'],
            j['created_at'],
          ]) ??
          ''),
      dueDate: _parseDate(
          _firstNonEmpty([j['dueDate'], j['due_date']]) ?? ''),
      description: _firstNonEmpty([
            j['description'],
            j['title'],
            payload?['description'],
          ]) ??
          '',
      status: status,
      paymentStatus: paymentStatus,
      stockUpdated: stockUpdated,
      items: items,
      freight: _toDouble(
        j['freightIn'] ??
            j['freight_in'] ??
            payload?['freight_in'] ??
            payloadTotals?['freight_in'],
      ),
      invoiceKind: kindFromApi,
      subtotal: subtotal,
      totalTax: totalTax,
      grandTotal: grandTotal,
      amountPaid: amountPaid,
      balance: balance,
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _parseDate(String s) {
    if (s.isEmpty) return DateTime.now();
    return DateTime.tryParse(s) ?? DateTime.now();
  }

  static PurchaseInvoiceStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return PurchaseInvoiceStatus.approved;
      case 'delivered':
        return PurchaseInvoiceStatus.delivered;
      case 'completed':
        return PurchaseInvoiceStatus.completed;
      case 'draft':
        return PurchaseInvoiceStatus.draft;
      case 'rejected':
        return PurchaseInvoiceStatus.rejected;
      default:
        return PurchaseInvoiceStatus.pending;
    }
  }
}

// =============================================================================
// Purchase Price Report row
// =============================================================================

class PurchasePriceReportRow {
  final String productName;
  final String vendorName;
  final String vendorId;
  final String invoiceNo;
  final DateTime date;
  final double qty;
  final String unit;
  final double unitPrice;
  final double lineTotal;
  final double taxAmt;
  final double grandTotal;

  const PurchasePriceReportRow({
    required this.productName,
    required this.vendorName,
    required this.vendorId,
    required this.invoiceNo,
    required this.date,
    required this.qty,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
    required this.taxAmt,
    required this.grandTotal,
  });
}

// =============================================================================
// Item-draft  (mutable row inside the New Invoice form)
// =============================================================================

class ItemDraft {
  final TextEditingController productCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  AccountCode selectedAccount;
  TaxCode     selectedTaxCode;

  // ── Set when user picks a product from the dropdown ──────────────────────
  String  productId;          // branch_catalog_product_id
  String  uom;                // warehouseUnit (what supplier sells in)
  String  workshopUnit;       // for display / payload
  double  conversionFactor;
  String? supplierProductId;
  double? lastSupplierPrice;  // incl. VAT, from last-purchase-prices API

  ItemDraft({
    String? product,
    String? description,
    String? qty,
    String? price,
    AccountCode? account,
    TaxCode? taxCode,
    String? uom,
    String? workshopUnit,
    String? productId,
    double? conversionFactor,
    this.supplierProductId,
    this.lastSupplierPrice,
  })  : productCtrl      = TextEditingController(text: product ?? ''),
        descriptionCtrl  = TextEditingController(text: description ?? ''),
        qtyCtrl          = TextEditingController(text: qty ?? '1'),
        priceCtrl        = TextEditingController(text: price ?? ''),
        selectedAccount  = account ?? AccountCode.defaultAccount,
        selectedTaxCode  = taxCode ?? TaxCode.defaultCode,
        uom              = uom ?? 'piece',
        workshopUnit     = workshopUnit ?? '',
        productId        = productId ?? '',
        conversionFactor = conversionFactor ?? 1;

  void dispose() {
    productCtrl.dispose();
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  double get _qty   => double.tryParse(qtyCtrl.text) ?? 0.0;
  double get _price => double.tryParse(priceCtrl.text) ?? 0.0;
  double get lineExcl => _qty * _price;
  double get lineTax  => lineExcl * selectedTaxCode.rate;
  double get lineIncl => lineExcl + lineTax;
}

// =============================================================================
// ViewModel
// =============================================================================

class PurchaseInvoicesViewModel extends ChangeNotifier {
  final OwnerRepository _repo;
  final SessionService _session;
  final OwnerDataService? _ownerData;
  String? _lastSyncedBranchId;

  PurchaseInvoicesViewModel({
    required OwnerRepository repository,
    required SessionService sessionService,
    OwnerDataService? ownerDataService,
  })  : _repo = repository,
        _session = sessionService,
        _ownerData = ownerDataService {
    _lastSyncedBranchId = _ownerData?.selectedBranchId;
    _ownerData?.addListener(_onOwnerDataChanged);
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  /// Refetch list when app-bar branch changes (same pattern as Approvals).
  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerData?.selectedBranchId;
    if (!force && next == _lastSyncedBranchId) return;
    _lastSyncedBranchId = next;
    if (!_isInitialised) return;
    await refresh();
  }

  String? get _listBranchId => _ownerData?.selectedBranchId;

  // ── Auth token (cached after first init) ──────────────────────────────────
  String? _token;

  // ── State ─────────────────────────────────────────────────────────────────

  bool    _isLoading = false;
  bool    _isInitialised = false;
  String? _error;
  String? _submitError;
  String  _searchQuery = '';
  PurchaseInvoiceStatus? _statusFilter;

  bool    get isLoading   => _isLoading;
  bool    get isInitialised => _isInitialised;
  String? get error       => _error;
  String? get submitError => _submitError;
  String  get searchQuery => _searchQuery;
  PurchaseInvoiceStatus? get statusFilter => _statusFilter;

  final String currency = 'SAR';

  // ── Tab ───────────────────────────────────────────────────────────────────

  PurchaseInvoicesTab _activeTab = PurchaseInvoicesTab.invoices;
  PurchaseInvoicesTab get activeTab => _activeTab;

  void setActiveTab(PurchaseInvoicesTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  // ── Raw data ──────────────────────────────────────────────────────────────

  List<PurchaseInvoiceEntity>  _allInvoices  = [];
  List<Supplier>               _suppliers    = []; // affiliated only (used by New Invoice form)
  List<Supplier>               _allVendors   = []; // affiliated + local (used by report dropdown)
  List<Branch>                 _branches     = [];
  List<PurchasePriceReportRow> _reportRows   = [];

  // Products for search dropdown in the New Invoice form.
  // Fetched once at init alongside invoices — zero extra wait when form opens.
  List<CatalogProductModel>    _products     = [];

  List<Supplier>            get suppliersList  => _suppliers;   // affiliated only
  List<Supplier>            get allVendorsList => _allVendors;  // affiliated + local
  List<Branch>              get branches       => _branches;
  List<CatalogProductModel> get products       => _products;

  // ── Supplier context data (fetched on vendor select) ─────────────────────
  // Keyed by supplierId so switching vendor re-fetches once, not on every tap.
  String?                           _loadedPricesSupplierId;
  List<SupplierProductPrice>        _lastPrices = [];
  List<SupplierUomRule>             _uomRules   = [];
  bool                              _isLoadingSupplierData = false;
  bool get isLoadingSupplierData => _isLoadingSupplierData;

  // ── Filtered invoice list ─────────────────────────────────────────────────

  List<PurchaseInvoiceEntity> get invoices {
    var list = _allInvoices;
    if (_statusFilter != null) {
      list = list.where((inv) => inv.status == _statusFilter).toList();
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((inv) =>
      inv.invoiceNo.toLowerCase().contains(q) ||
          inv.vendorName.toLowerCase().contains(q) ||
          inv.ref.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Summary numbers ───────────────────────────────────────────────────────

  /// Matches web: unpaid / partial balances only (excludes fully paid).
  double get totalAccountsPayable => _allInvoices
      .where((inv) => inv.paymentStatus != 'paid')
      .fold(0.0, (s, inv) => s + (inv.balance > 0 ? inv.balance : inv.grandTotal));

  int get totalInvoicesCount => _allInvoices.length;

  int get pendingCount => _allInvoices
      .where((inv) => inv.status == PurchaseInvoiceStatus.pending)
      .length;

  // ── Init / refresh ────────────────────────────────────────────────────────

  bool _formDataLoaded = false;

  Future<void> init() async {
    if (_isLoading) return;
    _setLoading(true);
    _error = null;

    _token = await _session.getToken(role: 'owner');
    if (_token == null) {
      _error = 'Not authenticated. Please log in again.';
      _isInitialised = true;
      _setLoading(false);
      return;
    }

    try {
      await Future.wait([
        _fetchInvoices(),
        if (!_formDataLoaded) _fetchFormSupportData(),
      ]);
    } catch (e) {
      _error = 'Failed to load invoices. Pull to retry.';
      debugPrint('[PurchaseInvoicesVM] init error: $e');
    }

    _isInitialised = true;
    _setLoading(false);
  }

  /// Branch change / pull-to-refresh — invoices only (not products/suppliers/branches).
  Future<void> refresh() async {
    if (_token == null) {
      await init();
      return;
    }
    _setLoading(true);
    _error = null;
    try {
      await _fetchInvoices();
    } catch (e) {
      _error = 'Failed to load invoices. Pull to retry.';
      debugPrint('[PurchaseInvoicesVM] refresh error: $e');
    }
    _setLoading(false);
  }

  Future<void> _fetchInvoices() async {
    final branchId = _listBranchId;
    final results = await Future.wait([
      _repo.getLocalPurchaseInvoices(_token!, branchId: branchId),
      _repo.getSupplierPurchaseInvoices(_token!, branchId: branchId),
    ]);
    _lastSyncedBranchId = branchId;

    final localList = results[0]
        .map((j) => PurchaseInvoiceEntity.fromLocalJson(j))
        .toList();
    final supplierList = results[1]
        .map((j) => PurchaseInvoiceEntity.fromSupplierJson(j))
        .toList();

    _allInvoices = _dedupeInvoices([...localList, ...supplierList])
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    _reportRows = _buildReportRows(_allInvoices);
  }

  /// Match web `dedupeWorkshopPurchaseInvoiceListRows` (WLPI + id keys).
  List<PurchaseInvoiceEntity> _dedupeInvoices(
      List<PurchaseInvoiceEntity> rows) {
    if (rows.length <= 1) return rows;
    final map = <String, PurchaseInvoiceEntity>{};
    for (final r in rows) {
      if (r.id.isEmpty && r.invoiceNo.isEmpty) continue;
      final no = r.invoiceNo.trim();
      final key = no.toUpperCase().startsWith('WLPI-')
          ? 'wlpi:${no.toUpperCase()}'
          : '${r.invoiceKind == InvoiceKind.local ? 'local' : 'affiliated'}:${r.id}';
      map.putIfAbsent(key, () => r);
    }
    return map.values.toList();
  }

  /// One-time support data for New Invoice form + price-report filters.
  Future<void> _fetchFormSupportData() async {
    final results = await Future.wait([
      _repo.getCatalogProducts(_token!, allBranches: true),
      _repo.getSuppliers(_token!),
      _repo.getLocalSuppliers(_token!),
      _repo.getBranches(_token!),
    ]);

    final productsResponse =
        ProductsResponse.fromJson(results[0] as Map<String, dynamic>);
    _products = productsResponse.allProducts;
    _suppliers = results[1] as List<Supplier>;

    final localSuppliers = results[2] as List<Supplier>;
    final seenIds = <String>{};
    _allVendors = [..._suppliers, ...localSuppliers]
        .where((s) => seenIds.add(s.id))
        .toList();

    final branchesResponse =
        BranchesResponse.fromJson(results[3] as Map<String, dynamic>);
    _branches = branchesResponse.branches
        .map((b) => Branch(
              id: b.id,
              name: b.name,
              location: b.address,
              vat: b.vatId ?? '',
              cr: b.crNumber,
              status: b.status,
              salesMTD: 0.0,
            ))
        .toList();
    _formDataLoaded = true;
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(PurchaseInvoiceStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  // ==========================================================================
  // Purchase Price Report tab
  // ==========================================================================

  String? _reportVendorFilter;
  String? _reportProductFilter;

  String? get reportVendorFilter  => _reportVendorFilter;
  String? get reportProductFilter => _reportProductFilter;

  List<String> get reportVendorOptions =>
      _allVendors.map((s) => s.name).toSet().toList()..sort();

  List<String> get reportProductOptions =>
      _products.map((p) => p.name).toSet().toList()..sort();

  List<PurchasePriceReportRow> get filteredReportRows {
    var list = _reportRows;
    if (_reportVendorFilter != null) {
      list = list.where((r) => r.vendorName == _reportVendorFilter).toList();
    }
    if (_reportProductFilter != null) {
      list = list.where((r) => r.productName == _reportProductFilter).toList();
    }
    return list;
  }

  void setReportVendorFilter(String? vendor) {
    _reportVendorFilter = vendor;
    notifyListeners();
  }

  void setReportProductFilter(String? product) {
    _reportProductFilter = product;
    notifyListeners();
  }

  // ==========================================================================
  // New Invoice form state
  // ==========================================================================

  final TextEditingController branchCtrl        = TextEditingController();
  final TextEditingController issueDateCtrl     = TextEditingController();
  final TextEditingController dueDaysCtrl       = TextEditingController(text: '30');
  final TextEditingController customDueDateCtrl = TextEditingController();
  final TextEditingController refCtrl           = TextEditingController();
  final TextEditingController descCtrl          = TextEditingController();
  final TextEditingController discountCtrl      = TextEditingController(text: '0');
  final TextEditingController freightCtrl       = TextEditingController(text: '0');
  final TextEditingController notesCtrl         = TextEditingController();

  String _selectedVendorName = '';
  String _selectedVendorId   = '';
  String _selectedBranchName = '';
  String _selectedBranchId   = '';

  String get selectedVendorName => _selectedVendorName;
  String get selectedBranchName => _selectedBranchName;
  String get selectedBranchId   => _selectedBranchId;

  DiscountType _discountType = DiscountType.fixed;
  DiscountType get discountType => _discountType;

  void setDiscountType(DiscountType type) {
    _discountType = type;
    recalculate();
  }

  DueDateType _dueDateType = DueDateType.net;
  DueDateType get dueDateType => _dueDateType;

  void setDueDateType(DueDateType type) {
    _dueDateType = type;
    if (type == DueDateType.custom && customDueDateCtrl.text.isEmpty) {
      customDueDateCtrl.text = issueDateCtrl.text;
    }
    notifyListeners();
  }

  DateTime get resolvedDueDate {
    final issue = _parseDate(issueDateCtrl.text) ?? DateTime.now();
    switch (_dueDateType) {
      case DueDateType.net:
        final days = int.tryParse(dueDaysCtrl.text.trim()) ?? 0;
        return issue.add(Duration(days: days));
      case DueDateType.eom:
        final firstOfNextMonth = DateTime(issue.year, issue.month + 1, 1);
        return firstOfNextMonth.subtract(const Duration(days: 1));
      case DueDateType.custom:
        return _parseDate(customDueDateCtrl.text) ?? issue;
    }
  }

  String get computedDueDate => _formatYyyyMmDd(resolvedDueDate);

  bool _showDescriptionColumn = true;
  bool _showDiscountColumn    = false;

  bool get showDescriptionColumn => _showDescriptionColumn;
  bool get showDiscountColumn    => _showDiscountColumn;

  void setShowDescriptionColumn(bool? v) {
    _showDescriptionColumn = v ?? false;
    notifyListeners();
  }

  void setShowDiscountColumn(bool? v) {
    _showDiscountColumn = v ?? false;
    notifyListeners();
  }

  bool _amountsAreTaxInclusive = false;
  bool get amountsAreTaxInclusive => _amountsAreTaxInclusive;

  void setAmountsAreTaxInclusive(bool? v) {
    _amountsAreTaxInclusive = v ?? false;
    recalculate();
  }

  bool _updateLastPurchasePrice = true;
  bool get updateLastPurchasePrice => _updateLastPurchasePrice;

  void setUpdateLastPurchasePrice(bool? v) {
    _updateLastPurchasePrice = v ?? true;
    notifyListeners();
  }

  List<ItemDraft> _itemDrafts = [];
  List<ItemDraft> get itemDrafts => _itemDrafts;

  void addItemDraft() {
    _itemDrafts.add(ItemDraft());
    notifyListeners();
  }

  void removeItemDraft(int index) {
    if (_itemDrafts.length <= 1) return;
    _itemDrafts[index].dispose();
    _itemDrafts.removeAt(index);
    recalculate();
  }

  void setItemAccount(int index, AccountCode account) {
    _itemDrafts[index].selectedAccount = account;
    notifyListeners();
  }

  void setItemTaxCode(int index, TaxCode taxCode) {
    _itemDrafts[index].selectedTaxCode = taxCode;
    recalculate();
  }

  // ── Product selection from dropdown ───────────────────────────────────────
  // Called when user taps a product in the search dropdown.
  // Auto-fills UOM, price, and last-supplier-price from cached data.
  void selectProductForLine(int index, CatalogProductModel product) {
    if (index >= _itemDrafts.length) return;
    final draft = _itemDrafts[index];

    draft.productCtrl.text = product.name;
    draft.productId = product.id;

    // Look up UOM rule for this product from the selected supplier's cache
    final rule = _uomRules.where((r) => r.productId == product.id).firstOrNull;
    if (rule != null) {
      draft.uom              = rule.warehouseUnit;
      draft.workshopUnit     = rule.workshopUnit;
      draft.conversionFactor = rule.conversionFactor;
      draft.supplierProductId = rule.supplierProductId;
    } else {
      // No supplier-specific UOM rule — fall back to product's own unit
      draft.uom              = product.unit;
      draft.workshopUnit     = product.unit;
      draft.conversionFactor = 1;
      draft.supplierProductId = null;
    }

    // Auto-fill price from last purchase price if available
    final lastPrice = _lastPrices
        .where((p) => p.productId == product.id)
        .firstOrNull;
    if (lastPrice != null) {
      draft.priceCtrl.text   = lastPrice.lastUnitPriceExVat.toStringAsFixed(2);
      draft.lastSupplierPrice = lastPrice.lastUnitPriceInclVat;
    } else {
      // Fall back to product's own purchase price
      if (product.purchasePrice > 0) {
        draft.priceCtrl.text  = product.purchasePrice.toStringAsFixed(2);
        draft.lastSupplierPrice = null;
      }
    }

    recalculate();
  }

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  double _draftSubtotal   = 0.0;
  double _draftTax        = 0.0;
  double _draftFreight    = 0.0;
  double _draftDiscount   = 0.0;
  double _draftGrandTotal = 0.0;

  double get draftSubtotal   => _draftSubtotal;
  double get draftTax        => _draftTax;
  double get draftFreight    => _draftFreight;
  double get draftDiscount   => _draftDiscount;
  double get draftGrandTotal => _draftGrandTotal;

  // ── Form init ─────────────────────────────────────────────────────────────

  void initNewInvoiceForm({required List<Branch> branches}) {
    branchCtrl.text        = '';
    issueDateCtrl.text     = _todayString();
    dueDaysCtrl.text       = '30';
    customDueDateCtrl.text = '';
    refCtrl.text           = '';
    descCtrl.text          = '';
    discountCtrl.text      = '0';
    freightCtrl.text       = '0';
    notesCtrl.text         = '';

    _selectedVendorName      = '';
    _selectedVendorId        = '';
    _selectedBranchName      = '';
    _selectedBranchId        = '';
    _amountsAreTaxInclusive  = false;
    _updateLastPurchasePrice = true;
    _discountType            = DiscountType.fixed;
    _dueDateType             = DueDateType.net;
    _showDescriptionColumn   = true;
    _showDiscountColumn      = false;
    _isSubmitting            = false;

    // Reset supplier-specific cache so it re-fetches for next vendor selection
    _loadedPricesSupplierId = null;
    _lastPrices = [];
    _uomRules   = [];

    for (final d in _itemDrafts) d.dispose();
    _itemDrafts = [ItemDraft()];

    recalculate();
  }

  // ── Vendor selection — triggers last-prices + UOM fetch ───────────────────

  Future<void> selectVendor(Supplier supplier) async {
    _selectedVendorName = supplier.name;
    _selectedVendorId   = supplier.id;
    notifyListeners();

    // Avoid re-fetching if same supplier selected again
    if (_loadedPricesSupplierId == supplier.id || supplier.id.isEmpty) return;

    // Need a branchId for these endpoints — use selected branch or first branch
    final branchId = _selectedBranchId.isNotEmpty
        ? _selectedBranchId
        : (_branches.isNotEmpty ? _branches.first.id : '');
    if (branchId.isEmpty || _token == null) return;

    _isLoadingSupplierData = true;
    notifyListeners();

    try {
      // Fetch last prices and UOM rules in parallel
      final results = await Future.wait([
        _repo.getSupplierLastPurchasePrices(_token!,
            supplierId: supplier.id, branchId: branchId),
        _repo.getSupplierUomRules(_token!,
            supplierId: supplier.id, branchId: branchId),
      ]);

      _lastPrices = (results[0] as List<Map<String, dynamic>>)
          .map((j) => SupplierProductPrice.fromJson(j))
          .toList();
      _uomRules = (results[1] as List<Map<String, dynamic>>)
          .map((j) => SupplierUomRule.fromJson(j))
          .toList();

      _loadedPricesSupplierId = supplier.id;
    } catch (e) {
      debugPrint('[PurchaseInvoicesVM] supplier data fetch error: $e');
      // Non-fatal — form still works, just no auto-fill
    } finally {
      _isLoadingSupplierData = false;
      notifyListeners();
    }
  }

  void selectBranch(Branch branch) {
    _selectedBranchName = branch.name;
    _selectedBranchId   = branch.id;
    branchCtrl.text = branch.name;
    // Reset supplier cache — prices are branch-specific
    if (_loadedPricesSupplierId != null) {
      _loadedPricesSupplierId = null;
      _lastPrices = [];
      _uomRules   = [];
    }
    notifyListeners();
  }

  // ── Recalculation ─────────────────────────────────────────────────────────

  void recalculate() {
    double subtotal = 0.0;
    double tax      = 0.0;

    for (final draft in _itemDrafts) {
      final qty   = double.tryParse(draft.qtyCtrl.text) ?? 0.0;
      final price = double.tryParse(draft.priceCtrl.text) ?? 0.0;
      final rate  = draft.selectedTaxCode.rate;

      double lineExcl;
      if (_amountsAreTaxInclusive && rate > 0) {
        lineExcl = (qty * price) / (1 + rate);
      } else {
        lineExcl = qty * price;
      }
      subtotal += lineExcl;
      tax      += lineExcl * rate;
    }

    _draftSubtotal = subtotal;
    _draftTax      = tax;
    _draftFreight  = double.tryParse(freightCtrl.text) ?? 0.0;

    final rawDiscount = double.tryParse(discountCtrl.text) ?? 0.0;
    _draftDiscount = _discountType == DiscountType.percent
        ? (subtotal * rawDiscount / 100)
        : rawDiscount;

    _draftGrandTotal = _draftSubtotal + _draftTax + _draftFreight - _draftDiscount;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? validateStep(int step) {
    switch (step) {
      case 0:
        if (_selectedVendorName.isEmpty) return 'Please select a supplier.';
        if (_selectedBranchId.isEmpty)   return 'Please select a branch.';
        if (issueDateCtrl.text.isEmpty)  return 'Please enter an issue date.';
        return null;
      case 1:
        if (_itemDrafts.isEmpty) return 'Add at least one line item.';
        for (final d in _itemDrafts) {
          if (d.productCtrl.text.trim().isEmpty) {
            return 'Each item needs a product name.';
          }
          if ((double.tryParse(d.qtyCtrl.text) ?? 0) <= 0) {
            return 'Quantity must be greater than 0.';
          }
        }
        return null;
      default:
        return null;
    }
  }

  // ── Submit — real API ─────────────────────────────────────────────────────

  Future<bool> submitNewInvoice(BuildContext context) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final issueDateStr = _formatYyyyMmDd(
          _parseDate(issueDateCtrl.text) ?? DateTime.now());
      final dueDateStr   = _formatYyyyMmDd(resolvedDueDate);
      final netDays      = int.tryParse(dueDaysCtrl.text.trim()) ?? 30;
      final freight      = double.tryParse(freightCtrl.text.trim()) ?? 0.0;
      final discountVal  = double.tryParse(discountCtrl.text.trim()) ?? 0.0;

      // Build line payload matching the API spec exactly
      final lines = <Map<String, dynamic>>[];
      final formLines = <Map<String, dynamic>>[];
      int lineNo = 1;

      for (final d in _itemDrafts) {
        if (d.productCtrl.text.trim().isEmpty) continue;
        final qty     = double.tryParse(d.qtyCtrl.text) ?? 1;
        final price   = double.tryParse(d.priceCtrl.text) ?? 0;
        final rate    = d.selectedTaxCode.rate;
        final grossEx = qty * price;
        final taxAmt  = grossEx * rate;
        final total   = grossEx + taxAmt;
        final clientId = '${DateTime.now().millisecondsSinceEpoch}-${lineNo}ln';

        lines.add({
          'line_no':                   lineNo,
          'client_line_id':            clientId,
          'branch_catalog_product_id': d.productId.isNotEmpty ? d.productId : null,
          'item_name':                 d.productCtrl.text.trim(),
          'account_display':           d.selectedAccount.display,
          'account_code':              d.selectedAccount.code,
          'account_name':              d.selectedAccount.label,
          'description':               d.descriptionCtrl.text.trim(),
          'uom':                       d.uom,
          'uom_profile_id':            null,
          'uomProfileId':              null,
          'qty':                       qty,
          'unit_price_ex_vat':         price,
          'unit_purchase_price_incl_vat': price * (1 + rate),
          'line_discount_raw':         0,
          'line_discount_amount':      0,
          'line_discount_mode':        'percent',
          'gross_ex_vat':              grossEx,
          'taxable_ex_vat':            grossEx,
          'tax_code':                  d.selectedTaxCode.label,
          'tax_rate':                  rate,
          'tax_amount':                taxAmt,
          'line_total_incl_vat':       total,
        });

        formLines.add({
          'client_line_id':    clientId,
          'productId':         d.productId.isNotEmpty ? d.productId : null,
          'item':              d.productCtrl.text.trim(),
          'account':           d.selectedAccount.display,
          'description':       d.descriptionCtrl.text.trim(),
          'uom':               d.uom,
          'qty':               qty,
          'price':             price,
          'discount':          0,
          'discountMode':      'percent',
          'taxCode':           d.selectedTaxCode.label,
          'taxAmt':            taxAmt.toStringAsFixed(2),
          'totalFinal':        total.toStringAsFixed(2),
          'warehouseUnit':     d.uom,
          'workshopUnit':      d.workshopUnit.isNotEmpty ? d.workshopUnit : d.uom,
          'conversionFactor':  d.conversionFactor,
          'uomProfileId':      null,
          'supplierProductId': d.supplierProductId,
        });

        lineNo++;
      }

      final totals = {
        'lines_taxable_ex_vat':          _draftSubtotal,
        'lines_total_vat':               _draftTax,
        'lines_grand_total_incl_vat':    _draftSubtotal + _draftTax,
        'line_gross_ex_vat':             _draftSubtotal,
        'line_discount_amount':          0,
        'invoice_discount_applied_ex_vat': 0,
        'subtotal_ex_vat':               _draftSubtotal,
        'total_vat':                     _draftTax,
        'grand_total':                   _draftGrandTotal,
        'freight_in':                    freight,
      };

      final payload = {
        'supplier': {
          'id':   _selectedVendorId,
          'name': _selectedVendorName,
        },
        'branch_id':  _selectedBranchId,
        'branchId':   _selectedBranchId,
        'issueDate':  issueDateStr,
        'issue_date': issueDateStr,
        'dueDate': {
          'type':            'Net',
          'netDays':         netDays,
          'issueDate':       issueDateStr,
          'issue_date':      issueDateStr,
          'computedDueDate': dueDateStr,
        },
        'due_date': {
          'type':              _dueDateType.name,
          'net_days':          netDays,
          'custom_date':       _dueDateType == DueDateType.custom ? dueDateStr : null,
          'computed_due_date': dueDateStr,
        },
        'due_date_iso':       dueDateStr,
        'description':        descCtrl.text.trim(),
        'notes':              notesCtrl.text.trim(),
        'currency':           currency,
        'status':             'pending',
        'updateLastPurchasePriceOnSave': _updateLastPurchasePrice,
        'update_last_purchase_price_on_save': _updateLastPurchasePrice,
        'freightIn':          freight,
        'freight_in':         freight,
        'ui': {
          'show_line_description_column': _showDescriptionColumn,
          'show_line_discount_column':    _showDiscountColumn,
          'line_discount_is_percent':     false,
          'amounts_tax_inclusive':        _amountsAreTaxInclusive,
          'amountsTaxInclusive':          _amountsAreTaxInclusive,
          'prices_include_vat':           false,
          'no_vat':                       false,
          'showLineDescriptionColumn':    _showDescriptionColumn,
          'showLineDiscountColumn':       _showDiscountColumn,
          'lineDiscountIsPercent':        false,
        },
        'tax': {'label': 'VAT 15%', 'rate': 0.15},
        'selected_branch_filter': 'all',
        'invoiceDiscount': {
          'mode':         _discountType == DiscountType.percent ? 'percent' : 'fixed_sar',
          'value':        discountVal,
          'discountType': _discountType == DiscountType.percent ? 'percent' : 'fixed',
        },
        'invoice_discount': {
          'mode':  _discountType == DiscountType.percent ? 'percent' : 'fixed_sar',
          'value': discountVal,
        },
        'vendor_invoice_ref': refCtrl.text.trim(),
        'lines':      lines,
        'form_lines': formLines,
        'totals':     totals,
        'form_snapshot': {
          'version':              1,
          'invoice_branch_id':    _selectedBranchId,
          'selected_vendor':      _selectedVendorName,
          'supplier_id':          _selectedVendorId,
          'issue_date':           issueDateStr,
          'due_date_type':        _dueDateType.name,
          'net_days':             netDays,
          'custom_due_date':      dueDateStr,
          'vendor_invoice_ref':   refCtrl.text.trim(),
          'invoice_description':  descCtrl.text.trim(),
          'invoice_notes':        notesCtrl.text.trim(),
          'invoice_discount_value': discountCtrl.text.trim(),
          'invoice_discount_mode':  _discountType == DiscountType.percent ? 'percent' : 'fixed_sar',
          'show_desc':            _showDescriptionColumn,
          'show_discount':        _showDiscountColumn,
          'discount_is_percent':  _discountType == DiscountType.percent,
          'amounts_tax_inclusive': _amountsAreTaxInclusive,
          'freight_sar':          freight.toString(),
          'update_last_purchase_price': _updateLastPurchasePrice,
          'line_items':           formLines,
        },
      };

      final response = await _repo.createSupplierPurchaseInvoice(_token!, payload);

      if (!response.success || response.invoice == null) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // Optimistically prepend the new invoice to the list from API response
      final created = response.invoice!;
      final newEntity = PurchaseInvoiceEntity(
        id:          created.id,
        invoiceNo:   created.invoiceNumber,
        vendorName:  created.supplierName,
        vendorId:    created.supplierId,
        branchName:  _selectedBranchName,
        branchId:    created.branchId,
        ref:         refCtrl.text.trim(),
        issueDate:   _parseDate(created.issueDate) ?? DateTime.now(),
        dueDate:     _parseDate(created.dueDate) ?? DateTime.now(),
        description: descCtrl.text.trim(),
        status:      PurchaseInvoiceStatus.pending,
        stockUpdated: false,
        discount:    _draftDiscount,
        freight:     freight,
        invoiceKind: InvoiceKind.supplier,
        subtotal:    created.subtotal,
        totalTax:    created.taxAmount,
        grandTotal:  created.grandTotal,
        amountPaid:  0.0,
        balance:     created.balance,
        items: _itemDrafts
            .where((d) => d.productCtrl.text.trim().isNotEmpty)
            .map((d) => PurchaseInvoiceItem(
          productName: d.productCtrl.text.trim(),
          accountCode: d.selectedAccount.code,
          description: d.descriptionCtrl.text.trim(),
          qty:         double.tryParse(d.qtyCtrl.text) ?? 1,
          uom:         d.uom,
          unitPrice:   double.tryParse(d.priceCtrl.text) ?? 0,
          taxCode:     d.selectedTaxCode.code,
          taxRate:     d.selectedTaxCode.rate,
          lastSupplierPrice: d.lastSupplierPrice,
        ))
            .toList(),
      );

      _allInvoices.insert(0, newEntity);
      _reportRows = _buildReportRows(_allInvoices);

      _isSubmitting = false;
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('[PurchaseInvoicesVM] submitNewInvoice error: $e');
      _submitError = 'Failed to create invoice: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Save as Draft — still local (no draft API endpoint provided) ──────────
  Future<bool> saveAsDraft(BuildContext context) async {
    _isSubmitting = true;
    notifyListeners();

    // Brief delay for UX — no real network call for draft
    await Future.delayed(const Duration(milliseconds: 300));

    final draft = PurchaseInvoiceEntity(
      id:          DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNo:   'PI-DRAFT-${_allInvoices.length + 1}',
      vendorName:  _selectedVendorName.isNotEmpty ? _selectedVendorName : 'Unknown',
      vendorId:    _selectedVendorId,
      branchName:  _selectedBranchName.isNotEmpty ? _selectedBranchName : 'Unknown',
      branchId:    _selectedBranchId,
      ref:         refCtrl.text.trim(),
      issueDate:   _parseDate(issueDateCtrl.text) ?? DateTime.now(),
      dueDate:     resolvedDueDate,
      description: descCtrl.text.trim(),
      status:      PurchaseInvoiceStatus.draft,
      stockUpdated: false,
      invoiceKind: InvoiceKind.local,
      items:       [],
    );

    _allInvoices.insert(0, draft);
    _isSubmitting = false;
    notifyListeners();
    return true;
  }

  // ==========================================================================
  // Helpers
  // ==========================================================================

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          try { return DateTime(y, m, d); } catch (_) { return null; }
        }
      }
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  String _formatYyyyMmDd(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static List<PurchasePriceReportRow> _buildReportRows(
      List<PurchaseInvoiceEntity> invoices) {
    final rows = <PurchasePriceReportRow>[];
    for (final inv in invoices) {
      for (final item in inv.items) {
        rows.add(PurchasePriceReportRow(
          productName: item.productName,
          vendorName:  inv.vendorName,
          vendorId:    inv.vendorId,
          invoiceNo:   inv.invoiceNo,
          date:        inv.issueDate,
          qty:         item.qty,
          unit:        item.uom,
          unitPrice:   item.unitPrice,
          lineTotal:   item.totalExcl,
          taxAmt:      item.taxAmt,
          grandTotal:  item.totalIncl,
        ));
      }
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  @override
  void dispose() {
    _ownerData?.removeListener(_onOwnerDataChanged);
    branchCtrl.dispose();
    issueDateCtrl.dispose();
    dueDaysCtrl.dispose();
    customDueDateCtrl.dispose();
    refCtrl.dispose();
    descCtrl.dispose();
    discountCtrl.dispose();
    freightCtrl.dispose();
    notesCtrl.dispose();
    for (final d in _itemDrafts) {
      d.dispose();
    }
    super.dispose();
  }
}