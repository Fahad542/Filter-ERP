import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/cashier_realtime_session_guard.dart';
import '../../../utils/toast_service.dart';
import 'package:intl/intl.dart';
import '../../../models/pos_product_model.dart';
import '../../../models/pos_order_model.dart';
import '../../../models/pos_technician_model.dart';
import '../../../models/petty_cash_model.dart';
import '../../../models/store_closing_model.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/catalog_sync_service.dart';
import '../../../services/catalog_local_database.dart';
import '../../../models/walk_in_customer_model.dart';
import '../../../models/customer_search_model.dart';
import '../../../models/create_invoice_model.dart';
import '../../../models/pos_payment_method.dart';
import '../../../models/invoiced_orders_model.dart';
import '../../../models/expense_category_model.dart'; // Added
import '../../../models/cashier_complete_job_model.dart'; // Added
import '../../../models/cashier_corporate_accounts_api_model.dart';
import '../../../models/corporate_quoted_products_model.dart';
import '../../../models/order_payment_method_draft.dart';
import '../Navbar/pos_shell.dart' show navigateToPosShellBroadcastTab;
import '../../../services/locker_translation_mixin.dart';
import '../../../services/softpos_bridge.dart';
import '../../../services/softpos_request_payment_flow.dart';
import '../More Tab/settings_view_model.dart';
import '../../../utils/promo_eligibility.dart';
import '../../../utils/app_formatters.dart';

/// One home-search result card: customer + a specific invoiced order.
class HomeCustomerInvoiceRow {
  final SearchedCustomer customer;
  final InvoicedOrder order;

  const HomeCustomerInvoiceRow({
    required this.customer,
    required this.order,
  });
}

class _DepartmentPromoState {
  final String code;
  final String? promoCodeId;
  final double discount;
  final bool isPercent;
  /// Server-computed promo amount (scoped by rules 1–3). When set, overrides local %/fixed math.
  final double? computedDiscountAmount;
  final PromoEligibility? eligibility;
  final String? discountLabel;
  final String? appliesToLabel;
  /// Category promos: cart line ids that matched at apply time (survives catalog reload).
  final Set<String> pinnedEligibleLineIds;

  const _DepartmentPromoState({
    required this.code,
    required this.promoCodeId,
    required this.discount,
    required this.isPercent,
    this.computedDiscountAmount,
    this.eligibility,
    this.discountLabel,
    this.appliesToLabel,
    this.pinnedEligibleLineIds = const {},
  });
}

/// Billing + vehicle fields saved from the walk-in "Invoice details" dialog, keyed by order id.
/// Prevents one order's draft from pre-filling another when [PosViewModel] is shared.
class WalkInBillingSnapshot {
  final String name;
  final String mobile;
  final String vat;
  final String vehicleNumber;
  final String vin;
  final String make;
  final String model;
  final int odometer;
  final String year;
  final String color;
  /// Cashier toggled “branch employee customer”; optional roster metadata for PATCH.
  final bool billingCustomerIsEmployee;
  final String? billingEmployeeId;
  final String? billingEmployeeType;

  /// Last-picked GCC plate country (`SA`/`AE`/`KW`/`BH`/`QA`/`OM`).
  /// Round-trips through the Edit-customer-details dialog so the country
  /// selector pre-fills correctly on reopen.
  final String vehiclePlateCountry;

  /// UAE emirate when [vehiclePlateCountry] is `AE`.
  final String? vehiclePlateEmirate;

  const WalkInBillingSnapshot({
    required this.name,
    required this.mobile,
    required this.vat,
    required this.vehicleNumber,
    required this.vin,
    required this.make,
    required this.model,
    required this.odometer,
    required this.year,
    required this.color,
    this.billingCustomerIsEmployee = false,
    this.billingEmployeeId,
    this.billingEmployeeType,
    this.vehiclePlateCountry = 'SA',
    this.vehiclePlateEmirate,
  });
}

/// Per-order payment modal draft (Orders Hub / checkout). Prevents bleed across orders.
class InvoicePaymentDraftState {
  final bool? isCorporate;
  final Set<PaymentMethod> methods;
  final Map<PaymentMethod, double> amounts;
  final Set<String> employeeIds;
  final bool wasUserEdited;

  const InvoicePaymentDraftState({
    this.isCorporate,
    this.methods = const {},
    this.amounts = const {},
    this.employeeIds = const {},
    this.wasUserEdited = false,
  });
}

/// Prefer saved "Invoice details" snapshot, then VM overlay, then order from API.
String _walkInPickField(String snap, String vm, String orderFallback) {
  final a = snap.trim();
  if (a.isNotEmpty) return a;
  final b = vm.trim();
  if (b.isNotEmpty) return b;
  return orderFallback.trim();
}

/// Backend expects integer year; tolerate spaces or extra text (e.g. "2010 ").
int? _parseYearForBillingApi(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final direct = int.tryParse(t);
  if (direct != null) return direct;
  final m = RegExp(r'\b(19|20)\d{2}\b').firstMatch(t);
  if (m != null) return int.tryParse(m.group(0)!);
  return null;
}

class PosViewModel extends ChangeNotifier with TranslatableMixin {
  final PosRepository posRepository;
  final SessionService sessionService;
  final CatalogSyncService catalogSync;
  final RealtimeService _realtimeService = RealtimeService();

  bool _isCatalogSyncing = false;
  bool get isCatalogSyncing => _isCatalogSyncing;

  bool _forcedLogoutPending = false;
  bool get forcedLogoutPending => _forcedLogoutPending;

  bool consumeForcedLogout() {
    if (!_forcedLogoutPending) return false;
    _forcedLogoutPending = false;
    return true;
  }

  void clearForcedLogoutPending() {
    _forcedLogoutPending = false;
  }

  PosViewModel({
    required this.posRepository,
    required this.sessionService,
    required this.catalogSync,
    SettingsViewModel? settingsViewModel,
  }) {
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel, retranslate);
    }
    _loadUserInfo();
  }

  Future<void> retranslate() async {
    await _applyHeaderTranslations();
    notifyListeners();
  }

  /// Called from the drawer header with the live widget-tree locale.
  /// Pass [notify: false] while the shell drawer is opening so [notifyListeners]
  /// does not rebuild the orders body and dismiss the drawer (RTL/LTR).
  Future<void> retranslateWithLocale(
    String langCode, {
    bool notify = true,
  }) async {
    await _applyHeaderTranslations(langCodeOverride: langCode);
    if (notify) notifyListeners();
  }

  bool _homeSearchHasFocus = false;

  void _onSearchFocusChanged() {
    final focused = _homeSearchFocusNode.hasFocus;
    if (focused != _homeSearchHasFocus) {
      _homeSearchHasFocus = focused;
      notifyListeners();
    }
  }

  Future<void> _loadUserInfo() async {
    _homeSearchFocusNode.addListener(_onSearchFocusChanged);
    final user = await sessionService.getUser();
    if (user != null) {
      _rawCashierName = user.cashier?.cashierName ?? user.name;
      _rawWorkshopName = user.workshopName;
      _rawBranchName = user.branchName;
      await _applyHeaderTranslations();
      notifyListeners();
    }
    await _initSocket();
  }

  Future<void> reconnectRealtime() async {
    await _initSocket();
  }

  Future<void> _initSocket() async {
    _attachOrderRealtimeListeners();
    await CashierRealtimeSessionGuard.instance.ensureConnected();
  }

  bool _orderRealtimeListenersAttached = false;

  void _attachOrderRealtimeListeners() {
    if (_orderRealtimeListenersAttached) return;
    _orderRealtimeListenersAttached = true;
    _realtimeService.on(RealtimeService.eventCashierOrdersUpdated, _onOrdersUpdated);
    _realtimeService.on(
        RealtimeService.eventCashierBroadcastUpdated, _onCashierBroadcastUpdated);
    _realtimeService.on(RealtimeService.eventCorporateWalkInOrderUpdated, _onOrdersUpdated);
    _realtimeService.on(RealtimeService.eventCashierCorporateWalkInApproved, _onOrdersUpdated);
    _realtimeService.on(RealtimeService.eventCashierCorporateWalkInRejected, _onOrdersUpdated);
  }

  void _onOrdersUpdated(Map<String, dynamic> payload) {
    final event = (payload['event'] ?? '').toString().toLowerCase();
    final removedId = (payload['orderId'] ?? payload['order_id'] ?? '')
        .toString()
        .trim();
    if (event == 'order_cancelled' ||
        event == 'order_invoiced' ||
        event.contains('invoice_created')) {
      if (removedId.isNotEmpty) {
        _applyOrderRemovedFromHub(removedId);
      }
      return;
    }
    _ordersRealtimeDebounce?.cancel();
    _ordersRealtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      _ordersRealtimeDebounce = null;
      final orderId = (payload['orderId'] ?? payload['order_id'] ?? '')
          .toString()
          .trim();
      if (orderId.isNotEmpty) {
        unawaited(refreshOrderInHubAfterMutation(orderId));
        return;
      }
      final preferredId = _selectedOrder?.id.trim();
      unawaited(
        fetchOrders(
          silent: true,
          preferredOrderId:
              preferredId != null && preferredId.isNotEmpty ? preferredId : null,
          force: true,
        ),
      );
    });
  }

  /// Technician accepted/rejected broadcast or window closed — end cashier broadcast timer / cooldown.
  void _onCashierBroadcastUpdated(Map<String, dynamic> payload) {
    _maybeEndBroadcastCooldownFromSocketPayload(payload);
    _onOrdersUpdated(payload);
  }

  String? _parseJobIdFromCashierBroadcastPayload(Map<String, dynamic> payload) {
    for (final key in ['jobId', 'job_id']) {
      final v = payload[key]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    final job = payload['job'];
    if (job is Map) {
      final m = Map<String, dynamic>.from(job);
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    final data = payload['data'];
    if (data is Map) {
      return _parseJobIdFromCashierBroadcastPayload(
          Map<String, dynamic>.from(data));
    }
    final broadcast = payload['broadcast'];
    if (broadcast is Map) {
      return _parseJobIdFromCashierBroadcastPayload(
          Map<String, dynamic>.from(broadcast));
    }
    return null;
  }

  bool _payloadIndicatesBroadcastEnded(Map<String, dynamic> payload) {
    final event = (payload['event'] ??
        payload['type'] ??
        payload['action'] ??
        '')
        .toString()
        .toLowerCase();
    if (event.contains('broadcast') && event.contains('create')) return false;
    if (event.contains('pending') &&
        !event.contains('accept') &&
        !event.contains('reject') &&
        !event.contains('close')) {
      return false;
    }

    if (event.contains('accept')) return true;
    if (event.contains('assign') && !event.contains('unassign')) return true;
    if (event.contains('reject')) return true;
    if (event.contains('declin')) return true;
    if (event.contains('expir')) return true;
    if (event.contains('cancel')) return true;
    if (event.contains('closed')) return true;

    final reason =
    (payload['reason'] ?? payload['closeReason'])?.toString().toLowerCase();
    if (reason != null) {
      if (reason.contains('accept')) return true;
      if (reason.contains('reject')) return true;
      if (reason.contains('declin')) return true;
      if (reason.contains('expir')) return true;
    }

    final status = (payload['status'] ?? payload['broadcastStatus'])
        ?.toString()
        .toLowerCase();
    if (status != null) {
      if (status.contains('accept')) return true;
      if (status.contains('assign')) return true;
      if (status.contains('reject') || status.contains('declin')) return true;
      if (status.contains('expir') || status.contains('cancel')) return true;
      if (status == 'closed' || status == 'completed') return true;
    }

    if (payload['accepted'] == true) return true;
    return false;
  }

  void _maybeEndBroadcastCooldownFromSocketPayload(Map<String, dynamic> payload) {
    if (!_payloadIndicatesBroadcastEnded(payload)) return;
    final jobId = _parseJobIdFromCashierBroadcastPayload(payload);
    if (jobId == null || jobId.isEmpty) return;
    final rawDept = payload['departmentId'] ?? payload['department_id'];
    final departmentId = rawDept?.toString().trim();
    _clearBroadcastCooldownKeys(
      jobId: jobId,
      departmentId: (departmentId != null && departmentId.isNotEmpty)
          ? departmentId
          : null,
    );
    notifyListeners();
  }

  /// When orders show a technician has taken the job (accept / in progress), drop broadcast cooldown.
  void _syncBroadcastCooldownWithOrdersAfterFetch(List<PosOrder> orders) {
    if (_broadcastCooldownEndsAt.isEmpty) return;
    var cleared = false;
    for (final o in orders) {
      for (final j in o.jobs) {
        if (j.isCancelledJob) continue;
        final jobKey = 'job:${j.id}';
        final deptId = j.departmentId?.trim();
        final deptKey =
        (deptId != null && deptId.isNotEmpty) ? 'dept:$deptId' : null;
        final hasCooldown = _broadcastCooldownEndsAt.containsKey(jobKey) ||
            (deptKey != null &&
                _broadcastCooldownEndsAt.containsKey(deptKey));
        if (!hasCooldown) continue;

        final st = j.status.trim().toLowerCase();
        final waitingOnTech = st.contains('waiting') &&
            (st.contains('technician') ||
                st.contains('acception') ||
                st.contains('acceptance'));
        if (waitingOnTech) continue;
        if (j.distinctActiveTechnicians.isEmpty) continue;

        _clearBroadcastCooldownKeys(jobId: j.id, departmentId: deptId);
        cleared = true;
      }
    }
    if (cleared) {
      notifyListeners();
    }
  }

  List<CashierCorporateAccount> _corporateAccounts = [];
  bool _isCorpAccountsLoading = false;
  /// After one successful GET, do not auto-fetch again while accounts stay empty (avoids a hydrate↔fetch loop).
  bool _corporateAccountsLoadedOnce = false;
  bool _corporateAccountsFetchInFlight = false;

  List<CashierCorporateAccount> get corporateAccounts => _corporateAccounts;
  bool get isCorpAccountsLoading => _isCorpAccountsLoading;

  /// Loads branch corporate accounts for corporate walk-in / booking payment defaults and Add Customer (Corporate tab).
  /// [forceRefresh] bypasses the one-shot cache (e.g. user opened Corporate customer tab to pick up newly added accounts).
  Future<void> fetchCorporateAccounts({
    bool silent = true,
    bool forceRefresh = false,
  }) async {
    if (_corporateAccountsFetchInFlight) return;
    if (!forceRefresh && _corporateAccountsLoadedOnce) return;

    _corporateAccountsFetchInFlight = true;
    if (!silent) {
      _isCorpAccountsLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final response = await posRepository.getCashierCorporateAccounts(token);
      if (response.success) {
        _corporateAccounts = response.accounts;
        _corporateAccountsLoadedOnce = true;
        _hydrateInvoicePaymentDefaultsForSelectedOrder();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
    } finally {
      _corporateAccountsFetchInFlight = false;
      if (!silent) {
        _isCorpAccountsLoading = false;
        notifyListeners();
      }
    }
  }

  // Walk-in Customer State
  String _customerName = '';
  String _vatNumber = '';
  String _mobile = '';
  String _vehicleNumber = '';
  String _vehiclePlateCountry = 'SA';
  String? _vehiclePlateEmirate;
  String? _corporateFleetVehicleId;
  String _vinNumber = '';
  String _make = '';
  String _model = '';
  int _odometerReading = 0;
  String _vehicleYear = '';
  String _vehicleColor = '';
  bool _billingCustomerIsEmployee = false;
  String? _billingEmployeeId;
  String? _billingEmployeeType;
  String? _previousOrderId;
  /// Last order returned from a successful walk-in shell / create (for jobId lookup by department).
  WalkInOrder? _lastPlacedWalkInOrder;
  /// Tracks the latest created walk-in order id for post-create redirect selection.
  String? _lastCreatedWalkInOrderId;
  /// Fallback selector when backend create response omits order.id.
  String? _lastCreatedWalkInVehicleNumber;
  /// Set when cashier saves a walk-in under Corporate Customer tab (submit-for-approval flow).
  String? _corporateAccountId;
  /// Corporate **quotation** lines from API (`quotedLines` / flagged rows only).
  final Map<String, List<CorporateQuotedProduct>> _corporateApiQuotedLinesByAccountId =
      {};
  /// Lines used to **overwrite branch tile prices** (quotation + portal booking items).
  final Map<String, List<CorporateQuotedProduct>> _corporateQuotedProductsByAccountId =
      {};
  /// Quotation lines from corporate booking payload (before cashier order exists).
  List<CorporateQuotedProduct> _extrinsicCorporateQuotedLines = const [];
  /// Corporate portal booking id — used to reload quoted lines on product grid.
  String? _activeCorporateBookingId;
  String? _loadedCorporateCatalogAccountId;
  bool _corporateCatalogLoading = false;
  /// Tracks whether [_allProducts] was loaded with corporate quote merge (vs branch-only).
  bool _lastCatalogFetchWasCorporate = false;
  String? _editDepartmentId;
  List<dynamic>? _editPreSelectedItems;
  PosOrder? _editingOrder;
  String? _editingCompletingOrderId;

  /// Orders summary panel: corporate vs individual + payment method(s) before Generate Invoice.
  bool? _invoicePaymentIsCorporate;
  final Set<PaymentMethod> _invoicePaymentMethods = <PaymentMethod>{};
  final Map<PaymentMethod, double> _invoicePaymentAmounts = <PaymentMethod, double>{};
  final Set<String> _invoicePaymentEmployeeIds = <String>{};
  bool _invoicePaymentWasUserEdited = false;
  /// Order id whose payment fields are currently loaded into the active UI slots.
  String? _activeInvoicePaymentOrderId;
  /// Per-order payment drafts keyed by order id (mirrors [_walkInBillingSnapshotsByOrderId]).
  final Map<String, InvoicePaymentDraftState> _paymentDraftByOrderId =
      <String, InvoicePaymentDraftState>{};
  /// Dedup concurrent clears when retail employee hides payment picker but Order still carries old draft rows.
  final Set<String> _retailEmployeePaymentDraftClearInFlight = {};

  /// Per–walk-in-order billing drafts (Add customer details / Final Review). Not global VM bleed.
  final Map<String, WalkInBillingSnapshot> _walkInBillingSnapshotsByOrderId =
  <String, WalkInBillingSnapshot>{};

  String get customerName => _customerName;
  String get vatNumber => _vatNumber;
  String get mobile => _mobile;
  String get vehicleNumber => _vehicleNumber;
  String get vehiclePlateCountry => _vehiclePlateCountry;
  String? get vehiclePlateEmirate => _vehiclePlateEmirate;
  String? get corporateFleetVehicleId => _corporateFleetVehicleId;
  String get vinNumber => _vinNumber;
  String get make => _make;
  String get model => _model;
  int get odometerReading => _odometerReading;
  String get vehicleYear => _vehicleYear;
  String get vehicleColor => _vehicleColor;
  String? get editDepartmentId => _editDepartmentId;
  List<dynamic>? get editPreSelectedItems => _editPreSelectedItems;
  PosOrder? get editingOrder => _editingOrder;
  String? get editingCompletingOrderId => _editingCompletingOrderId;
  String? get corporateAccountId => _corporateAccountId;
  bool get corporateCatalogLoading => _corporateCatalogLoading;
  bool get hasCorporateProductsCatalogLoaded =>
      _loadedCorporateCatalogAccountId != null &&
      _corporateQuotedProductsByAccountId
          .containsKey(_loadedCorporateCatalogAccountId);

  bool get lastCatalogFetchWasCorporate => _lastCatalogFetchWasCorporate;

  /// Branch catalog was loaded for a job department (corporate flow).
  bool get isCorporateCatalogDepartmentScoped =>
      shouldUseCorporateQuotedCatalog &&
      _lastCatalogFetchWasCorporate &&
      (_lastFetchedDepartmentId?.trim().isNotEmpty ?? false);

  /// Active corporate account (draft walk-in or order being edited).
  String? get activeCorporateAccountId {
    final draft = (_corporateAccountId ?? '').trim();
    if (draft.isNotEmpty) return draft;
    final fromOrder = (_editingOrder?.corporateAccountId ?? '').trim();
    if (fromOrder.isNotEmpty) return fromOrder;
    return null;
  }

  /// Corporate flows load quoted prices via
  /// `GET /cashier/corporate-accounts/:id/products` (+ order/booking `unitPrice` lines),
  /// merged with branch catalog when available.
  bool get shouldUseCorporateQuotedCatalog {
    final order = _editingOrder;
    if (order != null) {
      if (order.isCorporateBookingOrder) return true;
      if (order.isCorporateWalkIn) return true;
    }
    final draftCorpId = (_corporateAccountId ?? '').trim();
    if (draftCorpId.isNotEmpty) return true;
    // Portal booking primed before cashier order exists.
    return _extrinsicCorporateQuotedLines.isNotEmpty &&
        activeCorporateAccountId != null;
  }

  @Deprecated('Use shouldUseCorporateQuotedCatalog')
  bool get shouldUseCorporateBookingCatalog => shouldUseCorporateQuotedCatalog;

  WalkInOrder? get lastPlacedWalkInOrder => _lastPlacedWalkInOrder;
  String? get lastCreatedWalkInOrderId => _lastCreatedWalkInOrderId;
  String? get lastCreatedWalkInVehicleNumber => _lastCreatedWalkInVehicleNumber;

  bool? get invoicePaymentIsCorporate {
    _ensureActivePaymentMatchesSelectedOrder();
    return _invoicePaymentIsCorporate;
  }

  Set<PaymentMethod> get invoicePaymentMethods {
    _ensureActivePaymentMatchesSelectedOrder();
    return Set<PaymentMethod>.unmodifiable(_invoicePaymentMethods);
  }

  Map<PaymentMethod, double> get invoicePaymentAmounts {
    _ensureActivePaymentMatchesSelectedOrder();
    return Map<PaymentMethod, double>.unmodifiable(_invoicePaymentAmounts);
  }
  Set<String> get invoicePaymentEmployeeIds =>
      Set<String>.unmodifiable(_invoicePaymentEmployeeIds);
  bool get invoicePaymentSelectionReady {
    _ensureActivePaymentMatchesSelectedOrder();
    return _invoicePaymentIsCorporate != null &&
        _invoicePaymentMethods.isNotEmpty;
  }

  /// Payment UI for [order] — does not leak another order's in-memory selection.
  bool invoicePaymentSelectionReadyFor(PosOrder order) {
    final id = order.id.trim();
    if (id.isEmpty) return false;
    // SoftPOS / Request Payment already locked the order as paid.
    if (order.isPosPrepaid) {
      final prepaid = order.posPrepaidPayments;
      if (prepaid != null && prepaid.isNotEmpty) return true;
      final draft = order.posPayments;
      if (draft != null && draft.isNotEmpty) return true;
      if (_activeInvoicePaymentOrderId == id &&
          _invoicePaymentMethods.isNotEmpty) {
        return true;
      }
      return true;
    }
    if (_activeInvoicePaymentOrderId == id) {
      return _invoicePaymentIsCorporate != null &&
          _invoicePaymentMethods.isNotEmpty;
    }
    final cached = _paymentDraftByOrderId[id];
    if (cached != null &&
        cached.wasUserEdited &&
        cached.isCorporate != null &&
        cached.methods.isNotEmpty) {
      return true;
    }
    final rows = order.posPayments;
    if (rows != null && rows.isNotEmpty) return true;
    if (order.isCorporateWalkIn || order.isCorporateBookingOrder) {
      return true;
    }
    return false;
  }

  /// SoftPOS Tap to Pay approved → record received amount as prepaid.
  Future<String?> recordSoftPosAppBarPayment({
    required PosOrder order,
    required double paidAmount,
    String? intentUuid,
  }) {
    return recordAdvanceOrderPayment(
      order: order,
      method: PaymentMethod.tapToPay,
      paidAmount: paidAmount,
      intentUuid: intentUuid,
      softPos: true,
    );
  }

  /// Advance receive (total may be 0). Same method can be recorded many times;
  /// amounts accumulate on the order. Payment method tiles stay unlocked.
  Future<String?> recordAdvanceOrderPayment({
    required PosOrder order,
    required PaymentMethod method,
    required double paidAmount,
    String? intentUuid,
    bool softPos = false,
  }) async {
    final orderId = order.id.trim();
    if (orderId.isEmpty) return 'Order id missing';
    if (paidAmount <= 0.001) return 'Invalid amount';

    _requestingPaymentOrderId = orderId;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) return 'Session expired. Sign in again.';

      final methodLabel = method.label;
      final source = softPos || method == PaymentMethod.tapToPay
          ? 'softpos_app_bar'
          : 'advance_receive';
      final paymentSplits = <Map<String, dynamic>>[
        {
          'method': methodLabel,
          'amount': paidAmount,
          'source': source,
        },
      ];
      final prepaidRows = [
        PosPaymentDraftRow(
          method: methodLabel,
          amount: paidAmount,
          source: source,
        ),
      ];

      final res = await posRepository.recordOrderPrepayment(
        orderId: orderId,
        token: token,
        isCorporate: false,
        payments: paymentSplits,
        paidAmount: paidAmount,
        intentUuid: intentUuid,
        softPosAppBar: true,
      );
      if (res['success'] != true) {
        final msg = res['message']?.toString().trim();
        return msg != null && msg.isNotEmpty
            ? msg
            : 'Could not record payment.';
      }

      _applyPosPrepaidToHub(
        orderId: orderId,
        paidAmount: paidAmount,
        payments: prepaidRows,
        intentUuid: intentUuid,
        accumulate: true,
      );
      _hydrateInvoicePaymentDefaultsForSelectedOrder();
      notifyListeners();

      await refreshOrderInHubAfterMutation(orderId, apiResponse: res);
      _hydrateInvoicePaymentDefaultsForSelectedOrder();
      notifyListeners();
      return null;
    } catch (e) {
      return _extractErrorMessage(e.toString());
    } finally {
      if (_requestingPaymentOrderId == orderId) {
        _requestingPaymentOrderId = null;
        notifyListeners();
      }
    }
  }

  /// Patch prepaid fields onto hub list + selected order for immediate UI.
  void _applyPosPrepaidToHub({
    required String orderId,
    required double paidAmount,
    required List<PosPaymentDraftRow> payments,
    String? intentUuid,
    bool accumulate = false,
  }) {
    final id = orderId.trim();
    if (id.isEmpty) return;

    PosOrder patch(PosOrder o) {
      if (o.id.trim() != id) return o;
      final prevAmt = accumulate ? (o.posPrepaidAmount ?? 0) : 0.0;
      final prevRows = accumulate
          ? List<PosPaymentDraftRow>.of(o.posPrepaidPayments ?? const [])
          : <PosPaymentDraftRow>[];
      final nextRows = [...prevRows, ...payments];
      final nextAmt = prevAmt + paidAmount;
      return o.copyWith(
        posPrepaidAmount: nextAmt,
        posPrepaidAt: DateTime.now().toUtc().toIso8601String(),
        posPrepaidPayments: nextRows,
        posPrepaidIntentId: intentUuid ?? o.posPrepaidIntentId,
        posPayments: nextRows,
        posCustomerKind: (o.posCustomerKind ?? '').trim().isNotEmpty
            ? o.posCustomerKind
            : 'individual',
      );
    }

    _orders = _orders.map(patch).toList();
    if (_selectedOrder?.id.trim() == id) {
      _selectedOrder = patch(_selectedOrder!);
    }
    if (_editingOrder?.id.trim() == id) {
      _editingOrder = patch(_editingOrder!);
    }
  }

  void _ensureActivePaymentMatchesSelectedOrder() {
    final sel = _selectedOrder;
    if (sel == null) return;
    final sid = sel.id.trim();
    if (sid.isEmpty) return;
    if (_activeInvoicePaymentOrderId == sid) return;
    _activateInvoicePaymentContextForOrder(sel);
  }

  WalkInBillingSnapshot? walkInBillingSnapshotForOrder(String orderId) {
    final k = orderId.trim();
    if (k.isEmpty) return null;
    return _walkInBillingSnapshotsByOrderId[k];
  }

  /// Job id for a department on the last successful walk-in create response (shell).
  String? jobIdForPlacedDepartment(String departmentId) {
    final o = _lastPlacedWalkInOrder;
    if (o == null || departmentId.trim().isEmpty) return null;
    final want = departmentId.trim();
    for (final d in o.departments) {
      if ((d.departmentId ?? '').trim() == want) {
        final jid = d.jobId?.trim();
        if (jid != null && jid.isNotEmpty) return jid;
      }
    }
    return null;
  }

  bool _isLoading = false;
  /// True while user-triggered refresh runs on the Orders screen (GET /cashier/orders).
  bool _ordersScreenRefreshInFlight = false;
  /// True after [fetchOrders] finishes (success or error), including `silent` calls.
  bool _ordersApiFetchCompleted = false;
  /// Last GET /cashier/orders failure — shown on the Orders screen only.
  String? _ordersFetchError;
  /// True while Save on the product-grid invoice panel is running (pricing / walk-in from panel).
  bool _invoicePanelSaveBusy = false;
  String? _errorMessage;
  String? _currentJobId;
  List<PosOrder> _orders = [];
  int _ordersOffset = 0;
  /// Next server `offset` for load-more (advances only on successful page fetches).
  int _ordersNextOffset = 0;
  int _ordersListTotal = 0;
  bool _ordersHasMore = false;
  bool _isLoadingMoreOrders = false;
  static const int cashierOrdersPageSize = 50;
  PosOrder? _selectedOrder;
  OrderStats _orderStats = OrderStats.empty();
  List<SearchedCustomer> _searchedCustomers = [];
  /// True only after Apply / suggestion tap — typing must not keep old cards.
  bool _homeSearchApplied = false;
  String _appliedHomeSearchQuery = '';
  /// Flattened invoiced orders for home search results (one card per invoice).
  List<HomeCustomerInvoiceRow> _homeInvoiceRows = [];
  List<SearchedCustomer> _homeSearchSuggestions = [];
  bool _isSearchingCustomer = false;
  bool _isSuggestingCustomer = false;
  int _homeSuggestionGeneration = 0;
  int _shellSelectedIndex = 0;
  int _hubScrollRequestSerial = 0;
  String? _hubScrollToOrderId;

  String? _rawCashierName;
  String? _rawWorkshopName;
  String? _rawBranchName;
  String? _cashierName;
  String? _workshopName;
  String? _branchName;

  bool _isInvoiceLoading = false;
  final Map<String, String> _invoiceNoByOrderId = {};
  String? _loadingOrderId;
  String? _requestingPaymentOrderId;
  /// Cashier "Mark complete" API in flight for this job (orders list, product grid, sheets).
  String? _cashierCompletingJobId;
  bool get isLoading => _isLoading;
  bool get isOrdersScreenRefreshing => _ordersScreenRefreshInFlight;
  bool get ordersApiFetchCompleted => _ordersApiFetchCompleted;
  /// True when the cashier orders API returned at least one order (unfiltered store).
  bool get hasCashierOrdersFromApi => _orders.isNotEmpty;
  String? get ordersFetchError => _ordersFetchError;
  int get ordersListTotal => _ordersListTotal;
  bool get ordersHasMore => _ordersHasMore;
  bool get isLoadingMoreOrders => _isLoadingMoreOrders;
  bool get isInvoicePanelSaveBusy => _invoicePanelSaveBusy;
  bool get isInvoiceLoading => _isInvoiceLoading;
  String? get loadingOrderId => _loadingOrderId;

  bool isInvoicingOrder(String orderId) {
    final id = orderId.trim();
    return id.isNotEmpty && _isInvoiceLoading && _loadingOrderId == id;
  }

  void beginInvoiceGeneration(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) return;
    _isInvoiceLoading = true;
    _loadingOrderId = id;
    notifyListeners();
  }

  void endInvoiceGeneration() {
    if (!_isInvoiceLoading && _loadingOrderId == null) return;
    _isInvoiceLoading = false;
    _loadingOrderId = null;
    notifyListeners();
  }

  bool isRequestingPaymentFor(String orderId) {
    final id = orderId.trim();
    return id.isNotEmpty && _requestingPaymentOrderId == id;
  }
  bool isCashierCompletingJob(String jobId) =>
      jobId.isNotEmpty && _cashierCompletingJobId == jobId;
  String? get errorMessage => _errorMessage;
  String? get currentJobId => _currentJobId;
  PosOrder? get selectedOrder => _selectedOrder;
  OrderStats get orderStats => _orderStats;
  List<SearchedCustomer> get searchedCustomers => _searchedCustomers;
  List<HomeCustomerInvoiceRow> get homeInvoiceRows => _homeInvoiceRows;
  List<SearchedCustomer> get homeSearchSuggestions => _homeSearchSuggestions;
  bool get homeSearchApplied => _homeSearchApplied;
  bool get isSearchingCustomer => _isSearchingCustomer;
  bool get isSuggestingCustomer => _isSuggestingCustomer;
  int get shellSelectedIndex => _shellSelectedIndex;
  int get hubScrollRequestSerial => _hubScrollRequestSerial;
  String? get hubScrollToOrderId => _hubScrollToOrderId;

  /// Orders Hub list should scroll so [orderId] (or latest) is visible.
  void requestHubScrollToOrder([String? orderId]) {
    final explicit = orderId?.trim() ?? '';
    final id = explicit.isNotEmpty
        ? explicit
        : (_selectedOrder?.id.trim().isNotEmpty == true
            ? _selectedOrder!.id.trim()
            : (_lastCreatedWalkInOrderId?.trim().isNotEmpty == true
                ? _lastCreatedWalkInOrderId!.trim()
                : _latestOrderInHubList(_orders)?.id.trim() ?? ''));
    if (id.isEmpty) return;
    _hubScrollToOrderId = id;
    _hubScrollRequestSerial++;
    notifyListeners();
  }

  void setShellSelectedIndex(int index) {
    _shellSelectedIndex = index;
    notifyListeners();
  }

  /// Same rule as `_ordersIsRetailWalkInBranchEmployee` in [pos_orders_view] — payroll retail walk-ins hide cashier payment picker.
  bool cashierRetailBranchEmployeeHidesPaymentPicker(PosOrder o) {
    if (!_isStandardWalkInOrderForBilling(o)) return false;
    if (o.isCorporateWalkIn && !o.isCorporateBookingOrder) return false;
    final snap = _walkInBillingSnapshotsByOrderId[o.id.trim()];
    if (snap?.billingCustomerIsEmployee == true) return true;
    return o.customer?.isCustomerEmployee == true;
  }

  Future<void> _clearStaleDraftIfRetailEmployeeOrderHasServerPayments(
      String orderId,
      ) async {
    final id = orderId.trim();
    if (id.isEmpty || _retailEmployeePaymentDraftClearInFlight.contains(id)) {
      return;
    }
    _retailEmployeePaymentDraftClearInFlight.add(id);
    try {
      final err = await clearCashierOrderPaymentDraft(id);
      if (err != null) {
        debugPrint('Retail employee PAY draft clear skipped/failed: $err');
      }
    } finally {
      _retailEmployeePaymentDraftClearInFlight.remove(id);
    }
  }

  void _persistActivePaymentDraftToMap([String? orderId]) {
    final oid =
        (orderId ?? _activeInvoicePaymentOrderId ?? _selectedOrder?.id ?? '')
            .trim();
    if (oid.isEmpty) return;
    _paymentDraftByOrderId[oid] = InvoicePaymentDraftState(
      isCorporate: _invoicePaymentIsCorporate,
      methods: Set<PaymentMethod>.from(_invoicePaymentMethods),
      amounts: Map<PaymentMethod, double>.from(_invoicePaymentAmounts),
      employeeIds: Set<String>.from(_invoicePaymentEmployeeIds),
      wasUserEdited: _invoicePaymentWasUserEdited,
    );
  }

  void _applyPaymentDraftState(InvoicePaymentDraftState draft) {
    _invoicePaymentIsCorporate = draft.isCorporate;
    _invoicePaymentMethods
      ..clear()
      ..addAll(draft.methods);
    _invoicePaymentAmounts
      ..clear()
      ..addAll(draft.amounts);
    _invoicePaymentEmployeeIds
      ..clear()
      ..addAll(draft.employeeIds);
    _invoicePaymentWasUserEdited = draft.wasUserEdited;
  }

  /// Loads payment UI fields for [order], persisting the previous order's draft first.
  double _serverPayableAmountForOrder(PosOrder o) {
    final activeJobs = o.jobs.where((j) => !j.isCancelledJob).toList();
    if (activeJobs.isEmpty) {
      if (o.totalAmount > 0.0001) return o.totalAmount;
      return o.orderLevelLinesPayableTotal;
    }
    return o.draftPosOrderTotalDisplay;
  }

  void _activateInvoicePaymentContextForOrder(PosOrder order) {
    final newId = order.id.trim();
    if (newId.isEmpty) return;
    final prevId = (_activeInvoicePaymentOrderId ?? '').trim();
    if (prevId.isNotEmpty && prevId != newId) {
      _persistActivePaymentDraftToMap(prevId);
    }
    _activeInvoicePaymentOrderId = newId;

    _invoicePaymentIsCorporate = null;
    _invoicePaymentMethods.clear();
    _invoicePaymentAmounts.clear();
    _invoicePaymentEmployeeIds.clear();
    _invoicePaymentWasUserEdited = false;

    final serverPayable = _serverPayableAmountForOrder(order);
    if (serverPayable <= 0.0001) {
      _paymentDraftByOrderId.remove(newId);
    }

    final cached = _paymentDraftByOrderId[newId];
    if (cached != null &&
        cached.wasUserEdited &&
        serverPayable > 0.0001) {
      _applyPaymentDraftState(cached);
      return;
    }

    _hydrateInvoicePaymentDefaultsForOrder(order);
    _persistActivePaymentDraftToMap(newId);
  }

  void selectOrder(PosOrder? order) {
    if (order != null) {
      final id = order.id.trim();
      PosOrder resolved = order;
      if (id.isNotEmpty) {
        try {
          resolved = _orders.firstWhere((o) => o.id.trim() == id);
        } catch (_) {}
      }
      if (resolved.isCorporateWalkIn || resolved.isCorporateBookingOrder) {
        final corpId = (resolved.corporateAccountId ?? '').trim();
        if (corpId.isNotEmpty) {
          _corporateAccountId = corpId;
        }
      } else {
        clearCorporatePricingContext(notify: false);
      }
      _selectedOrder = resolved;
      _activateInvoicePaymentContextForOrder(resolved);
      _rehydrateWalkInVmFromSelectedOrderDraft();
      if (!resolved.linesIncluded && id.isNotEmpty) {
        unawaited(_hydrateOrderLinesIntoHub(id));
      }
    } else {
      _persistActivePaymentDraftToMap();
      _activeInvoicePaymentOrderId = null;
      _selectedOrder = null;
      _clearInvoicePaymentPreferences();
      _clearWalkInBillingOverlayFields();
    }
    notifyListeners();
  }

  /// Slim hub rows omit line items — load GET /cashier/order/:id before detail/checkout UI.
  Future<void> _hydrateOrderLinesIntoHub(String orderId) async {
    final id = orderId.trim();
    if (id.isEmpty) return;
    final detail = await loadCashierOrderDetail(id);
    if (detail == null) return;
    final hydrated = detail.copyWith(linesIncluded: true);
    _upsertOrderInHub(hydrated);
    if (_selectedOrder?.id.trim() == id) {
      _selectedOrder = hydrated;
      _activateInvoicePaymentContextForOrder(hydrated);
    }
    notifyListeners();
  }

  /// Ensures [orderId] has line items before edit / invoice / pricing mutations.
  Future<PosOrder?> ensureOrderLinesHydrated(
    String orderId, {
    bool force = false,
  }) async {
    final id = orderId.trim();
    if (id.isEmpty) return null;
    PosOrder? current;
    try {
      current = _orders.firstWhere((o) => o.id.trim() == id);
    } catch (_) {
      current = _selectedOrder?.id.trim() == id ? _selectedOrder : null;
    }
    final hasAnyJobLines = current?.jobs.any((j) => j.items.isNotEmpty) ?? false;
    // Slim/empty shells were previously stuck with linesIncluded:true + empty items.
    if (!force &&
        current != null &&
        current.linesIncluded &&
        hasAnyJobLines) {
      return current;
    }
    final detail = await loadCashierOrderDetail(id);
    if (detail == null) return current;
    final hydrated = detail.copyWith(linesIncluded: true);
    _upsertOrderInHub(hydrated);
    if (_selectedOrder?.id.trim() == id) {
      _selectedOrder = hydrated;
    }
    notifyListeners();
    return hydrated;
  }

  void _hydrateInvoicePaymentDefaultsForSelectedOrder() {
    final o = _selectedOrder;
    if (o == null) return;
    _hydrateInvoicePaymentDefaultsForOrder(o);
  }

  void _hydrateInvoicePaymentDefaultsForOrder(PosOrder o) {
    if (cashierRetailBranchEmployeeHidesPaymentPicker(o)) {
      _invoicePaymentIsCorporate = null;
      _invoicePaymentMethods.clear();
      _invoicePaymentAmounts.clear();
      _invoicePaymentEmployeeIds.clear();
      // caller handles notifyListeners(); we just kick off the async clear
      final hasStaleServerDraft = (o.posPayments != null && o.posPayments!.isNotEmpty) ||
          ((o.posCustomerKind ?? '').trim().isNotEmpty);
      if (hasStaleServerDraft) {
        unawaited(
          _clearStaleDraftIfRetailEmployeeOrderHasServerPayments(o.id.trim()),
        );
      }
      return;
    }

    final draftKind = o.posCustomerKind?.trim().toLowerCase();
    final draftRows = o.isPosPrepaid &&
            o.posPrepaidPayments != null &&
            o.posPrepaidPayments!.isNotEmpty
        ? o.posPrepaidPayments
        : o.posPayments;
    if (draftRows != null && draftRows.isNotEmpty) {
      if (draftKind != null && draftKind.isNotEmpty) {
        _invoicePaymentIsCorporate = draftKind == 'corporate';
      } else if (o.isCorporateWalkIn || o.isCorporateBookingOrder) {
        _invoicePaymentIsCorporate = true;
      } else {
        _invoicePaymentIsCorporate = false;
      }
      _invoicePaymentMethods.clear();
      _invoicePaymentAmounts.clear();
      _invoicePaymentEmployeeIds.clear();
      for (final row in draftRows) {
        final pm = parsePaymentMethodFromDraftApiLabel(row.method);
        if (pm == null || pm == PaymentMethod.employees) continue;
        _invoicePaymentMethods.add(pm);
        _invoicePaymentAmounts[pm] = row.amount;
      }
      if (_invoicePaymentMethods.isNotEmpty) {
        return; // caller will notify
      }
      _invoicePaymentMethods.clear();
      _invoicePaymentAmounts.clear();
    }

    // Corporate walk-in + corporate booking: default invoice payment dialog to corporate
    // methods, prefilling from order/booking payload or corporate account when possible.
    if (o.isCorporateWalkIn || o.isCorporateBookingOrder) {
      if (_corporateAccounts.isEmpty && !_corporateAccountsLoadedOnce) {
        unawaited(fetchCorporateAccounts(silent: true));
      }
      final preferred = _preferredCorporatePaymentMethodForOrder(o);
      final method = preferred ?? PaymentMethod.monthlyBilling;
      _invoicePaymentIsCorporate = true;
      _invoicePaymentEmployeeIds.clear();
      _invoicePaymentMethods
        ..clear()
        ..add(method);
      final payable = _serverPayableAmountForOrder(o);
      _invoicePaymentAmounts
        ..clear()
        ..[method] = payable > 0.0001 ? payable : 0.0;
    } else {
      // Retail / individual: no server draft — empty payment until user picks methods.
      _invoicePaymentIsCorporate = false;
      _invoicePaymentMethods.clear();
      _invoicePaymentAmounts.clear();
      _invoicePaymentEmployeeIds.clear();
    }
  }

  /// Sync payment modal + walk-in overlays when GET [/cashier/orders] swaps in fresh [PosOrder] rows.
  void _applyServerOrderSnapshotToBillingAndPaymentDraftState({
    String? previousSelectedOrderId,
  }) {
    final o = _selectedOrder;
    if (o == null) return;
    final oid = o.id.trim();
    final prev = (previousSelectedOrderId ?? '').trim();
    if (prev != oid) {
      _activateInvoicePaymentContextForOrder(o);
    } else {
      final cached = _paymentDraftByOrderId[oid];
      final serverPayable = _serverPayableAmountForOrder(o);
      if (serverPayable <= 0.0001 ||
          cached == null ||
          !cached.wasUserEdited) {
        _activateInvoicePaymentContextForOrder(o);
      }
    }
    _rehydrateWalkInVmFromSelectedOrderDraft();
  }

  /// Ensures payment dialog opens with sensible defaults for the given order.
  /// For corporate orders: Corporate tab + preferred method (or monthly billing).
  /// Also upserts into the hub list so SoftPOS / prepaid fields refresh the
  /// list badge without waiting for Sync.
  void ensureInvoicePaymentPrefillForOrder(PosOrder order) {
    _upsertOrderInHub(order);
    _selectedOrder = order;
    _activateInvoicePaymentContextForOrder(order);
    notifyListeners();
  }

  PaymentMethod? _preferredCorporatePaymentMethodForOrder(PosOrder order) {
    final orderLevel = (order.paymentMethod ?? '').trim();
    if (orderLevel.isNotEmpty) {
      final fromOrder = _paymentMethodFromBackendLabel(orderLevel);
      if (fromOrder != null) return fromOrder;
    }

    CashierCorporateAccount? account;
    final corporateId = (order.corporateAccountId ?? '').trim();
    if (corporateId.isNotEmpty) {
      for (final a in _corporateAccounts) {
        if (a.id.trim() == corporateId) {
          account = a;
          break;
        }
      }
    }
    account ??= _corporateAccounts.cast<CashierCorporateAccount?>().firstWhere(
          (a) =>
      (a?.companyName.trim().toLowerCase() ?? '') ==
          (order.corporateCompanyName ?? order.customerName).trim().toLowerCase(),
      orElse: () => null,
    );
    final raw = account?.preferredPaymentMethod?.trim() ?? '';
    if (raw.isEmpty) return null;
    return _paymentMethodFromBackendLabel(raw);
  }

  PaymentMethod? _paymentMethodFromBackendLabel(String raw) {
    final k = raw.trim().toLowerCase().replaceAll('_', ' ');
    if (k.contains('corporate credit')) {
      return PaymentMethod.monthlyBilling;
    }
    if (k.contains('monthly') ||
        k.contains('account receivable') ||
        k.contains('on account') ||
        k.contains('invoice to company')) {
      return PaymentMethod.monthlyBilling;
    }
    if (k.contains('bank') ||
        k.contains('wire') ||
        k.contains('transfer') ||
        k.contains('iban') ||
        k.contains('swift')) {
      return PaymentMethod.bankTransfer;
    }
    if (k.contains('cash')) return PaymentMethod.cash;
    if (k.contains('tap to pay') ||
        k.contains('taptopay') ||
        k.contains('softpos') ||
        k.contains('nearpay')) {
      return PaymentMethod.tapToPay;
    }
    if (k.contains('card') ||
        k.contains('credit') ||
        k.contains('debit') ||
        k.contains('mada') ||
        k.contains('visa') ||
        k.contains('master')) {
      return PaymentMethod.card;
    }
    if (k.contains('wallet')) return PaymentMethod.wallet;
    if (k.contains('tabby')) return PaymentMethod.tabby;
    if (k.contains('tamara')) return PaymentMethod.tamara;
    if (k.contains('employee')) return PaymentMethod.employees;
    return null;
  }

  int suggestedOdometerForOrder(PosOrder order) {
    if (order.odometerReading > 0) return order.odometerReading;
    final targetPlate = order.plateNumber.trim().toLowerCase();
    if (targetPlate.isEmpty) return 0;
    var best = 0;
    for (final o in _orders) {
      if (o.plateNumber.trim().toLowerCase() != targetPlate) continue;
      if (o.odometerReading > best) best = o.odometerReading;
    }
    return best;
  }

  void _clearWalkInBillingOverlayFields() {
    _customerName = '';
    _vatNumber = '';
    _mobile = '';
    _vehicleNumber = '';
    _vehiclePlateCountry = 'SA';
    _vehiclePlateEmirate = null;
    _corporateFleetVehicleId = null;
    _vinNumber = '';
    _make = '';
    _model = '';
    _odometerReading = 0;
    _vehicleYear = '';
    _vehicleColor = '';
    _billingCustomerIsEmployee = false;
    _billingEmployeeId = null;
    _billingEmployeeType = null;
  }

  void _applyWalkInSnapshotToVm(WalkInBillingSnapshot s) {
    _customerName = s.name;
    _mobile = s.mobile;
    _vatNumber = s.vat;
    _vehicleNumber = s.vehicleNumber;
    _vinNumber = s.vin;
    _make = s.make;
    _model = s.model;
    _odometerReading = s.odometer;
    _vehicleYear = s.year;
    _vehicleColor = s.color;
    _vehiclePlateCountry = s.vehiclePlateCountry.trim().isNotEmpty
        ? s.vehiclePlateCountry.trim().toUpperCase()
        : 'SA';
    _vehiclePlateEmirate = s.vehiclePlateEmirate?.trim().isNotEmpty == true
        ? s.vehiclePlateEmirate!.trim()
        : null;
  }

  /// Keeps [customerName] / vehicle fields aligned with the selected order's saved draft (or clears).
  void _rehydrateWalkInVmFromSelectedOrderDraft() {
    final oid = (_selectedOrder?.id ?? '').trim();
    if (oid.isEmpty) {
      _clearWalkInBillingOverlayFields();
      return;
    }
    final snap = _walkInBillingSnapshotsByOrderId[oid];
    if (snap != null) {
      _applyWalkInSnapshotToVm(snap);
    } else {
      _clearWalkInBillingOverlayFields();
    }
  }

  void setInvoicePaymentPreferences({
    required bool isCorporate,
    required Set<PaymentMethod> payments,
    Map<PaymentMethod, double> paymentAmounts = const {},
    Set<String> employeeIds = const <String>{},
    String? forOrderId,
  }) {
    _invoicePaymentWasUserEdited = true;
    _invoicePaymentIsCorporate = isCorporate;
    _invoicePaymentMethods
      ..clear()
      ..addAll(payments);
    _invoicePaymentAmounts
      ..clear()
      ..addAll(paymentAmounts);
    _invoicePaymentEmployeeIds.clear();
    if (payments.contains(PaymentMethod.employees)) {
      for (final id in employeeIds) {
        if (id.trim().isNotEmpty) {
          _invoicePaymentEmployeeIds.add(id);
          break;
        }
      }
    }
    final oid =
        (forOrderId ?? _activeInvoicePaymentOrderId ?? _selectedOrder?.id ?? '')
            .trim();
    if (oid.isNotEmpty) {
      _activeInvoicePaymentOrderId = oid;
      _persistActivePaymentDraftToMap(oid);
    }
    notifyListeners();
  }

  /// Product grid sidebar: prefill Employees payment (`employeeIds`) without changing methods.
  void setInvoicePaymentEmployeeSidebarId(String? employeeId) {
    _invoicePaymentEmployeeIds.clear();
    final id = employeeId?.trim();
    if (id != null && id.isNotEmpty) {
      _invoicePaymentEmployeeIds.add(id);
    }
    _invoicePaymentWasUserEdited = true;
    _persistActivePaymentDraftToMap();
    notifyListeners();
  }

  void _clearInvoicePaymentPreferences([String? orderId]) {
    _invoicePaymentWasUserEdited = false;
    _invoicePaymentIsCorporate = null;
    _invoicePaymentMethods.clear();
    _invoicePaymentAmounts.clear();
    _invoicePaymentEmployeeIds.clear();
    final oid =
        (orderId ?? _activeInvoicePaymentOrderId ?? '').trim();
    if (oid.isNotEmpty) {
      _paymentDraftByOrderId.remove(oid);
    }
  }

  /// Persists cashier payment-modal selection (customer kind + rows) via
  /// `PATCH /cashier/order/:orderId/payment-method` before invoice creation.
  ///
  /// [alreadyReceived] = SoftPOS / advance prepaid already on the order.
  /// Typed split amounts only need to cover the **remaining** payable.
  Future<String?> persistCashierOrderPaymentDraft({
    required String orderId,
    required bool isCorporate,
    required Set<PaymentMethod> methods,
    required Map<PaymentMethod, double> paymentAmounts,
    required double payableTotal,
    double alreadyReceived = 0,
  }) async {
    if (methods.isEmpty) return 'Choose at least one payment method.';
    double sum = 0;
    final rows = <Map<String, dynamic>>[];
    final payable = payableTotal > 0 ? payableTotal : 0.0;
    final prepaid = alreadyReceived > 0 ? alreadyReceived : 0.0;
    // Remaining to collect via this draft (0 when advance already covers).
    final remainingDue =
        (payable - prepaid).clamp(0.0, double.infinity);
    if (remainingDue <= 0.05) {
      // Already fully paid via SoftPOS / advance — nothing to draft-match.
      return null;
    }
    for (final pm in methods) {
      if (pm == PaymentMethod.employees) continue;
      final double amt;
      if (methods.length == 1) {
        final v = paymentAmounts[pm];
        amt = (v != null && v > 0) ? v : remainingDue;
      } else {
        amt = paymentAmounts[pm] ?? 0;
      }
      if (amt < 0.01) {
        return 'Each payment line must be at least 0.01 SAR.';
      }
      sum += amt;
      rows.add({
        'method': pm.cashierDraftApiMethodLabel,
        'amount': double.parse((amt).toStringAsFixed(2)),
      });
    }
    if (rows.isEmpty) return 'Choose at least one payment method.';
    // Underpay blocked here only when nothing remains due. Over/under match
    // against the invoice total is enforced on Generate Invoice.
    if (sum + 0.05 < remainingDue) {
      return 'Split totals must equal the order payable amount '
          '(${payable.toStringAsFixed(2)} SAR). Currently: '
          '${(prepaid + sum).toStringAsFixed(2)} SAR.';
    }
    rows.sort((a, b) =>
        (a['method'] as String).compareTo(b['method'] as String));

    try {
      final token = await sessionService.getToken();
      if (token == null) return 'Session expired. Sign in again.';
      final body = PatchOrderPaymentMethodPayload.saveDraft(
        isCorporate: isCorporate,
        payments: rows,
      ).toJson();

      final res = await posRepository.patchOrderPaymentMethod(
        orderId.trim(),
        body,
        token,
      );

      if (res['success'] != true) {
        final msg = res['message']?.toString().trim();
        return msg != null && msg.isNotEmpty
            ? msg
            : 'Could not save payment selection.';
      }

      await refreshOrderInHubAfterMutation(orderId.trim(), apiResponse: res);
      PosOrder? refreshed;
      for (final o in _orders) {
        if (o.id.trim() == orderId.trim()) {
          refreshed = o;
          break;
        }
      }
      if (refreshed != null) {
        _paymentDraftByOrderId.remove(orderId.trim());
        _activateInvoicePaymentContextForOrder(refreshed);
      }
      notifyListeners();
      return null;
    } catch (e) {
      return _extractErrorMessage(e.toString());
    }
  }

  Future<String?> clearCashierOrderPaymentDraft(String orderId) async {
    try {
      final token = await sessionService.getToken();
      if (token == null) return 'Session expired. Sign in again.';
      final res = await posRepository.patchOrderPaymentMethod(
        orderId.trim(),
        PatchOrderPaymentMethodPayload.clear().toJson(),
        token,
      );
      if (res['success'] != true) {
        final msg = res['message']?.toString().trim();
        return msg != null && msg.isNotEmpty
            ? msg
            : 'Could not clear saved payment.';
      }
      _clearInvoicePaymentPreferences();
      await refreshOrderInHubAfterMutation(orderId.trim(), apiResponse: res);
      _hydrateInvoicePaymentDefaultsForSelectedOrder();
      notifyListeners();
      return null;
    } catch (e) {
      return _extractErrorMessage(e.toString());
    }
  }

  /// Request Payment: SoftPOS (card) or cash confirm, then lock prepaid amount on order.
  Future<String?> requestPaymentForOrder({
    required BuildContext context,
    required PosOrder order,
    required double orderTotal,
    required List<Map<String, dynamic>> paymentSplits,
    required bool isCorporate,
    String? customerNameOverride,
    String? customerMobileOverride,
    String? plateNoOverride,
  }) async {
    final orderId = order.id.trim();
    if (orderId.isEmpty) return 'Order id missing';
    if (order.isPosPrepaid) return 'This order is already paid';

    _requestingPaymentOrderId = orderId;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) return 'Session expired. Sign in again.';

      final saveBody = PatchOrderPaymentMethodPayload.saveDraft(
        isCorporate: isCorporate,
        payments: paymentSplits
            .map(
              (p) => {
                'method': p['method']?.toString() ?? '',
                'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
              },
            )
            .toList(),
      ).toJson();
      final saveRes = await posRepository.patchOrderPaymentMethod(
        orderId,
        saveBody,
        token,
      );
      if (saveRes['success'] != true) {
        final msg = saveRes['message']?.toString().trim();
        return msg != null && msg.isNotEmpty
            ? msg
            : 'Could not save payment selection.';
      }

      String? intentUuid;
      try {
        final softResult = await runSoftPosRequestPayment(
          context: context,
          order: order,
          paymentSplits: paymentSplits,
          customerNameOverride: customerNameOverride,
          customerMobileOverride: customerMobileOverride,
          plateNoOverride: plateNoOverride,
        );
        if (!context.mounted) return 'Payment cancelled';
        if (!softResult.approved) {
          return 'Card payment was not approved on SoftPOS.';
        }
        intentUuid = softResult.intentUuid;
      } on SoftPosBridgeException catch (e) {
        return e.message;
      }

      final res = await posRepository.recordOrderPrepayment(
        orderId: orderId,
        token: token,
        isCorporate: isCorporate,
        payments: paymentSplits,
        paidAmount: orderTotal,
        intentUuid: intentUuid,
      );
      if (res['success'] != true) {
        final msg = res['message']?.toString().trim();
        return msg != null && msg.isNotEmpty
            ? msg
            : 'Could not record payment.';
      }

      final prepaidRows = paymentSplits
          .map(
            (p) => PosPaymentDraftRow(
              method: p['method']?.toString() ?? '',
              amount: (p['amount'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList();
      _applyPosPrepaidToHub(
        orderId: orderId,
        paidAmount: orderTotal,
        payments: prepaidRows,
        intentUuid: intentUuid,
      );
      _hydrateInvoicePaymentDefaultsForSelectedOrder();
      notifyListeners();

      await refreshOrderInHubAfterMutation(orderId, apiResponse: res);
      _hydrateInvoicePaymentDefaultsForSelectedOrder();
      notifyListeners();
      return null;
    } catch (e) {
      return _extractErrorMessage(e.toString());
    } finally {
      if (_requestingPaymentOrderId == orderId) {
        _requestingPaymentOrderId = null;
        notifyListeners();
      }
    }
  }

  /// Merge technicians from POST /cashier/job/:id/assign before [fetchOrders] returns.
  void applyJobTechniciansFromAssign({
    required String orderId,
    required String jobId,
    required List<JobTechnician> technicians,
  }) {
    if (orderId.trim().isEmpty || jobId.trim().isEmpty) return;
    final oi = _orders.indexWhere((o) => o.id == orderId.trim());
    if (oi < 0) return;
    final order = _orders[oi];
    final ji = order.jobs.indexWhere((j) => j.id == jobId.trim());
    if (ji < 0) return;
    final job = order.jobs[ji];
    final sortedTechs = List<JobTechnician>.from(technicians);
    sortJobTechniciansList(sortedTechs);
    final updatedJob = PosOrderJob(
      id: job.id,
      status: job.status,
      department: job.department,
      departmentId: job.departmentId,
      items: job.items,
      technicians: sortedTechs,
      amountBeforeDiscount: job.amountBeforeDiscount,
      amountAfterDiscount: job.amountAfterDiscount,
      amountAfterPromo: job.amountAfterPromo,
      totalAmount: job.totalAmount,
      vatAmount: job.vatAmount,
      vatPercent: job.vatPercent,
      promoCodeId: job.promoCodeId,
      promoCodeName: job.promoCodeName,
      promoDiscountType: job.promoDiscountType,
      promoDiscountValue: job.promoDiscountValue,
      promoDiscountAmount: job.promoDiscountAmount,
      totalDiscountType: job.totalDiscountType,
      totalDiscountValue: job.totalDiscountValue,
    );
    final newJobs = List<PosOrderJob>.from(order.jobs);
    newJobs[ji] = updatedJob;
    _orders[oi] = order.copyWith(jobs: newJobs);
    if (_selectedOrder?.id == orderId.trim()) {
      _selectedOrder = _orders[oi];
      _ensureActivePaymentMatchesSelectedOrder();
    }
    notifyListeners();
  }

  // Home Screen Search State
  final TextEditingController _homeSearchController = TextEditingController();
  final FocusNode _homeSearchFocusNode = FocusNode();

  /// Live invoice "Total discount" field — must stay in sync with [_globalDiscount] / [_mainTabGlobalDiscount]
  /// after async hydration ( [TextFormField.initialValue] does not update after first frame).
  final TextEditingController _globalDiscountTextController =
  TextEditingController();
  final TextEditingController _mainTabGlobalDiscountTextController =
  TextEditingController();

  TextEditingController get homeSearchController => _homeSearchController;
  FocusNode get homeSearchFocusNode => _homeSearchFocusNode;

  bool get homeCustomerSearchActive =>
      _homeSearchController.text.trim().isNotEmpty ||
      _homeSearchFocusNode.hasFocus;

  TextEditingController globalDiscountTextController(bool isMainTab) =>
      isMainTab
          ? _mainTabGlobalDiscountTextController
          : _globalDiscountTextController;

  /// Call after loading order/job discount in a post-frame callback so the text field matches the model.
  void refreshGlobalDiscountFieldText(bool isMainTab) {
    final c = globalDiscountTextController(isMainTab);
    final v =
    isMainTab ? _mainTabGlobalDiscount : _globalDiscount;
    final t = v > 0
        ? (v % 1 == 0 ? v.toInt().toString() : v.toString())
        : '';
    if (c.text == t) return;
    c.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  @override
  void dispose() {
    _realtimeService.off(RealtimeService.eventCashierOrdersUpdated, _onOrdersUpdated);
    _realtimeService.off(
        RealtimeService.eventCashierBroadcastUpdated, _onCashierBroadcastUpdated);
    _realtimeService.off(RealtimeService.eventCorporateWalkInOrderUpdated, _onOrdersUpdated);
    _realtimeService.off(RealtimeService.eventCashierCorporateWalkInApproved, _onOrdersUpdated);
    _realtimeService.off(RealtimeService.eventCashierCorporateWalkInRejected, _onOrdersUpdated);
    _realtimeService.disconnectSocket();
    _homeSearchController.dispose();
    _homeSearchFocusNode.removeListener(_onSearchFocusChanged);
    _homeSearchFocusNode.dispose();
    _globalDiscountTextController.dispose();
    _mainTabGlobalDiscountTextController.dispose();
    _searchDebounce?.cancel();
    _ordersRealtimeDebounce?.cancel();
    _broadcastCooldownTicker?.cancel();
    unbindLocaleRetranslation();
    super.dispose();
  }


  Future<void> _applyHeaderTranslations({String? langCodeOverride}) async {
    // Prefer the override (live widget-tree locale) so the drawer header is
    // always correct even on first boot, before SessionService has persisted
    // the locale preference.
    final langCode = langCodeOverride ?? await SessionService.getLocale();
    _cashierName = await AppTranslationService.localizedDynamicValueForLanguage(
      _rawCashierName ?? 'Cashier',
      langCode,
    );
    _workshopName = await AppTranslationService.localizedDynamicValueForLanguage(
      _rawWorkshopName ?? 'Loading...',
      langCode,
    );
    _branchName = await AppTranslationService.localizedDynamicValueForLanguage(
      _rawBranchName ?? '...',
      langCode,
    );
  }

  String get cashierName => _cashierName ?? 'Cashier';
  String get workshopName => _workshopName ?? 'Loading...';
  String get branchName => _branchName ?? '...';

  // Search Debounce (Moved from View)
  Timer? _searchDebounce;

  /// Coalesce rapid socket events (e.g. multiple job updates) into one list refresh.
  Timer? _ordersRealtimeDebounce;

  /// Coalesce parallel [fetchOrders] calls (shell visit + socket debounce firing together).
  Future<void>? _ordersFetchInFlight;

  /// Bumped on [fetchOrders] with `force: true` so stale in-flight responses are ignored.
  int _ordersFetchGeneration = 0;

  /// Per department (preferred) or per job: no second broadcast for 5 minutes.
  final Map<String, DateTime> _broadcastCooldownEndsAt = {};
  Timer? _broadcastCooldownTicker;
  String? _latestBroadcastCooldownKey;

  DateTime? _lastCashierOrdersFetchedAt;

  /// Cooldown scope: `dept:<id>` when [departmentId] is set, else `job:<jobId>`.
  String broadcastCooldownKey({
    String? departmentId,
    required String jobId,
  }) {
    final d = departmentId?.trim();
    if (d != null && d.isNotEmpty) return 'dept:$d';
    final j = jobId.trim();
    if (j.isEmpty) return '';
    return 'job:$j';
  }

  bool isBroadcastCooldownActiveForKey(String key) {
    if (key.isEmpty) return false;
    final end = _broadcastCooldownEndsAt[key];
    if (end == null) return false;
    if (DateTime.now().isBefore(end)) return true;
    _broadcastCooldownEndsAt.remove(key);
    return false;
  }

  bool isBroadcastCooldownActive({
    String? departmentId,
    required String jobId,
  }) {
    final ck = broadcastCooldownKey(departmentId: departmentId, jobId: jobId);
    return isBroadcastCooldownActiveForKey(ck);
  }

  Duration broadcastCooldownRemainingForKey(String key) {
    if (key.isEmpty) return Duration.zero;
    final end = _broadcastCooldownEndsAt[key];
    if (end == null) return Duration.zero;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String broadcastCooldownTimerLabelForKey(String key) {
    final left = broadcastCooldownRemainingForKey(key);
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _registerBroadcastCooldown(String key) {
    if (key.isEmpty) return;
    _broadcastCooldownEndsAt[key] =
        DateTime.now().add(const Duration(minutes: 5));
    _latestBroadcastCooldownKey = key;
    _ensureBroadcastCooldownTicker();
    notifyListeners();
  }

  void _ensureBroadcastCooldownTicker() {
    if (_broadcastCooldownTicker != null) return;
    _broadcastCooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final before = _broadcastCooldownEndsAt.length;
      _broadcastCooldownEndsAt
          .removeWhere((_, end) => !now.isBefore(end));
      final changed = _broadcastCooldownEndsAt.length != before;
      if (_latestBroadcastCooldownKey != null &&
          !_broadcastCooldownEndsAt
              .containsKey(_latestBroadcastCooldownKey)) {
        _latestBroadcastCooldownKey = null;
      }
      if (_broadcastCooldownEndsAt.isEmpty) {
        _broadcastCooldownTicker?.cancel();
        _broadcastCooldownTicker = null;
      }
      // Only rebuild if an entry expired (label changed) or ticker stopped
      if (changed) notifyListeners();
    });
  }

  void _clearBroadcastCooldownKeys({
    required String jobId,
    String? departmentId,
  }) {
    final j = jobId.trim();
    if (j.isNotEmpty) {
      _broadcastCooldownEndsAt.remove('job:$j');
    }
    final d = departmentId?.trim();
    if (d != null && d.isNotEmpty) {
      _broadcastCooldownEndsAt.remove('dept:$d');
    }
    if (_latestBroadcastCooldownKey != null &&
        !_broadcastCooldownEndsAt.containsKey(_latestBroadcastCooldownKey)) {
      _latestBroadcastCooldownKey =
      _broadcastCooldownEndsAt.keys.isNotEmpty
          ? _broadcastCooldownEndsAt.keys.first
          : null;
    }
    if (_broadcastCooldownEndsAt.isEmpty) {
      _broadcastCooldownTicker?.cancel();
      _broadcastCooldownTicker = null;
    }
    notifyListeners();
  }

  void handleSearchDebounce(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    final trimmed = query.trim();
    // Setting the field from a suggestion also fires onChanged — do not wipe
    // the cards we are about to load for that same query.
    if (trimmed.isNotEmpty &&
        _homeSearchApplied &&
        trimmed == _appliedHomeSearchQuery) {
      return;
    }
    // Drop stale cards as soon as the query changes — list must only show
    // results for the current Apply / suggestion, never leftover history.
    _homeSearchApplied = false;
    _appliedHomeSearchQuery = '';
    _searchedCustomers = [];
    _homeInvoiceRows = [];
    if (trimmed.length < 2) {
      _homeSuggestionGeneration++;
      _homeSearchSuggestions = [];
      _isSuggestingCustomer = false;
      notifyListeners();
      return;
    }
    notifyListeners();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(suggestHomeCustomers(trimmed));
    });
  }

  Future<void> suggestHomeCustomers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _homeSearchSuggestions = [];
      _isSuggestingCustomer = false;
      notifyListeners();
      return;
    }

    final generation = ++_homeSuggestionGeneration;
    _isSuggestingCustomer = true;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final classified = _classifyExactSearchQuery(trimmed);
      final plate = (classified.vehicleNumber ?? '').trim();
      final name = (classified.name ?? '').trim();
      final mobile = (classified.mobile ?? '').trim();
      // Plate (or mobile) is the tightest key. Do not also send name — the
      // API ORs fields, which would list every "أبو يوسف" with other plates.
      final apiParams = <String, String>{
        'match': plate.isNotEmpty && _isCompletePlateQuery(plate)
            ? 'exact'
            : 'partial',
        'limit': '8',
        if (plate.isNotEmpty)
          'vehicleNumber': plate
        else if (mobile.isNotEmpty)
          'mobile': mobile
        else if (name.isNotEmpty)
          'name': name
        else
          'q': trimmed,
      };

      final response = await posRepository.searchCustomers(apiParams, token);
      if (generation != _homeSuggestionGeneration) return;
      _homeSearchSuggestions = response.success
          ? _filterHomeSuggestionsToQuery(response.customers, trimmed)
          : [];
    } catch (_) {
      if (generation != _homeSuggestionGeneration) return;
      _homeSearchSuggestions = [];
    } finally {
      if (generation == _homeSuggestionGeneration) {
        _isSuggestingCustomer = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectHomeSearchSuggestion(SearchedCustomer customer) async {
    _searchDebounce?.cancel();
    _homeSuggestionGeneration++;
    _homeSearchFocusNode.unfocus();
    final plate = (customer.vehicleSnapshot?.resolvedPlate ?? '').trim();
    final display = plate.isNotEmpty
        ? '${customer.name} · $plate'
        : (customer.mobile.trim().isNotEmpty
            ? customer.mobile.trim()
            : customer.name);
    _appliedHomeSearchQuery = display.trim();
    _homeSearchApplied = true;
    _homeSearchController.value = TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
    _homeSearchSuggestions = [];
    _isSuggestingCustomer = false;
    _isSearchingCustomer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchedCustomers = [customer];
      _homeSearchApplied = true;
      _homeInvoiceRows = await _expandCustomersToInvoiceRows(
        [customer],
        plate: plate,
        customerId: customer.id,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _searchedCustomers = [];
      _homeInvoiceRows = [];
      _homeSearchApplied = true;
    } finally {
      _isSearchingCustomer = false;
      notifyListeners();
    }
  }

  void clearHomeSearch() {
    _searchDebounce?.cancel();
    _homeSuggestionGeneration++;
    _homeSearchController.clear();
    _homeSearchFocusNode.unfocus();
    _searchedCustomers = [];
    _homeInvoiceRows = [];
    _homeSearchSuggestions = [];
    _homeSearchApplied = false;
    _appliedHomeSearchQuery = '';
    _isSearchingCustomer = false;
    _isSuggestingCustomer = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Suggestion / Apply text like "أبو يوسف · EXA-98668".
  static ({String name, String plate})? _splitNamePlateCombo(String raw) {
    const seps = [' · ', ' • ', ' - ', ' – ', ' | ', '·', '•'];
    for (final sep in seps) {
      final idx = raw.lastIndexOf(sep);
      if (idx <= 0) continue;
      final left = raw.substring(0, idx).trim();
      final right = raw.substring(idx + sep.length).trim();
      if (left.isEmpty || right.isEmpty) continue;
      final hasLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(right);
      final hasDigit = RegExp(r'\d').hasMatch(right);
      if (hasLetter && hasDigit) {
        return (name: left, plate: right);
      }
    }
    return null;
  }

  static String _compactPlateKey(String raw) {
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9\u0600-\u06FF]'), '').toUpperCase();
  }

  static bool _platesEqual(String? a, String? b) {
    final ca = _compactPlateKey(a ?? '');
    final cb = _compactPlateKey(b ?? '');
    if (ca.isEmpty || cb.isEmpty) return false;
    return ca == cb;
  }

  static bool _plateContains(String? haystack, String needle) {
    final h = _compactPlateKey(haystack ?? '');
    final n = _compactPlateKey(needle);
    if (n.isEmpty) return true;
    if (h.isEmpty) return false;
    return h == n || h.contains(n);
  }

  SearchedCustomer _customerWithPreferredOrder(
    SearchedCustomer customer,
    SearchedCustomerOrder preferred,
  ) {
    final plate = preferred.vehicle?.resolvedPlate ?? '';
    final matching = customer.orders.where((o) {
      if (o.id == preferred.id) return true;
      if (plate.isEmpty) return false;
      return _platesEqual(o.vehicle?.resolvedPlate, plate);
    }).toList();
    return SearchedCustomer(
      id: customer.id,
      name: customer.name,
      mobile: customer.mobile,
      taxId: customer.taxId,
      whatsapp: customer.whatsapp,
      customerType: customer.customerType,
      orders: matching.isNotEmpty ? matching : [preferred],
    );
  }

  List<SearchedCustomer> _filterHomeSuggestionsToQuery(
    List<SearchedCustomer> customers,
    String rawQuery,
  ) {
    final classified = _classifyExactSearchQuery(rawQuery);
    final plate = (classified.vehicleNumber ?? '').trim();
    final name = (classified.name ?? '').trim().toLowerCase();
    final mobile = (classified.mobile ?? '').trim();
    final raw = rawQuery.trim().toLowerCase();
    final rawCompact = _compactPlateKey(rawQuery);

    final out = <SearchedCustomer>[];
    final seen = <String>{};

    void addSuggestion(SearchedCustomer customer) {
      final plateKey = _compactPlateKey(
        customer.vehicleSnapshot?.resolvedPlate ?? '',
      );
      final key = '${customer.id}|$plateKey';
      if (!seen.add(key)) return;
      out.add(customer);
    }

    for (final customer in customers) {
      if (name.isNotEmpty &&
          !customer.name.toLowerCase().contains(name)) {
        continue;
      }
      if (mobile.isNotEmpty) {
        final digits = customer.mobile.replaceAll(RegExp(r'\D'), '');
        final qDigits = mobile.replaceAll(RegExp(r'\D'), '');
        if (qDigits.isNotEmpty &&
            !digits.contains(qDigits) &&
            !_mobilesEqual(customer.mobile, mobile)) {
          continue;
        }
      }

      if (plate.isNotEmpty) {
        final matchingOrders = customer.orders.where((o) {
          return _plateContains(o.vehicle?.resolvedPlate, plate);
        }).toList();
        if (matchingOrders.isEmpty) {
          if (!_plateContains(customer.vehicleSnapshot?.resolvedPlate, plate)) {
            continue;
          }
          addSuggestion(customer);
          continue;
        }
        final plateSeen = <String>{};
        matchingOrders.sort((a, b) {
          final ad = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
          final bd = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
          return bd.compareTo(ad);
        });
        for (final order in matchingOrders) {
          final key = _compactPlateKey(order.vehicle?.resolvedPlate ?? '');
          if (key.isEmpty || !plateSeen.add(key)) continue;
          addSuggestion(_customerWithPreferredOrder(customer, order));
        }
        continue;
      }

      if (name.isEmpty && mobile.isEmpty) {
        final nameHit = customer.name.toLowerCase().contains(raw);
        final mobileHit = customer.mobile
            .replaceAll(RegExp(r'\D'), '')
            .contains(raw.replaceAll(RegExp(r'\D'), ''));
        final plateHit = customer.orders.any(
          (o) =>
              rawCompact.isNotEmpty &&
              _plateContains(o.vehicle?.resolvedPlate, rawQuery),
        );
        if (!nameHit && !mobileHit && !plateHit) continue;
      }
      addSuggestion(customer);
    }

    return out.take(6).toList();
  }

  static bool _mobilesEqual(String? a, String? b) {
    String norm(String raw) {
      var d = raw.replaceAll(RegExp(r'\D'), '');
      if (d.startsWith('966') && d.length > 3) d = d.substring(3);
      if (d.startsWith('0') && d.length >= 9) d = d.substring(1);
      return d;
    }

    final na = norm(a ?? '');
    final nb = norm(b ?? '');
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb;
  }

  /// Classify single-field input: mobile, plate, name, or "name · plate".
  /// Digits-only → mobile; letters+digits → plate; letters (name) otherwise.
  static ({String? mobile, String? vehicleNumber, String? name})
      _classifyExactSearchQuery(String raw) {
    final q = EnglishNumberFormatter.convert(raw).trim();
    if (q.isEmpty) {
      return (mobile: null, vehicleNumber: null, name: null);
    }

    final combo = _splitNamePlateCombo(q);
    if (combo != null) {
      return (mobile: null, vehicleNumber: combo.plate, name: combo.name);
    }

    final hasLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(q);
    final hasDigit = RegExp(r'\d').hasMatch(q);
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (!hasLetter && digits.isNotEmpty) {
      return (mobile: digits, vehicleNumber: null, name: null);
    }
    // Plate requires both letters and digits; pure letter queries are names.
    if (hasLetter && hasDigit) {
      return (mobile: null, vehicleNumber: q, name: null);
    }
    return (mobile: null, vehicleNumber: null, name: q);
  }

  /// Full Saudi mobile: `5XXXXXXXX` / `05XXXXXXXX` / `9665XXXXXXXX`.
  static bool _isCompleteMobileQuery(String digits) {
    var d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('966') && d.length > 3) d = d.substring(3);
    if (d.startsWith('05') && d.length >= 10) d = d.substring(1);
    if (d.startsWith('0') && d.length == 10) d = d.substring(1);
    return RegExp(r'^5\d{8}$').hasMatch(d);
  }

  /// Full plate: letters + digits, at least 4 compact alphanumerics.
  static bool _isCompletePlateQuery(String raw) {
    final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9\u0600-\u06FF]'), '');
    if (compact.length < 4) return false;
    final hasLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(compact);
    final hasDigit = RegExp(r'\d').hasMatch(compact);
    return hasLetter && hasDigit;
  }

  /// Returns normalized params for Apply: complete mobile/plate, or name (≥2 chars).
  static ({
    String? mobile,
    String? vehicleNumber,
    String? name,
    String? incompleteHint,
  }) _completeExactSearchParams(String raw) {
    final classified = _classifyExactSearchQuery(raw);
    final plate = classified.vehicleNumber?.trim() ?? '';
    final phone = classified.mobile?.trim() ?? '';
    final name = classified.name?.trim() ?? '';
    if (plate.isEmpty && phone.isEmpty && name.isEmpty) {
      return (
        mobile: null,
        vehicleNumber: null,
        name: null,
        incompleteHint: null,
      );
    }
    if (phone.isNotEmpty) {
      if (!_isCompleteMobileQuery(phone)) {
        return (
          mobile: null,
          vehicleNumber: null,
          name: null,
          incompleteHint: 'incomplete_mobile',
        );
      }
      var d = phone.replaceAll(RegExp(r'\D'), '');
      if (d.startsWith('966') && d.length > 3) d = d.substring(3);
      if (d.startsWith('0')) d = d.substring(1);
      return (
        mobile: d,
        vehicleNumber: null,
        name: null,
        incompleteHint: null,
      );
    }
    if (plate.isNotEmpty) {
      if (!_isCompletePlateQuery(plate)) {
        return (
          mobile: null,
          vehicleNumber: null,
          name: null,
          incompleteHint: 'incomplete_plate',
        );
      }
      return (
        mobile: null,
        vehicleNumber: plate,
        name: name.isNotEmpty ? name : null,
        incompleteHint: null,
      );
    }
    if (name.isNotEmpty) {
      if (name.length < 2) {
        return (
          mobile: null,
          vehicleNumber: null,
          name: null,
          incompleteHint: 'incomplete_name',
        );
      }
      return (
        mobile: null,
        vehicleNumber: null,
        name: name,
        incompleteHint: null,
      );
    }
    return (
      mobile: null,
      vehicleNumber: null,
      name: null,
      incompleteHint: null,
    );
  }

  bool _homeInvoiceMatchesSearch(
    SearchedCustomer customer,
    InvoicedOrder order, {
    String? plate,
    String? mobile,
    String? name,
    String? customerId,
  }) {
    if ((customerId ?? '').trim().isNotEmpty &&
        customer.id.trim() != customerId!.trim()) {
      return false;
    }
    if ((mobile ?? '').trim().isNotEmpty &&
        !_mobilesEqual(customer.mobile, mobile)) {
      return false;
    }
    if ((plate ?? '').trim().isNotEmpty) {
      final orderPlate = (order.plateNumber ?? '').trim();
      if (!_platesEqual(orderPlate, plate)) return false;
    }
    if ((name ?? '').trim().isNotEmpty && (plate ?? '').trim().isEmpty) {
      final q = name!.trim().toLowerCase();
      final customerName = customer.name.trim().toLowerCase();
      final orderName = order.customerName.trim().toLowerCase();
      if (!customerName.contains(q) && !orderName.contains(q)) {
        return false;
      }
    }
    return true;
  }

  Future<List<HomeCustomerInvoiceRow>> _expandCustomersToInvoiceRows(
    List<SearchedCustomer> customers, {
    String? plate,
    String? mobile,
    String? name,
    String? customerId,
  }) async {
    final rows = <HomeCustomerInvoiceRow>[];
    for (final customer in customers) {
      if ((customerId ?? '').trim().isNotEmpty &&
          customer.id.trim() != customerId!.trim()) {
        continue;
      }
      if ((mobile ?? '').trim().isNotEmpty &&
          !_mobilesEqual(customer.mobile, mobile)) {
        continue;
      }
      if ((name ?? '').trim().isNotEmpty &&
          (plate ?? '').trim().isEmpty &&
          !customer.name.toLowerCase().contains(name!.trim().toLowerCase())) {
        continue;
      }
      final history = await fetchCustomerInvoicedHistory(customer.id);
      final orders = history?.orders ?? const <InvoicedOrder>[];
      if (orders.isEmpty) continue;
      for (final order in orders) {
        if (!_homeInvoiceMatchesSearch(
          customer,
          order,
          plate: plate,
          mobile: mobile,
          name: name,
          customerId: customerId,
        )) {
          continue;
        }
        rows.add(HomeCustomerInvoiceRow(customer: customer, order: order));
      }
    }
    rows.sort((a, b) {
      final ad = DateTime.tryParse(a.order.createdAt) ?? DateTime(1970);
      final bd = DateTime.tryParse(b.order.createdAt) ?? DateTime(1970);
      return bd.compareTo(ad);
    });
    return rows;
  }

  /// Customer history search after Apply: exact mobile/plate, or name contains.
  /// Requires complete mobile (9-digit SA), complete plate, or name (≥2 chars).
  /// Returns `false` when the query is incomplete (caller may toast).
  Future<bool> searchCustomerHistoryExact({String? query}) async {
    final params = _completeExactSearchParams(
      query ?? _homeSearchController.text,
    );
    final plate = params.vehicleNumber ?? '';
    final phone = params.mobile ?? '';
    final name = params.name ?? '';
    if (params.incompleteHint != null ||
        (plate.isEmpty && phone.isEmpty && name.isEmpty)) {
      _searchedCustomers = [];
      _homeInvoiceRows = [];
      _homeSearchSuggestions = [];
      _homeSearchApplied = params.incompleteHint == null;
      _appliedHomeSearchQuery =
          _homeSearchApplied ? (query ?? _homeSearchController.text).trim() : '';
      _errorMessage = params.incompleteHint;
      notifyListeners();
      return params.incompleteHint == null;
    }

    _searchDebounce?.cancel();
    _homeSuggestionGeneration++;
    _homeSearchSuggestions = [];
    _isSuggestingCustomer = false;
    _isSearchingCustomer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Plate/mobile stay exact. Name-only uses contains. Combined name+plate
      // searches the plate so "Name · EXA-98668" does not become a fuzzy name.
      final apiParams = <String, String>{
        'match': plate.isNotEmpty || phone.isNotEmpty ? 'exact' : 'partial',
        if (plate.isNotEmpty) 'vehicleNumber': plate,
        if (phone.isNotEmpty) 'mobile': phone,
        if (name.isNotEmpty && plate.isEmpty && phone.isEmpty) 'name': name,
      };
      final response = await posRepository.searchCustomers(
        apiParams,
        token,
      );

      if (response.success) {
        _searchedCustomers = response.customers;
        _homeInvoiceRows = await _expandCustomersToInvoiceRows(
          response.customers,
          plate: plate.isNotEmpty ? plate : null,
          mobile: phone.isNotEmpty ? phone : null,
          name: name.isNotEmpty && plate.isEmpty ? name : null,
        );
      } else {
        _errorMessage = response.message;
        _searchedCustomers = [];
        _homeInvoiceRows = [];
      }
      _homeSearchApplied = true;
      _appliedHomeSearchQuery =
          (query ?? _homeSearchController.text).trim();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _searchedCustomers = [];
      _homeInvoiceRows = [];
      _homeSearchApplied = true;
      _appliedHomeSearchQuery =
          (query ?? _homeSearchController.text).trim();
      return true;
    } finally {
      _isSearchingCustomer = false;
      notifyListeners();
    }
  }

  // Date Formatting (Moved from View logic)
  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _extractErrorMessage(String error) {
    String clean = error;
    // Remove generic exception prefixes
    if (clean.startsWith('Exception: ')) clean = clean.substring(11);
    if (clean.startsWith('Error: ')) clean = clean.substring(7);
    if (clean.startsWith('Invalid Request: ')) clean = clean.substring(17);

    // Try to find JSON object
    final startIndex = clean.indexOf('{');
    final endIndex = clean.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      try {
        final jsonStr = clean.substring(startIndex, endIndex + 1);
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        if (json.containsKey('message') && json['message'] != null) {
          return json['message'].toString();
        }
      } catch (_) {
        // JSON parsing failed, just return the cleaned string
      }
    }
    return clean;
  }

  /// Billing + vehicle snapshot before invoice (walk-in billing PATCH). Scoped to [forOrderId].
  void updateWalkInBillingContact({
    required String forOrderId,
    required String name,
    required String mobile,
    String vat = '',
    String vehicleNumber = '',
    String vin = '',
    String make = '',
    String model = '',
    int odometer = 0,
    String year = '',
    String color = '',
    bool billingCustomerIsEmployee = false,
    String? billingEmployeeId,
    String? billingEmployeeType,
    String vehiclePlateCountry = 'SA',
    String? vehiclePlateEmirate,
  }) {
    final oid = forOrderId.trim();
    if (oid.isEmpty) return;
    final bid = billingEmployeeId?.trim();
    final et = billingEmployeeType?.trim();
    final em = vehiclePlateEmirate?.trim();
    final snap = WalkInBillingSnapshot(
      name: name.trim(),
      mobile: mobile.trim(),
      vat: vat.trim(),
      vehicleNumber: vehicleNumber.trim(),
      vin: vin.trim(),
      make: make.trim(),
      model: model.trim(),
      odometer: odometer,
      year: year.trim(),
      color: color.trim(),
      billingCustomerIsEmployee: billingCustomerIsEmployee,
      billingEmployeeId: bid != null && bid.isNotEmpty ? bid : null,
      billingEmployeeType: et != null && et.isNotEmpty ? et : null,
      vehiclePlateCountry: vehiclePlateCountry.trim().toUpperCase().isEmpty
          ? 'SA'
          : vehiclePlateCountry.trim().toUpperCase(),
      vehiclePlateEmirate: em != null && em.isNotEmpty ? em : null,
    );
    _walkInBillingSnapshotsByOrderId[oid] = snap;
    if (_selectedOrder?.id == oid) {
      _applyWalkInSnapshotToVm(snap);
    }
    notifyListeners();
  }

  /// PATCH `/cashier/order/:orderId/billing` after **Add customer details** / Invoice details (Orders).
  /// Skipped for corporate **booking** orders (billing owned by booking / corporate portal).
  /// Call after [updateWalkInBillingContact] so [_buildWalkInBillingPatchBody] sees the new snapshot.
  /// Returns `null` on success, otherwise a user-facing error string.
  Future<String?> submitWalkInOrderBillingPatch(PosOrder order) async {
    if (order.isCorporateBookingOrder) return null;
    if (!_isStandardWalkInOrderForBilling(order)) return null;
    if ((order.invoiceNo ?? '').trim().isNotEmpty) {
      return 'Billing cannot be edited after an invoice exists.';
    }
    try {
      final token = await sessionService.getToken();
      if (token == null) {
        return 'Session expired. Sign in again.';
      }
      final billingBody = _buildWalkInBillingPatchBody(order);
      final cn = (billingBody['customerName'] as String? ?? '').trim();
      final mb = (billingBody['mobile'] as String? ?? '').trim();
      if (cn.isEmpty || mb.isEmpty) {
        return 'Customer name and mobile are required.';
      }
      final patchRes = await posRepository.patchWalkInOrderBilling(
        order.id.trim(),
        billingBody,
        token,
      );
      if (patchRes['success'] != true) {
        return patchRes['message']?.toString() ??
            'Failed to update billing details';
      }
      final snapPost = _walkInBillingSnapshotsByOrderId[order.id.trim()];
      if (snapPost != null && snapPost.billingCustomerIsEmployee) {
        final clr = await posRepository.patchOrderPaymentMethod(
          order.id.trim(),
          PatchOrderPaymentMethodPayload.clear().toJson(),
          token,
        );
        if (clr['success'] != true) {
          return clr['message']?.toString() ??
              'Could not clear saved payment for employee customer.';
        }
        _clearInvoicePaymentPreferences();
      }
      await fetchOrders(silent: true, preferredOrderId: order.id);
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      return _extractErrorMessage(e.toString());
    }
  }

  void setCustomerData({
    required String name,
    required String vat,
    required String mobile,
    required String vehicleNumber,
    String vehiclePlateCountry = 'SA',
    String? vehiclePlateEmirate,
    String vinNumber = '',
    required String make,
    required String model,
    required int odometer,
    String? previousOrderId,
    String vehicleYear = '',
    String vehicleColor = '',
    bool billingCustomerIsEmployee = false,
    String? billingEmployeeId,
    String? billingEmployeeType,
  }) {
    _customerName = name;
    _vatNumber = vat;
    _mobile = mobile;
    _vehicleNumber = vehicleNumber;
    _vehiclePlateCountry =
        vehiclePlateCountry.trim().isNotEmpty ? vehiclePlateCountry.trim() : 'SA';
    _vehiclePlateEmirate = vehiclePlateEmirate?.trim().isNotEmpty == true
        ? vehiclePlateEmirate!.trim()
        : null;
    _vinNumber = vinNumber;
    _make = make;
    _model = model;
    _odometerReading = odometer;
    _previousOrderId = previousOrderId;
    _vehicleYear = vehicleYear;
    _vehicleColor = vehicleColor;
    _billingCustomerIsEmployee = billingCustomerIsEmployee;
    final bid = billingEmployeeId?.trim();
    _billingEmployeeId = (bid != null && bid.isNotEmpty) ? bid : null;
    final bet = billingEmployeeType?.trim();
    _billingEmployeeType = (bet != null && bet.isNotEmpty) ? bet : null;
    notifyListeners();
  }

  /// Clears corporate account, quote cache, and booking line overlays (retail walk-in).
  void clearCorporatePricingContext({bool notify = true}) {
    _corporateAccountId = null;
    _corporateFleetVehicleId = null;
    _loadedCorporateCatalogAccountId = null;
    _extrinsicCorporateQuotedLines = const [];
    _activeCorporateBookingId = null;
    _corporateApiQuotedLinesByAccountId.clear();
    _corporateQuotedProductsByAccountId.clear();
    if (notify) notifyListeners();
  }

  void primeCorporateWalkInDraftFromOrder(PosOrder order) {
    _corporateAccountId = (order.corporateAccountId ?? '').trim().isNotEmpty
        ? order.corporateAccountId!.trim()
        : null;
    setCustomerData(
      name: order.customerName,
      vat: order.customer?.vatNumber ?? '',
      mobile: order.customer?.mobile ?? '',
      vehicleNumber: order.plateNumber,
      vinNumber: order.vehicle?.vin ?? '',
      make: order.vehicle?.make ?? '',
      model: order.vehicle?.model ?? '',
      odometer: order.odometerReading,
      previousOrderId: order.id,
      vehicleYear: order.vehicle?.year ?? '',
      vehicleColor: order.vehicle?.color ?? '',
    );
  }

  void clearCustomerData() {
    _walkInBillingSnapshotsByOrderId.clear();
    _paymentDraftByOrderId.clear();
    _activeInvoicePaymentOrderId = null;
    _clearInvoicePaymentPreferences();
    _clearWalkInBillingOverlayFields();
    _previousOrderId = null;
    _lastPlacedWalkInOrder = null;
    clearCorporatePricingContext(notify: false);
    _vehiclePlateCountry = 'SA';
    _vehiclePlateEmirate = null;
    clearEditOrderContext(notify: false);
    _cartItems.clear();
    _activePromoCode = '';
    _promoDiscount = 0.0;
    _globalDiscount = 0.0;
    _globalDiscountTextController.clear();
    notifyListeners();
  }

  void setEditOrderContext({
    required String departmentId,
    required List<dynamic> preSelectedItems,
    required PosOrder order,
    required String completingOrderId,
  }) {
    _editDepartmentId = departmentId;
    _editPreSelectedItems = preSelectedItems;
    _editingOrder = order;
    _editingCompletingOrderId = completingOrderId;
    final corpId = (order.corporateAccountId ?? '').trim();
    if (order.isCorporateBookingOrder || order.isCorporateWalkIn) {
      if (corpId.isNotEmpty) {
        _corporateAccountId = corpId;
      }
    } else {
      clearCorporatePricingContext(notify: false);
    }
    notifyListeners();
    final needsLines = !order.linesIncluded ||
        order.jobs.every((j) => j.items.isEmpty);
    if (needsLines) {
      unawaited(() async {
        final hydrated = await ensureOrderLinesHydrated(order.id, force: true);
        if (hydrated == null) return;
        if (_editingCompletingOrderId != completingOrderId) return;
        _editingOrder = hydrated;
        if (preSelectedItems.isEmpty) {
          final dept = departmentId.trim();
          PosOrderJob? job;
          for (final j in hydrated.jobs) {
            if ((j.departmentId ?? '').trim() == dept) {
              job = j;
              break;
            }
          }
          // keep existing rest of block...

          if (job != null && job.items.isNotEmpty) {
            _editPreSelectedItems = job.items
                .map((i) => <String, dynamic>{
                      'id': i.id,
                      'itemType': i.itemType,
                      'productId': i.productId,
                      'productName': i.productName,
                      'qty': i.qty,
                      'unitPrice': i.unitPrice,
                      'lineTotal': i.lineTotal,
                    })
                .toList();
          }
        }
        notifyListeners();
      }());
    }
  }

  void clearEditOrderContext({bool notify = true}) {
    _editDepartmentId = null;
    _editPreSelectedItems = null;
    _editingOrder = null;
    _editingCompletingOrderId = null;
    if (notify) {
      notifyListeners();
    }
  }

  void saveCustomerAndProceed({
    required bool isNormal,
    required String name,
    required String vat,
    required String mobile,
    required String vehicleNumber,
    String vehiclePlateCountry = 'SA',
    String? vehiclePlateEmirate,
    required String vinNumber,
    required String make,
    required String model,
    required String odometerStr,
    required CashierCorporateAccount? selectedCorporateData,
    required VoidCallback onSuccess,
    required Function(String) onError,
    bool billingCustomerIsEmployee = false,
    String? billingEmployeeId,
    String? billingEmployeeType,
    String vehicleYear = '',
    String? corporateFleetVehicleId,
  }) {
    if (isNormal) {
      clearCorporatePricingContext(notify: false);
      setCustomerData(
        name: name,
        vat: vat,
        mobile: mobile,
        vehicleNumber: vehicleNumber,
        vehiclePlateCountry: vehiclePlateCountry,
        vehiclePlateEmirate: vehiclePlateEmirate,
        vinNumber: vinNumber,
        make: make,
        model: model,
        odometer: int.tryParse(odometerStr) ?? 0,
        vehicleYear: vehicleYear,
        billingCustomerIsEmployee: billingCustomerIsEmployee,
        billingEmployeeId: billingEmployeeId,
        billingEmployeeType: billingEmployeeType,
      );
    } else {
      if (selectedCorporateData == null) {
        onError('Please select a corporate account');
        return;
      }
      _corporateAccountId = selectedCorporateData.id;
      final fleetId = corporateFleetVehicleId?.trim();
      _corporateFleetVehicleId =
          fleetId != null && fleetId.isNotEmpty ? fleetId : null;
      setCustomerData(
        name: name.trim().isNotEmpty ? name.trim() : selectedCorporateData.companyName,
        vat: vat.isNotEmpty ? vat : (selectedCorporateData.effectiveVatNumber ?? ''),
        mobile: mobile.isNotEmpty ? mobile : (selectedCorporateData.customer?.mobile ?? ''),
        vehicleNumber: vehicleNumber,
        vehiclePlateCountry: vehiclePlateCountry,
        vehiclePlateEmirate: vehiclePlateEmirate,
        vinNumber: vinNumber,
        make: make,
        model: model,
        odometer: int.tryParse(odometerStr) ?? 0,
        vehicleYear: vehicleYear,
        billingCustomerIsEmployee: billingCustomerIsEmployee,
        billingEmployeeId: billingEmployeeId,
        billingEmployeeType: billingEmployeeType,
      );
      // Preload corporate quotation catalog so the product grid shows quoted prices.
      unawaited(loadCorporateProductsCatalog(selectedCorporateData.id));
    }
    onSuccess();
  }

  static const double _kCashierVatPercent = 15.0;

  /// Active walk-in draft order id after a successful create/append (for debugging / UI).
  String? get walkInDraftOrderId => _previousOrderId;

  Map<String, String> _departmentJobMapFromWalkInOrder(WalkInOrder? order) {
    final map = <String, String>{};
    if (order == null) return map;
    for (final d in order.departments) {
      final did = d.departmentId?.trim() ?? '';
      final jid = d.jobId?.trim() ?? '';
      if (did.isNotEmpty && jid.isNotEmpty) {
        map[did] = jid;
      }
    }
    return map;
  }

  Map<String, List<CartItem>> _groupCartItemsByDepartment(List<String> fallbackDepartmentIds) {
    final fallback =
    fallbackDepartmentIds.isNotEmpty ? fallbackDepartmentIds.first.trim() : '';
    final map = <String, List<CartItem>>{};
    for (final item in _cartItems) {
      final d = item.product.departmentId?.trim() ?? '';
      final key = d.isNotEmpty ? d : fallback;
      if (key.isEmpty) continue;
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Body for POST /cashier/job/:jobId/pricing (replace-all lines for that job).
  Map<String, dynamic> _buildCashierJobPricingPayload({
    required List<CartItem> items,
    required String defaultDepartmentId,
    required bool applyJobDiscountAndPromo,
    bool isMainTab = false,
    PosOrderJob? sourceJob,
    PosOrder? sourceOrder,
    /// Order used only for order-promo inheritance when [sourceOrder] is not
    /// available (e.g. product-grid completes resolve the hub order separately).
    PosOrder? promoInheritOrder,
    /// When true (e.g. **Mark complete** from Orders with an empty cart), copy lines from
    /// [sourceJob] into the pricing body. Otherwise an empty cart + non-null [sourceOrder]
    /// means the user cleared lines in the product grid and we must not resurrect them.
    bool hydrateFromJobWhenLinesEmpty = false,
  }) {
    final products = <Map<String, dynamic>>[];
    final services = <Map<String, dynamic>>[];

    for (final item in items) {
      final lineDept = item.product.departmentId?.trim().isNotEmpty == true
          ? item.product.departmentId!.trim()
          : defaultDepartmentId;
      if (item.product.isService) {
        final m = <String, dynamic>{
          'serviceId': item.product.id,
          'departmentId': lineDept,
          'qty': item.quantity,
        };
        if (item.discount > 0) {
          m['discountType'] = item.isDiscountPercent ? 'percent' : 'amount';
          m['discountValue'] = item.discount;
        }
        if (item.product.isPriceEditable) {
          m['unitPrice'] = item.effectiveUnitPrice;
        } else {
          final unitPrice = _cartLineUnitPriceForApi(item);
          if (unitPrice != null && unitPrice > 0) {
            m['unitPrice'] = unitPrice;
          }
        }
        services.add(m);
      } else {
        final m = <String, dynamic>{
          'productId': item.product.id,
          'departmentId': lineDept,
          'qty': item.quantity,
        };
        if (item.discount > 0) {
          m['discountType'] = item.isDiscountPercent ? 'percent' : 'amount';
          m['discountValue'] = item.discount;
        }
        if (item.product.isPriceEditable) {
          m['unitPrice'] = item.effectiveUnitPrice;
        } else {
          final unitPrice = _cartLineUnitPriceForApi(item);
          if (unitPrice != null && unitPrice > 0) {
            m['unitPrice'] = unitPrice;
          }
        }
        products.add(m);
      }
    }

    // Fall back to existing job lines when there is no cart data:
    // - new walk-in submit (sourceOrder == null), or
    // - complete-from-Orders (hydrateFromJobWhenLinesEmpty) so PATCH/ready checks see billable lines.
    // For product-grid edits, an empty cart + sourceOrder and hydrate false means intentional clear.
    if (products.isEmpty &&
        services.isEmpty &&
        sourceJob != null &&
        (sourceOrder == null || hydrateFromJobWhenLinesEmpty)) {
      for (final item in sourceJob.items) {
        final lineDept = item.departmentId.trim().isNotEmpty
            ? item.departmentId.trim()
            : defaultDepartmentId;
        if (item.itemType == 'service') {
          final m = <String, dynamic>{
            'serviceId': item.productId,
            'departmentId': lineDept,
            'qty': item.qty,
            'discountType': (item.discountType ?? '').isNotEmpty ? item.discountType : 'amount',
            'discountValue': item.discountValue ?? 0,
          };
          if (item.unitPrice > 0) {
            m['unitPrice'] = item.unitPrice;
          }
          services.add(m);
        } else {
          final m = <String, dynamic>{
            'productId': item.productId,
            'departmentId': lineDept,
            'qty': item.qty,
          };
          if ((item.discountType ?? '').isNotEmpty) {
            m['discountType'] = item.discountType;
          }
          if ((item.discountValue ?? 0) > 0) {
            m['discountValue'] = item.discountValue;
          }
          if (item.unitPrice > 0) {
            m['unitPrice'] = item.unitPrice;
          }
          products.add(m);
        }
      }
    }

    final hasLiveCartData = products.isNotEmpty || services.isNotEmpty;

    final activeGlobal = getActiveGlobalDiscount(isMainTab);
    final activeGlobalIsPct = getActiveIsGlobalDiscountPercent(isMainTab);
    final fallbackGlobalValue =
        sourceJob?.totalDiscountValue ?? sourceOrder?.totalDiscountValue ?? 0.0;
    final rawGlobalType =
        sourceJob?.totalDiscountType ?? sourceOrder?.totalDiscountType ?? 'amount';
    final fallbackGlobalType =
    rawGlobalType.toLowerCase().contains('percent') ? 'percent' : 'amount';

    double effectiveGlobalValue = 0.0;
    String effectiveGlobalType = 'amount';
    if (applyJobDiscountAndPromo) {
      if (hasLiveCartData) {
        // Cart / invoice panel is authoritative — do not resurrect cleared job-level discount.
        effectiveGlobalValue = activeGlobal;
        effectiveGlobalType = activeGlobalIsPct ? 'percent' : 'amount';
      } else {
        effectiveGlobalValue = activeGlobal > 0 ? activeGlobal : fallbackGlobalValue;
        effectiveGlobalType = activeGlobal > 0
            ? (activeGlobalIsPct ? 'percent' : 'amount')
            : fallbackGlobalType;
      }
    }

    String? promoCodeStr;
    String? promoId;
    var explicitClearPromo = false;
    if (applyJobDiscountAndPromo) {
      final promo = _resolvePromoState(isMainTab, departmentId: _editDepartmentId);
      final code = promo.code.trim();
      if (code.isNotEmpty) {
        promoCodeStr = code;
        final pid = promo.promoCodeId?.trim();
        if (pid != null && pid.isNotEmpty) promoId = pid;
      } else if (!isMainTab) {
        // Department carts no longer manage promos — order promos live on the
        // Order Summary and are stored per job. Inherit the promo already on
        // this job (or on the order's other jobs) so grid edits, completes and
        // newly added departments keep/receive it instead of clearing it.
        final inherited = _inheritedOrderPromoRef(
          sourceJob,
          sourceOrder ?? promoInheritOrder,
        );
        if (inherited != null) {
          if (inherited.code.isNotEmpty) promoCodeStr = inherited.code;
          if (inherited.id.isNotEmpty) promoId = inherited.id;
        } else if (hasLiveCartData) {
          explicitClearPromo = true;
        }
      } else if (hasLiveCartData) {
        // Main-tab cart still manages its own promo banner — cart is
        // authoritative, do not resurrect a promo the user removed there.
        explicitClearPromo = true;
      } else {
        final sid = sourceJob?.promoCodeId ?? sourceOrder?.promoCodeId;
        if (sid != null && sid.trim().isNotEmpty) {
          promoId = sid.trim();
        }
      }
    }

    return <String, dynamic>{
      'products': products,
      'services': services,
      'totalDiscountType': effectiveGlobalType,
      'totalDiscountValue': effectiveGlobalValue,
      'VAT': _kCashierVatPercent,
      if (promoCodeStr != null && promoCodeStr.isNotEmpty) 'promoCode': promoCodeStr,
      if (promoId != null && promoId.isNotEmpty) 'promoCodeId': promoId,
      if (explicitClearPromo) 'promoCode': null,
      if (explicitClearPromo) 'promoCodeId': null,
    };
  }

  /// Promo already applied to the order — from [sourceJob] itself, any other
  /// active job, or the order header. Used so job pricing writes keep the
  /// order-level promo instead of silently dropping it.
  ({String code, String id})? _inheritedOrderPromoRef(
    PosOrderJob? sourceJob,
    PosOrder? sourceOrder,
  ) {
    ({String code, String id})? refFrom(String? code, String? id) {
      final c = (code ?? '').trim();
      final i = (id ?? '').trim();
      if (c.isEmpty && i.isEmpty) return null;
      return (code: c, id: i);
    }

    final own = refFrom(sourceJob?.promoCodeName, sourceJob?.promoCodeId);
    if (own != null) return own;
    if (sourceOrder == null) return null;
    for (final j in sourceOrder.jobs) {
      if (j.isCancelledJob) continue;
      if (sourceJob != null && j.id == sourceJob.id) continue;
      final other = refFrom(j.promoCodeName, j.promoCodeId);
      if (other != null) return other;
    }
    return refFrom(sourceOrder.promoCodeName, sourceOrder.promoCodeId);
  }

  static String normalizeCashierJobStatus(String? raw) {
    var s = (raw ?? '').toLowerCase().trim();
    if (s == 'complete') return 'completed';
    if (s == 'job_edited') return 'edited';
    return s;
  }

  PosProduct? _productById(String id) {
    final want = id.trim();
    if (want.isEmpty) return null;
    for (final p in _allProducts) {
      if (p.id == want) return p;
    }
    return null;
  }

  static int _moneyKey(double v) => (v * 100).round();

  List<CartItem> _cartItemsSnapshotFromJob(List<PosOrderJobItem> jobItems) {
    final out = <CartItem>[];
    for (final ji in jobItems) {
      final p = _productById(ji.productId);
      if (p == null) continue;
      final rawDt = (ji.discountType ?? '').trim();
      final pct = rawDt.toLowerCase().contains('percent');
      final dv = ji.discountValue ?? 0.0;
      final ci = CartItem(
        product: p,
        quantity: ji.qty,
        discount: dv,
        isDiscountPercent: pct,
      );
      if (ji.unitPrice > 0) {
        if (p.isPriceEditable) {
          ci.serviceUnitPrice = ji.unitPrice;
        } else {
          ci.lineUnitPriceOverride = ji.unitPrice;
        }
      }
      out.add(ci);
    }
    return out;
  }

  String _pricingLineSigFromCartItem(CartItem item, String defaultDepartmentId) {
    final lineDept = item.product.departmentId?.trim().isNotEmpty == true
        ? item.product.departmentId!.trim()
        : defaultDepartmentId;
    if (item.product.isService) {
      final buf = StringBuffer(
        'S|$lineDept|${item.product.id}|${item.quantity}',
      );
      if (item.discount > 0) {
        buf.write('|${item.isDiscountPercent ? 'p' : 'a'}:${_moneyKey(item.discount)}');
      }
      if (item.product.isPriceEditable) {
        buf.write('|u:${_moneyKey(item.effectiveUnitPrice)}');
      }
      return buf.toString();
    }
    final buf = StringBuffer(
      'P|$lineDept|${item.product.id}|${item.quantity}',
    );
    if (item.discount > 0) {
      buf.write('|${item.isDiscountPercent ? 'p' : 'a'}:${_moneyKey(item.discount)}');
    }
    if (item.product.isPriceEditable) {
      buf.write('|u:${_moneyKey(item.effectiveUnitPrice)}');
    } else {
      final quoted = item.lineUnitPriceOverride;
      if (quoted != null && quoted > 0) {
        buf.write('|u:${_moneyKey(quoted)}');
      }
    }
    return buf.toString();
  }

  bool _multisetLineSigsEqual(
      List<CartItem> a,
      List<CartItem> b,
      String defaultDepartmentId,
      ) {
    if (a.length != b.length) return false;
    final sa = a.map((c) => _pricingLineSigFromCartItem(c, defaultDepartmentId)).toList()
      ..sort();
    final sb = b.map((c) => _pricingLineSigFromCartItem(c, defaultDepartmentId)).toList()
      ..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  bool _jobOrderPricingMatchesPersisted(
      Map<String, dynamic> body,
      PosOrderJob job,
      PosOrder order,
      ) {
    final gtv = (body['totalDiscountValue'] as num?)?.toDouble() ?? 0.0;
    final gtt = (body['totalDiscountType'] as String?)?.toLowerCase() ?? 'amount';
    final rawGt =
        job.totalDiscountType ?? order.totalDiscountType ?? 'amount';
    final expT =
    rawGt.toLowerCase().contains('percent') ? 'percent' : 'amount';
    if (gtt != expT) return false;
    final expV = job.totalDiscountValue != 0 ||
        (job.totalDiscountType != null && job.totalDiscountType!.trim().isNotEmpty)
        ? job.totalDiscountValue
        : (order.totalDiscountValue ?? 0);
    if (_moneyKey(gtv) != _moneyKey(expV)) return false;

    final jobPid = (job.promoCodeId ?? order.promoCodeId ?? '').trim();
    final explicitClear =
        body.containsKey('promoCode') && body['promoCode'] == null;
    if (explicitClear) {
      return jobPid.isEmpty;
    }
    final bodyPid = body['promoCodeId']?.toString().trim() ?? '';
    if (bodyPid.isEmpty && jobPid.isEmpty) return true;
    return bodyPid == jobPid;
  }

  bool _completedJobEditHasMeaningfulPricingChange({
    required PosOrderJob job,
    required PosOrder order,
    required List<CartItem> itemsForJob,
    required String defaultDept,
    required Map<String, dynamic> body,
  }) {
    final snap = _cartItemsSnapshotFromJob(job.items);
    if (!_multisetLineSigsEqual(itemsForJob, snap, defaultDept)) {
      return true;
    }
    return !_jobOrderPricingMatchesPersisted(body, job, order);
  }

  /// PATCH `/cashier/job/:id/mark-edited` — flips **completed → edited** on success.
  ///
  /// Returns **true** only when the server accepts the patch. Callers that must POST pricing on a
  /// completed job **must** get `true` before [updateJobPricing], or the backend will reject.
  /// Do **not** call on open — only after snapshot diff (or technician diff) says there is a change.
  Future<bool> tryMarkCashierJobEditedAfterMeaningfulChange(
      BuildContext? context, {
        required String jobId,
        required String orderId,
        bool refreshOrdersOnSuccess = true,
      }) async {
    if (jobId.trim().isEmpty) return false;
    try {
      final token = await sessionService.getToken();
      if (token == null) return false;
      final res = await posRepository.markCashierJobEdited(jobId, token);
      final ok = res['success'] != false;
      if (ok) {
        if (refreshOrdersOnSuccess) {
          await fetchOrders(silent: true, preferredOrderId: orderId);
        }
        await _refreshEditingOrderSnapshot(orderId);
        return true;
      }
      // Client still had `completed` while server is already `edited` → redundant PATCH fails.
      if (await _recoverEditingOrderIfJobAlreadyEdited(jobId, orderId)) {
        return true;
      }
      if (context != null && context.mounted) {
        ToastService.showError(
          context,
          res['message']?.toString() ?? 'Could not mark job as edited',
        );
      }
      return false;
    } catch (e) {
      if (await _recoverEditingOrderIfJobAlreadyEdited(jobId, orderId)) {
        return true;
      }
      final msg = _extractErrorMessage(e.toString());
      if (context != null && context.mounted) {
        ToastService.showError(context, msg);
      }
      return false;
    }
  }

  /// Keeps [_editingOrder] job status in sync with the server after mark-edited / list refresh,
  /// so a second Save on the same screen does not call mark-edited again (would fail).
  Future<void> _refreshEditingOrderSnapshot(String orderId) async {
    if (_editingOrder?.id != orderId) return;
    final detail = await loadCashierOrderDetail(orderId);
    if (detail != null) {
      _editingOrder = detail;
    } else {
      _syncEditingOrderFromOrdersList(orderId);
    }
    notifyListeners();
  }

  void _syncEditingOrderFromOrdersList(String orderId) {
    if (_editingOrder?.id != orderId) return;
    try {
      _editingOrder = _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {}
  }

  Future<bool> _recoverEditingOrderIfJobAlreadyEdited(String jobId, String orderId) async {
    if (_editingOrder?.id != orderId) return false;
    final detail = await loadCashierOrderDetail(orderId);
    if (detail == null) return false;
    PosOrderJob? job;
    for (final j in detail.jobs) {
      if (j.id == jobId) {
        job = j;
        break;
      }
    }
    if (normalizeCashierJobStatus(job?.status) != 'edited') return false;
    _editingOrder = detail;
    notifyListeners();
    return true;
  }

  static bool _responseLooksLikeCompletedJobPricingBlock(Map<String, dynamic> response) {
    if (response['success'] != false) return false;
    final m = (response['message']?.toString() ?? '').toLowerCase();
    return m.contains('completed') &&
        (m.contains('pricing') || m.contains('update'));
  }

  void _applyWalkInOrderSuccess(
      WalkInCustomerResponse response, {
        required bool isCorporateFlow,
        required bool clearCustomerOnSuccess,
      }) {
    String? maxJobId;
    if (response.order?.departments.isNotEmpty == true) {
      final sorted = [...response.order!.departments]
        ..sort(
              (a, b) => (int.tryParse(a.jobId ?? '') ?? 0).compareTo(
            int.tryParse(b.jobId ?? '') ?? 0,
          ),
        );
      maxJobId = sorted.last.jobId;
    }

    _previousOrderId = response.order?.id ?? _previousOrderId;
    _lastPlacedWalkInOrder = response.order;
    _lastCreatedWalkInOrderId = response.order?.id ?? _lastCreatedWalkInOrderId;
    final plate = response.order?.vehicle?.plateNo.trim() ?? '';
    if (plate.isNotEmpty) {
      _lastCreatedWalkInVehicleNumber = plate;
    }
    if (isCorporateFlow) {
      final jid = maxJobId ?? response.order?.jobId;
      _currentJobId = (jid != null && jid.isNotEmpty) ? jid : null;
    } else {
      _currentJobId = maxJobId ?? response.order?.jobId ?? response.order?.id;
    }
    _isLoading = false;
    final oid = (response.order?.id ?? '').trim();
    final shouldSeedBilling =
        clearCustomerOnSuccess && oid.isNotEmpty && !isCorporateFlow;

    final snapName = _customerName;
    final snapMobile = _mobile;
    final snapVat = _vatNumber;
    final snapVehicle = _vehicleNumber;
    final snapVin = _vinNumber;
    final snapMake = _make;
    final snapModel = _model;
    final snapOdom = _odometerReading;
    final snapYear = _vehicleYear;
    final snapColor = _vehicleColor;
    final snapEmp = _billingCustomerIsEmployee;
    final snapEid = _billingEmployeeId;
    final snapEt = _billingEmployeeType;
    final snapPlateCountry = _vehiclePlateCountry;
    final snapPlateEmirate = _vehiclePlateEmirate;

    if (clearCustomerOnSuccess) {
      clearCustomerData();
    }

    if (shouldSeedBilling) {
      updateWalkInBillingContact(
        forOrderId: oid,
        name: snapName,
        mobile: snapMobile,
        vat: snapVat,
        vehicleNumber: snapVehicle,
        vin: snapVin,
        make: snapMake,
        model: snapModel,
        odometer: snapOdom,
        year: snapYear,
        color: snapColor,
        billingCustomerIsEmployee: snapEmp,
        billingEmployeeId: snapEid,
        billingEmployeeType: snapEt,
        vehiclePlateCountry: snapPlateCountry,
        vehiclePlateEmirate: snapPlateEmirate,
      );
    }
    if (oid.isNotEmpty) {
      unawaited(refreshOrdersAfterPlacement(preferredOrderId: oid));
    }
    notifyListeners();
  }

  String? _walkInTrimOrNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  int? _walkInOdometerReadingOrNull() =>
      _odometerReading > 0 ? _odometerReading : null;

  String? _corporateFleetVehicleIdForRequest() {
    final id = _corporateFleetVehicleId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  WalkInCustomerRequest _walkInShellCreateRequest(List<String> departmentIds) {
    return WalkInCustomerRequest(
      customerName: _walkInTrimOrNull(_customerName),
      mobile: _walkInTrimOrNull(_mobile),
      vatNumber: _walkInTrimOrNull(_vatNumber),
      vehicleNumber: _vehicleNumber,
      vehiclePlateCountry: _vehiclePlateCountry,
      vehiclePlateEmirate: _vehiclePlateEmirate,
      vehicleId: _corporateFleetVehicleIdForRequest(),
      vinNumber: _walkInTrimOrNull(_vinNumber),
      make: _walkInTrimOrNull(_make),
      model: _walkInTrimOrNull(_model),
      odometerReading: _walkInOdometerReadingOrNull(),
      departmentIds: departmentIds,
      corporateAccountId: (_corporateAccountId ?? '').trim().isNotEmpty
          ? _corporateAccountId!.trim()
          : null,
    );
  }

  /// POST /cashier/walk-in-order — new order + empty jobs (vehicle + departmentIds only).
  /// Corporate accounts use the existing submit-for-approval path instead.
  Future<bool> placeWalkInShellOrder(
      List<String> departmentIds,
      BuildContext context,
      ) async {
    if (departmentIds.isEmpty) {
      if (context.mounted) {
        ToastService.showError(context, 'Select at least one department');
      }
      return false;
    }

    final isCorp =
        _corporateAccountId != null && _corporateAccountId!.trim().isNotEmpty;
    if (isCorp) {
      return submitWalkInOrder(departmentIds, context, clearCustomerOnSuccess: false);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      if (_vehicleNumber.trim().isEmpty) {
        _errorMessage = 'Vehicle plate is required';
        _isLoading = false;
        notifyListeners();
        if (context.mounted) ToastService.showError(context, _errorMessage!);
        return false;
      }
      final createdVehicle = _vehicleNumber.trim();

      final shellReq = _walkInShellCreateRequest(departmentIds);
      final res = await posRepository.postWalkInOrder(
        shellReq.toShellCreateJson(),
        token,
      );
      if (res.success) {
        if ((res.order?.id ?? '').trim().isEmpty && createdVehicle.isNotEmpty) {
          _lastCreatedWalkInVehicleNumber = createdVehicle;
        }
        _applyWalkInOrderSuccess(
          res,
          isCorporateFlow: false,
          clearCustomerOnSuccess: true,
        );
        if (context.mounted) {
          ToastService.showSuccess(
            context,
            res.message.isNotEmpty ? res.message : 'Order created',
          );
        }
        return true;
      }
      _errorMessage = res.message;
      _isLoading = false;
      notifyListeners();
      if (context.mounted) ToastService.showError(context, res.message);
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      if (context.mounted) ToastService.showError(context, _errorMessage!);
      return false;
    }
  }

  Future<bool> submitWalkInOrder(
      List<String> departmentIds,
      BuildContext context, {
        bool clearCustomerOnSuccess = true,
        bool forInvoicePanelSave = false,
      }) async {
    _isLoading = true;
    if (forInvoicePanelSave) _invoicePanelSaveBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Keep corporate edit context sticky: if caller forgot to hydrate VM corporate id,
      // recover it from the existing order being edited (same orderId in POS list).
      final existingOrderId = (_previousOrderId ?? '').trim();
      if ((_corporateAccountId == null || _corporateAccountId!.trim().isEmpty) &&
          existingOrderId.isNotEmpty) {
        PosOrder? existing;
        try {
          existing = _orders.firstWhere((o) => o.id == existingOrderId);
        } catch (_) {}
        existing ??= _selectedOrder?.id == existingOrderId ? _selectedOrder : null;
        final recoveredCorporateId = (existing?.corporateAccountId ?? '').trim();
        if (recoveredCorporateId.isNotEmpty) {
          _corporateAccountId = recoveredCorporateId;
        }
      }

      final contextOrderId = (_previousOrderId ?? '').trim();
      PosOrder? contextOrder;
      if (contextOrderId.isNotEmpty) {
        try {
          contextOrder = _orders.firstWhere((o) => o.id == contextOrderId);
        } catch (_) {
          if (_selectedOrder?.id == contextOrderId) {
            contextOrder = _selectedOrder;
          } else if (_editingOrder?.id == contextOrderId) {
            contextOrder = _editingOrder;
          }
        }
      }
      final forceCorporateByContext =
          contextOrder?.isCorporateWalkIn == true;

      final isCorpSubmit = forceCorporateByContext ||
          (_corporateAccountId != null && _corporateAccountId!.trim().isNotEmpty);

      // Hard safety: never allow an existing corporate draft/edit context
      // to fall through to the normal walk-in branch.
      if (forceCorporateByContext &&
          (_corporateAccountId == null || _corporateAccountId!.trim().isEmpty)) {
        final recovered = (contextOrder?.corporateAccountId ?? '').trim();
        if (recovered.isNotEmpty) {
          _corporateAccountId = recovered;
        } else {
          _errorMessage = 'Corporate account is missing for this corporate draft.';
          _isLoading = false;
          if (forInvoicePanelSave) _invoicePanelSaveBusy = false;
          notifyListeners();
          if (context.mounted) ToastService.showError(context, _errorMessage!);
          return false;
        }
      }
      if (isCorpSubmit && _customerName.trim().isEmpty) {
        _errorMessage = 'Contact name is required for corporate quote';
        _isLoading = false;
        notifyListeners();
        if (context.mounted) ToastService.showError(context, _errorMessage!);
        return false;
      }

      if (_vehicleNumber.trim().isEmpty) {
        _errorMessage = 'Vehicle plate is required';
        _isLoading = false;
        notifyListeners();
        if (context.mounted) ToastService.showError(context, _errorMessage!);
        return false;
      }

      final List<RequestedProduct> products = [];
      final List<RequestedService> services = [];

      for (var item in _cartItems) {
        if (item.product.isPriceEditable) {
          if (item.effectiveUnitPrice <= 0) {
            _errorMessage = 'Enter a valid unit price for ${item.product.name}';
            _isLoading = false;
            notifyListeners();
            if (context.mounted) ToastService.showError(context, _errorMessage!);
            return false;
          }
          final priceErr = item.product.validateEditableUnitPrice(item.effectiveUnitPrice);
          if (priceErr == 'below_min') {
            _errorMessage =
                'Price cannot be below SAR ${item.product.minEditablePriceVatInclusive.toStringAsFixed(2)} for ${item.product.name}';
            _isLoading = false;
            notifyListeners();
            if (context.mounted) ToastService.showError(context, _errorMessage!);
            return false;
          }
        }
        if (item.product.isService) {
          services.add(
            RequestedService(
              serviceId: item.product.id,
              departmentId: item.product.departmentId ?? departmentIds.first,
              qty: item.quantity,
              discountType: item.discount > 0 ? (item.isDiscountPercent ? 'percent' : 'amount') : null,
              discountValue: item.discount > 0 ? item.discount : null,
              unitPrice: item.product.isPriceEditable ? item.effectiveUnitPrice : null,
            ),
          );
        } else {
          products.add(
            RequestedProduct(
              productId: item.product.id,
              departmentId: item.product.departmentId ?? departmentIds.first,
              qty: item.quantity,
              discountType: item.discount > 0 ? (item.isDiscountPercent ? 'percent' : 'amount') : null,
              discountValue: item.discount > 0 ? item.discount : null,
              unitPrice: item.product.isPriceEditable
                  ? item.effectiveUnitPrice
                  : _cartLineUnitPriceForApi(item),
            ),
          );
        }
      }

      // Combine the passed departmentIds with any departmentIds from the selected products
      final Set<String> allDepartmentIds = {...departmentIds};
      for (var product in products) {
        if (product.departmentId.isNotEmpty) {
          allDepartmentIds.add(product.departmentId);
        }
      }
      for (var service in services) {
        if (service.departmentId.isNotEmpty) {
          allDepartmentIds.add(service.departmentId);
        }
      }

      final amountBeforeDiscount = getSubtotalGross(false);
      final amountAfterDiscount = getPriceAfterJobDiscount(false);
      final amountAfterPromo = getTotalTaxableAmountValue(false);
      const vatPercent = 15.0;
      final totalAmount = getTotalAmountValue(false);

      if (isCorpSubmit) {
        // Submit for corporate approval on create / while still unapproved. Backend
        // auto-approves when super-admin or corporate auto-approve is enabled.
        // Omit sendForApproval on later edits so status is preserved.
        final bool? corpSendForApproval =
            _previousOrderId == null ||
                contextOrder?.isCorporateUnapproved == true
            ? true
            : null;
        final request = WalkInCustomerRequest(
          orderId: _previousOrderId,
          customerName: _customerName,
          vatNumber: _vatNumber,
          mobile: _mobile,
          vehicleNumber: _vehicleNumber,
          vehiclePlateCountry: _vehiclePlateCountry,
          vehiclePlateEmirate: _vehiclePlateEmirate,
          vehicleId: _corporateFleetVehicleIdForRequest(),
          vinNumber: _walkInTrimOrNull(_vinNumber),
          make: _walkInTrimOrNull(_make),
          model: _walkInTrimOrNull(_model),
          odometerReading: _walkInOdometerReadingOrNull(),
          departmentIds: allDepartmentIds.toList(),
          products: products.isNotEmpty ? products : null,
          services: services.isNotEmpty ? services : null,
          totalDiscountType: _globalDiscount > 0 ? (_isGlobalDiscountPercent ? 'percent' : 'amount') : null,
          totalDiscountValue: _globalDiscount > 0 ? _globalDiscount : null,
          promoCode: _promoDiscount > 0 ? _activePromoCode : null,
          promoCodeId: _promoDiscount > 0 ? _activePromoCodeId : null,
          amountBeforeDiscount: amountBeforeDiscount,
          amountAfterDiscount: amountAfterDiscount,
          amountAfterPromo: amountAfterPromo,
          vat: vatPercent,
          totalAmount: totalAmount,
          corporateAccountId: _corporateAccountId!.trim(),
          sendForApproval: corpSendForApproval,
        );

        final corpRes = await posRepository.createWalkInOrder(request, token);
        if (corpRes.success) {
          _applyWalkInOrderSuccess(
            corpRes,
            isCorporateFlow: true,
            clearCustomerOnSuccess: clearCustomerOnSuccess,
          );
          if (context.mounted) {
            ToastService.showSuccess(context, corpRes.message);
          }
          return true;
        }
        _errorMessage = corpRes.message;
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ToastService.showError(context, corpRes.message);
        }
        return false;
      }

      // Standard cashier walk-in (Nest: shell create + per-job pricing).
      if (_previousOrderId == null) {
        if (products.isEmpty && services.isEmpty) {
          if (allDepartmentIds.isEmpty) {
            _errorMessage = 'Select at least one department';
            _isLoading = false;
            notifyListeners();
            if (context.mounted) ToastService.showError(context, _errorMessage!);
            return false;
          }
          final shellReq =
          _walkInShellCreateRequest(allDepartmentIds.toList());
          final shellRes =
          await posRepository.postWalkInOrder(shellReq.toShellCreateJson(), token);
          if (shellRes.success) {
            _applyWalkInOrderSuccess(
              shellRes,
              isCorporateFlow: false,
              clearCustomerOnSuccess: clearCustomerOnSuccess,
            );
            if (context.mounted) {
              ToastService.showSuccess(context, shellRes.message);
            }
            return true;
          }
          _errorMessage = shellRes.message;
          _isLoading = false;
          notifyListeners();
          if (context.mounted) {
            ToastService.showError(context, shellRes.message);
          }
          return false;
        }

        if (allDepartmentIds.isEmpty) {
          _errorMessage = 'Each line needs a department';
          _isLoading = false;
          notifyListeners();
          if (context.mounted) ToastService.showError(context, _errorMessage!);
          return false;
        }

        final shellReq = _walkInShellCreateRequest(allDepartmentIds.toList());
        final shellRes =
        await posRepository.postWalkInOrder(shellReq.toShellCreateJson(), token);
        if (!shellRes.success || shellRes.order == null) {
          _errorMessage = shellRes.message;
          _isLoading = false;
          notifyListeners();
          if (context.mounted) {
            ToastService.showError(context, shellRes.message);
          }
          return false;
        }

        _previousOrderId = shellRes.order!.id;
        final deptJob = _departmentJobMapFromWalkInOrder(shellRes.order);
        final grouped = _groupCartItemsByDepartment(allDepartmentIds.toList());
        final keys = grouped.keys.toList()..sort();
        if (keys.isEmpty) {
          _errorMessage = 'No line items to save';
          _isLoading = false;
          notifyListeners();
          if (context.mounted) ToastService.showError(context, _errorMessage!);
          return false;
        }

        for (var i = 0; i < keys.length; i++) {
          final deptId = keys[i];
          final jid = deptJob[deptId];
          if (jid == null || jid.isEmpty) {
            _errorMessage =
            'No job for department $deptId. Use “Add departments” or refresh orders.';
            _isLoading = false;
            notifyListeners();
            if (context.mounted) ToastService.showError(context, _errorMessage!);
            return false;
          }
          final payload = _buildCashierJobPricingPayload(
            items: grouped[deptId]!,
            defaultDepartmentId: deptId,
            applyJobDiscountAndPromo: i == 0,
            isMainTab: false,
          );
          final pr = await posRepository.updateJobPricing(jid, payload, token);
          if (pr['success'] == false) {
            _errorMessage =
                pr['message']?.toString() ?? 'Failed to save pricing for department $deptId';
            _isLoading = false;
            notifyListeners();
            if (context.mounted) ToastService.showError(context, _errorMessage!);
            return false;
          }
        }

        String? maxJobId;
        if (shellRes.order!.departments.isNotEmpty) {
          final sorted = [...shellRes.order!.departments]
            ..sort(
                  (a, b) => (int.tryParse(a.jobId ?? '') ?? 0).compareTo(
                int.tryParse(b.jobId ?? '') ?? 0,
              ),
            );
          maxJobId = sorted.last.jobId;
        }
        _currentJobId = maxJobId ?? shellRes.order?.jobId ?? shellRes.order?.id;
        final placedOrderId = (shellRes.order?.id ?? _previousOrderId ?? '').trim();
        if (placedOrderId.isNotEmpty) {
          _lastCreatedWalkInOrderId = placedOrderId;
        }
        _isLoading = false;
        if (clearCustomerOnSuccess) {
          clearCustomerData();
        }
        notifyListeners();
        if (placedOrderId.isNotEmpty) {
          await refreshOrdersAfterPlacement(preferredOrderId: placedOrderId);
        }
        if (context.mounted) {
          ToastService.showSuccess(context, shellRes.message);
        }
        return true;
      }

      final request = WalkInCustomerRequest(
        orderId: _previousOrderId,
        customerName: _customerName,
        vatNumber: _vatNumber,
        mobile: _mobile,
        vehicleNumber: _vehicleNumber,
        vehiclePlateCountry: _vehiclePlateCountry,
        vehiclePlateEmirate: _vehiclePlateEmirate,
        vehicleId: _corporateFleetVehicleIdForRequest(),
        vinNumber: _walkInTrimOrNull(_vinNumber),
        make: _walkInTrimOrNull(_make),
        model: _walkInTrimOrNull(_model),
        odometerReading: _walkInOdometerReadingOrNull(),
        departmentIds: allDepartmentIds.toList(),
        products: products.isNotEmpty ? products : null,
        services: services.isNotEmpty ? services : null,
        totalDiscountType: _globalDiscount > 0 ? (_isGlobalDiscountPercent ? 'percent' : 'amount') : null,
        totalDiscountValue: _globalDiscount > 0 ? _globalDiscount : null,
        promoCode: _promoDiscount > 0 ? _activePromoCode : null,
        promoCodeId: _promoDiscount > 0 ? _activePromoCodeId : null,
        amountBeforeDiscount: amountBeforeDiscount,
        amountAfterDiscount: amountAfterDiscount,
        amountAfterPromo: amountAfterPromo,
        vat: vatPercent,
        totalAmount: totalAmount,
      );

      final response = await posRepository.createWalkInOrder(request, token);

      if (response.success) {
        _applyWalkInOrderSuccess(
          response,
          isCorporateFlow: false,
          clearCustomerOnSuccess: clearCustomerOnSuccess,
        );
        if (context.mounted) {
          ToastService.showSuccess(context, response.message);
        }
        return true;
      }
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ToastService.showError(context, response.message);
      }
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ToastService.showError(context, _errorMessage!);
      }
      return false;
    } finally {
      if (forInvoicePanelSave) {
        _invoicePanelSaveBusy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> submitEditOrder(
      List<String> departmentIds,
      BuildContext context, {
        bool forInvoicePanelSave = false,
      }) async {
    final orderId = _editingOrder?.id ?? '';
    final jobId = _editingCompletingOrderId ?? '';

    if (orderId.isEmpty || jobId.isEmpty) {
      if (context.mounted) {
        ToastService.showError(context, 'Edit context missing. Please try again.');
      }
      return false;
    }

    _isLoading = true;
    if (forInvoicePanelSave) _invoicePanelSaveBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      for (var item in _cartItems) {
        if (item.product.isPriceEditable) {
          if (item.effectiveUnitPrice <= 0) {
            if (context.mounted) {
              ToastService.showError(context, 'Enter a valid unit price for ${item.product.name}');
            }
            return false;
          }
          final priceErr = item.product.validateEditableUnitPrice(item.effectiveUnitPrice);
          if (priceErr == 'below_min') {
            if (context.mounted) {
              ToastService.showError(
                context,
                'Price cannot be below SAR ${item.product.minEditablePriceVatInclusive.toStringAsFixed(2)} for ${item.product.name}',
              );
            }
            return false;
          }
        }
      }

      final deptId = (_editDepartmentId ?? '').trim();
      final fallbackDept =
      departmentIds.isNotEmpty ? departmentIds.first.trim() : deptId;
      final defaultDept = deptId.isNotEmpty ? deptId : fallbackDept;

      final itemsForJob = _cartItems.where((c) {
        if (deptId.isEmpty) return true;
        final pd = c.product.departmentId?.trim() ?? '';
        return pd.isEmpty || pd == deptId;
      }).toList();

      PosOrderJob? jobMeta;
      for (final j in _editingOrder?.jobs ?? const <PosOrderJob>[]) {
        if (j.id == jobId) {
          jobMeta = j;
          break;
        }
      }

      final body = _buildCashierJobPricingPayload(
        items: itemsForJob,
        defaultDepartmentId: defaultDept.isNotEmpty ? defaultDept : '0',
        applyJobDiscountAndPromo: true,
        isMainTab: false,
        sourceJob: jobMeta,
        sourceOrder: _editingOrder,
      );

      final st = normalizeCashierJobStatus(jobMeta?.status);
      final isCompleted = st == 'completed';
      final meaningfulPricingChange = jobMeta != null &&
          _completedJobEditHasMeaningfulPricingChange(
            job: jobMeta,
            order: _editingOrder!,
            itemsForJob: itemsForJob,
            defaultDept: defaultDept.isNotEmpty ? defaultDept : '0',
            body: body,
          );

      // Backend rejects POST …/pricing while the job is still `completed` — never POST in that case
      // unless we successfully PATCH mark-edited first (or there is nothing to persist).
      if (isCompleted && !meaningfulPricingChange) {
        if (context.mounted) {
          ToastService.showInfo(context, 'No changes to save');
        }
        return true;
      }

      if (isCompleted && meaningfulPricingChange) {
        final marked = await tryMarkCashierJobEditedAfterMeaningfulChange(
          context,
          jobId: jobId,
          orderId: orderId,
          refreshOrdersOnSuccess: false,
        );
        if (!marked) {
          _errorMessage = 'Could not unlock this job for editing';
          if (context.mounted) {
            ToastService.showError(
              context,
              'Could not unlock this job for editing. Please try again.',
            );
          }
          return false;
        }
      }

      var response = await posRepository.updateJobPricing(jobId, body, token);
      var success = response['success'] != false;

      if (!success &&
          isCompleted &&
          _responseLooksLikeCompletedJobPricingBlock(response)) {
        final marked = await tryMarkCashierJobEditedAfterMeaningfulChange(
          context,
          jobId: jobId,
          orderId: orderId,
          refreshOrdersOnSuccess: false,
        );
        if (marked) {
          response = await posRepository.updateJobPricing(jobId, body, token);
          success = response['success'] != false;
        }
      }

      if (success) {
        // Prefer detail hydrate so hub gets job.items (slim list omits lines).
        await refreshOrderInHubAfterMutation(orderId, apiResponse: response);
        await ensureOrderLinesHydrated(orderId, force: true);
      }

      if (context.mounted) {
        if (success) {
          ToastService.showSuccess(
            context,
            response['message']?.toString() ?? 'Order updated successfully',
          );
        } else {
          final msg = response['message']?.toString() ?? 'Failed to update order';
          _errorMessage = msg;
          ToastService.showError(context, msg);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      if (context.mounted) {
        ToastService.showError(context, _errorMessage!);
      }
      return false;
    } finally {
      _isLoading = false;
      if (forInvoicePanelSave) _invoicePanelSaveBusy = false;
      notifyListeners();
    }
  }

  List<PosProduct> _allProducts = [];
  String? _lastFetchedDepartmentId;
  String? get lastFetchedDepartmentId => _lastFetchedDepartmentId;

  /// Non-empty when the POS catalog was loaded from `GET .../branches/:id/catalog`.
  String? _catalogBranchId;
  String? get catalogBranchId => _catalogBranchId;

  void _applyCatalogSnapshot(LocalCatalogSnapshot snapshot) {
    var snap = snapshot;
    if (shouldUseCorporateQuotedCatalog) {
      final corpId = activeCorporateAccountId;
      if (corpId != null && corpId.isNotEmpty) {
        final quoted = _corporateQuotedProductsByAccountId[corpId];
        if (quoted != null && quoted.isNotEmpty && !snap.isEmpty) {
          snap = _mergeBranchCatalogWithQuotedPrices(
            snap,
            quoted,
            departmentId: _lastFetchedDepartmentId,
          );
        }
      }
    }
    _allProducts = List<PosProduct>.from(snap.products);
    _apiCategories = List<ProductCategory>.from(snap.categories);
    _refreshCartProductReferences();
  }

  /// Re-applies cached corporate quotation prices onto the current branch catalog tiles.
  Future<void> reapplyCorporateQuotedPricesToCatalog({bool forceRefresh = false}) async {
    if (!shouldUseCorporateQuotedCatalog) return;
    final corpId = activeCorporateAccountId;
    if (corpId == null || corpId.isEmpty || _allProducts.isEmpty) return;
    var quoted = _corporateQuotedProductsByAccountId[corpId];
    if ((quoted == null || quoted.isEmpty) && forceRefresh) {
      quoted = await _resolveCorporateQuotedLines(
        corpId,
        departmentId: _lastFetchedDepartmentId,
        forceRefresh: true,
      );
    }
    if (quoted == null || quoted.isEmpty) return;
    final snap = _mergeBranchCatalogWithQuotedPrices(
      LocalCatalogSnapshot(products: _allProducts, categories: _apiCategories),
      quoted,
      departmentId: _lastFetchedDepartmentId,
    );
    _allProducts = List<PosProduct>.from(snap.products);
    _refreshCartProductReferences();
    notifyListeners();
  }

  /// Catalog tile price — corporate flows prefer cached quotation lines.
  double catalogDisplayPriceFor(PosProduct product) {
    final quoted = _quotedPriceForProduct(product);
    if (quoted != null && quoted > 0) return quoted;
    return product.price;
  }

  void clearCorporateProductsCatalog() {
    _loadedCorporateCatalogAccountId = null;
    _extrinsicCorporateQuotedLines = const [];
    _activeCorporateBookingId = null;
    _corporateApiQuotedLinesByAccountId.clear();
    _corporateQuotedProductsByAccountId.clear();
    _lastCatalogFetchWasCorporate = false;
    notifyListeners();
  }

  void setActiveCorporateBookingContext({
    String? bookingId,
    List<dynamic>? bookingItems,
  }) {
    final bid = bookingId?.trim();
    if (bid != null && bid.isNotEmpty) {
      _activeCorporateBookingId = bid;
    }
    if (bookingItems != null && bookingItems.isNotEmpty) {
      setCorporateBookingQuotedItems(bookingItems);
    }
  }

  Future<void> _hydrateQuotedLinesFromCorporateBookingDetail(
    String bookingId,
  ) async {
    final bid = bookingId.trim();
    if (bid.isEmpty) return;
    final token = await sessionService.getToken(role: 'cashier');
    if (token == null) return;
    try {
      final detail = await posRepository.getCorporateBookingDetail(bid, token);
      if (detail?.items != null && detail!.items!.isNotEmpty) {
        setCorporateBookingQuotedItems(detail.items);
      }
    } catch (e) {
      debugPrint('Corporate booking detail for quotes failed: $e');
    }
  }

  /// Corporate booking list/detail `items` / `lineItems` (quoted lines from corporate app).
  void setCorporateBookingQuotedItems(List<dynamic>? rawItems) {
    _extrinsicCorporateQuotedLines = _quotedLinesFromDynamicList(rawItems);
    notifyListeners();
  }

  /// Before cashier order exists: corporate account + portal `items` with `unitPrice`.
  void primeCorporateBookingFromPortal({
    required String corporateAccountId,
    List<dynamic>? bookingItems,
    String? corporateBookingId,
  }) {
    final corpId = corporateAccountId.trim();
    if (corpId.isNotEmpty) {
      _corporateAccountId = corpId;
    }
    setActiveCorporateBookingContext(
      bookingId: corporateBookingId,
      bookingItems: bookingItems,
    );
    if (bookingItems == null || bookingItems.isEmpty) {
      notifyListeners();
    }
  }

  /// Corporate booking order → product grid: portal/cashier quoted prices on catalog tiles.
  Future<void> prepareCorporateJobProductCatalog({
    required PosOrder order,
    String? departmentId,
    String? departmentName,
    List<dynamic>? bookingItemsFallback,
    String? corporateBookingId,
    bool forceRefresh = true,
  }) async {
    final corpId = (order.corporateAccountId ?? _corporateAccountId ?? '').trim();
    if (corpId.isEmpty) return;

    _corporateAccountId = corpId;
    _editingOrder = order;

    if (forceRefresh) {
      _corporateApiQuotedLinesByAccountId.removeWhere(
        (key, _) => key.startsWith('$corpId|') || key == corpId,
      );
      _corporateQuotedProductsByAccountId.remove(corpId);
    }

    final bookingId = (corporateBookingId ??
            order.corporateOrderId ??
            _activeCorporateBookingId ??
            '')
        .trim();
    if (bookingId.isNotEmpty) {
      _activeCorporateBookingId = bookingId;
      await _hydrateQuotedLinesFromCorporateBookingDetail(bookingId);
    }
    if (bookingItemsFallback != null && bookingItemsFallback.isNotEmpty) {
      _extrinsicCorporateQuotedLines = _mergeQuotedCatalogLinesFillGaps(
        _extrinsicCorporateQuotedLines,
        _quotedLinesFromDynamicList(bookingItemsFallback),
      );
      notifyListeners();
    }
    seedCorporateQuotedItemsFromOrder(order);

    final jobDeptIds = order.jobs
        .map((j) => (j.departmentId ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final scopedDeptIds = <String>{
      if (departmentId != null && departmentId.trim().isNotEmpty)
        departmentId.trim(),
      ...jobDeptIds,
    }.toList();

    await loadCorporateProductsCatalog(
      corpId,
      departmentId: departmentId,
      departmentIds: scopedDeptIds.isNotEmpty ? scopedDeptIds : null,
      departmentName: departmentName,
      forceRefresh: forceRefresh,
    );
    await reapplyCorporateQuotedPricesToCatalog();
  }

  static bool _quotedLineMatchesDepartment(
    CorporateQuotedProduct q, {
    String? departmentId,
    String? departmentName,
  }) {
    final deptFilter = departmentId?.trim() ?? '';
    if (deptFilter.isEmpty) return true;

    final qDept = q.departmentId?.trim() ?? '';
    if (qDept.isNotEmpty && qDept == deptFilter) return true;

    final nameFilter = departmentName?.trim().toLowerCase() ?? '';
    final qName = q.departmentName?.trim().toLowerCase() ?? '';
    if (nameFilter.isNotEmpty && qName.isNotEmpty && qName == nameFilter) {
      return true;
    }

    // Quotation lines often omit departmentId — keep them visible for the active job.
    if (qDept.isEmpty) return true;
    return false;
  }

  /// Full corporate-account catalog (includes zero-price editable services).
  static LocalCatalogSnapshot _catalogSnapshotFromCorporateAccountLines(
    List<CorporateQuotedProduct> lines, {
    String? departmentId,
    String? departmentName,
  }) {
    final products = <PosProduct>[];
    for (final q in lines) {
      if (q.id.isEmpty) continue;
      if (!_quotedLineMatchesDepartment(
        q,
        departmentId: departmentId,
        departmentName: departmentName,
      )) {
        continue;
      }
      products.add(q.toPosProduct());
    }

    final byCategory = <String, List<PosProduct>>{};
    for (final p in products) {
      final cat = p.categoryName?.trim().isNotEmpty == true
          ? p.categoryName!.trim()
          : 'Uncategorized';
      byCategory.putIfAbsent(cat, () => []).add(p);
    }
    final categories = byCategory.entries
        .map(
          (e) => ProductCategory(
            id: e.key,
            name: e.key,
            type: 'mixed',
            subCategories: const [],
            productsWithoutSub: e.value,
          ),
        )
        .toList();

    return LocalCatalogSnapshot(products: products, categories: categories);
  }

  static LocalCatalogSnapshot _catalogSnapshotFromCorporateQuoted(
    List<CorporateQuotedProduct> quoted, {
    String? departmentId,
    String? departmentName,
  }) {
    final products = <PosProduct>[];
    for (final q in quoted) {
      if (q.id.isEmpty || q.effectiveQuotedPrice <= 0) continue;
      if (!_quotedLineMatchesDepartment(
        q,
        departmentId: departmentId,
        departmentName: departmentName,
      )) {
        continue;
      }
      products.add(q.toPosProduct());
    }

    final byCategory = <String, List<PosProduct>>{};
    for (final p in products) {
      final cat = p.categoryName?.trim().isNotEmpty == true
          ? p.categoryName!.trim()
          : 'Uncategorized';
      byCategory.putIfAbsent(cat, () => []).add(p);
    }
    final categories = byCategory.entries
        .map(
          (e) => ProductCategory(
            id: e.key,
            name: e.key,
            type: 'mixed',
            subCategories: const [],
            productsWithoutSub: e.value,
          ),
        )
        .toList();

    return LocalCatalogSnapshot(products: products, categories: categories);
  }

  /// Adds [from] only for keys not already in [into] (API / branch catalog filler).
  List<CorporateQuotedProduct> _mergeQuotedCatalogLinesFillGaps(
    List<CorporateQuotedProduct> into,
    List<CorporateQuotedProduct> from,
  ) {
    final byKey = <String, CorporateQuotedProduct>{};
    for (final q in into) {
      final k = _quotedLineMergeKey(q);
      if (k.isNotEmpty) byKey[k] = q;
    }
    for (final q in from) {
      final k = _quotedLineMergeKey(q);
      if (k.isEmpty) continue;
      byKey.putIfAbsent(k, () => q);
    }
    return byKey.values.toList();
  }

  /// [authoritative] overwrites [base] per catalog key (booking / order / job lines win).
  List<CorporateQuotedProduct> _mergeQuotedCatalogLinesOverwrite(
    List<CorporateQuotedProduct> base,
    List<CorporateQuotedProduct> authoritative,
  ) {
    final byKey = <String, CorporateQuotedProduct>{};
    for (final q in base) {
      final k = _quotedLineMergeKey(q);
      if (k.isNotEmpty) byKey[k] = q;
    }
    for (final q in authoritative) {
      final k = _quotedLineMergeKey(q);
      if (k.isEmpty) continue;
      byKey[k] = q;
    }
    return byKey.values.toList();
  }

  static String _quotedLineMergeKey(CorporateQuotedProduct q) {
    if (q.id.trim().isNotEmpty) return q.catalogKey;
    final name = q.name.trim();
    if (name.isEmpty) return '';
    return 'name:${CorporateQuotedProduct.nameKeyFor(name, q.isService)}';
  }

  List<CorporateQuotedProduct> _quotedLinesFromDynamicList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final out = <CorporateQuotedProduct>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final q = CorporateQuotedProduct.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (q.effectiveQuotedPrice <= 0) continue;
      if (q.id.trim().isEmpty && q.name.trim().isEmpty) continue;
      out.add(q);
    }
    return out;
  }

  /// Corporate quotation prices to overlay on branch catalog (not every account SKU).
  static List<CorporateQuotedProduct> _quotationLinesFromCorporateApiResponse(
    CorporateQuotedProductsResponse response,
  ) {
    final byKey = <String, CorporateQuotedProduct>{};
    void put(CorporateQuotedProduct q) {
      if (q.id.trim().isEmpty && q.name.trim().isEmpty) return;
      if (!q.isCorporateQuotedPrice && !q.isEligibleForPriceOverlay) return;
      byKey[q.catalogKey] = q;
    }

    for (final q in response.products) {
      put(q);
    }
    for (final q in response.services) {
      put(q);
    }
    for (final q in response.quotedLines) {
      put(q);
    }
    if (byKey.isNotEmpty) return byKey.values.toList();

    final overlay = response.quotationPriceOverlayLines;
    if (overlay.isNotEmpty) return overlay;

    if (response.quotedLines.isNotEmpty) {
      return List<CorporateQuotedProduct>.from(response.quotedLines);
    }
    return const [];
  }

  String _corporateQuotedLinesCacheKey(
    String corpId, {
    String? departmentId,
    List<String>? departmentIds,
  }) {
    final parts = <String>[corpId.trim()];
    if (departmentIds != null && departmentIds.isNotEmpty) {
      parts.addAll(departmentIds.map((d) => d.trim()).where((d) => d.isNotEmpty));
    } else if (departmentId != null && departmentId.trim().isNotEmpty) {
      parts.add(departmentId.trim());
    }
    return parts.join('|');
  }

  Future<CorporateQuotedProductsResponse?> _fetchCorporateProductsApi(
    String token,
    String corpId, {
    String? departmentId,
    List<String>? departmentIds,
    bool quotedOnly = false,
  }) async {
    try {
      return await posRepository.getCorporateQuotedProducts(
        token,
        corpId,
        departmentId: departmentId,
        departmentIds: departmentIds,
        quotedOnly: quotedOnly,
      );
    } catch (e) {
      debugPrint(
        'Corporate products API failed (quotedOnly=$quotedOnly): $e',
      );
      return null;
    }
  }

  List<CorporateQuotedProduct> _quotedLinesFromPosOrder(PosOrder order) {
    final out = <CorporateQuotedProduct>[];
    out.addAll(_quotedLinesFromDynamicList(order.items));
    for (final job in order.jobs) {
      for (final item in job.items) {
        if (item.productId.isEmpty || item.unitPrice <= 0) continue;
        out.add(CorporateQuotedProduct.fromPosOrderJobItem(item));
      }
    }
    for (final dept in order.proposalDepartments) {
      if (dept is! Map) continue;
      final map = Map<String, dynamic>.from(dept);
      out.addAll(_quotedLinesFromDynamicList(map['items'] as List?));
      out.addAll(_quotedLinesFromDynamicList(map['lineItems'] as List?));
      out.addAll(_quotedLinesFromDynamicList(map['products'] as List?));
      out.addAll(_quotedLinesFromDynamicList(map['services'] as List?));
    }
    return out;
  }

  Future<List<CorporateQuotedProduct>> _resolveCorporateQuotedLines(
    String corporateAccountId, {
    String? departmentId,
    List<String>? departmentIds,
    String? departmentName,
    bool forceRefresh = false,
  }) async {
    final corpId = corporateAccountId.trim();
    if (corpId.isEmpty) return const [];

    var apiLines = <CorporateQuotedProduct>[];
    final cacheKey = _corporateQuotedLinesCacheKey(
      corpId,
      departmentId: departmentId,
      departmentIds: departmentIds,
    );
    final hasApiCache = _corporateApiQuotedLinesByAccountId.containsKey(cacheKey);
    if (!forceRefresh && hasApiCache) {
      apiLines = List<CorporateQuotedProduct>.from(
        _corporateApiQuotedLinesByAccountId[cacheKey]!,
      );
    } else {
      final token = await sessionService.getToken(role: 'cashier');
      if (token != null) {
        // Full branch catalog first — backend resolves quotation price on every SKU.
        var response = await _fetchCorporateProductsApi(
          token,
          corpId,
          departmentId: departmentId,
          departmentIds: departmentIds,
          quotedOnly: false,
        );
        apiLines = response != null
            ? _quotationLinesFromCorporateApiResponse(response)
            : const [];

        if (apiLines.isEmpty) {
          response = await _fetchCorporateProductsApi(
            token,
            corpId,
            departmentId: departmentId,
            departmentIds: departmentIds,
            quotedOnly: true,
          );
          apiLines = response != null
              ? _quotationLinesFromCorporateApiResponse(response)
              : const [];
        }

        if (apiLines.isEmpty &&
            ((departmentIds != null && departmentIds.isNotEmpty) ||
                (departmentId != null && departmentId.trim().isNotEmpty))) {
          response = await _fetchCorporateProductsApi(
            token,
            corpId,
            quotedOnly: false,
          );
          apiLines = response != null
              ? _quotationLinesFromCorporateApiResponse(response)
              : const [];
        }
      }
      _corporateApiQuotedLinesByAccountId[cacheKey] = apiLines;
    }

    // Price overlay = corporate quotation API + portal booking lines (not full branch catalog).
    var quoted = List<CorporateQuotedProduct>.from(apiLines);

    final bookingId = (_activeCorporateBookingId ?? '').trim();
    if (bookingId.isNotEmpty) {
      await _hydrateQuotedLinesFromCorporateBookingDetail(bookingId);
    }

    // Corporate quotation API wins (same as walk-in). Portal/order lines only fill gaps.
    quoted = _mergeQuotedCatalogLinesFillGaps(
      apiLines,
      _extrinsicCorporateQuotedLines,
    );

    _corporateQuotedProductsByAccountId[corpId] = quoted;
    _loadedCorporateCatalogAccountId = corpId;
    return quoted;
  }

  static LocalCatalogSnapshot _filterCatalogByDepartment(
    LocalCatalogSnapshot source, {
    String? departmentId,
    String? departmentName,
  }) {
    final id = departmentId?.trim() ?? '';
    final nameKey = (departmentName ?? '').trim().toLowerCase();
    if (id.isEmpty && nameKey.isEmpty) return source;

    bool matches(PosProduct p) {
      final pid = (p.departmentId ?? '').trim();
      final pname = (p.departmentName ?? '').trim().toLowerCase();
      if (id.isNotEmpty && pid == id) return true;
      if (nameKey.isEmpty) return false;
      if (pname == nameKey) return true;
      if (pname.contains(nameKey) || nameKey.contains(pname)) return true;
      return false;
    }

    final products = source.products.where(matches).toList();
    return LocalCatalogSnapshot(
      products: products,
      categories: source.categories,
    );
  }

  Future<LocalCatalogSnapshot?> _fetchBranchCatalogSnapshot({
    String? departmentId,
    String? departmentName,
  }) async {
    // Full branch catalog — corporate quotation prices are merged separately.
    var local = await catalogSync.loadProductsLocal(departmentId: departmentId);
    if (local == null || local.isEmpty) {
      final allLocal = await catalogSync.loadProductsLocal();
      if (allLocal != null && !allLocal.isEmpty) {
        local = _filterCatalogByDepartment(
          allLocal,
          departmentId: departmentId,
          departmentName: departmentName,
        );
      }
    }
    if (local != null && !local.isEmpty) return local;

    final token = await sessionService.getToken(role: 'cashier');
    final user = await sessionService.getUser();
    if (token == null || user?.workshopId == null) return local;

    final branchId = user!.branchId?.trim() ?? '';
    try {
      final response = await posRepository.getProducts(
        user.workshopId!,
        token,
        departmentId: departmentId,
        branchId: branchId.isNotEmpty ? branchId : null,
        corporateAccountId: null,
      );
      if (!response.success) return local;
      var snap = LocalCatalogSnapshot.fromResponse(
        response,
        departmentId: departmentId,
      );
      if (snap.isEmpty) {
        snap = _filterCatalogByDepartment(
          LocalCatalogSnapshot.fromResponse(response),
          departmentId: departmentId,
          departmentName: departmentName,
        );
      }
      return snap.isEmpty ? null : snap;
    } catch (e) {
      debugPrint('Branch catalog fetch failed: $e');
      return local;
    }
  }

  static String _normalizeCatalogName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Full [branch] catalog; only products present in [quoted] get a new tile price.
  LocalCatalogSnapshot _mergeBranchCatalogWithQuotedPrices(
    LocalCatalogSnapshot branch,
    List<CorporateQuotedProduct> quoted, {
    String? departmentId,
    bool appendQuotedOnlyNotInBranch = false,
  }) {
    final priceByKey = <String, double>{};
    final priceByNameKey = <String, double>{};
    final priceByNormalizedName = <String, double>{};
    final quotedLineByKey = <String, CorporateQuotedProduct>{};
    for (final q in quoted) {
      if (q.effectiveQuotedPrice <= 0) continue;
      priceByKey[q.catalogKey] = q.effectiveQuotedPrice;
      quotedLineByKey[q.catalogKey] = q;
      final nameKey =
          CorporateQuotedProduct.nameKeyFor(q.name, q.isService);
      priceByNameKey[nameKey] = q.effectiveQuotedPrice;
      quotedLineByKey.putIfAbsent('name:$nameKey', () => q);
      final norm = _normalizeCatalogName(q.name);
      if (norm.isNotEmpty) {
        priceByNormalizedName['$norm|${q.isService ? 'service' : 'product'}'] =
            q.effectiveQuotedPrice;
        quotedLineByKey.putIfAbsent(
          'name:$norm|${q.isService ? 'service' : 'product'}',
          () => q,
        );
      }
    }

    CorporateQuotedProduct? _lookupQuotedLine(PosProduct p) {
      final key = CorporateQuotedProduct.catalogKeyFor(p.id, p.isServiceType);
      final byId = quotedLineByKey[key];
      if (byId != null) return byId;
      final nameKey =
          CorporateQuotedProduct.nameKeyFor(p.name, p.isServiceType);
      return quotedLineByKey['name:$nameKey'];
    }

    double? _lookupQuotedPrice(PosProduct p) {
      final key = CorporateQuotedProduct.catalogKeyFor(p.id, p.isServiceType);
      final byId = priceByKey[key];
      if (byId != null && byId > 0) return byId;
      final byName = priceByNameKey[
          CorporateQuotedProduct.nameKeyFor(p.name, p.isServiceType)];
      if (byName != null && byName > 0) return byName;
      final norm = _normalizeCatalogName(p.name);
      if (norm.isEmpty) return null;
      return priceByNormalizedName[
          '$norm|${p.isServiceType ? 'service' : 'product'}'];
    }

    final mergedProducts = <PosProduct>[];
    final seen = <String>{};
    for (final p in branch.products) {
      final key = CorporateQuotedProduct.catalogKeyFor(p.id, p.isServiceType);
      final quoteLine = _lookupQuotedLine(p);
      final quotedPrice = _lookupQuotedPrice(p);
      if (quotedPrice != null && quotedPrice > 0) {
        final priced = p.withCatalogPrice(quotedPrice);
        if (quoteLine?.isService == true) priced.isServiceType = true;
        mergedProducts.add(priced);
      } else {
        if (quoteLine?.isService == true) p.isServiceType = true;
        mergedProducts.add(p);
      }
      seen.add(key);
    }

    if (appendQuotedOnlyNotInBranch) {
      for (final q in quoted) {
        if (q.id.isEmpty || seen.contains(q.catalogKey)) continue;
        if (departmentId != null &&
            departmentId.trim().isNotEmpty &&
            (q.departmentId?.trim().isNotEmpty ?? false) &&
            q.departmentId!.trim() != departmentId.trim()) {
          continue;
        }
        mergedProducts.add(q.toPosProduct());
        seen.add(q.catalogKey);
      }
    }

    return LocalCatalogSnapshot(
      products: mergedProducts,
      categories: branch.categories,
    );
  }

  Future<void> _fetchCorporateFlowProducts({
    required String corporateAccountId,
    String? departmentId,
    List<String>? departmentIds,
    String? departmentName,
    bool forceRefresh = false,
  }) async {
    final corpId = corporateAccountId.trim();
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      _lastFetchedDepartmentId = departmentId.trim();
    }
    _corporateCatalogLoading = true;
    _lastCatalogFetchWasCorporate = true;
    notifyListeners();
    try {
      final quoted = await _resolveCorporateQuotedLines(
        corpId,
        departmentId: departmentId,
        departmentIds: departmentIds,
        departmentName: departmentName,
        forceRefresh: forceRefresh,
      );

      final branch = await _fetchBranchCatalogSnapshot(
        departmentId: departmentId,
        departmentName: departmentName,
      );

      if (branch != null && !branch.isEmpty) {
        _applyCatalogSnapshot(
          quoted.isNotEmpty
              ? _mergeBranchCatalogWithQuotedPrices(
                  branch,
                  quoted,
                  departmentId: departmentId,
                )
              : branch,
        );
        return;
      }

      if (quoted.isNotEmpty) {
        final fallback = _catalogSnapshotFromCorporateQuoted(
          quoted,
          departmentId: departmentId,
          departmentName: departmentName,
        );
        if (fallback.products.isNotEmpty) {
          _applyCatalogSnapshot(fallback);
          return;
        }
      }

      _allProducts = [];
      _apiCategories = [];
      _refreshCartProductReferences();
    } finally {
      _corporateCatalogLoading = false;
      await reapplyCorporateQuotedPricesToCatalog(forceRefresh: forceRefresh);
      applyCorporateQuotedPricesToActiveCart();
      notifyListeners();
    }
  }

  /// Loads corporate quoted catalog into the product grid (cashier APIs + booking/order lines).
  /// Seeds quotation lines from corporate booking / cashier order (authoritative for pricing).
  void seedCorporateQuotedItemsFromOrder(PosOrder order) {
    final lines = <Map<String, dynamic>>[];
    void addJobItem(PosOrderJobItem i) {
      lines.add({
        if (i.itemType == 'service') 'serviceId': i.productId else 'productId': i.productId,
        'productName': i.productName,
        if (i.productNameArabic.isNotEmpty) 'productNameArabic': i.productNameArabic,
        'unitPrice': i.unitPrice,
        if (i.unitPriceExcludingVat > 0) 'unitPriceExcludingVat': i.unitPriceExcludingVat,
        'departmentId': i.departmentId,
        'departmentName': i.departmentName,
        'itemType': i.itemType,
        'qty': i.qty,
      });
    }

    for (final raw in order.items) {
      if (raw is Map) {
        lines.add(Map<String, dynamic>.from(raw));
      }
    }
    for (final job in order.jobs) {
      for (final i in job.items) {
        addJobItem(i);
      }
    }
    _extrinsicCorporateQuotedLines = _mergeQuotedCatalogLinesFillGaps(
      _extrinsicCorporateQuotedLines,
      _quotedLinesFromDynamicList(lines),
    );
    notifyListeners();
  }

  Future<void> loadCorporateProductsCatalog(
    String corporateAccountId, {
    bool forceRefresh = false,
    String? departmentId,
    List<String>? departmentIds,
    String? departmentName,
  }) async {
    final corpId = corporateAccountId.trim();
    if (corpId.isEmpty) return;
    await _fetchCorporateFlowProducts(
      corporateAccountId: corpId,
      departmentId: departmentId,
      departmentIds: departmentIds,
      departmentName: departmentName,
      forceRefresh: forceRefresh,
    );
  }

  double? _quotedPriceForProduct(PosProduct product) {
    if (!shouldUseCorporateQuotedCatalog) return null;
    final corpId = activeCorporateAccountId;
    if (corpId == null || corpId.isEmpty) return null;
    final lines = _corporateQuotedProductsByAccountId[corpId];
    if (lines == null || lines.isEmpty) return null;
    final key = CorporateQuotedProduct.catalogKeyFor(product.id, product.isServiceType);
    for (final q in lines) {
      if (q.catalogKey == key && q.effectiveQuotedPrice > 0) {
        return q.effectiveQuotedPrice;
      }
    }
    final nameKey =
        CorporateQuotedProduct.nameKeyFor(product.name, product.isServiceType);
    for (final q in lines) {
      if (CorporateQuotedProduct.nameKeyFor(q.name, q.isService) == nameKey &&
          q.effectiveQuotedPrice > 0) {
        return q.effectiveQuotedPrice;
      }
    }
    final norm = _normalizeCatalogName(product.name);
    if (norm.isNotEmpty) {
      final normKey = '$norm|${product.isServiceType ? 'service' : 'product'}';
      for (final q in lines) {
        final qNorm = _normalizeCatalogName(q.name);
        final qKey = '$qNorm|${q.isService ? 'service' : 'product'}';
        if (qKey == normKey && q.effectiveQuotedPrice > 0) {
          return q.effectiveQuotedPrice;
        }
      }
    }
    return null;
  }

  /// Corporate quotation unit price (cached quote lines, then merged catalog tile price).
  double? _resolveCorporateUnitPrice(PosProduct product) {
    if (!shouldUseCorporateQuotedCatalog) return null;
    final quoted = _quotedPriceForProduct(product);
    if (quoted != null && quoted > 0) return quoted;
    final display = catalogDisplayPriceFor(product);
    if (display > 0) return display;
    return null;
  }

  void _applyQuotedPriceToCartLine(PosProduct product, {bool isMainTab = false}) {
    final unitPrice = _resolveCorporateUnitPrice(product);
    if (unitPrice == null || unitPrice <= 0) return;
    if (product.isPriceEditable) {
      setServiceUnitPrice(product, unitPrice, isMainTab: isMainTab);
    } else {
      setLineUnitPrice(product, unitPrice, isMainTab: isMainTab);
    }
  }

  /// Applies corporate quotation prices to cart lines (quoted catalog + merged tile price).
  void applyCorporateQuotedPricesToActiveCart({bool isMainTab = false}) {
    if (!shouldUseCorporateQuotedCatalog) return;
    for (final item in _getActiveCart(isMainTab)) {
      final unitPrice = _resolveCorporateUnitPrice(item.product);
      if (unitPrice == null || unitPrice <= 0) continue;
      if (item.product.isPriceEditable) {
        setServiceUnitPrice(item.product, unitPrice, isMainTab: isMainTab);
      } else {
        setLineUnitPrice(item.product, unitPrice, isMainTab: isMainTab);
      }
    }
  }

  /// Corporate flows → cashier corporate products API + branch SQLite merge.
  Future<void> fetchProducts({
    String? departmentId,
    String? departmentName,
    bool forceRefresh = false,
  }) async {
    _lastFetchedDepartmentId = departmentId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await sessionService.getUser();
      if (user == null || user.workshopId == null) {
        throw Exception('Authentication information missing');
      }

      final branchId = user.branchId?.trim() ?? '';
      _catalogBranchId = branchId.isNotEmpty ? branchId : null;

      if (shouldUseCorporateQuotedCatalog) {
        final corpId = activeCorporateAccountId;
        if (corpId != null && corpId.isNotEmpty) {
          String? deptName;
          final editDept = (departmentId ?? _editDepartmentId)?.trim();
          if (editDept != null && editDept.isNotEmpty) {
            try {
              final depts = await catalogSync.loadDepartmentsLocal();
              for (final d in depts) {
                if (d.id == editDept) {
                  deptName = d.name;
                  break;
                }
              }
            } catch (_) {}
          }
          await _fetchCorporateFlowProducts(
            corporateAccountId: corpId,
            departmentId: departmentId,
            departmentIds: departmentId != null && departmentId.trim().isNotEmpty
                ? [departmentId.trim()]
                : null,
            departmentName: departmentName ?? deptName,
            forceRefresh: forceRefresh,
          );
          return;
        }
      }

      clearCorporateProductsCatalog();

      final local = await catalogSync.loadProductsLocal(
        departmentId: departmentId,
      );
      if (local != null && !local.isEmpty) {
        _applyCatalogSnapshot(local);
      } else {
        final branch = await _fetchBranchCatalogSnapshot(
          departmentId: departmentId,
        );
        if (branch != null && !branch.isEmpty) {
          _applyCatalogSnapshot(branch);
        } else {
          _allProducts = [];
          _apiCategories = [];
          _refreshCartProductReferences();
        }
      }
      _lastCatalogFetchWasCorporate = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// API → SQLite; reloads current product list from local cache.
  Future<CatalogSyncResult> syncCatalogFromApi() async {
    _isCatalogSyncing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await catalogSync.syncAll();
      if (result.success) {
        final local = await catalogSync.loadProductsLocal(
          departmentId: _lastFetchedDepartmentId,
        );
        if (local != null && !local.isEmpty) {
          _applyCatalogSnapshot(local);
        }
      } else {
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return CatalogSyncResult(success: false, message: e.toString());
    } finally {
      _isCatalogSyncing = false;
      notifyListeners();
    }
  }

  Future<void> refreshProductsAfterInvoice() async {
    try {
      final result = await catalogSync.syncProducts();
      if (!result.success) return;
      final local = await catalogSync.loadProductsLocal(
        departmentId: _lastFetchedDepartmentId,
      );
      if (local != null && !local.isEmpty) {
        _applyCatalogSnapshot(local);
        notifyListeners();
      }
    } catch (_) {}
  }

  final List<CartItem> _cartItems = [];
  String _activePromoCode = '';
  String? _activePromoCodeId;
  double _promoDiscount = 0.0;
  bool _isPromoPercent = false;
  double? _computedPromoDiscountAmount;
  PromoEligibility? _promoEligibility;
  String? _promoDiscountLabel;
  String? _promoAppliesToLabel;
  Set<String> _pinnedPromoLineIds = const {};
  bool _promoUserApplied = false;
  final Map<String, _DepartmentPromoState> _departmentPromoById = {};
  String? _promoContextDepartmentId;
  int _promoRevision = 0;
  int get promoRevision => _promoRevision;
  double _globalDiscount = 0.0;
  bool _isGlobalDiscountPercent = false;

  // Secondary cart state for main navigation tab
  final List<CartItem> _mainTabCartItems = [];
  String _mainTabActivePromoCode = '';
  String? _mainTabActivePromoCodeId;
  double _mainTabPromoDiscount = 0.0;
  bool _mainTabIsPromoPercent = false;
  double? _mainTabComputedPromoDiscountAmount;
  PromoEligibility? _mainTabPromoEligibility;
  String? _mainTabPromoDiscountLabel;
  String? _mainTabPromoAppliesToLabel;
  Set<String> _mainTabPinnedPromoLineIds = const {};
  bool _mainTabPromoUserApplied = false;
  final Map<String, _DepartmentPromoState> _mainTabDepartmentPromoById = {};
  Future<void> Function({required bool isMainTab})? _promoRevalidateHook;
  void Function({required bool isMainTab, String? departmentId})? _promoRemoveHook;
  String? _mainTabPromoContextDepartmentId;
  double _mainTabGlobalDiscount = 0.0;
  bool _mainTabIsGlobalDiscountPercent = false;

  String _selectedProductType = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<ProductCategory> _apiCategories = [];

  List<PosProduct> get allProducts => _allProducts;
  List<ProductCategory> get apiCategories => _apiCategories;
  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get mainTabCartItems => _mainTabCartItems;
  String get selectedProductType => _selectedProductType;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void setProductType(String type) {
    if (_selectedProductType != type) {
      _selectedProductType = type;
      _selectedCategory = 'All';
      notifyListeners();
    }
  }

  Future<void> initMainProductsTab() async {
    _selectedProductType = 'All';
    _selectedCategory = 'All';
    _searchQuery = '';
    notifyListeners();
    await fetchProducts(departmentId: null);
  }

  String get activePromoCode => _activePromoCode;
  String? get activePromoCodeId => _activePromoCodeId;
  double get promoDiscount => _promoDiscount;
  bool get isPromoPercent => _isPromoPercent;

  double get globalDiscount => _globalDiscount;
  bool get isGlobalDiscountPercent => _isGlobalDiscountPercent;

  // Context-aware getters for discounts
  double getActiveGlobalDiscount(bool isMainTab) => isMainTab ? _mainTabGlobalDiscount : _globalDiscount;
  bool getActiveIsGlobalDiscountPercent(bool isMainTab) => isMainTab ? _mainTabIsGlobalDiscountPercent : _isGlobalDiscountPercent;

  bool getActiveIsPromoPercent(bool isMainTab, {String? departmentId}) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.isNotEmpty) return promo.isPercent;
    return isMainTab ? _mainTabIsPromoPercent : _isPromoPercent;
  }

  double computeOrderLevelVat({
    required bool isMainTab,
    required double afterItemExclVat,
    required double globalDiscount,
    required double promoDiscount,
    String? departmentId,
  }) {
    return computePosOrderLevelVat(
      afterItemExclVat: afterItemExclVat,
      globalDiscount: globalDiscount,
      globalIsPercent: getActiveIsGlobalDiscountPercent(isMainTab),
      promoDiscount: promoDiscount,
      promoIsPercent: getActiveIsPromoPercent(isMainTab, departmentId: departmentId),
    );
  }
  String getActivePromoCode(bool isMainTab, {String? departmentId}) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    return promo.code;
  }

  String? getActivePromoCodeId(bool isMainTab, {String? departmentId}) =>
      _resolvePromoState(isMainTab, departmentId: departmentId).promoCodeId;

  double getActivePromoDiscount(bool isMainTab, {String? departmentId}) =>
      _resolvePromoState(isMainTab, departmentId: departmentId).discount;

  String? getActivePromoDiscountLabel(bool isMainTab, {String? departmentId}) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    final label = promo.discountLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    if (promo.code.isEmpty) return null;
    if (promo.isPercent) return '${promo.discount.toStringAsFixed(0)}% discount';
    return 'SAR ${promo.discount.toStringAsFixed(2)} off';
  }

  String? getActivePromoAppliesToLabel(bool isMainTab, {String? departmentId}) {
    final label = _resolvePromoState(isMainTab, departmentId: departmentId)
        .appliesToLabel
        ?.trim();
    if (label == null || label.isEmpty) return null;
    return label;
  }

  PromoEligibility? getActivePromoEligibility(bool isMainTab, {String? departmentId}) =>
      _resolvePromoState(isMainTab, departmentId: departmentId).eligibility;

  bool hasPinnedCategoryPromoLines(bool isMainTab, {String? departmentId}) =>
      _resolvePromoState(isMainTab, departmentId: departmentId)
          .pinnedEligibleLineIds
          .isNotEmpty;

  bool isPromoUserApplied(bool isMainTab) =>
      isMainTab ? _mainTabPromoUserApplied : _promoUserApplied;

  void markPromoUserApplied(bool isMainTab) {
    if (isMainTab) {
      _mainTabPromoUserApplied = true;
    } else {
      _promoUserApplied = true;
    }
  }

  /// Re-assert cashier-applied promo after dialog reopen / catalog refresh.
  void reaffirmAppliedPromoOnCart({
    required bool isMainTab,
    String? departmentId,
  }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return;

    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) {
      if (promo.pinnedEligibleLineIds.isEmpty) return;
      var computed = getTotalPromoDiscountValue(
        isMainTab,
        departmentId: departmentId,
      );
      if (computed <= 0.0001 &&
          promo.computedDiscountAmount != null &&
          promo.computedDiscountAmount! > 0.0001) {
        computed = promo.computedDiscountAmount!;
      }
      if (computed > 0.0001) {
        applyPromoCode(
          promo.code,
          promo.discount,
          promo.isPercent,
          isMainTab: isMainTab,
          promoCodeId: promo.promoCodeId,
          departmentId: departmentId,
          computedDiscountAmount: computed,
          eligibility: promo.eligibility,
          discountLabel: promo.discountLabel,
          appliesToLabel: promo.appliesToLabel,
        );
      }
      return;
    }

    _reconcilePinnedCategoryPromoLines(isMainTab: isMainTab);

    var computed = getTotalPromoDiscountValue(
      isMainTab,
      departmentId: departmentId,
    );
    if (computed <= 0.0001 &&
        promo.computedDiscountAmount != null &&
        promo.computedDiscountAmount! > 0.0001) {
      computed = promo.computedDiscountAmount!;
    }

    applyPromoCode(
      promo.code,
      promo.discount,
      promo.isPercent,
      isMainTab: isMainTab,
      promoCodeId: promo.promoCodeId,
      departmentId: departmentId,
      computedDiscountAmount:
          computed > 0.0001 ? computed : promo.computedDiscountAmount,
      eligibility: eligibility,
      discountLabel: promo.discountLabel,
      appliesToLabel: promo.appliesToLabel,
      refreshPinnedEligibleLines: true,
    );
  }

  List<String> get uniqueCategories {
    final cats = _allProducts
        .where((p) {
      if (_selectedProductType == 'All') return true;
      return _selectedProductType == 'Products'
          ? !p.isService
          : p.isService;
    })
        .map((p) => p.category)
        .toSet()
        .toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<PosProduct> get products {
    return _allProducts.where((p) {
      final matchesType =
          _selectedProductType == 'All' ||
              (_selectedProductType == 'Products' ? !p.isService : p.isService);
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesType && matchesCategory && matchesSearch;
    }).toList();
  }

  int get cartCount => getCartCount(false);

  // --- Backward Compatibility Getters (defaults to primary cart) ---
  double get subtotalExclVat => getSubtotalExclVat(false);
  double get totalIndividualDiscount => getTotalIndividualDiscount(false);
  double get totalGlobalDiscount => getTotalGlobalDiscountValue(false);
  double get totalPromoDiscount => getTotalPromoDiscountValue(false);
  double get totalTaxableAmount => getTotalTaxableAmountValue(false);
  double get totalTax => getTotalTaxValue(false);
  double get totalAmount => getTotalAmountValue(false);

  /// Gross amount VAT-exclusive (sum of unit price excl. VAT × qty).
  double getSubtotalGross(bool isMainTab) => _getActiveCart(isMainTab).fold(
    0,
        (sum, item) => sum + item.lineSubtotalExclVat,
  );

  double getSubtotalExclVat(bool isMainTab) => getSubtotalGross(isMainTab);

  /// Rule 3 (`entire_order`) — promo is a separate summary row before VAT.
  bool promoUsesEntireOrderRule(bool isMainTab, {String? departmentId}) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return false;
    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) return false;
    return eligibility.usesEntireOrderDiscount;
  }

  /// Line item strike/green price + badge amount — Rules 1/2 only (per-line promo).
  bool shouldShowLineItemPromoPriceCut(bool isMainTab, {String? departmentId}) =>
      !promoUsesEntireOrderRule(isMainTab, departmentId: departmentId);

  /// Separate promo discount + price-after-promo rows — Rule 3 only.
  bool shouldShowPromoSummaryRows(bool isMainTab, {String? departmentId}) =>
      promoUsesEntireOrderRule(isMainTab, departmentId: departmentId);

  /// Invoice gross excl. VAT row — Rules 1/2 subtract per-line promo from gross.
  double getDisplayGrossExclVat(
    bool isMainTab, {
    Iterable<CartItem>? items,
    String? departmentId,
  }) {
    final cart = items?.toList() ?? _getActiveCart(isMainTab);
    final rawGross = cart.fold<double>(
      0,
      (sum, item) => sum + item.lineSubtotalExclVat,
    );
    if (shouldShowPromoSummaryRows(isMainTab, departmentId: departmentId)) {
      return rawGross;
    }
    final linePromoTotal = cart.fold<double>(
      0,
      (sum, item) =>
          sum +
          getCartItemPromoDiscount(
            item,
            isMainTab,
            departmentId: departmentId,
          ),
    );
    if (linePromoTotal <= 0.0001) return rawGross;
    return (rawGross - linePromoTotal).clamp(0, double.infinity).toDouble();
  }

  double getTotalIndividualDiscount(bool isMainTab) =>
      _getActiveCart(isMainTab).fold(0, (sum, item) => sum + item.actualDiscountAmount);

  double getPriceAfterItemDiscounts(bool isMainTab) =>
      getSubtotalGross(isMainTab) - getTotalIndividualDiscount(isMainTab);

  double getTotalGlobalDiscountValue(bool isMainTab) {
    final baseForGlobal = getPriceAfterItemDiscounts(isMainTab);
    if (isMainTab) {
      if (_mainTabIsGlobalDiscountPercent) return baseForGlobal * (_mainTabGlobalDiscount / 100);
      return _mainTabGlobalDiscount;
    } else {
      if (_isGlobalDiscountPercent) return baseForGlobal * (_globalDiscount / 100);
      return _globalDiscount;
    }
  }

  double getPriceAfterJobDiscount(bool isMainTab) =>
      getPriceAfterItemDiscounts(isMainTab) - getTotalGlobalDiscountValue(isMainTab);

  /// VAT-inclusive cart total after job/global discounts, before promo.
  double getOrderTotalInclVatAfterJobDiscount(bool isMainTab) {
    final afterJob = getPriceAfterJobDiscount(isMainTab);
    final globalDisc = getTotalGlobalDiscountValue(isMainTab);
    final double vat;
    if (globalDisc <= 0.0001) {
      vat = _getActiveCart(isMainTab).fold(
        0.0,
        (sum, item) => sum + item.lineVatAmount,
      );
    } else {
      final afterItem = _getActiveCart(isMainTab).fold(
        0.0,
        (sum, item) => sum + item.totalPriceExclVat,
      );
      vat = computeOrderLevelVat(
        isMainTab: isMainTab,
        afterItemExclVat: afterItem,
        globalDiscount: globalDisc,
        promoDiscount: 0,
      );
    }
    return afterJob + vat;
  }

  bool _promoHasPinnedCoverage(
    _DepartmentPromoState promo,
    Iterable<CartItem> cart,
  ) {
    if (promo.pinnedEligibleLineIds.isEmpty) return false;
    for (final item in cart) {
      final lineId = item.product.id.trim();
      if (lineId.isNotEmpty && promo.pinnedEligibleLineIds.contains(lineId)) {
        return true;
      }
    }
    return false;
  }

  double _pinnedEligibleCartBase(
    _DepartmentPromoState promo,
    Iterable<CartItem> cart,
  ) {
    var total = 0.0;
    for (final item in cart) {
      final lineId = item.product.id.trim();
      if (lineId.isNotEmpty && promo.pinnedEligibleLineIds.contains(lineId)) {
        total += item.totalPriceExclVat;
      }
    }
    return total;
  }

  bool _promoCoversCartItem(CartItem item, _DepartmentPromoState promo) {
    final lineId = item.product.id.trim();
    if (lineId.isNotEmpty && promo.pinnedEligibleLineIds.contains(lineId)) {
      return true;
    }
    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) return false;
    return eligibility.isCartItemEligible(item);
  }

  bool _promoCanApplyToCart(_DepartmentPromoState promo, Iterable<CartItem> cart) {
    if (_promoHasPinnedCoverage(promo, cart)) return true;
    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) return false;
    return eligibility.canApplyToCart(cart);
  }

  double _promoEligibleCartBase(
    _DepartmentPromoState promo,
    Iterable<CartItem> cart,
  ) {
    if (promo.pinnedEligibleLineIds.isNotEmpty) {
      final pinnedBase = _pinnedEligibleCartBase(promo, cart);
      if (pinnedBase > 0.0001) return pinnedBase;
    }
    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) return 0;
    return eligibility.eligibleCartBase(cart);
  }

  PromoEligibility _preferRetainedPromoEligibility(
    PromoEligibility existing,
    PromoEligibility incoming,
  ) {
    if (existing.hasCategorySelection && !incoming.hasCategorySelection) {
      return existing;
    }
    if (existing.hasSelectedScope && !incoming.hasSelectedScope) {
      return existing;
    }
    if (existing.productIds.isNotEmpty &&
        incoming.productIds.isEmpty &&
        incoming.productScope == 'all') {
      return existing;
    }
    if (existing.serviceIds.isNotEmpty &&
        incoming.serviceIds.isEmpty &&
        incoming.serviceScope == 'all') {
      return existing;
    }
    return incoming;
  }

  Set<String> _capturePinnedEligibleLineIds(
    PromoEligibility eligibility,
    bool isMainTab,
  ) {
    if (!eligibility.hasCategorySelection) return const {};
    final ids = <String>{};
    for (final item in _getActiveCart(isMainTab)) {
      if (!eligibility.isCartItemEligible(item)) continue;
      final lineId = item.product.id.trim();
      if (lineId.isEmpty) continue;
      ids.add(lineId);
      _resolveCategoryIdFromApiCategories(item.product);
      if ((item.product.categoryId == null ||
              item.product.categoryId!.trim().isEmpty) &&
          eligibility.productCategoryIds.length == 1) {
        item.product.categoryId = eligibility.productCategoryIds.first;
      }
    }
    return ids;
  }

  Set<String> _resolvePinnedEligibleLineIds({
    required PromoEligibility? passedEligibility,
    required PromoEligibility? resolvedEligibility,
    required _DepartmentPromoState existing,
    required bool sameCode,
    required bool isMainTab,
    bool refreshPinnedLines = false,
  }) {
    if (sameCode && existing.pinnedEligibleLineIds.isNotEmpty) {
      if (!refreshPinnedLines) return existing.pinnedEligibleLineIds;
    }
    if (refreshPinnedLines &&
        resolvedEligibility != null &&
        resolvedEligibility.isKnown &&
        resolvedEligibility.hasCategorySelection) {
      final captured = _capturePinnedEligibleLineIds(resolvedEligibility, isMainTab);
      if (captured.isNotEmpty) return captured;
    }
    if (passedEligibility != null &&
        passedEligibility.isKnown &&
        passedEligibility.hasCategorySelection) {
      final captured = _capturePinnedEligibleLineIds(passedEligibility, isMainTab);
      if (captured.isNotEmpty) return captured;
    }
    if (sameCode && existing.pinnedEligibleLineIds.isNotEmpty) {
      return existing.pinnedEligibleLineIds;
    }
    if (resolvedEligibility != null &&
        resolvedEligibility.isKnown &&
        resolvedEligibility.hasCategorySelection) {
      final captured =
          _capturePinnedEligibleLineIds(resolvedEligibility, isMainTab);
      if (captured.isNotEmpty) return captured;
    }
    return const {};
  }

  double _allocatePinnedLinePromoDiscount({
    required CartItem item,
    required Iterable<CartItem> cart,
    required _DepartmentPromoState promo,
    required double totalPromoDiscount,
  }) {
    if (!_promoCoversCartItem(item, promo)) return 0;
    final eligibleBase = _promoEligibleCartBase(promo, cart);
    if (eligibleBase <= 0.0001 || totalPromoDiscount <= 0.0001) return 0;
    final lineBase = item.totalPriceExclVat;
    if (lineBase <= 0.0001) return 0;
    return (totalPromoDiscount * (lineBase / eligibleBase))
        .clamp(0, lineBase)
        .toDouble();
  }

  double getTotalPromoDiscountValue(bool isMainTab, {String? departmentId}) {
    final baseForPromo = getPriceAfterJobDiscount(isMainTab);
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.isEmpty) return 0;

    final cart = _getActiveCart(isMainTab);
    var amount = 0.0;
    final eligibility = promo.eligibility;
    if (_promoCanApplyToCart(promo, cart)) {
      if (promo.computedDiscountAmount != null) {
        amount = promo.computedDiscountAmount!
            .clamp(0, baseForPromo)
            .toDouble();
      }
      if (amount <= 0.0001) {
        if (eligibility != null &&
            eligibility.isKnown &&
            eligibility.usesEntireOrderDiscount) {
          if (promo.isPercent) {
            if (eligibility.usesPerEligibleLineDiscountForPromo(
              isPercent: promo.isPercent,
            )) {
              for (final item in cart) {
                amount += _computeCartItemPromoDiscount(item, promo, isMainTab);
              }
            } else {
              final eligibleBase = _promoEligibleCartBase(promo, cart);
              amount = eligibleBase * (promo.discount / 100);
            }
          } else {
            for (final item in cart) {
              amount += _computeCartItemPromoDiscount(item, promo, isMainTab);
            }
          }
        } else {
          for (final item in cart) {
            amount += _computeCartItemPromoDiscount(item, promo, isMainTab);
          }
        }
      }
    }

    if (amount <= 0.0001) {
      amount = _fallbackPromoDiscountAmount(
        promo,
        baseForPromo,
        cart: cart,
      );
    }
    return amount.clamp(0, baseForPromo).toDouble();
  }

  /// Server amount, then %/fixed — scoped to eligible lines when rules are known.
  double _fallbackPromoDiscountAmount(
    _DepartmentPromoState promo,
    double baseForPromo, {
    Iterable<CartItem>? cart,
  }) {
    if (promo.computedDiscountAmount != null &&
        promo.computedDiscountAmount! > 0.0001) {
      return promo.computedDiscountAmount!.clamp(0, baseForPromo).toDouble();
    }
    final eligibility = promo.eligibility;
    if (promo.isPercent) {
      if (cart != null) {
        final eligibleBase = _promoEligibleCartBase(promo, cart);
        if (eligibleBase > 0.0001) {
          return (eligibleBase * promo.discount / 100)
              .clamp(0, baseForPromo)
              .toDouble();
        }
        if (eligibility != null && eligibility.isKnown) return 0;
      }
      return (baseForPromo * (promo.discount / 100)).clamp(0, baseForPromo).toDouble();
    }
    return promo.discount.clamp(0, baseForPromo).toDouble();
  }

  double getPromoDiscountForBase(
      double baseForPromo, {
        bool isMainTab = false,
        String? departmentId,
      }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.isEmpty) return 0;

    if (promo.eligibility != null && promo.eligibility!.isKnown) {
      final cart = _getActiveCart(isMainTab);
      var sum = 0.0;
      for (final line in cart) {
        if (departmentId != null &&
            (line.product.departmentId ?? '') != departmentId) {
          continue;
        }
        sum += _computeCartItemPromoDiscount(line, promo, isMainTab);
      }
      return sum.clamp(0, baseForPromo).toDouble();
    }

    final totalBase = getPriceAfterJobDiscount(isMainTab);
    if (promo.code.isNotEmpty) {
      if (promo.computedDiscountAmount != null) {
        if (totalBase <= 0.0001) return 0;
        final ratio = (baseForPromo / totalBase).clamp(0.0, 1.0);
        return (promo.computedDiscountAmount! * ratio)
            .clamp(0, baseForPromo)
            .toDouble();
      }
      final raw =
          promo.isPercent ? baseForPromo * (promo.discount / 100) : promo.discount;
      return raw.clamp(0, baseForPromo).toDouble();
    }
    final computed = isMainTab
        ? _mainTabComputedPromoDiscountAmount
        : _computedPromoDiscountAmount;
    if (computed != null && totalBase > 0.0001) {
      final ratio = (baseForPromo / totalBase).clamp(0.0, 1.0);
      return (computed * ratio).clamp(0, baseForPromo).toDouble();
    }
    final raw = getActiveIsPromoPercent(isMainTab, departmentId: departmentId)
        ? baseForPromo * ((isMainTab ? _mainTabPromoDiscount : _promoDiscount) / 100)
        : (isMainTab ? _mainTabPromoDiscount : _promoDiscount);
    return raw.clamp(0, baseForPromo).toDouble();
  }

  /// Line ex-VAT after proportional job/global discount (qty-aware).
  double _lineAmountAfterJobDiscount(CartItem item, bool isMainTab) {
    final cart = _getActiveCart(isMainTab);
    final cartTotal = cart.fold<double>(
      0.0,
      (sum, line) => sum + line.totalPriceExclVat,
    );
    if (cartTotal <= 0.0001) return item.totalPriceExclVat;
    final afterJob = getPriceAfterJobDiscount(isMainTab);
    return (item.totalPriceExclVat * (afterJob / cartTotal))
        .clamp(0, item.totalPriceExclVat)
        .toDouble();
  }

  double _computeCartItemPromoDiscount(
    CartItem item,
    _DepartmentPromoState promo,
    bool isMainTab,
  ) {
    final cart = _getActiveCart(isMainTab);
    if (!_promoCanApplyToCart(promo, cart)) return 0;
    if (!_promoCoversCartItem(item, promo)) return 0;

    final lineBase = _lineAmountAfterJobDiscount(item, isMainTab);
    if (lineBase <= 0.0001) return 0;

    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) {
      if (promo.isPercent) {
        return (lineBase * promo.discount / 100)
            .clamp(0, lineBase)
            .toDouble();
      }
      return (promo.discount * item.quantity).clamp(0, lineBase).toDouble();
    }

    // Mirrors backend promoUsesPerEligibleLineDiscount: promos without a
    // "selected" scope (e.g. all products/services) are a single flat discount
    // on the whole eligible base — distribute proportionally per line instead
    // of applying the full amount to every line.
    if (!eligibility.usesPerEligibleLineDiscountForPromo(
      isPercent: promo.isPercent,
    )) {
      final eligibleBase = _promoEligibleCartBase(promo, cart);
      if (eligibleBase <= 0.0001) return 0;
      final rawTotal = promo.computedDiscountAmount ??
          (promo.isPercent
              ? eligibleBase * (promo.discount / 100)
              : promo.discount);
      final flatTotal = rawTotal.clamp(0.0, eligibleBase).toDouble();
      if (flatTotal <= 0.0001) return 0;
      if (eligibility.isCartItemEligible(item)) {
        return eligibility.linePromoDiscount(
          item: item,
          cart: cart,
          totalPromoDiscount: flatTotal,
        );
      }
      return _allocatePinnedLinePromoDiscount(
        item: item,
        cart: cart,
        promo: promo,
        totalPromoDiscount: flatTotal,
      );
    }

    if (eligibility.usesEntireOrderDiscount) {
      if (promo.isPercent) {
        if (!_promoCoversCartItem(item, promo)) return 0;
        if (eligibility.usesPerEligibleLineDiscountForPromo(
          isPercent: promo.isPercent,
        )) {
          return (lineBase * promo.discount / 100)
              .clamp(0, lineBase)
              .toDouble();
        }
        final eligibleBase = _promoEligibleCartBase(promo, cart);
        final totalPromo = promo.computedDiscountAmount ??
            (eligibleBase * (promo.discount / 100));
        if (eligibility.isCartItemEligible(item)) {
          return eligibility.linePromoDiscount(
            item: item,
            cart: cart,
            totalPromoDiscount: totalPromo.clamp(0, eligibleBase).toDouble(),
          );
        }
        return _allocatePinnedLinePromoDiscount(
          item: item,
          cart: cart,
          promo: promo,
          totalPromoDiscount: totalPromo.clamp(0, eligibleBase).toDouble(),
        );
      }
      if (!_promoCoversCartItem(item, promo)) return 0;
      return (promo.discount * item.quantity).clamp(0, lineBase).toDouble();
    }

    if (!_promoCoversCartItem(item, promo)) return 0;

    if (promo.isPercent) {
      return (lineBase * promo.discount / 100)
          .clamp(0, lineBase)
          .toDouble();
    }
    return (promo.discount * item.quantity).clamp(0, lineBase).toDouble();
  }

  String _cartItemPromoKey(CartItem item) => item.product.id.trim();

  double _provisionalPromoLineCandidate(
    CartItem item,
    _DepartmentPromoState promo,
    bool isMainTab,
  ) {
    final lineBase = _lineAmountAfterJobDiscount(item, isMainTab);
    if (lineBase <= 0.0001) return 0;
    if (promo.isPercent) {
      return (lineBase * promo.discount / 100).clamp(0.0, lineBase).toDouble();
    }
    return (promo.discount * item.quantity).clamp(0.0, lineBase).toDouble();
  }

  Map<String, double> _resolveProvisionalPromoLineDiscounts(
    bool isMainTab, {
    String? departmentId,
  }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return const {};
    if (promo.pinnedEligibleLineIds.isNotEmpty) return const {};
    if (promo.eligibility != null && promo.eligibility!.isKnown) {
      return const {};
    }

    final totalPromo = promo.computedDiscountAmount ??
        getTotalPromoDiscountValue(isMainTab, departmentId: departmentId);
    if (totalPromo <= 0.0001) return const {};

    final cart = _getActiveCart(isMainTab);
    final candidates = <CartItem, double>{};
    for (final item in cart) {
      if (departmentId != null &&
          departmentId.trim().isNotEmpty &&
          (item.product.departmentId ?? '') != departmentId) {
        continue;
      }
      final candidate = _provisionalPromoLineCandidate(item, promo, isMainTab);
      if (candidate > 0.0001) {
        candidates[item] = candidate;
      }
    }
    if (candidates.isEmpty) return const {};

    final sorted = candidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var remaining = totalPromo;
    final picked = <String, double>{};
    for (final entry in sorted) {
      if (remaining <= 0.0001) break;
      if (entry.value <= remaining + 0.05) {
        picked[_cartItemPromoKey(entry.key)] = entry.value;
        remaining -= entry.value;
      }
    }
    if (remaining.abs() <= 0.05) return picked;

    final sumCandidates =
        candidates.values.fold<double>(0, (sum, value) => sum + value);
    if (sumCandidates <= 0.0001) return const {};
    for (final entry in candidates.entries) {
      picked[_cartItemPromoKey(entry.key)] =
          (totalPromo * (entry.value / sumCandidates))
              .clamp(0.0, entry.value)
              .toDouble();
    }
    return picked;
  }

  double _provisionalCartItemPromoDiscount(
    CartItem item,
    bool isMainTab, {
    String? departmentId,
  }) {
    final provisional = _resolveProvisionalPromoLineDiscounts(
      isMainTab,
      departmentId: departmentId,
    );
    return provisional[_cartItemPromoKey(item)] ?? 0;
  }

  /// Whether [item] is covered by the active promo (product/service scope rules).
  bool isCartItemPromoEligible(
    CartItem item,
    bool isMainTab, {
    String? departmentId,
  }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return false;
    final lineId = _cartItemPromoKey(item);
    if (lineId.isNotEmpty && promo.pinnedEligibleLineIds.contains(lineId)) {
      return true;
    }
    final eligibility = promo.eligibility;
    if (eligibility != null && eligibility.isKnown) {
      return _promoCoversCartItem(item, promo);
    }
    return _provisionalCartItemPromoDiscount(
          item,
          isMainTab,
          departmentId: departmentId,
        ) >
        0.0001;
  }

  /// Promo discount for one cart line — scales with qty via [CartItem.totalPriceExclVat].
  double getCartItemPromoDiscount(
    CartItem item,
    bool isMainTab, {
    String? departmentId,
  }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return 0;

    if (promo.pinnedEligibleLineIds.isNotEmpty &&
        _promoCoversCartItem(item, promo)) {
      return _computeCartItemPromoDiscount(item, promo, isMainTab);
    }

    if (promo.eligibility != null && promo.eligibility!.isKnown) {
      final line = _computeCartItemPromoDiscount(item, promo, isMainTab);
      if (line > 0.0001) return line;

      final totalPromo = getTotalPromoDiscountValue(
        isMainTab,
        departmentId: departmentId,
      );
      if (totalPromo <= 0.0001) return 0;
      final eligibility = promo.eligibility!;
      if (!_promoCoversCartItem(item, promo)) return 0;
      if (eligibility.usesEntireOrderDiscount) {
        if (eligibility.isCartItemEligible(item)) {
          return eligibility.linePromoDiscount(
            item: item,
            cart: _getActiveCart(isMainTab),
            totalPromoDiscount: totalPromo,
          );
        }
        return _allocatePinnedLinePromoDiscount(
          item: item,
          cart: _getActiveCart(isMainTab),
          promo: promo,
          totalPromoDiscount: totalPromo,
        );
      }
      final cart = _getActiveCart(isMainTab);
      if (eligibility.isCartItemEligible(item)) {
        return eligibility.linePromoDiscount(
          item: item,
          cart: cart,
          totalPromoDiscount: totalPromo,
        );
      }
      return _allocatePinnedLinePromoDiscount(
        item: item,
        cart: cart,
        promo: promo,
        totalPromoDiscount: totalPromo,
      );
    }
    return _provisionalCartItemPromoDiscount(
      item,
      isMainTab,
      departmentId: departmentId,
    );
  }

  double getTotalTaxableAmountValue(bool isMainTab) =>
      getPriceAfterJobDiscount(isMainTab) - getTotalPromoDiscountValue(isMainTab);

  double getTotalTaxValue(bool isMainTab) {
    final hasOrderLevelDiscount =
        getTotalGlobalDiscountValue(isMainTab) > 0.0001 ||
            getTotalPromoDiscountValue(isMainTab) > 0.0001;
    if (!hasOrderLevelDiscount) {
      return _getActiveCart(isMainTab).fold(
        0.0,
        (sum, item) => sum + item.lineVatAmount,
      );
    }
    final afterItem = _getActiveCart(isMainTab).fold(
      0.0,
      (sum, item) => sum + item.totalPriceExclVat,
    );
    return computeOrderLevelVat(
      isMainTab: isMainTab,
      afterItemExclVat: afterItem,
      globalDiscount: getTotalGlobalDiscountValue(isMainTab),
      promoDiscount: getTotalPromoDiscountValue(isMainTab),
    );
  }

  double getTotalAmountValue(bool isMainTab) =>
      getTotalTaxableAmountValue(isMainTab) + getTotalTaxValue(isMainTab);

  int getCartCount(bool isMainTab) => _getActiveCart(isMainTab).fold(
    0,
        (sum, item) => sum + (item.quantity >= 1 ? item.quantity.toInt() : 1),
  );

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- Cart Management Helpers ---
  List<CartItem> _getActiveCart(bool isMainTab) => isMainTab ? _mainTabCartItems : _cartItems;

  /// After catalog reload, cart lines may still reference old [PosProduct] instances with stale prices.
  void _refreshCartProductReferences() {
    for (final item in _cartItems) {
      final stale = item.product;
      final fresh = _findCatalogProductForCartLine(stale);
      if (fresh != null) {
        _mergeCatalogFieldsOntoProduct(fresh, stale);
        _resolveCategoryIdFromApiCategories(fresh);
        item.product = fresh;
      } else {
        _resolveCategoryIdFromApiCategories(stale);
      }
    }
    for (final item in _mainTabCartItems) {
      final stale = item.product;
      final fresh = _findCatalogProductForCartLine(stale);
      if (fresh != null) {
        _mergeCatalogFieldsOntoProduct(fresh, stale);
        _resolveCategoryIdFromApiCategories(fresh);
        item.product = fresh;
      } else {
        _resolveCategoryIdFromApiCategories(stale);
      }
    }
    if (shouldUseCorporateQuotedCatalog) {
      applyCorporateQuotedPricesToActiveCart(isMainTab: false);
      applyCorporateQuotedPricesToActiveCart(isMainTab: true);
    }
    _reconcilePinnedCategoryPromoLines(isMainTab: false);
    _reconcilePinnedCategoryPromoLines(isMainTab: true);
  }

  /// Re-attach category promo lines after catalog reload using pinned line ids.
  void _reconcilePinnedCategoryPromoLines({required bool isMainTab}) {
    final promo = _resolvePromoState(isMainTab);
    if (promo.code.trim().isEmpty || promo.pinnedEligibleLineIds.isEmpty) {
      return;
    }
    final eligibility = promo.eligibility;
    if (eligibility == null || !eligibility.isKnown) return;
    for (final item in _getActiveCart(isMainTab)) {
      final lineId = item.product.id.trim();
      if (!promo.pinnedEligibleLineIds.contains(lineId)) continue;
      _resolveCategoryIdFromApiCategories(item.product);
      if ((item.product.categoryId == null ||
              item.product.categoryId!.trim().isEmpty) &&
          eligibility.productCategoryIds.length == 1) {
        item.product.categoryId = eligibility.productCategoryIds.first;
      }
    }
  }

  void _mergeCatalogFieldsOntoProduct(PosProduct target, PosProduct source) {
    if ((target.categoryId == null || target.categoryId!.trim().isEmpty) &&
        source.categoryId != null &&
        source.categoryId!.trim().isNotEmpty) {
      target.categoryId = source.categoryId;
    }
    if ((target.categoryName == null || target.categoryName!.trim().isEmpty) &&
        source.categoryName != null &&
        source.categoryName!.trim().isNotEmpty) {
      target.categoryName = source.categoryName;
    }
    if ((target.subCategoryName == null ||
            target.subCategoryName!.trim().isEmpty) &&
        source.subCategoryName != null &&
        source.subCategoryName!.trim().isNotEmpty) {
      target.subCategoryName = source.subCategoryName;
    }
  }

  void _resolveCategoryIdFromApiCategories(PosProduct product) {
    if (product.categoryId != null && product.categoryId!.trim().isNotEmpty) {
      return;
    }
    final name = product.categoryName?.trim().toLowerCase();
    if (name == null || name.isEmpty) return;
    for (final cat in _apiCategories) {
      if (cat.name.trim().toLowerCase() == name) {
        product.categoryId = cat.id;
        return;
      }
      for (final sub in cat.subCategories) {
        if (sub.name.trim().toLowerCase() == name) {
          product.categoryId = cat.id;
          return;
        }
      }
    }
  }

  PosProduct? _findCatalogProductForCartLine(PosProduct lineProduct) {
    for (final p in _allProducts) {
      if (_isSameCartProduct(lineProduct, p)) return p;
    }
    return null;
  }

  bool _isSameCartProduct(PosProduct a, PosProduct b) {
    return a.id == b.id &&
        a.isServiceType == b.isServiceType &&
        (a.departmentId ?? '') == (b.departmentId ?? '');
  }

  String? addToCart(PosProduct product, {double qty = 1.0, bool isMainTab = false}) {
    // Services always use whole units (allowDecimalQty stays false in catalog).
    if (product.isService || !product.allowDecimalQty) {
      if (qty % 1 != 0) qty = qty.floorToDouble();
    }
    final activeCart = _getActiveCart(isMainTab);
    final existingIndex = activeCart.indexWhere(
          (item) => _isSameCartProduct(item.product, product),
    );
    if (existingIndex != -1) {
      if (product.isServiceQtyLocked) {
        return 'Services can only be booked once per order.';
      }
      if (product.cartQtyExceedsStock(activeCart[existingIndex].quantity + qty)) {
        return 'Cannot exceed available stock limit (${product.stock})';
      }
      activeCart[existingIndex].quantity += qty;
    } else {
      if (product.cartQtyExceedsStock(qty)) {
        return 'Cannot exceed available stock limit (${product.stock})';
      }
      activeCart.add(
        CartItem(product: product, quantity: qty, isDiscountPercent: false),
      );
    }
    _applyQuotedPriceToCartLine(product, isMainTab: isMainTab);
    notifyListeners();
    _maybeRevalidatePromo(isMainTab);
    return null;
  }

  void removeFromCart(
    PosProduct product, {
    bool isMainTab = false,
    bool andClearPromo = false,
  }) {
    _getActiveCart(isMainTab).removeWhere(
          (item) => _isSameCartProduct(item.product, product),
    );
    if (andClearPromo) {
      _clearAllPromos(isMainTab);
    } else {
      _maybeRevalidatePromo(isMainTab);
    }
    notifyListeners();
  }

  String? updateQuantity(PosProduct product, double delta, {bool isMainTab = false}) {
    if (product.isService || !product.allowDecimalQty) {
      if (delta % 1 != 0) delta = delta.floorToDouble();
    }
    final activeCart = _getActiveCart(isMainTab);
    final index = activeCart.indexWhere(
          (item) => _isSameCartProduct(item.product, product),
    );
    if (index != -1) {
      if (product.isServiceQtyLocked && delta > 0) {
        return 'Services can only be booked once per order.';
      }
      if (product.cartQtyExceedsStock(activeCart[index].quantity + delta)) {
        return 'Cannot exceed available stock limit (${product.stock})';
      }
      activeCart[index].quantity += delta;
      if (activeCart[index].quantity <= 0) {
        activeCart.removeAt(index);
      }
      notifyListeners();
      _maybeRevalidatePromo(isMainTab);
    }
    return null;
  }

  String? setSpecificQuantity(PosProduct product, double qty, {bool isMainTab = false}) {
    if (qty <= 0) {
      removeFromCart(product, isMainTab: isMainTab);
      return null;
    }
    if (product.isService || !product.allowDecimalQty) {
      if (qty % 1 != 0) qty = qty.floorToDouble();
    }

    if (product.isServiceQtyLocked && qty > 1) {
      return 'Services can only be booked once per order.';
    }

    if (product.cartQtyExceedsStock(qty)) {
      return 'Cannot exceed available stock limit (${product.stock})';
    }

    final activeCart = _getActiveCart(isMainTab);
    final index = activeCart.indexWhere(
          (item) => _isSameCartProduct(item.product, product),
    );
    if (index != -1) {
      activeCart[index].quantity = qty;
      notifyListeners();
      _maybeRevalidatePromo(isMainTab);
      return null;
    } else {
      return addToCart(product, qty: qty, isMainTab: isMainTab);
    }
  }

  void setIndividualDiscount(
      PosProduct product,
      double discount,
      bool isPercent,
      {bool isMainTab = false}
      ) {
    final activeCart = _getActiveCart(isMainTab);
    final index = activeCart.indexWhere(
          (item) => _isSameCartProduct(item.product, product),
    );
    if (index != -1) {
      activeCart[index].discount = discount;
      activeCart[index].isDiscountPercent = isPercent;
      notifyListeners();
      _maybeRevalidatePromo(isMainTab);
    }
  }

  /// VAT-inclusive unit price sent to walk-in / job pricing APIs.
  double? _cartLineUnitPriceForApi(CartItem item) {
    if (item.product.isPriceEditable) {
      final u = item.serviceUnitPrice;
      if (u != null && u > 0) return u;
      return null;
    }

    final override = item.lineUnitPriceOverride;
    if (override != null && override > 0) return override;

    if (item.product.isService) {
      return _resolveCorporateUnitPrice(item.product);
    }

    if (shouldUseCorporateQuotedCatalog) {
      return _resolveCorporateUnitPrice(item.product);
    }
    return null;
  }

  /// Per-unit price override for corporate quotation lines (products & non-editable services).
  void setLineUnitPrice(
    PosProduct product,
    double? unitPrice, {
    bool isMainTab = false,
  }) {
    final activeCart = _getActiveCart(isMainTab);
    final index = activeCart.indexWhere(
      (item) => _isSameCartProduct(item.product, product),
    );
    if (index == -1) return;
    if (unitPrice == null || unitPrice <= 0) {
      activeCart[index].lineUnitPriceOverride = null;
    } else {
      activeCart[index].lineUnitPriceOverride = unitPrice;
    }
    notifyListeners();
  }

  /// Per-unit price override for price-editable catalog lines (service or product).
  void setServiceUnitPrice(
      PosProduct product,
      double? unitPrice, {
        bool isMainTab = false,
      }) {
    if (!product.isPriceEditable) return;
    final activeCart = _getActiveCart(isMainTab);
    final index = activeCart.indexWhere(
          (item) => _isSameCartProduct(item.product, product),
    );
    if (index == -1) return;
    if (unitPrice == null || unitPrice <= 0) {
      activeCart[index].serviceUnitPrice = null;
    } else {
      activeCart[index].serviceUnitPrice = unitPrice;
    }
    notifyListeners();
  }

  /// VAT-inclusive unit price for **this cart / order only**. Does not call the network
  /// (no catalog PATCH, no job pricing sync). Persist when the user saves the invoice / walk-in.
  void applyLocalEditableServiceUnitPrice(
    PosProduct product,
    double unitPriceVatInclusive, {
    bool isMainTab = false,
  }) {
    if (!product.isPriceEditable) return;
    if (unitPriceVatInclusive <= 0 || !unitPriceVatInclusive.isFinite) return;

    final activeCart = _getActiveCart(isMainTab);
    var index = activeCart.indexWhere(
      (item) => _isSameCartProduct(item.product, product),
    );
    if (index == -1) {
      activeCart.add(
        CartItem(
          product: product,
          quantity: 1.0,
          isDiscountPercent: false,
        ),
      );
      index = activeCart.length - 1;
    }
    activeCart[index].serviceUnitPrice = unitPriceVatInclusive;
    notifyListeners();
  }

  void setGlobalDiscount(double value, bool isPercent, {bool isMainTab = false}) {
    if (isMainTab) {
      _mainTabGlobalDiscount = value;
      _mainTabIsGlobalDiscountPercent = isPercent;
    } else {
      _globalDiscount = value;
      _isGlobalDiscountPercent = isPercent;
    }
    notifyListeners();
    _maybeRevalidatePromo(isMainTab);
  }

  void clearCart({bool isMainTab = false}) {
    _getActiveCart(isMainTab).clear();
    clearPromoCode(isMainTab: isMainTab, userInitiated: true);
    if (isMainTab) {
      _mainTabPromoContextDepartmentId = null;
      _mainTabGlobalDiscount = 0.0;
      _mainTabIsGlobalDiscountPercent = false;
      _mainTabGlobalDiscountTextController.clear();
    } else {
      _promoContextDepartmentId = null;
      _globalDiscount = 0.0;
      _isGlobalDiscountPercent = false;
      _globalDiscountTextController.clear();
    }
    notifyListeners();
  }

  void removeDepartmentItemsFromCart(
      String departmentId, {
        bool isMainTab = false,
      }) {
    final depId = departmentId.trim();
    if (depId.isEmpty) return;
    final activeCart = _getActiveCart(isMainTab);
    activeCart.removeWhere((item) => (item.product.departmentId ?? '') == depId);
    if (isMainTab) {
      _mainTabDepartmentPromoById.remove(depId);
      if (_mainTabPromoContextDepartmentId == depId) {
        _mainTabPromoContextDepartmentId = null;
      }
    } else {
      _departmentPromoById.remove(depId);
      if (_promoContextDepartmentId == depId) {
        _promoContextDepartmentId = null;
      }
    }
    notifyListeners();
  }

  void setPromoContextDepartment(String? departmentId, {bool isMainTab = false}) {
    if (isMainTab) {
      _mainTabPromoContextDepartmentId = departmentId;
    } else {
      _promoContextDepartmentId = departmentId;
    }
  }

  void setPromoRevalidateHook(
    Future<void> Function({required bool isMainTab}) hook,
  ) {
    _promoRevalidateHook = hook;
  }

  void setPromoRemoveHook(
    void Function({required bool isMainTab, String? departmentId}) hook,
  ) {
    _promoRemoveHook = hook;
  }

  String? getPromoContextDepartmentId(bool isMainTab) =>
      _getPromoContextDepartmentId(isMainTab);

  List<String> activePromoDepartmentIds(bool isMainTab) {
    final map = isMainTab ? _mainTabDepartmentPromoById : _departmentPromoById;
    return map.entries
        .where((e) => e.value.code.trim().isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  bool hasActivePromo(bool isMainTab) {
    return _resolvePromoState(isMainTab).code.trim().isNotEmpty;
  }

  void _maybeRevalidatePromo(bool isMainTab) {
    if (!hasActivePromo(isMainTab)) return;
    _autoClearPromoIfInapplicable(isMainTab);
    // Never background-revalidate: it can overwrite a user-applied promo.
  }

  /// Drops active promo when the cart no longer contains any eligible lines.
  void _autoClearPromoIfInapplicable(bool isMainTab) {
    final cart = _getActiveCart(isMainTab);
    if (cart.isEmpty) {
      _clearAllPromos(isMainTab);
    }
    // Keep applied promos until the user explicitly removes them.
  }

  void _clearAllPromos(bool isMainTab) {
    if (!hasActivePromo(isMainTab)) return;
    clearPromoCode(isMainTab: isMainTab, userInitiated: true);
    _promoRemoveHook?.call(isMainTab: isMainTab, departmentId: null);
  }

  void _dropPromo(bool isMainTab, {String? departmentId}) {
    if (_promoRemoveHook != null) {
      _promoRemoveHook!(isMainTab: isMainTab, departmentId: departmentId);
      return;
    }
    clearPromoCode(isMainTab: isMainTab, departmentId: departmentId);
  }

  bool _promoNoLongerApplies(bool isMainTab, {String? departmentId}) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return false;

    final cart = _getActiveCart(isMainTab);
    final scopedCart = (departmentId != null && departmentId.trim().isNotEmpty)
        ? cart
            .where((i) => (i.product.departmentId ?? '') == departmentId)
            .toList()
        : cart;

    return _promoNoLongerAppliesForCart(scopedCart, promo);
  }

  bool _promoNoLongerAppliesForCart(
    Iterable<CartItem> scopedCart,
    _DepartmentPromoState promo,
  ) {
    if (scopedCart.isEmpty) return true;

    if (_promoHasPinnedCoverage(promo, scopedCart)) return false;

    final eligibility = promo.eligibility;
    if (eligibility != null && eligibility.isKnown) {
      return !eligibility.canApplyToCart(scopedCart);
    }

    return false;
  }

  /// Promo codes that would no longer apply if [product] is removed from the cart.
  List<String> promoCodesInvalidatedIfItemRemoved(
    PosProduct product, {
    bool isMainTab = false,
  }) {
    if (!hasActivePromo(isMainTab)) return const [];

    final cart = _getActiveCart(isMainTab);
    if (!cart.any((item) => _isSameCartProduct(item.product, product))) {
      return const [];
    }

    final simulatedCart = cart
        .where((item) => !_isSameCartProduct(item.product, product))
        .toList();
    final invalidated = <String>{};

    // Items that are not part of the promo (selected ids/categories or an
    // "all" scope) can never break it — remove them without a warning.
    bool removedItemTouchesPromo(_DepartmentPromoState promo) {
      final eligibility = promo.eligibility;
      if (eligibility == null || !eligibility.isKnown) return true;
      return eligibility.isProductPartOfPromo(
        productId: product.id,
        isService: product.isService,
        categoryId: product.categoryId,
      );
    }

    final global = _readGlobalPromoState(isMainTab);
    if (global.code.trim().isNotEmpty &&
        removedItemTouchesPromo(global) &&
        _promoNoLongerAppliesForCart(simulatedCart, global)) {
      invalidated.add(global.code.trim());
    }

    final map = isMainTab ? _mainTabDepartmentPromoById : _departmentPromoById;
    for (final entry in map.entries) {
      final code = entry.value.code.trim();
      if (code.isEmpty) continue;
      if (!removedItemTouchesPromo(entry.value)) continue;
      final deptId = entry.key;
      final scopedSimulated = simulatedCart
          .where((i) => (i.product.departmentId ?? '') == deptId)
          .toList();
      if (_promoNoLongerAppliesForCart(scopedSimulated, entry.value)) {
        invalidated.add(code);
      }
    }

    return invalidated.toList();
  }

  /// True when every active promo has product/service scope loaded (local qty-aware math).
  bool hasKnownPromoEligibility(bool isMainTab, {String? departmentId}) {
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      return _resolvePromoState(isMainTab, departmentId: departmentId)
              .eligibility
              ?.isKnown ==
          true;
    }
    final deptIds = activePromoDepartmentIds(isMainTab);
    if (deptIds.isNotEmpty) {
      for (final id in deptIds) {
        if (_resolvePromoState(isMainTab, departmentId: id).eligibility?.isKnown !=
            true) {
          return false;
        }
      }
      return true;
    }
    return _resolvePromoState(isMainTab).eligibility?.isKnown == true;
  }

  void applyPromoCode(
      String code,
      double discount,
      bool isPercent, {
        bool isMainTab = false,
        String? promoCodeId,
        String? departmentId,
        double? computedDiscountAmount,
        PromoEligibility? eligibility,
        String? discountLabel,
        String? appliesToLabel,
        bool refreshPinnedEligibleLines = false,
      }) {
    final targetDepartmentId = (departmentId ?? _getPromoContextDepartmentId(isMainTab))
        ?.trim();
    final existing = _resolvePromoState(
      isMainTab,
      departmentId: targetDepartmentId,
    );
    final newCode = code.trim();
    final sameCode = newCode.isNotEmpty &&
        newCode.toUpperCase() == existing.code.trim().toUpperCase();
    var resolvedEligibility =
        eligibility ?? (sameCode ? existing.eligibility : null);
    if (sameCode && existing.eligibility?.isKnown == true) {
      final incoming = resolvedEligibility;
      if (incoming == null || !incoming.isKnown) {
        resolvedEligibility = existing.eligibility;
      } else if (isPromoUserApplied(isMainTab) ||
          existing.pinnedEligibleLineIds.isNotEmpty) {
        resolvedEligibility = _preferRetainedPromoEligibility(
          existing.eligibility!,
          incoming,
        );
      }
    }
    var pinnedLineIds = _resolvePinnedEligibleLineIds(
      passedEligibility: eligibility,
      resolvedEligibility: resolvedEligibility,
      existing: existing,
      sameCode: sameCode,
      isMainTab: isMainTab,
      refreshPinnedLines: refreshPinnedEligibleLines,
    );
    if (sameCode &&
        existing.pinnedEligibleLineIds.isNotEmpty &&
        pinnedLineIds.isEmpty) {
      pinnedLineIds = existing.pinnedEligibleLineIds;
    }

    final state = _DepartmentPromoState(
      code: code,
      promoCodeId: promoCodeId ?? (sameCode ? existing.promoCodeId : null),
      discount: discount,
      isPercent: isPercent,
      computedDiscountAmount: computedDiscountAmount ??
          (sameCode ? existing.computedDiscountAmount : null),
      eligibility: resolvedEligibility,
      discountLabel: discountLabel ?? (sameCode ? existing.discountLabel : null),
      appliesToLabel:
          appliesToLabel ?? (sameCode ? existing.appliesToLabel : null),
      pinnedEligibleLineIds: pinnedLineIds,
    );

    _writeGlobalPromoState(isMainTab, state);

    final map = isMainTab ? _mainTabDepartmentPromoById : _departmentPromoById;
    if (targetDepartmentId != null && targetDepartmentId.isNotEmpty) {
      map[targetDepartmentId] = state;
    } else {
      map.clear();
    }
    _promoRevision++;
    notifyListeners();
  }

  void _writeGlobalPromoState(bool isMainTab, _DepartmentPromoState state) {
    if (isMainTab) {
      _mainTabActivePromoCode = state.code;
      _mainTabActivePromoCodeId = state.promoCodeId;
      _mainTabPromoDiscount = state.discount;
      _mainTabIsPromoPercent = state.isPercent;
      _mainTabComputedPromoDiscountAmount = state.computedDiscountAmount;
      _mainTabPromoEligibility = state.eligibility;
      _mainTabPromoDiscountLabel = state.discountLabel;
      _mainTabPromoAppliesToLabel = state.appliesToLabel;
      _mainTabPinnedPromoLineIds = state.pinnedEligibleLineIds;
      return;
    }
    _activePromoCode = state.code;
    _activePromoCodeId = state.promoCodeId;
    _promoDiscount = state.discount;
    _isPromoPercent = state.isPercent;
    _computedPromoDiscountAmount = state.computedDiscountAmount;
    _promoEligibility = state.eligibility;
    _promoDiscountLabel = state.discountLabel;
    _promoAppliesToLabel = state.appliesToLabel;
    _pinnedPromoLineIds = state.pinnedEligibleLineIds;
  }

  /// Restore promo saved on the job/order when reopening the invoice panel.
  void hydratePromoFromSavedOrder({
    required PosOrder order,
    PosOrderJob? job,
    bool isMainTab = false,
  }) {
    final code = (job?.promoCodeName ?? order.promoCodeName ?? '').trim();
    final promoId = (job?.promoCodeId ?? order.promoCodeId)?.trim();
    final promoAmount =
        job?.promoDiscountAmount ?? order.promoDiscountAmount ?? 0.0;

    if (code.isEmpty &&
        (promoId == null || promoId.isEmpty) &&
        promoAmount <= 0.0001) {
      if (isPromoUserApplied(isMainTab) &&
          _getActiveCart(isMainTab).isNotEmpty &&
          hasActivePromo(isMainTab)) {
        return;
      }
      clearPromoCode(isMainTab: isMainTab, userInitiated: false);
      return;
    }

    if (code.isEmpty) {
      if (isPromoUserApplied(isMainTab) &&
          _getActiveCart(isMainTab).isNotEmpty &&
          hasActivePromo(isMainTab)) {
        return;
      }
      clearPromoCode(isMainTab: isMainTab, userInitiated: false);
      return;
    }

    final existing = _resolvePromoState(isMainTab);
    if (existing.code.trim().toUpperCase() == code.trim().toUpperCase() &&
        (existing.eligibility?.isKnown == true ||
            existing.pinnedEligibleLineIds.isNotEmpty)) {
      return;
    }

    final rawType =
        (job?.promoDiscountType ?? order.promoDiscountType ?? '').toLowerCase();
    final isPercent = rawType.contains('percent');
    final discountValue =
        job?.promoDiscountValue ?? order.promoDiscountValue ?? 0.0;
    var computedAmount = promoAmount > 0.0001 ? promoAmount : null;

    applyPromoCode(
      code,
      isPercent ? discountValue : (discountValue > 0 ? discountValue : (computedAmount ?? 0)),
      isPercent,
      isMainTab: isMainTab,
      promoCodeId: promoId,
      computedDiscountAmount: computedAmount,
      discountLabel: isPercent
          ? '${discountValue.toStringAsFixed(0)}% discount'
          : 'SAR ${(computedAmount ?? discountValue).toStringAsFixed(2)} Discount',
    );

    if (isPercent &&
        (computedAmount == null || computedAmount <= 0.0001) &&
        discountValue > 0) {
      final base = getPriceAfterJobDiscount(isMainTab);
      if (base > 0.0001) {
        computedAmount = base * discountValue / 100;
        applyPromoCode(
          code,
          discountValue,
          true,
          isMainTab: isMainTab,
          promoCodeId: promoId,
          computedDiscountAmount: computedAmount,
          discountLabel: '${discountValue.toStringAsFixed(0)}% discount',
        );
      }
    }

    if (!isPercent) {
      computedAmount = _scaleHydratedFixedPromoFromCart(
        isMainTab: isMainTab,
        perUnit: discountValue > 0 ? discountValue : (computedAmount ?? 0),
        storedAmount: computedAmount ?? 0,
      );
      if (computedAmount != null && computedAmount > 0.0001) {
        _patchPromoComputedDisplay(
          isMainTab: isMainTab,
          amount: computedAmount,
        );
      }
    }
  }

  /// Fixed scoped promos were stored as a single-unit discount — scale by cart qty immediately.
  double? _scaleHydratedFixedPromoFromCart({
    required bool isMainTab,
    required double perUnit,
    required double storedAmount,
  }) {
    if (perUnit <= 0.0001 || storedAmount <= 0.0001) return null;
    if ((storedAmount - perUnit).abs() > 0.03) return storedAmount;

    final cart = _getActiveCart(isMainTab);
    if (cart.isEmpty) return storedAmount;

    var scaled = storedAmount;
    for (final item in cart) {
      if (item.quantity <= 1.0001) continue;
      final lineBase = _lineAmountAfterJobDiscount(item, isMainTab);
      final candidate =
          (perUnit * item.quantity).clamp(0.0, lineBase).toDouble();
      if (candidate > scaled + 0.0001) scaled = candidate;
    }
    return scaled;
  }

  void _patchPromoComputedDisplay({
    required bool isMainTab,
    required double amount,
    String? departmentId,
  }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return;
    applyPromoCode(
      promo.code,
      promo.discount,
      promo.isPercent,
      isMainTab: isMainTab,
      promoCodeId: promo.promoCodeId,
      departmentId: departmentId,
      computedDiscountAmount: amount,
      eligibility: promo.eligibility,
      discountLabel: 'SAR ${amount.toStringAsFixed(2)} Discount',
      appliesToLabel: promo.appliesToLabel,
      // pinnedEligibleLineIds preserved via same-code merge in applyPromoCode
    );
  }

  void patchHydratedPromoEligibility({
    required bool isMainTab,
    required PromoEligibility eligibility,
    String? discountLabel,
    String? appliesToLabel,
    String? departmentId,
  }) {
    final promo = _resolvePromoState(isMainTab, departmentId: departmentId);
    if (promo.code.trim().isEmpty) return;
    if (isPromoUserApplied(isMainTab)) return;
    if (promo.pinnedEligibleLineIds.isNotEmpty) return;
    final current = promo.eligibility;
    if (current?.isKnown == true) {
      if (current!.hasSelectedScope) return;
      final incomingIsNarrower =
          eligibility.isKnown && eligibility.hasSelectedScope;
      final currentIsBroadAll = current.productScope == 'all' &&
          current.serviceScope == 'all' &&
          !current.hasSelectedScope;
      if (!(incomingIsNarrower && currentIsBroadAll)) return;
    }
    applyPromoCode(
      promo.code,
      promo.discount,
      promo.isPercent,
      isMainTab: isMainTab,
      promoCodeId: promo.promoCodeId,
      departmentId: departmentId,
      computedDiscountAmount: promo.computedDiscountAmount,
      eligibility: eligibility,
      discountLabel: discountLabel ?? promo.discountLabel,
      appliesToLabel: appliesToLabel ?? promo.appliesToLabel,
      // pinned lines preserved when code unchanged
    );
  }

  void clearPromoCode({
    bool isMainTab = false,
    String? departmentId,
    bool userInitiated = false,
  }) {
    if (!userInitiated &&
        isPromoUserApplied(isMainTab) &&
        _getActiveCart(isMainTab).isNotEmpty &&
        hasActivePromo(isMainTab)) {
      return;
    }
    final map = isMainTab ? _mainTabDepartmentPromoById : _departmentPromoById;
    map.clear();

    if (isMainTab) {
      _mainTabActivePromoCode = '';
      _mainTabActivePromoCodeId = null;
      _mainTabPromoDiscount = 0.0;
      _mainTabIsPromoPercent = false;
      _mainTabComputedPromoDiscountAmount = null;
      _mainTabPromoEligibility = null;
      _mainTabPromoDiscountLabel = null;
      _mainTabPromoAppliesToLabel = null;
      _mainTabPinnedPromoLineIds = const {};
      _mainTabPromoUserApplied = false;
    } else {
      _activePromoCode = '';
      _activePromoCodeId = null;
      _promoDiscount = 0.0;
      _isPromoPercent = false;
      _computedPromoDiscountAmount = null;
      _promoEligibility = null;
      _promoDiscountLabel = null;
      _promoAppliesToLabel = null;
      _pinnedPromoLineIds = const {};
      _promoUserApplied = false;
    }
    _promoRevision++;
    notifyListeners();
  }

  String? _getPromoContextDepartmentId(bool isMainTab) =>
      isMainTab ? _mainTabPromoContextDepartmentId : _promoContextDepartmentId;

  _DepartmentPromoState _resolvePromoState(
      bool isMainTab, {
        String? departmentId,
      }) {
    final map = isMainTab ? _mainTabDepartmentPromoById : _departmentPromoById;
    final targetDepartmentId = (departmentId ?? _getPromoContextDepartmentId(isMainTab))
        ?.trim();

    if (targetDepartmentId != null && targetDepartmentId.isNotEmpty) {
      final byDepartment = map[targetDepartmentId];
      if (byDepartment != null && byDepartment.code.trim().isNotEmpty) {
        return byDepartment;
      }
    }

    final global = _readGlobalPromoState(isMainTab);
    if (global.code.trim().isNotEmpty) return global;

    for (final entry in map.entries) {
      if (entry.value.code.trim().isNotEmpty) return entry.value;
    }
    return global;
  }

  _DepartmentPromoState _readGlobalPromoState(bool isMainTab) {
    if (isMainTab) {
      return _DepartmentPromoState(
        code: _mainTabActivePromoCode,
        promoCodeId: _mainTabActivePromoCodeId,
        discount: _mainTabPromoDiscount,
        isPercent: _mainTabIsPromoPercent,
        computedDiscountAmount: _mainTabComputedPromoDiscountAmount,
        eligibility: _mainTabPromoEligibility,
        discountLabel: _mainTabPromoDiscountLabel,
        appliesToLabel: _mainTabPromoAppliesToLabel,
        pinnedEligibleLineIds: _mainTabPinnedPromoLineIds,
      );
    }
    return _DepartmentPromoState(
      code: _activePromoCode,
      promoCodeId: _activePromoCodeId,
      discount: _promoDiscount,
      isPercent: _isPromoPercent,
      computedDiscountAmount: _computedPromoDiscountAmount,
      eligibility: _promoEligibility,
      discountLabel: _promoDiscountLabel,
      appliesToLabel: _promoAppliesToLabel,
      pinnedEligibleLineIds: _pinnedPromoLineIds,
    );
  }

  String _orderSearchQuery = '';
  String _orderStatusFilter = 'All';
  String _ordersListTab = 'All';

  String get orderStatusFilter => _orderStatusFilter;
  String get ordersListTab => _ordersListTab;
  String get orderSearchQuery => _orderSearchQuery;

  /// Cashier hub list — **stable FIFO series by creation time ASC** (oldest first).
  ///
  /// Cashiers process orders in creation sequence, so the list is ordered by the
  /// order's creation instant and falls back to the monotonic id when two orders
  /// share a timestamp or carry no timestamp at all. This guarantees that:
  ///   • the newest order always appears at the **bottom** of the list,
  ///   • every other order keeps its original slot regardless of refresh,
  ///     socket events, status changes, or pagination,
  ///   • paginated "load more" requests (served newest page first) slot their
  ///     older rows above the existing ones in deterministic order.
  /// Result: the list never shuffles up/down between fetches.
  ///
  /// Id alone is not enough: branches restored from a seed/reset carry low ids
  /// with recent timestamps, which used to push genuinely new orders to the top.
  static int _compareOrdersStableSeries(PosOrder a, PosOrder b) {
    final at = a.hubSortInstant;
    final bt = b.hubSortInstant;
    if (at != null && bt != null) {
      final c = at.compareTo(bt);
      if (c != 0) return c;
    } else if (at != null) {
      return 1;
    } else if (bt != null) {
      return -1;
    }
    final ai = BigInt.tryParse(a.id.trim());
    final bi = BigInt.tryParse(b.id.trim());
    if (ai != null && bi != null) {
      final c = ai.compareTo(bi);
      if (c != 0) return c;
    } else {
      final ia = int.tryParse(a.id.trim()) ?? 0;
      final ib = int.tryParse(b.id.trim()) ?? 0;
      if (ia != ib) return ia.compareTo(ib);
    }
    return a.id.compareTo(b.id);
  }

  static void _sortOrdersStableSeriesInPlace(List<PosOrder> orders) {
    if (orders.length < 2) return;
    orders.sort(_compareOrdersStableSeries);
  }

  /// Newest order in hub list (last row of the sorted series) — default Orders
  /// Hub selection.
  static PosOrder? _latestOrderInHubList(Iterable<PosOrder> orders) {
    PosOrder? latest;
    for (final o in orders) {
      if (latest == null || _compareOrdersStableSeries(o, latest) > 0) {
        latest = o;
      }
    }
    return latest;
  }

  /// One hub row per order id (last row wins). Prevents duplicate cards when
  /// placement refresh and detail-merge both add the same order.
  static List<PosOrder> _dedupeOrdersById(Iterable<PosOrder> source) {
    final byId = <String, PosOrder>{};
    for (final o in source) {
      final id = o.id.trim();
      if (id.isEmpty) continue;
      byId[id] = o;
    }
    final list = byId.values.toList();
    list.sort(_compareOrdersStableSeries);
    return list;
  }

  List<PosOrder> get orders {
    // Globally filter out invoiced orders based on order status
    Iterable<PosOrder> filtered = _orders.where(
          (o) => o.statusText.toLowerCase() != 'invoiced',
    );

    // Status Tab Filter (hub search is applied in [PosOrdersView] only)
    if (_orderStatusFilter != 'All') {
      filtered = filtered.where((o) {
        final status = o.normalizedJobStatus.toLowerCase();
        switch (_orderStatusFilter) {
          case 'Draft':
            return status == 'draft' || status == 'pending assignment';
          case 'Waiting':
            return status.contains('waiting') ||
                status == 'pending' ||
                status == 'assigned';
          case 'Accepted by Tech':
            return status.contains('accepted');
          case 'In Progress':
            return status == 'in progress';
          case 'Tech Completed':
            return status == 'completed by technician';
          case 'Completed':
            return status == 'completed' || status == 'edited';
          case 'Cancelled':
            return status.contains('rejected') || status.contains('cancelled');
          case 'Corp. pending approval':
            final s = o.status.toLowerCase();
            return s.contains('waiting for corporate') || s.trim() == 'unapproved';
          case 'Corporate approved':
            return o.status.toLowerCase().trim() == 'corporate approved';
          case 'Rejected by corporate':
            return o.status.toLowerCase().contains('rejected by corporate');
          default:
            return true;
        }
      });
    }

    return filtered.toList();
  }

  Future<void> fetchOrders({
    bool silent = false,
    String? statusQuery,
    int? limit,
    int? offset,
    String? preferredOrderId,
    bool ordersScreenRefresh = false,
    bool force = false,
  }) {
    if (force) {
      _ordersFetchGeneration++;
    }
    final generation = _ordersFetchGeneration;

    if (!force && _ordersFetchInFlight != null) {
      return _ordersFetchInFlight!;
    }

    final future = _fetchOrdersImpl(
      silent: silent,
      statusQuery: statusQuery,
      limit: limit,
      offset: offset,
      preferredOrderId: preferredOrderId,
      ordersScreenRefresh: ordersScreenRefresh,
      fetchGeneration: generation,
    );
    _ordersFetchInFlight = future.whenComplete(() {
      if (identical(_ordersFetchInFlight, future)) {
        _ordersFetchInFlight = null;
      }
    });
    return _ordersFetchInFlight!;
  }

  /// Remove a cancelled / invoiced order from the in-memory hub immediately.
  void _applyOrderRemovedFromHub(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) return;
    _orders = _orders.where((o) => o.id.trim() != id).toList();
    if (_selectedOrder?.id.trim() == id) {
      _selectedOrder = _latestOrderInHubList(_orders);
    }
    if (_lastCreatedWalkInOrderId?.trim() == id) {
      _lastCreatedWalkInOrderId = null;
      _lastCreatedWalkInVehicleNumber = null;
    }
    if (_editingOrder?.id.trim() == id) {
      _editingOrder = null;
    }
    _lastCashierOrdersFetchedAt = null;
    notifyListeners();
  }

  /// Replace or append one order in the hub list (authoritative GET /cashier/order/:id).
  void _upsertOrderInHub(PosOrder order) {
    final id = order.id.trim();
    if (id.isEmpty) return;
    var found = false;
    _orders = _orders.map((o) {
      if (o.id.trim() != id) return o;
      found = true;
      return order;
    }).toList();
    if (!found) {
      _orders = _dedupeOrdersById([..._orders, order]);
    }
    if (_selectedOrder?.id.trim() == id) {
      _selectedOrder = order;
    }
    if (_editingOrder?.id.trim() == id) {
      _editingOrder = order;
    }
  }

  /// Instant UI after POST complete-cashier — avoids waiting on a stale list GET.
  void _applyJobCompletedInHub(String orderId, String jobId) {
    final oid = orderId.trim();
    final jid = jobId.trim();
    if (oid.isEmpty || jid.isEmpty) return;

    PosOrder patch(PosOrder o) {
      if (o.id.trim() != oid) return o;
      final jobs = o.jobs.map((j) {
        if (j.id.trim() != jid) return j;
        return j.copyWith(status: 'completed');
      }).toList();
      return o.copyWith(jobs: jobs);
    }

    _orders = _orders.map(patch).toList();
    if (_selectedOrder?.id.trim() == oid) {
      _selectedOrder = patch(_selectedOrder!);
    }
    if (_editingOrder?.id.trim() == oid) {
      _editingOrder = patch(_editingOrder!);
    }
  }

  Future<void> _refreshOrderAfterJobComplete({String? orderId}) async {
    final oid = orderId?.trim() ?? '';
    await refreshOrderInHubAfterMutation(oid);
  }

  Map<String, dynamic>? _orderMapFromMutationResponse(
    Map<String, dynamic>? apiResponse,
  ) {
    if (apiResponse == null) return null;
    dynamic raw = apiResponse['order'];
    if (raw is! Map && apiResponse['id'] != null) {
      raw = apiResponse;
    }
    if (raw is! Map) return null;
    var map = Map<String, dynamic>.from(raw);
    final nested = map['order'];
    if (nested is Map && map['id'] == null) {
      map = Map<String, dynamic>.from(nested);
    }
    return map['id'] != null ? map : null;
  }

  /// Authoritative hub refresh after PATCH/POST that returns an updated order snapshot.
  Future<void> refreshOrderInHubAfterMutation(
    String orderId, {
    Map<String, dynamic>? apiResponse,
  }) async {
    final oid = orderId.trim();
    if (oid.isEmpty) return;

    try {
      final rawOrder = _orderMapFromMutationResponse(apiResponse);
      if (rawOrder != null) {
        final parsed = PosOrder.fromJson(rawOrder);
        final hasLines = parsed.jobs.any((j) => j.items.isNotEmpty) ||
            parsed.items.isNotEmpty;
        _upsertOrderInHub(
          parsed.copyWith(linesIncluded: hasLines || parsed.linesIncluded),
        );
        notifyListeners();
      }
    } catch (_) {}

    final detail = await loadCashierOrderDetail(oid);
    if (detail == null) return;

    final st = detail.status.toLowerCase();
    if (st == 'invoiced' ||
        st == 'cancelled' ||
        st == 'canceled' ||
        st.contains('rejected by corporate')) {
      _applyOrderRemovedFromHub(oid);
      return;
    }

    _upsertOrderInHub(detail.copyWith(linesIncluded: true));
    if (_selectedOrder?.id.trim() == oid) {
      _selectedOrder = detail.copyWith(linesIncluded: true);
    }
    notifyListeners();
  }

  /// Authoritative hub refresh after walk-in create / department placement.
  ///
  /// Bypasses coalesced stale GETs; merges the new order by id when missing.
  Future<void> refreshOrdersAfterPlacement({String? preferredOrderId}) async {
    final id = (preferredOrderId ?? _lastCreatedWalkInOrderId ?? '').trim();
    _lastCashierOrdersFetchedAt = null;
    await fetchOrders(
      silent: true,
      preferredOrderId: id.isNotEmpty ? id : null,
      force: true,
    );
    if (id.isNotEmpty) {
      await _mergePreferredOrderIfMissing(id);
      // New order may sit past the first page — always pull detail into hub.
      final detail = await loadCashierOrderDetail(id);
      if (detail != null) {
        final st = detail.status.toLowerCase();
        if (st != 'invoiced' &&
            st != 'cancelled' &&
            st != 'canceled' &&
            !st.contains('rejected by corporate')) {
          _upsertOrderInHub(detail.copyWith(linesIncluded: true));
          try {
            _selectedOrder = _orders.firstWhere((o) => o.id.trim() == id);
          } catch (_) {}
        }
      }
    }
    notifyListeners();
  }

  /// Order Summary promo: jobs that can still take a promo change.
  /// Includes **completed** jobs (backend allows promo-only pricing updates
  /// before invoice) so the Grand Total banner stays visible after all
  /// departments are marked complete. Excludes cancelled / already-invoiced.
  List<PosOrderJob> promoEditableJobsForOrder(PosOrder order) {
    return order.jobs.where((j) {
      if (j.isCancelledJob) return false;
      final s = normalizeCashierJobStatus(j.status);
      if (s == 'invoiced') return false;
      return j.items.isNotEmpty;
    }).toList();
  }

  /// Promo currently applied to the order being edited in the department
  /// popup (stored per job; falls back to the order header).
  ({String code, String id})? editingOrderAppliedPromo() {
    final order = _editingOrder;
    if (order == null) return null;
    return _inheritedOrderPromoRef(null, order);
  }

  /// Order-wide cart simulation for the department edit popup: the live dept
  /// cart (optionally without [excludeProduct]) plus every other job's
  /// persisted lines. Returns null when the edit context is incomplete —
  /// callers must then skip promo-invalidation warnings.
  List<CartItem>? editingOrderCartSnapshot({PosProduct? excludeProduct}) {
    final order = _editingOrder;
    final editDept = (_editDepartmentId ?? '').trim();
    if (order == null || editDept.isEmpty) return null;
    final combined = _cartItems
        .where((item) =>
            excludeProduct == null ||
            !_isSameCartProduct(item.product, excludeProduct))
        .toList();
    for (final job in order.jobs) {
      if (job.isCancelledJob) continue;
      final jobDept = (job.departmentId ?? '').trim();
      if (jobDept == editDept) continue;
      combined.addAll(_cartItemsSnapshotFromJob(job.items));
    }
    return combined;
  }

  /// Serializes order-promo apply/remove calls: rapid re-taps used to fire
  /// dozens of concurrent POST …/pricing transactions and jam the DB pool.
  bool _orderPromoMutationInFlight = false;
  bool get isOrderPromoMutationInFlight => _orderPromoMutationInFlight;

  /// One retry for transient DB/transaction timeouts on the pricing endpoint
  /// (remote DB can briefly refuse new transactions under load).
  Future<Map<String, dynamic>> _postJobPromoBodyWithRetry(
    String jobId,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      return await posRepository.updateJobPricing(jobId, body, token);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final transient = msg.contains('transaction') ||
          msg.contains('took too long') ||
          msg.contains('try again');
      if (!transient) rethrow;
      await Future.delayed(const Duration(milliseconds: 1500));
      return posRepository.updateJobPricing(jobId, body, token);
    }
  }

  /// Applies [promoCode] to every promo-editable job of [order].
  ///
  /// POST …/pricing with a promo-only body keeps the job's existing lines
  /// (backend only replaces lines when products/services/items are sent).
  /// Refreshes the orders hub on success so the summary shows server-computed
  /// promo amounts.
  Future<bool> applyPromoCodeToOrder({
    required PosOrder order,
    required String promoCode,
    String? promoCodeId,
  }) async {
    final code = promoCode.trim().toUpperCase();
    if (code.isEmpty) return false;
    if (_orderPromoMutationInFlight) return false;
    final jobs = promoEditableJobsForOrder(order);
    if (jobs.isEmpty) {
      _errorMessage = 'No editable department items to apply the promo to';
      notifyListeners();
      return false;
    }
    _orderPromoMutationInFlight = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      var anySuccess = false;
      String? failMessage;
      for (final job in jobs) {
        final body = <String, dynamic>{
          'promoCode': code,
          if (promoCodeId != null && promoCodeId.trim().isNotEmpty)
            'promoCodeId': promoCodeId.trim(),
        };
        try {
          final r = await _postJobPromoBodyWithRetry(job.id, body, token);
          if (r['success'] != false) {
            anySuccess = true;
          } else {
            failMessage = r['message']?.toString();
          }
        } catch (e) {
          failMessage = _extractErrorMessage(e.toString());
        }
      }
      if (anySuccess) {
        await refreshOrdersAfterPlacement(preferredOrderId: order.id);
        return true;
      }
      _errorMessage = failMessage ?? 'Failed to apply promo code';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return false;
    } finally {
      _orderPromoMutationInFlight = false;
      notifyListeners();
    }
  }

  /// Clears the promo from every promo-editable job of [order] and refreshes
  /// the orders hub. Explicit `promoCodeId: null` tells the backend to clear.
  Future<bool> removePromoCodeFromOrder(PosOrder order) async {
    if (_orderPromoMutationInFlight) return false;
    final jobs = promoEditableJobsForOrder(order);
    if (jobs.isEmpty) {
      _errorMessage = 'This order can no longer be edited';
      notifyListeners();
      return false;
    }
    _orderPromoMutationInFlight = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      var anySuccess = false;
      String? failMessage;
      for (final job in jobs) {
        final hasJobPromo = (job.promoCodeId ?? '').trim().isNotEmpty ||
            (job.promoCodeName ?? '').trim().isNotEmpty ||
            job.promoDiscountAmount > 0.0001;
        final hasOrderPromo = (order.promoCodeId ?? '').trim().isNotEmpty ||
            (order.promoCodeName ?? '').trim().isNotEmpty;
        if (!hasJobPromo && !hasOrderPromo) continue;
        final body = <String, dynamic>{
          'promoCode': null,
          'promoCodeId': null,
        };
        try {
          final r = await _postJobPromoBodyWithRetry(job.id, body, token);
          if (r['success'] != false) {
            anySuccess = true;
          } else {
            failMessage = r['message']?.toString();
          }
        } catch (e) {
          failMessage = _extractErrorMessage(e.toString());
        }
      }
      if (anySuccess) {
        await refreshOrdersAfterPlacement(preferredOrderId: order.id);
        return true;
      }
      _errorMessage = failMessage ?? 'Failed to remove promo code';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return false;
    } finally {
      _orderPromoMutationInFlight = false;
      notifyListeners();
    }
  }

  bool _orderReferralMutationInFlight = false;
  bool get isOrderReferralMutationInFlight => _orderReferralMutationInFlight;

  /// Validate + stamp marketing referral code on [order]. Benefit applies at invoice.
  Future<bool> applyReferralCodeToOrder({
    required PosOrder order,
    required String referralCode,
  }) async {
    final code = referralCode.trim();
    if (code.isEmpty) return false;
    if (_orderReferralMutationInFlight) return false;
    _orderReferralMutationInFlight = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final preview = await posRepository.applyReferralCode(
        code,
        token,
        orderId: order.id,
        customerMobile: order.customer?.mobile,
      );
      if (preview['valid'] != true) {
        _errorMessage =
            preview['message']?.toString() ?? 'Invalid referral code';
        notifyListeners();
        return false;
      }

      final stamped = await posRepository.setOrderReferralCode(
        order.id,
        token,
        referralCode: code,
      );
      if (stamped['success'] == false) {
        _errorMessage =
            stamped['message']?.toString() ?? 'Failed to apply referral code';
        notifyListeners();
        return false;
      }

      await refreshOrdersAfterPlacement(preferredOrderId: order.id);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return false;
    } finally {
      _orderReferralMutationInFlight = false;
      notifyListeners();
    }
  }

  Future<bool> removeReferralCodeFromOrder(PosOrder order) async {
    if (_orderReferralMutationInFlight) return false;
    _orderReferralMutationInFlight = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.setOrderReferralCode(
        order.id,
        token,
        clear: true,
      );
      if (res['success'] == false) {
        _errorMessage =
            res['message']?.toString() ?? 'Failed to remove referral code';
        notifyListeners();
        return false;
      }
      await refreshOrdersAfterPlacement(preferredOrderId: order.id);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return false;
    } finally {
      _orderReferralMutationInFlight = false;
      notifyListeners();
    }
  }

  Future<void> _mergePreferredOrderIfMissing(String orderId) async {
    final id = orderId.trim();
    if (id.isEmpty) return;
    if (_orders.any((o) => o.id.trim() == id)) return;

    final detail = await loadCashierOrderDetail(id);
    if (detail == null) return;

    final st = detail.status.toLowerCase();
    if (st == 'invoiced' ||
        st == 'cancelled' ||
        st == 'canceled' ||
        st.contains('rejected by corporate')) {
      return;
    }

    _orders = _dedupeOrdersById([..._orders, detail.copyWith(linesIncluded: true)]);
    try {
      _selectedOrder = _orders.firstWhere((o) => o.id.trim() == id);
    } catch (_) {}
  }

  /// Orders tab: GET /cashier/orders with loading indicator (does not toggle global [_isLoading]).
  void dismissOrdersFetchError() {
    if (_ordersFetchError == null) return;
    _ordersFetchError = null;
    notifyListeners();
  }

  Future<void> refreshOrdersScreen() async {
    final id = _selectedOrder?.id.trim();
    await fetchOrders(
      silent: true,
      preferredOrderId: id != null && id.isNotEmpty ? id : null,
      ordersScreenRefresh: true,
      force: true,
    );
  }

  /// True when the cashier orders list was successfully fetched within [ttl].
  ///
  /// Used by the shell to skip duplicate `GET /cashier/orders` calls when the
  /// user opens the Orders tab right after an action (walk-in placement,
  /// invoice generation, socket update) already refreshed the list. Manual
  /// refresh (pull-to-refresh, refresh icon) ignores this and always fetches.
  bool ordersListFreshlyFetched({
    Duration ttl = const Duration(seconds: 8),
  }) {
    final at = _lastCashierOrdersFetchedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < ttl;
  }

  /// Refresh the Orders Hub on tab-visit, but skip the network request when
  /// data is still fresh (see [ordersListFreshlyFetched]). Returns true when
  /// a fetch was actually issued.
  Future<bool> refreshOrdersScreenIfStale({
    Duration ttl = const Duration(seconds: 8),
  }) async {
    final placedId = (_lastCreatedWalkInOrderId ?? '').trim();
    final placedMissingFromHub = placedId.isNotEmpty &&
        !_orders.any((o) => o.id == placedId);

    if (ordersListFreshlyFetched(ttl: ttl) && !placedMissingFromHub) {
      return false;
    }
    if (_ordersFetchInFlight != null) {
      await _ordersFetchInFlight;
      if (ordersListFreshlyFetched(ttl: ttl) && !placedMissingFromHub) {
        return false;
      }
    }
    if (placedMissingFromHub && placedId.isNotEmpty) {
      await refreshOrdersAfterPlacement(preferredOrderId: placedId);
      return true;
    }
    await refreshOrdersScreen();
    return true;
  }

  /// Orders tab / Orders Hub visit: refresh if needed, select newest order, scroll to it.
  Future<void> prepareOrdersHubForVisit({
    Duration staleTtl = const Duration(seconds: 8),
  }) async {
    final placedId = (_lastCreatedWalkInOrderId ?? '').trim();
    final placedMissingFromHub = placedId.isNotEmpty &&
        !_orders.any((o) => o.id == placedId);

    if (placedMissingFromHub) {
      await refreshOrdersAfterPlacement(preferredOrderId: placedId);
      return;
    }

    if (_ordersFetchInFlight != null) {
      await _ordersFetchInFlight;
    }

    if (!ordersListFreshlyFetched(ttl: staleTtl)) {
      _selectedOrder = null;
      await fetchOrders(silent: true, force: true);
    }

    focusHubOnLatestOrder();
  }

  /// Select the newest hub order and request list scroll (see [requestHubScrollToOrder]).
  void focusHubOnLatestOrder() {
    final latest = _latestOrderInHubList(_orders);
    if (latest == null) {
      if (_selectedOrder != null) {
        selectOrder(null);
      }
      return;
    }
    if (_selectedOrder?.id.trim() != latest.id.trim()) {
      selectOrder(latest);
    }
    requestHubScrollToOrder(latest.id);
  }

  Future<void> loadMoreOrders() async {
    if (!_ordersHasMore || _isLoadingMoreOrders) return;
    if (_ordersFetchInFlight != null) {
      await _ordersFetchInFlight;
      if (!_ordersHasMore || _isLoadingMoreOrders) return;
    }

    _isLoadingMoreOrders = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) return;

      final response = await posRepository.getCashierOrders(
        token,
        status: 'pending',
        limit: cashierOrdersPageSize,
        offset: _ordersNextOffset,
      );
      if (!response.success) return;

      _orders = _dedupeOrdersById([..._orders, ...response.orders]);
      _ordersNextOffset = response.offset + response.orders.length;
      _ordersOffset = _orders.length;
      _ordersListTotal = response.total;
      _ordersHasMore = _ordersNextOffset < response.total;
      _orderStats = response.stats;
      _lastCashierOrdersFetchedAt = DateTime.now();
      _syncBroadcastCooldownWithOrdersAfterFetch(_orders);
    } catch (e) {
      debugPrint('[Orders Hub] loadMoreOrders failed: $e');
    } finally {
      _isLoadingMoreOrders = false;
      notifyListeners();
    }
  }

  Future<void> _fetchOrdersImpl({
    bool silent = false,
    String? statusQuery,
    int? limit,
    int? offset,
    String? preferredOrderId,
    bool ordersScreenRefresh = false,
    required int fetchGeneration,
  }) async {
    // Default to `pending` (backend excludes invoiced / cancelled / rejected by corporate).
    final effectiveStatusQuery =
        (statusQuery == null || statusQuery.trim().isEmpty)
            ? 'pending'
            : statusQuery;

    // Refresh reloads the already-visible window (capped); first load uses page size.
    final effectiveOffset = offset ?? 0;
    final effectiveLimit = limit ??
        math.min(
          math.max(_ordersNextOffset, cashierOrdersPageSize),
          200,
        );

    // Batch all loading-state changes into a single notify
    var needsNotify = false;
    if (ordersScreenRefresh) {
      _ordersScreenRefreshInFlight = true;
      needsNotify = true;
    }
    if (!silent && !ordersScreenRefresh) {
      _isLoading = true;
      _errorMessage = null;
      needsNotify = true;
    }
    if (needsNotify) notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await posRepository.getCashierOrders(
        token,
        status: effectiveStatusQuery,
        limit: effectiveLimit,
        offset: effectiveOffset,
      );
      if (response.success) {
        if (fetchGeneration == _ordersFetchGeneration) {
          if (effectiveOffset > 0) {
            _orders = _dedupeOrdersById([..._orders, ...response.orders]);
          } else {
            // Preserve previously hydrated line items when list returns slim rows.
            final previousById = <String, PosOrder>{
              for (final o in _orders) o.id.trim(): o,
            };
            _orders = _dedupeOrdersById(response.orders.map((o) {
              final prev = previousById[o.id.trim()];
              if (prev == null) return o;
              var merged = o;
              if (prev.linesIncluded &&
                  !o.linesIncluded &&
                  prev.jobs.any((j) => j.items.isNotEmpty)) {
                merged = merged.copyWith(
                  jobs: prev.jobs,
                  items: prev.items,
                  linesIncluded: true,
                );
              }
              // Slim GET /cashier/orders always sends referralDiscountAmount: 0.
              // Keep the already-applied amount when the same code is still on
              // the order (detail GET recomputes it after job add/remove).
              final incomingCode = (o.referralCode ?? '').trim();
              final prevCode = (prev.referralCode ?? '').trim();
              if (incomingCode.isNotEmpty &&
                  incomingCode == prevCode &&
                  o.referralDiscountAmount <= 0.0001 &&
                  prev.referralDiscountAmount > 0.0001) {
                merged = merged.copyWith(
                  referralDiscountAmount: prev.referralDiscountAmount,
                  referralReferrerName:
                      (o.referralReferrerName ?? '').trim().isNotEmpty
                          ? o.referralReferrerName
                          : prev.referralReferrerName,
                );
              }
              // SoftPOS / Request Payment: stale coalesced list GET must not
              // wipe prepaid that we already applied locally.
              if (prev.isPosPrepaid && !merged.isPosPrepaid) {
                merged = merged.copyWith(
                  posPrepaidAmount: prev.posPrepaidAmount,
                  posPrepaidAt: prev.posPrepaidAt,
                  posPrepaidPayments: prev.posPrepaidPayments,
                  posPrepaidIntentId: prev.posPrepaidIntentId,
                  posPayments: prev.posPrepaidPayments ?? prev.posPayments,
                );
              }
              return merged;
            }));
          }
          _ordersNextOffset = response.offset + response.orders.length;
          _ordersOffset = _orders.length;
          _ordersListTotal = response.total;
          _ordersHasMore = _ordersNextOffset < response.total;
          _orderStats = response.stats;
          _lastCashierOrdersFetchedAt = DateTime.now();
          _syncBroadcastCooldownWithOrdersAfterFetch(_orders);

          if (_editingOrder != null) {
            try {
              _editingOrder =
                  _orders.firstWhere((o) => o.id == _editingOrder!.id);
            } catch (_) {}
          }

          final previousSelectedOrderId = _selectedOrder?.id;

          final preferredId = (preferredOrderId?.trim().isNotEmpty == true)
              ? preferredOrderId!.trim()
              : ((_lastCreatedWalkInOrderId ?? '').trim().isNotEmpty
                  ? _lastCreatedWalkInOrderId!.trim()
                  : null);

          // Always prioritize a caller-requested order selection.
          if (preferredId != null) {
            try {
              _selectedOrder = _orders.firstWhere((o) => o.id == preferredId);
            } catch (_) {
              _selectedOrder = null;
            }
          }

          // Fallback: when create response didn't include order id, select by latest matching vehicle plate.
          if (_selectedOrder == null &&
              (_lastCreatedWalkInVehicleNumber ?? '').trim().isNotEmpty) {
            final targetPlate =
                _lastCreatedWalkInVehicleNumber!.trim().toLowerCase();
            final matches = _orders.where(
              (o) => o.plateNumber.trim().toLowerCase() == targetPlate,
            ).toList();
            if (matches.isNotEmpty) {
              _selectedOrder = _latestOrderInHubList(matches);
            }
          } else if (_selectedOrder != null) {
            // Re-select order if it already exists
            try {
              _selectedOrder =
                  _orders.firstWhere((o) => o.id == _selectedOrder!.id);
            } catch (_) {
              _selectedOrder = null;
            }
          }

          // Default hub selection: newest order (list stays FIFO oldest → newest).
          var selectedNewestByDefault = false;
          if (_selectedOrder == null && _orders.isNotEmpty) {
            _selectedOrder = _latestOrderInHubList(_orders);
            selectedNewestByDefault = _selectedOrder != null;
          }

          if (preferredId != null && _selectedOrder != null) {
            _lastCreatedWalkInOrderId = _selectedOrder!.id;
            _lastCreatedWalkInVehicleNumber = null;
          }

          _applyServerOrderSnapshotToBillingAndPaymentDraftState(
            previousSelectedOrderId: previousSelectedOrderId,
          );

          _ordersFetchError = null;

          if (preferredId != null) {
            await _mergePreferredOrderIfMissing(preferredId);
            _orders = _dedupeOrdersById(_orders);
            requestHubScrollToOrder(preferredId);
          } else if (selectedNewestByDefault) {
            requestHubScrollToOrder(_selectedOrder!.id);
          }

          final selectedId = _selectedOrder?.id.trim();
          if (selectedId != null &&
              selectedId.isNotEmpty &&
              _selectedOrder?.linesIncluded == false) {
            unawaited(_hydrateOrderLinesIntoHub(selectedId));
          }
        }
        // notifyListeners() is called unconditionally in finally below
      } else if (fetchGeneration == _ordersFetchGeneration) {
        _ordersFetchError = 'Failed to fetch orders';
        _errorMessage = _ordersFetchError;
      }
    } catch (e) {
      if (fetchGeneration == _ordersFetchGeneration) {
        _ordersFetchError = _extractErrorMessage(e.toString());
        _errorMessage = _ordersFetchError;
      }
    } finally {
      if (fetchGeneration == _ordersFetchGeneration) {
      if (!silent && !ordersScreenRefresh) {
        _isLoading = false;
      }
      if (ordersScreenRefresh) {
          _ordersScreenRefreshInFlight = false;
        }
        _ordersApiFetchCompleted = true;
        notifyListeners(); // single rebuild — covers success, error, and loading-state reset
      }
    }
  }

  /// GET /cashier/order/:orderId — use for `pendingDepartments` after corporate approval.
  Future<PosOrder?> loadCashierOrderDetail(String orderId) async {
    try {
      final token = await sessionService.getToken();
      if (token == null) return null;
      final raw = await posRepository.getCashierOrderDetail(orderId, token);
      final orderMap = raw['order'];
      if (orderMap is Map) {
        return PosOrder.fromJson(Map<String, dynamic>.from(orderMap));
      }
      if (raw['id'] != null) {
        return PosOrder.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST …/walk-in-corporate/order/:orderId/start-department
  Future<bool> startCorporateWalkInDepartment(
      BuildContext context, {
        required String orderId,
        required String departmentId,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.startCorporateWalkInDepartment(orderId, departmentId, token);
      final ok = res['success'] == true;
      if (ok) {
        final jid = res['jobId']?.toString();
        if (jid != null && jid.isNotEmpty) {
          _currentJobId = jid;
        }
        _previousOrderId = orderId;
        await fetchOrders(silent: true);
        if (context.mounted) {
          ToastService.showSuccess(
            context,
            res['message']?.toString() ?? 'Department started',
          );
        }
      } else {
        final msg = res['message']?.toString() ?? 'Failed to start department';
        _errorMessage = msg;
        if (context.mounted) ToastService.showError(context, msg);
      }
      return ok;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      if (context.mounted) ToastService.showError(context, _errorMessage!);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendCorporateOrderForApproval(
      BuildContext context, {
        required String orderId,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.sendWalkInCorporateForApproval(orderId, token);
      final ok = res['success'] == true;
      final msg = res['message']?.toString().trim().isNotEmpty == true
          ? res['message'].toString()
          : (ok ? 'Sent for corporate approval' : 'Failed to send for approval');
      if (context.mounted) {
        if (ok) {
          ToastService.showSuccess(context, msg);
        } else {
          ToastService.showError(context, msg);
        }
      }
      if (ok) {
        await fetchOrders(silent: true, preferredOrderId: orderId);
      }
      return ok;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      if (context.mounted) ToastService.showError(context, _errorMessage!);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  WalkInCustomerRequest _buildCorporateWalkInApprovalRequest(
      PosOrder order, {
        required bool sendForApproval,
      }) {
    final products = <RequestedProduct>[];
    final services = <RequestedService>[];
    for (final raw in order.items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final itemType = (item['itemType'] ?? '').toString().trim().toLowerCase();
      final departmentId = (item['departmentId'] ?? '').toString().trim();
      final qty = double.tryParse(item['qty']?.toString() ?? '') ??
          double.tryParse(item['quantity']?.toString() ?? '') ??
          0.0;
      if (departmentId.isEmpty || qty <= 0) continue;
      final discountType = item['discountType']?.toString();
      final discountValue =
      double.tryParse(item['discountValue']?.toString() ?? '');
      if (itemType == 'service') {
        final sid = (item['serviceId'] ?? item['productId'] ?? '').toString().trim();
        if (sid.isEmpty) continue;
        services.add(
          RequestedService(
            serviceId: sid,
            departmentId: departmentId,
            qty: qty,
            discountType: discountType,
            discountValue: discountValue,
            unitPrice: double.tryParse(item['unitPrice']?.toString() ?? ''),
          ),
        );
      } else {
        final pid = (item['productId'] ?? '').toString().trim();
        if (pid.isEmpty) continue;
        final unitPrice = double.tryParse(item['unitPrice']?.toString() ?? '');
        products.add(
          RequestedProduct(
            productId: pid,
            departmentId: departmentId,
            qty: qty,
            discountType: discountType,
            discountValue: discountValue,
            unitPrice: unitPrice != null && unitPrice > 0 ? unitPrice : null,
          ),
        );
      }
    }

    final deptIds = order.selectedDepartmentEntries
        .map((e) => e['id'] ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    return WalkInCustomerRequest(
      orderId: order.id,
      customerName: order.customerName,
      vatNumber: order.customer?.vatNumber,
      mobile: order.customer?.mobile,
      vehicleNumber: order.plateNumber,
      vinNumber: order.vehicle?.vin,
      make: order.vehicle?.make,
      model: order.vehicle?.model,
      odometerReading: order.odometerReading > 0 ? order.odometerReading : null,
      departmentIds: deptIds,
      products: products.isNotEmpty ? products : null,
      services: services.isNotEmpty ? services : null,
      totalDiscountType: order.totalDiscountType,
      totalDiscountValue: order.totalDiscountValue,
      promoCodeId: order.promoCodeId,
      amountBeforeDiscount: order.subtotal > 0 ? order.subtotal : null,
      amountAfterDiscount: order.subtotal > 0 ? order.subtotal : null,
      amountAfterPromo: order.subtotal > 0 ? order.subtotal : null,
      vat: 15.0,
      totalAmount: order.totalAmount > 0 ? order.totalAmount : null,
      corporateAccountId: (order.corporateAccountId ?? '').trim().isNotEmpty
          ? order.corporateAccountId!.trim()
          : null,
      sendForApproval: sendForApproval,
      isCorporate: order.posCustomerKind?.trim().toLowerCase() == 'corporate',
      payments: order.posPayments != null && order.posPayments!.isNotEmpty
          ? order.posPayments!
          .where((p) => p.method.trim().isNotEmpty && p.amount > 0)
          .map(
            (p) => RequestedPayment(
          method: p.method.trim(),
          amount: p.amount,
        ),
      )
          .toList()
          : null,
    );
  }

  /// Orders Hub search — plate, name, id, mobile, VIN, etc. (not applied in [orders] getter).
  bool orderMatchesHubSearch(PosOrder o) {
    final q = _orderSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;

    bool hit(String? value) =>
        value != null && value.trim().toLowerCase().contains(q);

    if (hit(o.id)) return true;
    if (hit(o.customerName)) return true;
    if (hit(o.customer?.name)) return true;
    if (hit(o.customer?.mobile)) return true;
    if (hit(o.plateNumber)) return true;
    if (hit(o.vehicle?.plateNo)) return true;
    if (hit(o.vehicle?.vin)) return true;
    if (hit(o.carModel)) return true;
    if (hit(o.vehicle?.make)) return true;
    if (hit(o.vehicle?.model)) return true;
    return false;
  }

  void setOrderSearchQuery(String query) {
    _orderSearchQuery = query;
    notifyListeners();
  }

  void setOrderStatusFilter(String status) {
    _orderStatusFilter = status;
    notifyListeners();
  }

  void setOrdersListTab(String tab) {
    if (tab != 'All' && tab != 'Pending' && tab != 'Completed') return;
    _ordersListTab = tab;
    notifyListeners();
  }

  Future<void> searchCustomers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchedCustomers = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isSearchingCustomer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Backend `q`: OR of name, mobile, and plate on invoiced orders (see cashier getCustomersByName).
      final response = await posRepository.searchCustomers(
        {'q': trimmed},
        token,
      );

      if (response.success) {
        _searchedCustomers = response.customers;
      } else {
        _errorMessage = response.message;
        _searchedCustomers = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
      _searchedCustomers = [];
    } finally {
      _isSearchingCustomer = false;
      notifyListeners();
    }
  }

  final List<PosTechnician> _allTechnicians = [
    // Oil Change
    PosTechnician(id: 'T1', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T2', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T3', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T4', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T5', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T6', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T7', name: 'M. Sheraz', technicianType: 'Oil Change'),
    PosTechnician(id: 'T8', name: 'M. Sheraz', technicianType: 'Oil Change'),
    // General Repair
    PosTechnician(
      id: 'T9',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T10',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T11',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T12',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T13',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T14',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T15',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
    PosTechnician(
      id: 'T16',
      name: 'M. Sheraz',
      technicianType: 'General Repair',
    ),
  ];

  String _techSearchQuery = '';

  List<PosTechnician> get technicians {
    if (_techSearchQuery.isEmpty) return _allTechnicians;
    return _allTechnicians
        .where(
          (t) => t.name.toLowerCase().contains(_techSearchQuery.toLowerCase()),
    )
        .toList();
  }

  Map<String, List<PosTechnician>> get techniciansByCategory {
    final Map<String, List<PosTechnician>> map = {};
    for (PosTechnician tech in technicians) {
      if (!map.containsKey(tech.serviceCategory)) {
        map[tech.serviceCategory] = [];
      }
      map[tech.serviceCategory]!.add(tech);
    }
    return map;
  }

  void setTechSearchQuery(String query) {
    _techSearchQuery = query;
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  /// True only when this order may use PATCH `/cashier/order/:id/billing` (walk-in per backend).
  /// Corporate **booking** fulfillment often has corporate flags but a non–walk-in `source` — must stay false.
  bool _isStandardWalkInOrderForBilling(PosOrder o) {
    if (o.isCorporateBookingOrder) return false;

    final s = o.source
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .trim();
    final walkInLike =
        s == 'walk_in' || s == 'walkin' || (s.contains('walk_in') && s.isNotEmpty);

    if (o.isCorporateWalkIn) {
      if (o.isCorporateUnapproved ||
          o.isWaitingCorporateApproval ||
          o.isRejectedByCorporate) {
        return true;
      }
      if (o.isCorporateApproved) return true;
      if (walkInLike && s.contains('corporate')) return true;
      return walkInLike;
    }

    return walkInLike;
  }

  bool isStandardWalkInOrderForBilling(PosOrder o) =>
      _isStandardWalkInOrderForBilling(o);

  /// Plate, name, and mobile required for walk-in invoice (VM fields or order payload).
  bool walkInBillingReadyForInvoice(PosOrder order) {
    if (!_isStandardWalkInOrderForBilling(order)) return true;
    final oid = order.id.trim();
    final snap = _walkInBillingSnapshotsByOrderId[oid];
    final overlayActive = _selectedOrder?.id.trim() == oid;
    var name = snap != null
        ? _walkInPickField(snap.name, overlayActive ? _customerName : '', order.customer?.name ?? '')
        : (overlayActive && _customerName.trim().isNotEmpty
            ? _customerName.trim()
            : (order.customer?.name ?? '').trim());
    if (name.isEmpty) {
      name = (order.corporateCompanyName ?? '').trim();
    }
    final mobile = snap != null
        ? _walkInPickField(snap.mobile, overlayActive ? _mobile : '', order.customer?.mobile ?? '')
        : (overlayActive && _mobile.trim().isNotEmpty
            ? _mobile.trim()
            : (order.customer?.mobile ?? '').trim());
    final plate = snap != null
        ? _walkInPickField(
            snap.vehicleNumber,
            overlayActive ? _vehicleNumber : '',
            order.plateNumber,
          )
        : (overlayActive && _vehicleNumber.trim().isNotEmpty
            ? _vehicleNumber.trim()
            : order.plateNumber.trim());
    return name.isNotEmpty && mobile.isNotEmpty && plate.isNotEmpty;
  }

  Map<String, dynamic> _buildWalkInBillingPatchBody(PosOrder order) {
    final snap = _walkInBillingSnapshotsByOrderId[order.id.trim()];

    final nameOrder = (order.customer?.name ?? '').trim();
    final mobOrder = (order.customer?.mobile ?? '').trim();
    final vatOrder = (order.customer?.vatNumber ?? '').trim();

    final name = snap != null
        ? _walkInPickField(snap.name, _customerName, nameOrder)
        : (nameOrder.isNotEmpty ? nameOrder : _customerName.trim());
    final mobile = snap != null
        ? _walkInPickField(snap.mobile, _mobile, mobOrder)
        : (mobOrder.isNotEmpty ? mobOrder : _mobile.trim());
    final vat = snap != null
        ? _walkInPickField(snap.vat, _vatNumber, vatOrder)
        : (vatOrder.isNotEmpty ? vatOrder : _vatNumber.trim());

    final body = <String, dynamic>{
      'customerName': name,
      'mobile': mobile,
    };
    if (vat.isNotEmpty) body['vatNumber'] = vat;

    // Snapshot reflects the last Invoice details dialog save — explicitly clear employee
    // flags when toggle is off so the server does not keep a previous payroll customer.
    if (snap != null) {
      if (snap.billingCustomerIsEmployee) {
        body['billingCustomerIsEmployee'] = true;
        final bid = snap.billingEmployeeId?.trim();
        if (bid != null && bid.isNotEmpty) {
          body['branchEmployeeId'] = bid;
        }
        final et = snap.billingEmployeeType?.trim();
        if (et != null && et.isNotEmpty) {
          body['employeeType'] = et;
        }
      } else {
        body['billingCustomerIsEmployee'] = false;
        body['isCustomerEmployee'] = false;
      }
    }

    final plateOrder = (order.vehicle?.plateNo ?? '').trim();
    final plateEff = snap != null
        ? _walkInPickField(snap.vehicleNumber, _vehicleNumber, plateOrder)
        : _vehicleNumber.trim().isNotEmpty
        ? _vehicleNumber.trim()
        : plateOrder;

    int odoEff = order.odometerReading;
    if (snap != null && snap.odometer != 0) {
      odoEff = snap.odometer;
    } else if (_odometerReading != 0) {
      odoEff = _odometerReading;
    }
    if (odoEff != 0) {
      body['odometerReading'] = odoEff;
    }

    final makeEff = snap != null
        ? _walkInPickField(snap.make, _make, (order.vehicle?.make ?? '').trim())
        : _make.trim();
    final modelEff = snap != null
        ? _walkInPickField(snap.model, _model, (order.vehicle?.model ?? '').trim())
        : _model.trim();
    final vinEff = snap != null
        ? _walkInPickField(snap.vin, _vinNumber, (order.vehicle?.vin ?? '').trim())
        : _vinNumber.trim().isNotEmpty
        ? _vinNumber.trim()
        : (order.vehicle?.vin ?? '').trim();
    final yearEff = snap != null
        ? _walkInPickField(snap.year, _vehicleYear, (order.vehicle?.year ?? '').trim())
        : _vehicleYear.trim().isNotEmpty
        ? _vehicleYear.trim()
        : (order.vehicle?.year ?? '').trim();
    final colorEff = snap != null
        ? _walkInPickField(snap.color, _vehicleColor, (order.vehicle?.color ?? '').trim())
        : _vehicleColor.trim();

    final wantsVehicleFields = plateEff.isNotEmpty ||
        makeEff.isNotEmpty ||
        modelEff.isNotEmpty ||
        vinEff.isNotEmpty ||
        yearEff.isNotEmpty ||
        colorEff.isNotEmpty;

    if (wantsVehicleFields) {
      final plate = plateEff.isNotEmpty ? plateEff : plateOrder;
      if (plate.isEmpty) {
        throw StateError(
          'vehicleNumber is required when sending vehicle fields. Add the plate under Add Customer.',
        );
      }
      body['vehicleNumber'] = plate;
      if (makeEff.isNotEmpty) {
        body['make'] = makeEff;
      } else if ((order.vehicle?.make ?? '').trim().isNotEmpty) {
        body['make'] = order.vehicle!.make.trim();
      }
      if (modelEff.isNotEmpty) {
        body['model'] = modelEff;
      } else if ((order.vehicle?.model ?? '').trim().isNotEmpty) {
        body['model'] = order.vehicle!.model.trim();
      }
      if (yearEff.isNotEmpty) {
        final yi = _parseYearForBillingApi(yearEff);
        if (yi != null) {
          body['year'] = yi;
        } else {
          debugPrint(
            'WalkIn billing: year "$yearEff" could not be parsed as int; omitting year field',
          );
        }
      } else {
        final yStr = order.vehicle?.year?.trim();
        if (yStr != null && yStr.isNotEmpty) {
          final yi = _parseYearForBillingApi(yStr);
          if (yi != null) body['year'] = yi;
        }
      }
      if (colorEff.isNotEmpty) {
        body['color'] = colorEff;
      } else {
        final col = order.vehicle?.color?.trim();
        if (col != null && col.isNotEmpty) body['color'] = col;
      }
      if (vinEff.isNotEmpty) {
        body['vin'] = vinEff;
      } else {
        final ov = order.vehicle?.vin?.trim();
        if (ov != null && ov.isNotEmpty) body['vin'] = ov;
      }
    }

    return body;
  }

  /// Production [createInvoice] may still require **completed** jobs only. After mark-edited,
  /// jobs stay **edited** until `complete-cashier` with `{}` (recalc, no line overwrite).
  /// Mirrors backend behavior when present; safe no-op when there are no edited jobs.
  Map<String, dynamic> _buildInvoicePaymentBody({
    required double totalAmount,
    String? paymentMethod,
    List<Map<String, dynamic>>? payments,
    bool? isCorporate,
  }) {
    final cleanMethod = paymentMethod?.trim();
    final normalizedPayments = <Map<String, dynamic>>[];

    if (payments != null && payments.isNotEmpty) {
      for (final p in payments) {
        final method = p['method']?.toString().trim() ?? '';
        if (method.isEmpty) continue;
        final amount =
            double.tryParse(p['amount']?.toString() ?? '') ?? 0.0;
        if (amount <= 0) continue;
        final entry = <String, dynamic>{
          'method': method,
          'amount': amount,
        };
        final idsRaw = p['employeeIds'];
        if (idsRaw is List && idsRaw.isNotEmpty) {
          entry['employeeIds'] =
              idsRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        }
        normalizedPayments.add(entry);
      }
    }

    if (normalizedPayments.isEmpty && cleanMethod != null && cleanMethod.isNotEmpty) {
      normalizedPayments.add(<String, dynamic>{
        'method': cleanMethod,
        'amount': totalAmount > 0 ? totalAmount : 0.0,
      });
    }

    return <String, dynamic>{
      if (isCorporate != null) 'isCorporate': isCorporate,
      if (cleanMethod != null && cleanMethod.isNotEmpty) 'paymentMethod': cleanMethod,
      'payments': normalizedPayments,
    };
  }

  /// ZATCA `invoiceType` for POST /cashier/invoice/create.
  /// Corporate booking / corporate walk-in / explicit [isCorporate] → `B2B`; else `B2C`.
  static String zatcaInvoiceTypeForOrder({
    required PosOrder? order,
    bool? isCorporate,
  }) {
    if (isCorporate == true) return 'B2B';
    if (order != null &&
        (order.isCorporateBookingOrder || order.isCorporateWalkIn)) {
      return 'B2B';
    }
    return 'B2C';
  }

  Future<CreateInvoiceResponse?> generateInvoice(
      String orderId, {
        String? paymentMethod,
        List<Map<String, dynamic>>? payments,
        bool? isCorporate,
        PosOrder? orderForBilling,
        /// Optional ZATCA Fatoora OTP — only when workshop needs Compliance CSID / sandbox.
        String? zatcaOtp,
      }) async {
    beginInvoiceGeneration(orderId);
    _errorMessage = null;

    try {
      final token = await sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      // Prefer a fresh GET so jobs, unassigned lines, and totals match the server
      // (list snapshots can be stale after edits or realtime updates).
      PosOrder? orderCtx = await loadCashierOrderDetail(orderId);
      if (orderCtx == null) {
        orderCtx = orderForBilling;
        if (orderCtx == null) {
          for (final o in _orders) {
            if (o.id == orderId) {
              orderCtx = o;
              break;
            }
          }
        }
      }

      // Build the inline billing payload (walk-in only). Backend's
      // createInvoice will apply this inside the same transaction, so we
      // skip the dedicated PATCH /cashier/order/:id/billing call entirely.
      Map<String, dynamic>? billingForServer;
      if (orderCtx != null &&
          _isStandardWalkInOrderForBilling(orderCtx) &&
          !orderCtx.isCorporateBookingOrder) {
        try {
          final billingBody = _buildWalkInBillingPatchBody(orderCtx);
          final cn = (billingBody['customerName'] as String? ?? '').trim();
          final mb = (billingBody['mobile'] as String? ?? '').trim();
          if (cn.isEmpty || mb.isEmpty) {
            final msg =
                'Customer name and mobile are required before invoice. Complete the billing prompt or update customer details.';
            _errorMessage = msg;
            _isInvoiceLoading = false;
            _loadingOrderId = null;
            notifyListeners();
            return CreateInvoiceResponse(success: false, message: msg);
          }
          final plateOnOrder = (orderCtx.vehicle?.plateNo ?? '').trim();
          final plateInBody = (billingBody['vehicleNumber'] as String? ?? '').trim();
          if (plateOnOrder.isEmpty && plateInBody.isEmpty) {
            final msg =
                'Vehicle plate is required before invoice. Add it under Add Customer (billing), then try again.';
            _errorMessage = msg;
            _isInvoiceLoading = false;
            _loadingOrderId = null;
            notifyListeners();
            return CreateInvoiceResponse(success: false, message: msg);
          }
          billingForServer = billingBody;
        } on StateError catch (e) {
          final msg = e.message;
          _errorMessage = msg;
          _isInvoiceLoading = false;
          _loadingOrderId = null;
          notifyListeners();
          return CreateInvoiceResponse(success: false, message: msg);
        }
      }

      // Normalize payment payload locally (no API hit) so the backend can
      // persist Payment rows inside the same createInvoice transaction.
      final estimatedTotal =
          orderCtx?.draftPosOrderPayableDisplay.toDouble() ?? 0.0;
      final paymentBody = _buildInvoicePaymentBody(
        totalAmount: estimatedTotal,
        paymentMethod: paymentMethod,
        payments: payments,
        isCorporate: isCorporate,
      );
      final paymentRows = (paymentBody['payments'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const <Map<String, dynamic>>[];
      final paymentMethodForRequest =
          paymentBody['paymentMethod'] as String?;
      if (paymentRows.isEmpty &&
          (paymentMethodForRequest == null ||
              paymentMethodForRequest.trim().isEmpty)) {
        final msg = 'Payment method is required before generating invoice.';
        _errorMessage = msg;
        _isInvoiceLoading = false;
        _loadingOrderId = null;
        notifyListeners();
        return CreateInvoiceResponse(success: false, message: msg);
      }

      // Single round-trip: backend createInvoice now does
      //   billing PATCH (if `billing` present)
      //   → finalize any jobs still in `edited`
      //   → create Invoice + Payment rows from `payments[]`
      //   → ZATCA signing/reporting (server-side; failures do not block POS success)
      //   → return the hydrated invoice (via getInvoiceByOrderId)
      // No follow-up GETs / PATCH / payment API calls are needed.
      final invoiceType = zatcaInvoiceTypeForOrder(
        order: orderCtx,
        isCorporate: isCorporate,
      );
      final request = CreateInvoiceRequest(
        orderId: orderId,
        discountAmount: 0.0,
        invoiceDate: DateTime.now().toIso8601String(),
        paymentMethod: paymentMethodForRequest,
        payments: paymentRows.isNotEmpty ? paymentRows : null,
        isCorporate: isCorporate,
        billing: billingForServer,
        invoiceType: invoiceType,
        otp: zatcaOtp,
      );

      debugPrint(
        'InvoiceFlow: creating invoice for orderId=$orderId, '
        'invoiceDate=${request.invoiceDate}, '
        'invoiceType=$invoiceType, '
        'paymentMethod=${request.paymentMethod ?? 'N/A'}, '
        'paymentsCount=${paymentRows.length}, '
        'inlineBilling=${billingForServer != null}, '
        'zatcaOtp=${(zatcaOtp ?? '').trim().isNotEmpty}',
      );
      final createResponse = await posRepository.createInvoice(request, token);
      if (createResponse.success) {
        debugPrint(
          'InvoiceFlow: create success, invoiceId=${createResponse.invoice?.id ?? 'N/A'}, invoiceNo=${createResponse.invoice?.invoiceNo ?? 'N/A'}',
        );

        Invoice? mergedInvoice = createResponse.invoice;
        if (mergedInvoice != null) {
          mergedInvoice = invoiceWithMergedCustomerTax(
            mergedInvoice,
            orderCtx?.customer?.vatNumber,
          );
          mergedInvoice = invoiceWithMergedCustomerTax(
            mergedInvoice,
            _vatNumber,
          );
        } else {
          debugPrint(
            'InvoiceFlow: createInvoice returned success but no invoice payload — '
            'downstream WhatsApp/thermal print will be skipped.',
          );
        }

        final finalResponse = CreateInvoiceResponse(
          success: true,
          message: createResponse.message.trim().isNotEmpty
              ? createResponse.message
              : 'Invoice saved',
          invoice: mergedInvoice,
          statusCode: createResponse.statusCode,
        );

        // Remove the invoiced order from the in-memory list (no refetch) and
        // keep stats consistent. The cashier sees the order disappear from the
        // pending/in-progress lists immediately.
        final removedIndex = _orders.indexWhere((o) => o.id == orderId);
        if (removedIndex != -1) {
          final removed = _orders.removeAt(removedIndex);
          final prevStatus = removed.status.trim().toLowerCase();
          int draft = _orderStats.draft;
          int inProgress = _orderStats.inProgress;
          int readyForInvoice = _orderStats.readyForInvoice;
          int waitingForCorporateApproval =
              _orderStats.waitingForCorporateApproval;
          int corporateApproved = _orderStats.corporateApproved;
          if (prevStatus == 'draft' && draft > 0) {
            draft -= 1;
          } else if (prevStatus == 'in_progress' && inProgress > 0) {
            inProgress -= 1;
          } else if (prevStatus == 'ready_for_invoice' &&
              readyForInvoice > 0) {
            readyForInvoice -= 1;
          } else if (prevStatus == 'waiting_for_corporate_approval' &&
              waitingForCorporateApproval > 0) {
            waitingForCorporateApproval -= 1;
          } else if (prevStatus == 'corporate_approved' &&
              corporateApproved > 0) {
            corporateApproved -= 1;
          }
          _orderStats = OrderStats(
            total: _orderStats.total > 0 ? _orderStats.total - 1 : 0,
            draft: draft,
            inProgress: inProgress,
            readyForInvoice: readyForInvoice,
            invoiced: _orderStats.invoiced + 1,
            cancelled: _orderStats.cancelled,
            waitingForCorporateApproval: waitingForCorporateApproval,
            corporateApproved: corporateApproved,
            rejectedByCorporate: _orderStats.rejectedByCorporate,
          );
        }
        if (_selectedOrder?.id == orderId) {
          _selectedOrder = null;
        }
        _isInvoiceLoading = false;
        _loadingOrderId = null;
        debugPrint(
          'InvoiceFlow: completed. mergedInvoice=${mergedInvoice != null} total=${mergedInvoice?.totalAmount ?? 0}',
        );
        _clearInvoicePaymentPreferences(orderId.trim());
        _walkInBillingSnapshotsByOrderId.remove(orderId.trim());
        _paymentDraftByOrderId.remove(orderId.trim());
        if (_activeInvoicePaymentOrderId == orderId.trim()) {
          _activeInvoicePaymentOrderId = null;
        }
        _rehydrateWalkInVmFromSelectedOrderDraft();
        notifyListeners();
        unawaited(refreshProductsAfterInvoice());
        return finalResponse;
      } else {
        debugPrint(
          'InvoiceFlow: create failed for orderId=$orderId. reason=${createResponse.message}',
        );
        _errorMessage = createResponse.message;
        _isInvoiceLoading = false;
        _loadingOrderId = null;
        notifyListeners();
        return createResponse;
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _isInvoiceLoading = false;
      _loadingOrderId = null;
      notifyListeners();
      return CreateInvoiceResponse(success: false, message: _errorMessage!);
    }
  }

  Future<CashierCompleteJobResponse?> completeCashierJob(
      String jobId, {
        bool isMainTab = false,
        PosOrder? sourceOrder,
      }) async {
    _cashierCompletingJobId = jobId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      // Orders list "Mark complete" must use persisted job lines only. The POS cart is shared
      // and filtered by department — two orders with the same department would overwrite each
      // other's pricing if we sent cart/hydrated pricing from here.
      final completeFromOrdersList = sourceOrder != null;

      // Product-grid completes get no [sourceOrder]; resolve the hub order that
      // owns this job so the pricing payload can inherit an order-level promo
      // instead of clearing it. Does not affect [sourceJob]/dept resolution.
      var promoSourceOrder = sourceOrder;
      if (promoSourceOrder == null) {
        for (final o in _orders) {
          if (o.jobs.any((j) => j.id == jobId)) {
            promoSourceOrder = o;
            break;
          }
        }
      }

      PosOrderJob? sourceJob;
      if (sourceOrder != null) {
        for (final j in sourceOrder.jobs) {
          if (j.id == jobId) {
            sourceJob = j;
            break;
          }
        }
      }
      sourceJob ??= sourceOrder?.latestJob;

      Map<String, dynamic> pricingBody = const {};
      List<CartItem> itemsForJob = const [];
      var pricingBodyHasLines = false;

      if (!completeFromOrdersList) {
        // 1) Build pricing payload from the live product-grid cart (replace-all snapshot).
        final activeCart = isMainTab ? _mainTabCartItems : _cartItems;
        for (var item in activeCart) {
          if (item.product.isPriceEditable) {
            if (item.effectiveUnitPrice <= 0) {
              _errorMessage = 'Enter a valid unit price for ${item.product.name}';
              _isLoading = false;
              notifyListeners();
              return CashierCompleteJobResponse(success: false, message: _errorMessage!);
            }
            final priceErr = item.product.validateEditableUnitPrice(item.effectiveUnitPrice);
            if (priceErr == 'below_min') {
              _errorMessage =
                  'Price cannot be below SAR ${item.product.minEditablePriceVatInclusive.toStringAsFixed(2)} for ${item.product.name}';
              _isLoading = false;
              notifyListeners();
              return CashierCompleteJobResponse(success: false, message: _errorMessage!);
            }
          }
        }

        var deptId = '';
        if (sourceJob != null) {
          final did = sourceJob.departmentId?.trim() ?? '';
          if (did.isNotEmpty) {
            deptId = did;
          } else if (sourceJob.items.isNotEmpty) {
            final fd = sourceJob.items.first.departmentId.trim();
            if (fd.isNotEmpty) deptId = fd;
          }
        }

        itemsForJob = activeCart.where((c) {
          if (deptId.isEmpty) return true;
          final pd = c.product.departmentId?.trim() ?? '';
          return pd.isEmpty || pd == deptId;
        }).toList();

        final defaultDept = deptId.isNotEmpty ? deptId : '0';
        pricingBody = _buildCashierJobPricingPayload(
          items: itemsForJob,
          defaultDepartmentId: defaultDept,
          applyJobDiscountAndPromo: true,
          isMainTab: isMainTab,
          sourceJob: sourceJob,
          sourceOrder: sourceOrder,
          promoInheritOrder: promoSourceOrder,
          hydrateFromJobWhenLinesEmpty: true,
        );

        pricingBodyHasLines =
            ((pricingBody['products'] as List?)?.isNotEmpty ?? false) ||
                ((pricingBody['services'] as List?)?.isNotEmpty ?? false);

        // 2) Persist/refresh job-level pricing from the cart before completion.
        final jobAlreadyHasItems = sourceJob != null && sourceJob.items.isNotEmpty;
        if (itemsForJob.isNotEmpty || !jobAlreadyHasItems || pricingBodyHasLines) {
          await posRepository.updateJobPricing(jobId, pricingBody, token);
        }
      }

      // 3) Readiness check (product-grid path only). Orders Hub uses persisted server lines;
      // corporate/web lines may exist with jobId null until the server links them on complete.
      if (!completeFromOrdersList) {
        final readyResponse = await posRepository.checkJobCompleteReady(jobId, token);
        if (!readyResponse.success || !readyResponse.isReady) {
          _errorMessage = readyResponse.message.isNotEmpty
              ? readyResponse.message
              : 'Please add products/services before completing the job.';
          _isLoading = false;
          notifyListeners();
          return CashierCompleteJobResponse(
            success: false,
            message: _errorMessage!,
          );
        }
      }

      // 4) Complete cashier job — orders-list path sends empty body so the server recalculates
      // from persisted lines; product-grid path sends cart pricing when present.
      final response = await posRepository.completeCashierJob(
        jobId,
        token,
        body: completeFromOrdersList
            ? <String, dynamic>{}
            : ((itemsForJob.isNotEmpty || pricingBodyHasLines)
                ? pricingBody
                : <String, dynamic>{}),
      );
      if (response.success) {
        final hubOrderId =
            (sourceOrder?.id ?? _selectedOrder?.id ?? '').trim();
        if (hubOrderId.isNotEmpty) {
          _applyJobCompletedInHub(hubOrderId, jobId);
        }
        setOrdersListTab('All');
        _isLoading = false;
        notifyListeners();
        unawaited(_refreshOrderAfterJobComplete(orderId: hubOrderId));
        return response;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return response;
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return CashierCompleteJobResponse(
        success: false,
        message: _errorMessage!,
      );
    } finally {
      if (_cashierCompletingJobId == jobId) {
        _cashierCompletingJobId = null;
      }
      notifyListeners();
    }
  }

  /// Broadcast a job to technicians in workshop or on-call duty (POST /cashier/jobs/:jobId/broadcast).
  Future<bool> broadcastJob(
      BuildContext context,
      String jobId, {
        required String dutyMode,
        String? departmentId,
      }) async {
    if (jobId.isEmpty) {
      if (context.mounted) {
        ToastService.showError(
          context,
          'Save the order first before broadcasting.',
        );
      }
      return false;
    }
    final cooldownKey =
    broadcastCooldownKey(departmentId: departmentId, jobId: jobId);
    if (cooldownKey.isNotEmpty &&
        isBroadcastCooldownActiveForKey(cooldownKey)) {
      if (context.mounted) {
        final wait = broadcastCooldownTimerLabelForKey(cooldownKey);
        ToastService.showError(
          context,
          'Please wait $wait before broadcasting this department again.',
        );
      }
      return false;
    }
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.postJobBroadcast(jobId, dutyMode, token);
      if (res['success'] != true) {
        throw Exception(res['message']?.toString() ?? 'Broadcast failed');
      }
      if (context.mounted) {
        ToastService.showSuccess(
          context,
          res['message']?.toString() ?? 'Broadcast sent to technicians',
        );
      }
      if (cooldownKey.isNotEmpty) {
        _registerBroadcastCooldown(cooldownKey);
      }
      await fetchOrders(silent: true);
      if (context.mounted) {
        navigateToPosShellBroadcastTab(context);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, _extractErrorMessage(e.toString()));
      }
      return false;
    }
  }

  /// Cancel an active broadcast and return job to pending assignment.
  Future<bool> cancelJobBroadcast(
      BuildContext context,
      String jobId, {
        String? departmentId,
      }) async {
    if (jobId.isEmpty) return false;
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.cancelJobBroadcast(jobId, token);
      if (res['success'] != true) {
        throw Exception(res['message']?.toString() ?? 'Cancel broadcast failed');
      }
      if (context.mounted) {
        ToastService.showSuccess(
          context,
          res['message']?.toString() ?? 'Broadcast cancelled',
        );
      }
      _clearBroadcastCooldownKeys(jobId: jobId, departmentId: departmentId);
      await fetchOrders(silent: true);
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, _extractErrorMessage(e.toString()));
      }
      return false;
    }
  }

  Future<bool> cancelOrder(BuildContext context, String orderId, String reason) async {
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      await posRepository.cancelOrder(orderId, reason, token);
      _applyOrderRemovedFromHub(orderId);
      if (context.mounted) {
        ToastService.showSuccess(context, 'Order cancelled successfully');
      }
      await fetchOrders(silent: true, force: true);
      return true;
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().contains('reason is required')
            ? 'Cancellation reason is required'
            : 'Failed to cancel order';
        ToastService.showError(context, msg);
      }
      return false;
    }
  }

  /// PATCH /cashier/job/:jobId/cancel — single job, before invoice.
  Future<bool> cancelCashierJob(
      BuildContext context,
      String jobId, [
        String reason = 'Cancelled by cashier',
      ]) async {
    if (jobId.trim().isEmpty) return false;
    final trimmed = reason.trim().isEmpty ? 'Cancelled by cashier' : reason.trim();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.cancelCashierJob(jobId, trimmed, token);
      final ok = res['success'] != false;
      if (context.mounted) {
        if (ok) {
          ToastService.showSuccess(
            context,
            res['message']?.toString() ?? 'Job cancelled',
          );
        } else {
          ToastService.showError(
            context,
            res['message']?.toString() ?? 'Failed to cancel job',
          );
        }
      }
      if (ok) {
        final raw = _orderMapFromMutationResponse(res);
        final oid = (raw?['id']?.toString() ?? _selectedOrder?.id ?? '').trim();
        if (oid.isNotEmpty) {
          await refreshOrderInHubAfterMutation(oid, apiResponse: res);
        } else {
          await fetchOrders(
            silent: true,
            preferredOrderId: _selectedOrder?.id,
            force: true,
          );
        }
      }
      return ok;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, _extractErrorMessage(e.toString()));
      }
      return false;
    }
  }

  /// POST /cashier/order/:orderId/jobs — add departments to an existing walk-in draft.
  Future<bool> addDepartmentsToWalkInOrder(
      BuildContext context,
      String orderId,
      List<String> departmentIds,
      ) async {
    if (orderId.trim().isEmpty || departmentIds.isEmpty) return false;
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final res = await posRepository.addJobsToCashierOrder(orderId, departmentIds, token);
      final ok = res['success'] != false;
      if (context.mounted) {
        if (ok) {
          ToastService.showSuccess(
            context,
            res['message']?.toString() ?? 'Departments added',
          );
        } else {
          ToastService.showError(
            context,
            res['message']?.toString() ?? 'Failed to add departments',
          );
        }
      }
      if (ok) {
        await refreshOrderInHubAfterMutation(
          orderId.trim(),
          apiResponse: res,
        );
      }
      return ok;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, _extractErrorMessage(e.toString()));
      }
      return false;
    }
  }

  Future<InvoicedOrderResponse?> fetchCustomerInvoicedHistory(String customerId) async {
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      final response = await posRepository.getInvoicedOrdersByCustomer(
        customerId,
        token,
        scope: 'all',
      );
      if (response.success) {
        for (final order in response.orders) {
          rememberInvoiceNo(order.id, order.invoiceNo);
        }
      }
      return response;
    } catch (e) {
      return null;
    }
  }

  void rememberInvoiceNo(String orderId, String invoiceNo) {
    final oid = orderId.trim();
    final inv = invoiceNo.trim();
    if (oid.isEmpty || inv.isEmpty) return;
    _invoiceNoByOrderId[oid] = inv;
  }

  String? invoiceNoForOrder(String orderId) {
    final cached = _invoiceNoByOrderId[orderId.trim()];
    if (cached != null && cached.trim().isNotEmpty) return cached.trim();
    return null;
  }

  Future<CreateInvoiceResponse?> fetchInvoiceByOrder(String orderId) async {
    _isInvoiceLoading = true;
    _loadingOrderId = orderId;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await posRepository.getInvoiceByOrder(orderId, token);
      if (response.success && response.invoice != null) {
        rememberInvoiceNo(orderId, response.invoice!.invoiceNo);
      }
      _isInvoiceLoading = false;
      _loadingOrderId = null;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _isInvoiceLoading = false;
      _loadingOrderId = null;
      notifyListeners();
      return CreateInvoiceResponse(success: false, message: _errorMessage!);
    }
  }

  /// Public invoice URL for WhatsApp link share (creates token if missing).
  Future<Map<String, dynamic>?> fetchPublicInvoiceLinkByOrder(
    String orderId,
  ) async {
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');
      return await posRepository.getPublicInvoiceLinkByOrder(orderId, token);
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return null;
    }
  }
}