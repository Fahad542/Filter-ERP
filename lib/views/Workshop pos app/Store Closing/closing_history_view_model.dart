import 'package:flutter/material.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../models/cashier_closing_history_model.dart';
import '../../../services/session_service.dart';
import '../../../utils/business_timezone.dart';

enum ClosingHistoryFilter { all, balanced, short }

class ClosingHistoryViewModel extends ChangeNotifier {
  ClosingHistoryViewModel({
    PosRepository? posRepository,
    SessionService? sessionService,
  })  : _posRepository = posRepository ?? PosRepository(),
        _sessionService = sessionService ?? SessionService() {
    _applyCurrentMonthDefault();
  }

  final PosRepository _posRepository;
  final SessionService _sessionService;

  bool _loading = false;
  bool get loading => _loading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  List<CashierClosingHistoryItem> _items = [];

  ClosingHistoryFilter _filter = ClosingHistoryFilter.all;
  ClosingHistoryFilter get filter => _filter;

  int _page = 1;
  int get page => _page;
  int _totalPages = 1;
  int get totalPages => _totalPages;
  int _total = 0;
  int get total => _total;

  bool get hasMore => _page < _totalPages;
  bool get hasRawItems => _items.isNotEmpty;
  bool get showInitialShimmer => _loading && !hasRawItems;

  DateTime? _fromDate;
  DateTime? get fromDate => _fromDate;
  DateTime? _toDate;
  DateTime? get toDate => _toDate;

  void _applyCurrentMonthDefault() {
    final today = BusinessTimezone.calendarToday();
    _fromDate = DateTime(today.year, today.month, 1);
    _toDate = today;
  }

  double _totalCommission = 0;
  double get totalCommission => _totalCommission;
  double _totalSales = 0;
  double get totalSales => _totalSales;
  int _loadEpoch = 0;

  String? get _fromQuery => _ymd(_fromDate);
  String? get _toQuery => _ymd(_toDate);

  String? _ymd(DateTime? d) {
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  int get allCount => _items.length;
  int get balancedCount => _items
      .where((e) => e.reconciliationTotalDifference.abs() < 0.01)
      .length;
  int get shortCount => _items
      .where((e) => e.reconciliationTotalDifference > 0.01)
      .length;

  List<CashierClosingHistoryItem> get items {
    switch (_filter) {
      case ClosingHistoryFilter.all:
        return _items;
      case ClosingHistoryFilter.balanced:
        return _items
            .where((e) => e.reconciliationTotalDifference.abs() < 0.01)
            .toList();
      case ClosingHistoryFilter.short:
        return _items
            .where((e) => e.reconciliationTotalDifference > 0.01)
            .toList();
    }
  }

  void setFilter(ClosingHistoryFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  Future<void> setFromDate(DateTime? date) async {
    _fromDate = date == null ? null : DateTime(date.year, date.month, date.day);
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      _toDate = _fromDate;
    }
    await load(refresh: true, showShimmer: true);
  }

  Future<void> setToDate(DateTime? date) async {
    _toDate = date == null ? null : DateTime(date.year, date.month, date.day);
    if (_fromDate != null && _toDate != null && _toDate!.isBefore(_fromDate!)) {
      _fromDate = _toDate;
    }
    await load(refresh: true, showShimmer: true);
  }

  Future<void> clearDates() async {
    if (_fromDate == null && _toDate == null) return;
    _fromDate = null;
    _toDate = null;
    await load(refresh: true, showShimmer: true);
  }

  Future<void> load({bool refresh = true, bool showShimmer = false}) async {
    if (_loading && !showShimmer) return;
    final epoch = ++_loadEpoch;
    _loading = true;
    _loadingMore = !refresh && hasRawItems;
    _error = null;
    if (refresh) {
      _page = 1;
      if (showShimmer) {
        _items = [];
        _totalCommission = 0;
        _totalSales = 0;
      }
    }
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      final res = await _posRepository.getClosingHistory(
        token,
        page: _page,
        pageSize: 20,
        from: _fromQuery,
        to: _toQuery,
      );
      if (epoch != _loadEpoch) return;
      _items = refresh ? res.items : [..._items, ...res.items];
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
      _totalCommission = res.totalCommission;
      _totalSales = res.totalSales;
      if (_totalSales.abs() < 0.0001) {
        _totalSales = _items.fold<double>(
          0,
          (sum, item) => sum + item.systemTotalSales,
        );
      }
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (epoch == _loadEpoch) {
        _loading = false;
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    _page += 1;
    await load(refresh: false);
    if (_error != null && _page > 1) {
      _page -= 1;
    }
  }
}
