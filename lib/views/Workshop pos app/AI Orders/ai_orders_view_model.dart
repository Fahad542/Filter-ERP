import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/ai_orders_repository.dart';
import '../../../models/cashier_ai_order_model.dart';
import '../../../services/realtime_service.dart';
import '../../../services/session_service.dart';

class AiOrdersViewModel extends ChangeNotifier {
  AiOrdersViewModel({
    required this.repository,
    required this.sessionService,
  }) {
    _realtime.on(RealtimeService.eventCashierAiOrderUnbilled, _onUnbilled);
    _realtime.on(RealtimeService.eventCashierAiOrderMatched, _onMatched);
  }

  final AiOrdersRepository repository;
  final SessionService sessionService;
  final RealtimeService _realtime = RealtimeService();

  List<AiOrderCashier> orders = [];
  int total = 0;
  int page = 1;
  int limit = 50;
  int unbilledCount = 0;
  AiOrdersSettings settings = const AiOrdersSettings();
  bool settingsLoaded = false;

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  String? statusFilter;
  String searchQuery = '';
  bool unbilledOnly = false;
  bool companyVehiclesOnly = false;

  AiOrderCashier? selectedOrder;
  bool isDetailLoading = false;
  String? detailError;
  bool isActionBusy = false;

  Timer? _socketDebounce;
  Future<void>? _fetchInFlight;
  Future<void>? _unbilledInFlight;

  String get socketEventUnbilled => settings.socketEventUnbilled;
  String get socketEventMatched => settings.socketEventMatched;

  Future<String?> _token() => sessionService.getToken(role: 'cashier');

  void _onUnbilled(Map<String, dynamic> _) {
    _socketDebounce?.cancel();
    _socketDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchUnbilledCount(silent: true);
      fetchList(silent: true);
    });
  }

  void _onMatched(Map<String, dynamic> _) {
    _socketDebounce?.cancel();
    _socketDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchUnbilledCount(silent: true);
      fetchList(silent: true);
      final id = selectedOrder?.id;
      if (id != null && id.isNotEmpty) {
        loadDetail(id, silent: true);
      }
    });
  }

  Future<void> bootstrap() async {
    await Future.wait([
      loadSettings(),
      fetchUnbilledCount(silent: true),
    ]);
  }

  Future<void> loadSettings() async {
    final token = await _token();
    if (token == null) return;
    settings = await repository.getSettings(token);
    settingsLoaded = true;
    notifyListeners();
  }

  Future<void> fetchList({bool silent = false}) {
    if (_fetchInFlight != null) return _fetchInFlight!;
    _fetchInFlight = _fetchListImpl(silent: silent)
        .whenComplete(() => _fetchInFlight = null);
    return _fetchInFlight!;
  }

  Future<void> _fetchListImpl({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    } else {
      isRefreshing = true;
    }
    try {
      final token = await _token();
      if (token == null) {
        errorMessage = 'Session expired';
        return;
      }
      final result = await repository.listAiOrders(
        token,
        status: statusFilter,
        unbilledOnly: unbilledOnly,
        companyVehiclesOnly: companyVehiclesOnly,
        search: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
        page: page,
        limit: limit,
      );
      orders = result.data;
      total = result.total;
      if (result.unbilledGraceMinutes != null) {
        settings = AiOrdersSettings(
          unbilledGraceMinutes: result.unbilledGraceMinutes!,
          repeatAlertMinutes: settings.repeatAlertMinutes,
          socketEventUnbilled: settings.socketEventUnbilled,
          socketEventMatched: settings.socketEventMatched,
          notificationType: settings.notificationType,
        );
      }
    } catch (e) {
      if (!silent) errorMessage = e.toString();
      if (kDebugMode) debugPrint('[AI Orders] list error: $e');
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnbilledCount({bool silent = false}) {
    if (_unbilledInFlight != null) return _unbilledInFlight!;
    _unbilledInFlight = _fetchUnbilledImpl(silent: silent)
        .whenComplete(() => _unbilledInFlight = null);
    return _unbilledInFlight!;
  }

  Future<void> _fetchUnbilledImpl({bool silent = false}) async {
    try {
      final token = await _token();
      if (token == null) return;
      final result = await repository.listUnbilledAlerts(token, limit: 100);
      unbilledCount = result.total;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[AI Orders] unbilled count error: $e');
      if (!silent) {
        // Keep previous count on silent failure.
      }
    }
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    page = 1;
    notifyListeners();
    fetchList();
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    page = 1;
    notifyListeners();
    fetchList();
  }

  void setUnbilledOnly(bool value) {
    unbilledOnly = value;
    page = 1;
    notifyListeners();
    fetchList();
  }

  void setCompanyVehiclesOnly(bool value) {
    companyVehiclesOnly = value;
    page = 1;
    notifyListeners();
    fetchList();
  }

  /// Seed detail from list cache (instant paint), then refresh from API.
  Future<void> openDetail(String id) async {
    AiOrderCashier? cached;
    for (final o in orders) {
      if (o.id == id) {
        cached = o;
        break;
      }
    }
    if (cached == null && selectedOrder?.id == id) {
      cached = selectedOrder;
    }
    if (cached != null) {
      selectedOrder = cached;
      detailError = null;
      notifyListeners();
      await loadDetail(id, silent: true);
      return;
    }
    await loadDetail(id, silent: false);
  }

  Future<void> loadDetail(String id, {bool silent = false}) async {
    if (!silent) {
      isDetailLoading = true;
      detailError = null;
      notifyListeners();
    }
    try {
      final token = await _token();
      if (token == null) {
        detailError = 'Session expired';
        return;
      }
      selectedOrder = await repository.getAiOrder(token, id);
      detailError = null;
    } catch (e) {
      if (!silent) detailError = e.toString();
      if (kDebugMode) debugPrint('[AI Orders] detail error: $e');
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<AiOrderCashier?> acknowledgeSelected() async {
    final order = selectedOrder;
    if (order == null) return null;
    isActionBusy = true;
    notifyListeners();
    try {
      final token = await _token();
      if (token == null) throw Exception('Session expired');
      final updated = await repository.acknowledge(token, order.id);
      selectedOrder = updated;
      await Future.wait([
        fetchList(silent: true),
        fetchUnbilledCount(silent: true),
      ]);
      return updated;
    } finally {
      isActionBusy = false;
      notifyListeners();
    }
  }

  Future<OpenPosOrdersByPlateResult> openPosOrdersForSelected() async {
    final order = selectedOrder;
    if (order == null) {
      return const OpenPosOrdersByPlateResult(
        plateNumber: '',
        found: false,
        orders: [],
      );
    }
    final token = await _token();
    if (token == null) throw Exception('Session expired');
    return repository.openPosByPlate(token, order.plateNumber);
  }

  Future<AiOrderCashier?> linkSelectedToSalesOrder(String salesOrderId) async {
    final order = selectedOrder;
    if (order == null) return null;
    isActionBusy = true;
    notifyListeners();
    try {
      final token = await _token();
      if (token == null) throw Exception('Session expired');
      final updated =
          await repository.linkOrder(token, order.id, salesOrderId);
      selectedOrder = updated;
      await Future.wait([
        fetchList(silent: true),
        fetchUnbilledCount(silent: true),
      ]);
      return updated;
    } finally {
      isActionBusy = false;
      notifyListeners();
    }
  }

  void clearSelected() {
    selectedOrder = null;
    detailError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketDebounce?.cancel();
    _realtime.off(RealtimeService.eventCashierAiOrderUnbilled, _onUnbilled);
    _realtime.off(RealtimeService.eventCashierAiOrderMatched, _onMatched);
    super.dispose();
  }
}
