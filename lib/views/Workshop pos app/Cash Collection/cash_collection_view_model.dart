import 'package:flutter/material.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../models/cashier_cash_collection_model.dart';
import '../../../services/session_service.dart';
import '../../../utils/business_timezone.dart';

enum CashCollectionFilter { all, pending, collected }

class CashCollectionViewModel extends ChangeNotifier {
  CashCollectionViewModel({
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
  String? _error;
  String? get error => _error;

  List<CashierCashCollectionItem> _items = [];
  CashCollectionFilter _filter = CashCollectionFilter.all;
  CashCollectionFilter get filter => _filter;

  DateTime? _fromDate;
  DateTime? get fromDate => _fromDate;
  DateTime? _toDate;
  DateTime? get toDate => _toDate;

  double _totalExpected = 0;
  double get totalExpected => _totalExpected;
  double _totalCollected = 0;
  double get totalCollected => _totalCollected;
  double _balance = 0;
  double get balance => _balance;

  int _loadEpoch = 0;

  bool get hasRawItems => _items.isNotEmpty;
  bool get showInitialShimmer => _loading && !hasRawItems;

  void _applyCurrentMonthDefault() {
    final today = BusinessTimezone.calendarToday();
    _fromDate = DateTime(today.year, today.month, 1);
    _toDate = today;
  }

  String? get _fromQuery => _ymd(_fromDate);
  String? get _toQuery => _ymd(_toDate);

  String? _ymd(DateTime? d) {
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  int get allCount => _items.length;
  int get pendingCount => _items.where((e) => e.isPending).length;
  int get collectedCount => _items.where((e) => e.isCollected).length;

  List<CashierCashCollectionItem> get items {
    switch (_filter) {
      case CashCollectionFilter.all:
        return _items;
      case CashCollectionFilter.pending:
        return _items.where((e) => e.isPending).toList();
      case CashCollectionFilter.collected:
        return _items.where((e) => e.isCollected).toList();
    }
  }

  void setFilter(CashCollectionFilter value) {
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
    _error = null;
    if (showShimmer) {
      _items = [];
      _totalExpected = 0;
      _totalCollected = 0;
      _balance = 0;
    }
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      final res = await _posRepository.getCashCollectionHistory(
        token,
        from: _fromQuery,
        to: _toQuery,
      );
      if (epoch != _loadEpoch) return;
      _items = res.items;
      _totalExpected = res.totalExpected;
      _totalCollected = res.totalCollected;
      _balance = res.balance;
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (epoch == _loadEpoch) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
