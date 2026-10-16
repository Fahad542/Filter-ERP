import 'package:flutter/material.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

// ---------------------------------------------------------------------------
// ApprovalsViewModel
//
// Matches filter-web WorkshopApprovals.jsx loadApprovals merge:
//   petty-cash (queue=all|fund|expense) + supplier SI + sales returns +
//   affiliated purchase returns + admin wallet.
//
// Queue keys (type filter — like web requestTypeFilter):
//   'all' | 'fund' | 'expense' | 'supplier' | 'purchase_returns' | 'returns' | 'wallet'
//
// Status keys (like web queueFilter): 'all' | 'pending' | 'approved' | 'rejected'
// ---------------------------------------------------------------------------

class ApprovalsViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final SettingsViewModel settingsViewModel;
  final OwnerDataService ownerDataService;

  ApprovalsViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.settingsViewModel,
    required this.ownerDataService,
  }) {
    _branchId = ownerDataService.selectedBranchId;
    _lastSyncedBranchId = _branchId;
    ownerDataService.addListener(_onOwnerDataChanged);
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  String? _lastSyncedBranchId;

  // ── Locale re-translation ─────────────────────────────────────────────────
  // Raw (never-translated) merge sources cached from the last successful
  // fetchRequests() — reused to rebuild translated rows on locale change
  // without another round-trip to the API.
  PettyCashRequestsResponse? _rawPettyResp;
  List<Map<String, dynamic>> _rawInvoices = [];
  WorkshopSalesReturnsResponse? _rawSalesReturnsResp;
  AffiliatedPurchaseReturnsResponse? _rawPurchaseReturnsResp;
  AdminWalletApprovalsResponse? _rawWalletResp;
  String? _rawStatusParam;

  Future<void> retranslate() async {
    await _rebuildRows(_rawStatusParam);
    notifyListeners();
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = ownerDataService.selectedBranchId;
    if (!force && next == _lastSyncedBranchId) return;
    _lastSyncedBranchId = next;
    _branchId = next;
    await fetchRequests();
  }

  // ── State ─────────────────────────────────────────────────────────────────
  List<ApprovalRow> _rows = [];
  bool _isLoading = false;
  String? _error;

  /// Raw filter keys — NEVER translated.
  String _statusFilter = 'pending';
  String _queueFilter = 'all';

  /// Branch context — set by the parent screen / dashboard.
  String? _branchId;

  String _currency = 'SAR';

  /// IDs currently in-flight for approve / reject.
  final Set<String> _approvingIds = {};
  final Set<String> _rejectingIds = {};

  // ── Getters ───────────────────────────────────────────────────────────────
  List<ApprovalRow> get rows => _rows;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get queueFilter => _queueFilter;
  String get currency => _currency;

  bool get hasApprovalActionInFlight =>
      _approvingIds.isNotEmpty || _rejectingIds.isNotEmpty;

  bool isApprovingRequest(String id) => _approvingIds.contains(id);
  bool isRejectingRequest(String id) => _rejectingIds.contains(id);

  // ── Branch setter ─────────────────────────────────────────────────────────
  void setBranch({String? branchId, bool allBranches = true}) {
    _branchId = branchId;
    _lastSyncedBranchId = branchId;
    fetchRequests();
  }

  // ── Filter setters ────────────────────────────────────────────────────────
  void setStatusFilter(String key) {
    if (_statusFilter == key) return;
    _statusFilter = key;
    notifyListeners();
    fetchRequests();
  }

  void setQueueFilter(String key) {
    if (_queueFilter == key) return;
    _queueFilter = key;
    notifyListeners();
    fetchRequests();
  }

  // ── Data fetch (web-parity merge) ─────────────────────────────────────────
  Future<void> fetchRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      final String? statusParam =
          _statusFilter == 'all' ? null : _statusFilter;

      // Web: SI / sales returns / purchase returns only when status is all|pending.
      final bool loadReviewQueue =
          _statusFilter == 'all' || _statusFilter == 'pending';

      final bool wantPetty = _queueFilter == 'all' ||
          _queueFilter == 'fund' ||
          _queueFilter == 'expense';
      final bool wantSupplier =
          (_queueFilter == 'all' || _queueFilter == 'supplier') &&
              loadReviewQueue;
      final bool wantSalesReturns =
          (_queueFilter == 'all' || _queueFilter == 'returns') &&
              loadReviewQueue;
      final bool wantPurchaseReturns =
          (_queueFilter == 'all' || _queueFilter == 'purchase_returns') &&
              loadReviewQueue;
      // Admin wallet folds into fund/expense on web; mobile also has a Wallet tab.
      final bool wantWallet = _queueFilter == 'all' ||
          _queueFilter == 'wallet' ||
          _queueFilter == 'fund' ||
          _queueFilter == 'expense';

      // Petty-cash: MUST pass queue=all (backend defaults to fund-only).
      String? pettyQueue;
      if (_queueFilter == 'fund') {
        pettyQueue = 'fund';
      } else if (_queueFilter == 'expense') {
        pettyQueue = 'expense';
      } else {
        pettyQueue = 'all';
      }

      // Admin wallet: web uses pending when queue/status is "all".
      final String walletStatus =
          _statusFilter == 'all' ? 'pending' : (statusParam ?? 'pending');

      Future<T?> safe<T>(Future<T> Function() run) async {
        try {
          return await run();
        } catch (_) {
          return null;
        }
      }

      final results = await Future.wait([
        wantPetty
            ? safe(() => ownerRepository.getPettyCashRequests(
                  token,
                  status: statusParam,
                  branchId: _branchId,
                  queue: pettyQueue,
                  limit: 100,
                ))
            : Future<PettyCashRequestsResponse?>.value(null),
        wantSupplier
            ? safe(() => ownerRepository.getSupplierSalesInvoices(
                  token,
                  branchId: _branchId,
                  limit: 100,
                ))
            : Future<dynamic>.value(null),
        wantSalesReturns
            ? safe(() => ownerRepository.getSalesReturns(
                  token,
                  status: 'pending',
                  branchId: _branchId,
                  limit: 100,
                ))
            : Future<WorkshopSalesReturnsResponse?>.value(null),
        wantPurchaseReturns
            ? safe(() => ownerRepository.getAffiliatedPurchaseReturns(
                  token,
                  status: 'pending',
                  branchId: _branchId,
                ))
            : Future<AffiliatedPurchaseReturnsResponse?>.value(null),
        wantWallet
            ? safe(() => ownerRepository.getAdminWalletApprovals(
                  token,
                  status: walletStatus,
                  branchId: _branchId,
                ))
            : Future<AdminWalletApprovalsResponse?>.value(null),
      ]);

      // ── Cache raw (untranslated) merge sources for locale re-translation ──
      _rawStatusParam = statusParam;
      _rawPettyResp = results[0] is PettyCashRequestsResponse
          ? results[0] as PettyCashRequestsResponse
          : null;
      _rawInvoices = (results[1] is Map)
          ? ((results[1] as Map)['invoices'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : [];
      if (results[1] is Map) {
        final currency = (results[1] as Map)['currency']?.toString();
        if (currency != null && currency.isNotEmpty) _currency = currency;
      }
      _rawSalesReturnsResp = results[2] is WorkshopSalesReturnsResponse
          ? results[2] as WorkshopSalesReturnsResponse
          : null;
      _rawPurchaseReturnsResp = results[3] is AffiliatedPurchaseReturnsResponse
          ? results[3] as AffiliatedPurchaseReturnsResponse
          : null;
      _rawWalletResp = results[4] is AdminWalletApprovalsResponse
          ? results[4] as AdminWalletApprovalsResponse
          : null;

      await _rebuildRows(statusParam);
    } catch (e) {
      _error = e.toString();
      _rows = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rebuilds [_rows] (translated) from the cached raw merge sources — used
  /// both right after a fetch and again on every locale change.
  Future<void> _rebuildRows(String? statusParam) async {
    final List<ApprovalRow> combined = [];

    // ── 1. Petty cash ──────────────────────────────────────────────────────
    final pcResp = _rawPettyResp;
    if (pcResp != null) {
      _currency = pcResp.currency.isNotEmpty ? pcResp.currency : _currency;
      for (final req in pcResp.requests) {
        final tCashierName = await tPerson(req.cashierName);
        final tBranchName = await tBranch(req.branchName);
        combined.add(await ApprovalRow.fromPettyCash(
          req.copyWith(
            translatedCashierName: tCashierName,
            translatedBranchName: tBranchName,
          ),
          translate: t,
        ));
      }
    }

    // ── 2. Supplier sales invoices ─────────────────────────────────────────
    for (final inv in _rawInvoices) {
      final row = await ApprovalRow.fromSupplierInvoice(
        inv,
        _currency,
        translate: t,
      );
      // Client status filter for SI uses workshopReviewStatus mapping.
      if (statusParam == null ||
          statusParam == 'pending' ||
          row.status == statusParam) {
        combined.add(row);
      }
    }

    // ── 3. Sales returns ────────────────────────────────────────────────────
    final srResp = _rawSalesReturnsResp;
    if (srResp != null) {
      for (final ret in srResp.salesReturns) {
        if (statusParam == null ||
            statusParam == 'pending' ||
            ret.status == statusParam) {
          combined.add(
              await ApprovalRow.fromSalesReturn(ret, _currency, translate: t));
        }
      }
    }

    // ── 4. Affiliated purchase returns ─────────────────────────────────────
    final aprResp = _rawPurchaseReturnsResp;
    if (aprResp != null) {
      for (final pr in aprResp.items) {
        if (statusParam == null ||
            statusParam == 'pending' ||
            pr.status == statusParam) {
          combined.add(await ApprovalRow.fromPurchaseReturn(pr, _currency,
              translate: t));
        }
      }
    }

    // ── 5. Admin wallet ─────────────────────────────────────────────────────
    final walletResp = _rawWalletResp;
    if (walletResp != null) {
      for (final req in walletResp.requests) {
        // When on fund/expense tabs, only matching admin-wallet kinds.
        if (_queueFilter == 'fund' && req.kind != 'admin_wallet_fund') {
          continue;
        }
        if (_queueFilter == 'expense' &&
            req.kind != 'admin_wallet_expense') {
          continue;
        }
        combined.add(
            await ApprovalRow.fromAdminWallet(req, _currency, translate: t));
      }
    }

    combined.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    _rows = combined;
  }

  // ── Actions (petty-cash) ──────────────────────────────────────────────────
  Future<void> approveRequest(String id) async {
    if (_approvingIds.contains(id)) return;
    _approvingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.approvePettyCashRequest(token, id);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _approvingIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String id, String reason) async {
    if (_rejectingIds.contains(id)) return;
    _rejectingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.rejectPettyCashRequest(token, id, reason);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _rejectingIds.remove(id);
      notifyListeners();
    }
  }

  // ── Actions (supplier invoices) ───────────────────────────────────────────
  Future<void> approveSupplierInvoice(String id) async {
    if (_approvingIds.contains(id)) return;
    _approvingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.approveSupplierSalesInvoice(token, id);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _approvingIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> rejectSupplierInvoice(String id, String reason) async {
    if (_rejectingIds.contains(id)) return;
    _rejectingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.rejectSupplierSalesInvoice(token, id, reason);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _rejectingIds.remove(id);
      notifyListeners();
    }
  }

  // ── Actions (admin wallet) ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> loadCashBankAccounts({
    String? branchId,
  }) async {
    final token = await sessionService.getToken(role: 'owner') ?? '';
    return ownerRepository.getCashBankAccounts(token, branchId: branchId);
  }

  Future<List<Map<String, dynamic>>> loadBudgetAccounts({
    String? branchId,
  }) async {
    final token = await sessionService.getToken(role: 'owner') ?? '';
    return ownerRepository.getAdminWalletBudgetAccounts(
      token,
      branchId: branchId,
    );
  }

  Future<void> approveAdminWallet(
    String id,
    String kind, {
    required Map<String, dynamic> body,
  }) async {
    if (_approvingIds.contains(id)) return;
    _approvingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.approveAdminWalletRequest(
        token,
        kind: kind,
        requestId: id,
        body: body,
      );
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _approvingIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> rejectAdminWallet(
      String id, String kind, String reason) async {
    if (_rejectingIds.contains(id)) return;
    _rejectingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.rejectAdminWalletRequest(
        token,
        kind: kind,
        requestId: id,
        rejectionReason: reason,
      );
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _rejectingIds.remove(id);
      notifyListeners();
    }
  }

  // ── Actions (sales returns) ───────────────────────────────────────────────
  Future<void> approveSalesReturn(String id) async {
    if (_approvingIds.contains(id)) return;
    _approvingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.approveSalesReturn(token, id);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _approvingIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> rejectSalesReturn(String id, String reason) async {
    if (_rejectingIds.contains(id)) return;
    _rejectingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.rejectSalesReturn(token, id, reason);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _rejectingIds.remove(id);
      notifyListeners();
    }
  }

  // ── Actions (purchase returns) ────────────────────────────────────────────
  Future<void> approvePurchaseReturn(String id) async {
    if (_approvingIds.contains(id)) return;
    _approvingIds.add(id);
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      await ownerRepository.approveAffiliatedPurchaseReturn(token, id);
      await fetchRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _approvingIds.remove(id);
      notifyListeners();
    }
  }

  // ── Realtime stubs ────────────────────────────────────────────────────────
  void bindRealtime() {}
  void unbindRealtime() {}

  @override
  void dispose() {
    ownerDataService.removeListener(_onOwnerDataChanged);
    unbindLocaleRetranslation();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// ApprovalRow — unified view model for all approval types.
// ---------------------------------------------------------------------------
enum ApprovalRowType {
  topUp,
  expense,
  supplierInvoice,
  salesReturn,
  purchaseReturn,
  adminWallet,
}

class ApprovalRow {
  final String id;
  final ApprovalRowType type;
  final double amount;
  final String requestedBy;
  final DateTime requestedAt;
  final String status; // 'pending' | 'approved' | 'rejected' | 'completed'
  final String? reason;
  final String? rejectionReason;
  final String? categoryLabel;
  final String? branchName;
  final String? branchId;

  /// Translated status label (e.g. "معتمد") — status itself stays raw so
  /// filtering / colour logic keeps working regardless of locale.
  final String? translatedStatusLabel;

  /// True for rows that support approve/reject from this screen.
  final bool canApproveReject;

  /// Purchase returns initiated by workshop cannot be approved here (web parity).
  final String? initiationMode;

  /// `admin_wallet_fund` | `admin_wallet_expense` when row comes from admin wallet.
  final String? adminWalletKind;

  bool get isAdminWallet =>
      adminWalletKind != null && adminWalletKind!.isNotEmpty;

  const ApprovalRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    this.reason,
    this.rejectionReason,
    this.categoryLabel,
    this.branchName,
    this.branchId,
    this.translatedStatusLabel,
    this.canApproveReject = false,
    this.initiationMode,
    this.adminWalletKind,
  });

  // ── Petty Cash ────────────────────────────────────────────────────────────
  static Future<ApprovalRow> fromPettyCash(
    PettyCashRequestItem req, {
    required Future<String> Function(String) translate,
  }) async {
    final rowType =
        (req.kind == 'expense') ? ApprovalRowType.expense : ApprovalRowType.topUp;
    return ApprovalRow(
      id: req.id,
      type: rowType,
      amount: req.amount,
      requestedBy: req.translatedCashierName ?? req.cashierName,
      requestedAt: req.requestedAt ?? DateTime.now(),
      status: req.status,
      reason: req.reason.isNotEmpty ? await translate(req.reason) : null,
      rejectionReason: req.rejectionReason,
      categoryLabel: req.categoryLabel,
      branchName: req.translatedBranchName ??
          (req.branchName.isNotEmpty ? req.branchName : null),
      branchId: req.branchId.isNotEmpty ? req.branchId : null,
      translatedStatusLabel: await translate(req.status),
      canApproveReject: req.status == 'pending',
    );
  }

  // ── Supplier Invoice (web: outstanding + workshopReviewStatus) ────────────
  static Future<ApprovalRow> fromSupplierInvoice(
    Map<String, dynamic> json,
    String currency, {
    required Future<String> Function(String) translate,
  }) async {
    final supplier = (json['supplier'] as Map<String, dynamic>?) ?? {};
    final branch = (json['branch'] as Map<String, dynamic>?) ?? {};
    final supplierName = supplier['name']?.toString() ??
        supplier['companyName']?.toString() ??
        json['supplierName']?.toString() ??
        'Unknown Supplier';
    final outstanding =
        double.tryParse(json['outstanding']?.toString() ?? '') ??
            double.tryParse(json['grandTotal']?.toString() ?? '') ??
            double.tryParse(json['totalAmount']?.toString() ?? '') ??
            double.tryParse(json['amount']?.toString() ?? '') ??
            0;
    final review = json['workshopReviewStatus']?.toString().trim();
    final status = (review == null || review.isEmpty) ? 'pending' : review;
    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : (json['invoiceDate'] != null
            ? DateTime.tryParse(json['invoiceDate'].toString()) ?? DateTime.now()
            : DateTime.now());
    final invoiceNo =
        json['invoiceNo']?.toString() ?? json['invoiceNumber']?.toString();
    final productLabel = json['productLabel']?.toString();
    final branchId = branch['id']?.toString() ?? json['branchId']?.toString();
    final branchName = branch['name']?.toString();

    return ApprovalRow(
      id: json['id']?.toString() ?? '',
      type: ApprovalRowType.supplierInvoice,
      amount: outstanding,
      requestedBy: await translate(supplierName),
      requestedAt: createdAt,
      status: status,
      reason: productLabel != null && productLabel.isNotEmpty
          ? 'Lines: ${await translate(productLabel)}'
          : (json['notes'] != null
              ? await translate(json['notes'].toString())
              : null),
      categoryLabel: invoiceNo,
      branchName: branchName != null ? await translate(branchName) : null,
      branchId: branchId,
      translatedStatusLabel: await translate(status),
      canApproveReject: status.toLowerCase() == 'pending',
    );
  }

  // ── Sales Return ──────────────────────────────────────────────────────────
  static Future<ApprovalRow> fromSalesReturn(
    WorkshopSalesReturn ret,
    String currency, {
    required Future<String> Function(String) translate,
  }) async {
    final requestedByRaw = ret.customerName.isNotEmpty
        ? ret.customerName
        : (ret.cashierName.isNotEmpty ? ret.cashierName : '—');
    return ApprovalRow(
      id: ret.id,
      type: ApprovalRowType.salesReturn,
      amount: ret.totalAmount,
      requestedBy: requestedByRaw == '—'
          ? requestedByRaw
          : await translate(requestedByRaw),
      requestedAt: ret.createdAt,
      status: ret.status,
      reason: ret.reason.isNotEmpty ? await translate(ret.reason) : null,
      rejectionReason: ret.rejectionReason,
      categoryLabel: '${ret.returnNo} • ${ret.invoiceNo}',
      branchName: ret.branchName.isNotEmpty
          ? await translate(ret.branchName)
          : null,
      branchId: ret.branchId.isNotEmpty ? ret.branchId : null,
      translatedStatusLabel: await translate(ret.status),
      canApproveReject: ret.status == 'pending',
    );
  }

  // ── Purchase Return ───────────────────────────────────────────────────────
  static Future<ApprovalRow> fromPurchaseReturn(
    AffiliatedPurchaseReturnItem pr,
    String currency, {
    required Future<String> Function(String) translate,
  }) async {
    final workshopInitiated =
        (pr.initiationMode ?? '').toLowerCase() == 'workshop_initiated';
    return ApprovalRow(
      id: pr.id,
      type: ApprovalRowType.purchaseReturn,
      amount: pr.grandTotal,
      requestedBy:
          pr.supplierName != null ? await translate(pr.supplierName!) : '—',
      requestedAt: pr.issueDate,
      status: pr.status,
      reason: pr.supplierSalesReturnNo != null &&
              pr.supplierSalesReturnNo!.isNotEmpty
          ? 'Linked supplier return ${pr.supplierSalesReturnNo}'
          : null,
      categoryLabel: pr.returnNumber.isNotEmpty
          ? (pr.invoiceNo != null && pr.invoiceNo!.isNotEmpty
              ? '${pr.returnNumber} • ${pr.invoiceNo}'
              : pr.returnNumber)
          : pr.invoiceNo,
      branchName:
          pr.branchName != null ? await translate(pr.branchName!) : null,
      branchId: pr.branchId,
      initiationMode: pr.initiationMode,
      translatedStatusLabel: await translate(pr.status),
      canApproveReject: pr.status == 'pending' && !workshopInitiated,
    );
  }

  // ── Admin Wallet ──────────────────────────────────────────────────────────
  static Future<ApprovalRow> fromAdminWallet(
    AdminWalletApproval req,
    String currency, {
    required Future<String> Function(String) translate,
  }) async {
    final isExpense = req.kind == 'admin_wallet_expense';
    final requestedByRaw = req.requestedBy ??
        (req.workshopName.isNotEmpty ? req.workshopName : 'Platform admin');
    return ApprovalRow(
      id: req.id,
      type: isExpense ? ApprovalRowType.expense : ApprovalRowType.topUp,
      amount: req.amount,
      requestedBy: await translate(requestedByRaw),
      requestedAt: req.requestedAt,
      status: req.status,
      reason: req.description != null ? await translate(req.description!) : null,
      rejectionReason: req.rejectionReason,
      categoryLabel: req.requestNumber ??
          (isExpense ? 'Admin wallet expense' : 'Admin wallet top-up'),
      branchName:
          req.branchName != null ? await translate(req.branchName!) : null,
      branchId: req.branchId,
      adminWalletKind: req.kind,
      translatedStatusLabel: await translate(req.status),
      canApproveReject: req.status.toLowerCase() == 'pending',
    );
  }
}
