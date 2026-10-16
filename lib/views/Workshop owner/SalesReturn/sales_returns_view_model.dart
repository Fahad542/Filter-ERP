import 'package:flutter/material.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

// ---------------------------------------------------------------------------
// SalesReturnItem — unified model for a single sales return record
// ---------------------------------------------------------------------------

enum SalesReturnType { cash, creditNote, exchange }

class SalesReturnItem {
  final String id;
  final String creditNoteNumber;
  final String returnNo;
  final String invoiceNumber;
  final String customerName;
  final String customerMobile;
  final String vehiclePlate;
  final String cashierName;
  final String branchName;
  final SalesReturnType type;
  final double amount;
  final double subtotal;
  final double vatAmount;
  final String currency;
  final String status; // 'approved' | 'pending' | 'rejected'
  final String returnScope; // 'full' | 'partial'
  final DateTime dateTime;
  final String? notes;
  final String? invoicePublicToken;
  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedCustomerName;
  final String? translatedCashierName;
  final String? translatedBranchName;
  final String? translatedStatus;
  final String? translatedNotes;

  const SalesReturnItem({
    required this.id,
    required this.creditNoteNumber,
    required this.returnNo,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerMobile,
    required this.vehiclePlate,
    required this.cashierName,
    required this.branchName,
    required this.type,
    required this.amount,
    required this.subtotal,
    required this.vatAmount,
    required this.currency,
    required this.status,
    required this.returnScope,
    required this.dateTime,
    this.notes,
    this.invoicePublicToken,
    this.translatedCustomerName,
    this.translatedCashierName,
    this.translatedBranchName,
    this.translatedStatus,
    this.translatedNotes,
  });

  String get displayCustomerName => translatedCustomerName ?? customerName;
  String get displayCashierName => translatedCashierName ?? cashierName;
  String get displayBranchName => translatedBranchName ?? branchName;
  String get displayStatus => translatedStatus ?? status;
  String? get displayNotes => translatedNotes ?? notes;

  SalesReturnItem copyWith({
    String? translatedCustomerName,
    String? translatedCashierName,
    String? translatedBranchName,
    String? translatedStatus,
    String? translatedNotes,
  }) {
    return SalesReturnItem(
      id: id,
      creditNoteNumber: creditNoteNumber,
      returnNo: returnNo,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerMobile: customerMobile,
      vehiclePlate: vehiclePlate,
      cashierName: cashierName,
      branchName: branchName,
      type: type,
      amount: amount,
      subtotal: subtotal,
      vatAmount: vatAmount,
      currency: currency,
      status: status,
      returnScope: returnScope,
      dateTime: dateTime,
      notes: notes,
      invoicePublicToken: invoicePublicToken,
      translatedCustomerName: translatedCustomerName ?? this.translatedCustomerName,
      translatedCashierName: translatedCashierName ?? this.translatedCashierName,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
      translatedStatus: translatedStatus ?? this.translatedStatus,
      translatedNotes: translatedNotes ?? this.translatedNotes,
    );
  }
}

// ---------------------------------------------------------------------------
// SalesReturnsViewModel
// ---------------------------------------------------------------------------
//
// Backed by GET /workshop-staff/sales-returns. Network calls only happen when
// a *server-side* filter changes (status / from-date / to-date) — the
// invoice/credit-note search box filters the already-fetched list locally,
// so typing never triggers a request. Results for each status+date
// combination are cached in memory for the lifetime of this ViewModel, so
// flipping between tabs you've already visited is instant and free. Pull-to-
// refresh (`refresh()`) always bypasses the cache.
class SalesReturnsViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository _ownerRepository;
  final SessionService _sessionService;
  final OwnerDataService _ownerData;
  final SettingsViewModel? _settingsViewModel;
  String? _lastSyncedBranchId;
  int _lastSyncedDateGeneration = -1;

  SalesReturnsViewModel({
    required OwnerRepository ownerRepository,
    required SessionService sessionService,
    required OwnerDataService ownerDataService,
    SettingsViewModel? settingsViewModel,
  })  : _ownerRepository = ownerRepository,
        _sessionService = sessionService,
        _ownerData = ownerDataService,
        _settingsViewModel = settingsViewModel {
    _lastSyncedBranchId = _ownerData.selectedBranchId;
    _lastSyncedDateGeneration = _ownerData.dateGeneration;
    _ownerData.addListener(_onOwnerDataChanged);
    final settings = _settingsViewModel;
    if (settings != null) {
      bindLocaleRetranslation(settings, retranslate);
    }
    _fetchAndFilter();
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerData.selectedBranchId;
    final nextDateGen = _ownerData.dateGeneration;
    if (!force &&
        next == _lastSyncedBranchId &&
        nextDateGen == _lastSyncedDateGeneration) {
      return;
    }
    _lastSyncedBranchId = next;
    _lastSyncedDateGeneration = nextDateGen;
    await _fetchAndFilter(forceRefresh: true);
  }

  // ── Locale re-translation ─────────────────────────────────────────────────

  Future<void> retranslate() async {
    await _translateFetched();
    _applyLocalFilter();
    notifyListeners();
  }

  /// Re-translates [_fetched] in place — always run after assigning it from
  /// either the network or the in-memory cache so translations stay correct
  /// even when a cached (possibly stale-locale) entry is reused.
  Future<void> _translateFetched() async {
    _fetched = await Future.wait(_fetched.map(_translateItem));
  }

  Future<SalesReturnItem> _translateItem(SalesReturnItem r) async {
    return r.copyWith(
      translatedCustomerName: await tPerson(r.customerName),
      translatedCashierName: await tPerson(r.cashierName),
      translatedBranchName: await tBranch(r.branchName),
      translatedStatus: await tUiStatus(r.status),
      translatedNotes: await tNotes(r.notes),
    );
  }

  @override
  void dispose() {
    _ownerData.removeListener(_onOwnerDataChanged);
    unbindLocaleRetranslation();
    super.dispose();
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  // App-wide date range via [OwnerDataService] — same as Dashboard / Reports.
  String _statusFilter = 'approved'; // matches web default
  String? _invoiceSearch;

  DateTime get fromDate => _ownerData.filterFrom;
  DateTime get toDate => _ownerData.filterTo;
  String   get statusFilter => _statusFilter;
  String?  get invoiceSearch => _invoiceSearch;

  // ── State ─────────────────────────────────────────────────────────────────
  bool    _isLoading = false;
  String? _error;
  bool    get isLoading => _isLoading;
  String? get error     => _error;

  // ── Data ──────────────────────────────────────────────────────────────────
  // Items for the currently-active server-side filter combo (status + dates).
  List<SalesReturnItem> _fetched = [];
  // _fetched with the local invoice/credit-note search applied on top.
  List<SalesReturnItem> _filtered = [];

  List<SalesReturnItem> get returns    => _filtered;
  int    get shownCount  => _filtered.length;
  double get shownAmount => _filtered.fold(0.0, (s, r) => s + r.amount);
  String get currency    => _filtered.isEmpty ? 'SAR' : _filtered.first.currency;

  // status+dateFrom+dateTo -> already-fetched, already-mapped items.
  final Map<String, List<SalesReturnItem>> _cache = {};

  // Lets a stale in-flight request detect that a newer one has superseded it,
  // so flicking quickly between filters can never let an old response clobber
  // a newer one.
  int _requestId = 0;

  // ── Filter setters ────────────────────────────────────────────────────────
  Future<void> setDateRange(DateTime from, DateTime to) async {
    _ownerData.setFilterRange(from, to);
  }

  Future<void> applyFilterStartDate(DateTime d) async {
    _ownerData.setFilterFrom(d);
  }

  Future<void> applyFilterEndDate(DateTime d) async {
    _ownerData.setFilterTo(d);
  }

  void setStatusFilter(String key) {
    if (_statusFilter == key) return;
    _statusFilter = key;
    _fetchAndFilter();
  }

  void setInvoiceSearch(String? q) {
    final next = q?.trim().isEmpty == true ? null : q?.trim();
    if (_invoiceSearch == next) return;
    _invoiceSearch = next;
    // Purely client-side — the matching set is already on the device, so
    // there's no need to hit the network just because the user is typing.
    _applyLocalFilter();
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = 'all';
    _invoiceSearch = null;
    _fetchAndFilter();
  }

  Future<void> refresh() async {
    await _fetchAndFilter(forceRefresh: true);
  }

  // ── UI status keys ('approved'/'pending'/'rejected'/'all') <-> backend ────
  static String? _apiStatusFor(String uiStatus) {
    switch (uiStatus) {
      case 'approved':
        return 'completed';
      case 'pending':
        return 'pending';
      case 'rejected':
        return 'rejected';
      default:
        return null; // 'all' — no status filter sent
    }
  }

  static String _uiStatusFor(String apiStatus) {
    switch (apiStatus) {
      case 'completed':
        return 'approved';
      case 'pending':
        return 'pending';
      case 'rejected':
        return 'rejected';
      default:
        return apiStatus.isEmpty ? 'pending' : apiStatus;
    }
  }

  // Asia/Riyadh wall → UTC ISO (same as Dashboard / web).
  String _dateFromParam() => OwnerRepository.reportsRangeStartIso(fromDate);

  String _dateToParam() => OwnerRepository.reportsRangeEndIso(toDate);

  String _cacheKey() =>
      '${_apiStatusFor(_statusFilter) ?? 'all'}|${_dateFromParam()}|${_dateToParam()}';

  // ── Core fetch ────────────────────────────────────────────────────────────
  Future<void> _fetchAndFilter({bool forceRefresh = false}) async {
    final key = _cacheKey();
    final myRequestId = ++_requestId;

    if (!forceRefresh && _cache.containsKey(key)) {
      _fetched = _cache[key]!;
      await _translateFetched();
      _applyLocalFilter();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _sessionService.getToken(role: 'owner');
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please log in again.');
      }

      final response = await _ownerRepository.getSalesReturns(
        token,
        status: _apiStatusFor(_statusFilter),
        dateFrom: _dateFromParam(),
        dateTo: _dateToParam(),
        limit: 100,
        offset: 0,
      );

      // A newer request has since started — drop this stale response.
      if (myRequestId != _requestId) return;

      final items = response.salesReturns.map(_mapToItem).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      _cache[key] = items;
      _fetched    = items;
      await _translateFetched();
      _applyLocalFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (myRequestId != _requestId) return;
      _isLoading = false;
      _error     = 'Could not load sales returns. Pull down to retry.';
      _fetched   = [];
      _filtered  = [];
      notifyListeners();
    }
  }

  void _applyLocalFilter() {
    List<SalesReturnItem> result = _fetched;

    final branchName = _ownerData.selectedBranch?.name;
    if (branchName != null && branchName.isNotEmpty) {
      final bn = branchName.toLowerCase();
      result = result
          .where((r) => r.branchName.toLowerCase() == bn)
          .toList();
    }

    if (_invoiceSearch != null && _invoiceSearch!.isNotEmpty) {
      final q = _invoiceSearch!.toLowerCase();
      result = result
          .where((r) =>
      r.invoiceNumber.toLowerCase().contains(q) ||
          r.creditNoteNumber.toLowerCase().contains(q))
          .toList();
    }

    _filtered = result;
  }

  SalesReturnItem _mapToItem(WorkshopSalesReturn r) {
    final notesParts = <String>[];
    if (r.reason.isNotEmpty) notesParts.add(r.reason);
    if ((r.rejectionReason ?? '').isNotEmpty) {
      notesParts.add('Rejected: ${r.rejectionReason}');
    }

    return SalesReturnItem(
      id:                  r.id,
      creditNoteNumber:    r.creditNoteNo,
      returnNo:            r.returnNo,
      invoiceNumber:       r.invoiceNo,
      customerName:        r.customerName.isNotEmpty ? r.customerName : r.customerMobile,
      customerMobile:      r.customerMobile,
      vehiclePlate:        r.returnNo,
      cashierName:         r.cashierName,
      branchName:          r.branchName,
      type:                SalesReturnType.creditNote,
      amount:              r.totalAmount,
      subtotal:            r.subtotal,
      vatAmount:           r.vatAmount,
      currency:            'SAR',
      status:              _uiStatusFor(r.status),
      returnScope:         r.returnScope.isNotEmpty ? r.returnScope : 'full',
      dateTime:            r.returnDate,
      notes:               notesParts.isEmpty ? null : notesParts.join('\n'),
      invoicePublicToken:  r.invoicePublicToken,
    );
  }
}