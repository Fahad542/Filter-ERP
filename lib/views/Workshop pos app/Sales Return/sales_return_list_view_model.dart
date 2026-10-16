import 'package:flutter/material.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../services/session_service.dart';
import '../../../models/sales_return_list_model.dart';
import '../../../utils/toast_service.dart';
import '../../../services/locker_translation_mixin.dart';

class SalesReturnListViewModel extends ChangeNotifier with TranslatableMixin {
  final PosRepository posRepository;
  final SessionService sessionService;

  SalesReturnListViewModel({
    required this.posRepository,
    required this.sessionService,
  });

  bool _isLoading = false;
  String? _error;
  List<SalesReturnInfo> _returns = [];
  int _totalCount = 0;
  int _offset = 0;
  final int _limit = 50;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SalesReturnInfo> get returns => _returns;
  int get totalCount => _totalCount;
  bool get hasMore => _returns.length < _totalCount;

  Future<void> fetchReturns({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _returns = [];
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await posRepository.getSalesReturns(
        token,
        limit: _limit,
        offset: _offset,
      );

      if (response.success) {
        if (refresh) {
          _returns = response.salesReturns;
        } else {
          _returns.addAll(response.salesReturns);
        }
        _totalCount = response.total;
        _offset += response.salesReturns.length;
      } else {
        _error = 'Failed to fetch returns';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _returns = [];
    _totalCount = 0;
    _offset = 0;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    super.dispose();
  }

}
