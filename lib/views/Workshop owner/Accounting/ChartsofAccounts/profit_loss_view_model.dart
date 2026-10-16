import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/owner_repository.dart';
import '../../../../services/owner_data_service.dart';
import '../../../../services/session_service.dart';

// ── Models matching GET /accounts/reports/pl ─────────────────────────────────

class PlLineItem {
  final String id;
  final String name;
  final String code;
  final double amount;

  const PlLineItem({
    required this.id,
    required this.name,
    required this.code,
    required this.amount,
  });

  factory PlLineItem.fromJson(Map<String, dynamic> j) => PlLineItem(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        code: j['code']?.toString() ?? '',
        amount: _toDouble(j['amount']),
      );
}

class ProfitLossReport {
  final List<PlLineItem> revenue;
  final double totalRevenue;
  final List<PlLineItem> costOfGoodsSold;
  final double totalCOGS;
  final double grossProfit;
  final List<PlLineItem> operatingExpenses;
  final double totalOperatingExpenses;
  final List<PlLineItem> otherIncome;
  final double totalOtherIncome;
  final List<PlLineItem> otherExpenses;
  final double totalOtherExpenses;
  final double netIncome;

  const ProfitLossReport({
    this.revenue = const [],
    this.totalRevenue = 0,
    this.costOfGoodsSold = const [],
    this.totalCOGS = 0,
    this.grossProfit = 0,
    this.operatingExpenses = const [],
    this.totalOperatingExpenses = 0,
    this.otherIncome = const [],
    this.totalOtherIncome = 0,
    this.otherExpenses = const [],
    this.totalOtherExpenses = 0,
    this.netIncome = 0,
  });

  factory ProfitLossReport.fromJson(Map<String, dynamic> j) {
    List<PlLineItem> list(dynamic v) {
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map((e) => PlLineItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return ProfitLossReport(
      revenue: list(j['revenue']),
      totalRevenue: _toDouble(j['totalRevenue']),
      costOfGoodsSold: list(j['costOfGoodsSold']),
      totalCOGS: _toDouble(j['totalCOGS']),
      grossProfit: _toDouble(j['grossProfit']),
      operatingExpenses: list(j['operatingExpenses']),
      totalOperatingExpenses: _toDouble(j['totalOperatingExpenses']),
      otherIncome: list(j['otherIncome']),
      totalOtherIncome: _toDouble(j['totalOtherIncome']),
      otherExpenses: list(j['otherExpenses']),
      totalOtherExpenses: _toDouble(j['totalOtherExpenses']),
      netIncome: _toDouble(j['netIncome']),
    );
  }

  static const empty = ProfitLossReport();
}

class PlBranchOption {
  final String id;
  final String name;
  const PlBranchOption({required this.id, required this.name});
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class ProfitLossViewModel extends ChangeNotifier {
  final OwnerRepository _repo;
  final SessionService _session;
  final OwnerDataService _ownerData;

  ProfitLossViewModel({
    required OwnerRepository ownerRepository,
    required SessionService sessionService,
    required OwnerDataService ownerDataService,
  })  : _repo = ownerRepository,
        _session = sessionService,
        _ownerData = ownerDataService {
    _branchId = _ownerData.selectedBranchId;
    _lastSyncedBranchId = _branchId;
    _lastSyncedDateGeneration = _ownerData.dateGeneration;
    _ownerData.addListener(_onOwnerDataChanged);
  }

  String? _branchId; // null = all branches
  String? _lastSyncedBranchId;
  int _lastSyncedDateGeneration = -1;

  List<PlBranchOption> _branches = const [];
  ProfitLossReport _report = ProfitLossReport.empty;
  bool _isLoading = true;
  bool _branchesLoading = false;
  String? _error;
  bool _initialized = false;

  DateTime get fromDate => _ownerData.filterFrom;
  DateTime get toDate => _ownerData.filterTo;
  String? get branchId => _branchId;
  List<PlBranchOption> get branches => _branches;
  ProfitLossReport get report => _report;
  bool get isLoading => _isLoading;
  bool get branchesLoading => _branchesLoading;
  String? get error => _error;
  bool get isInitialized => _initialized;

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
    _branchId = next;
    if (_initialized) await loadReport();
  }

  @override
  void dispose() {
    _ownerData.removeListener(_onOwnerDataChanged);
    super.dispose();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _branchId = _ownerData.selectedBranchId;
    _lastSyncedBranchId = _branchId;
    _lastSyncedDateGeneration = _ownerData.dateGeneration;
    await Future.wait([loadBranches(), loadReport()]);
  }

  Future<void> loadBranches() async {
    _branchesLoading = true;
    notifyListeners();
    try {
      final token = await _session.getToken(role: 'owner');
      if (token == null || token.isEmpty) {
        _branches = const [];
        return;
      }
      final rows = await _repo.getAccountsBranches(token);
      _branches = rows
          .map((b) => PlBranchOption(
                id: b['id']?.toString() ?? '',
                name: b['name']?.toString() ?? '',
              ))
          .where((b) => b.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[ProfitLossViewModel] loadBranches: $e');
      _branches = const [];
    } finally {
      _branchesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _session.getToken(role: 'owner');
      if (token == null || token.isEmpty) {
        _error = 'Not authenticated';
        _report = ProfitLossReport.empty;
        return;
      }
      final raw = await _repo.getProfitAndLossReport(
        token,
        dateFrom: OwnerRepository.reportsRangeStartIso(fromDate),
        dateTo: OwnerRepository.reportsRangeEndIso(toDate),
        branchId: _branchId,
      );
      _report = ProfitLossReport.fromJson(raw);
    } catch (e) {
      debugPrint('[ProfitLossViewModel] loadReport: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _report = ProfitLossReport.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setBranchId(String? id) {
    final next = (id == null || id.isEmpty || id == 'all') ? null : id;
    _branchId = next;
    _lastSyncedBranchId = next;
    notifyListeners();
  }

  Future<void> applyFilters() => loadReport();

  Future<void> refresh() => loadReport();
}
