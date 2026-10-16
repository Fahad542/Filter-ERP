import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/owner_repository.dart';
import '../../../../services/owner_data_service.dart';
import '../../../../services/session_service.dart';

class CoaExpenseAccount {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String type;
  final String subType;
  final String? branchId;
  final String branchLabel;
  final String status;
  final bool isAutoLinked;
  final bool isControl;
  final double closingDebit;
  final double closingCredit;

  const CoaExpenseAccount({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    required this.subType,
    this.branchId,
    required this.branchLabel,
    required this.status,
    required this.isAutoLinked,
    required this.isControl,
    required this.closingDebit,
    required this.closingCredit,
  });

  String get subtypeLabel => _humanize(subType);

  String get normalBalance =>
      (type == 'ASSET' || type == 'EXPENSE') ? 'Debit' : 'Credit';

  bool get isActive => status.toLowerCase() == 'active';

  /// Same display rule as web `formatFinalBalance`, without SAR prefix.
  String get finalBalanceText {
    if (closingDebit >= 0.005) {
      return '${_fmt(closingDebit)} Dr';
    }
    if (closingCredit >= 0.005) {
      return '${_fmt(closingCredit)} Cr';
    }
    return '—';
  }

  bool get isDebitBalance => closingDebit >= 0.005;
  bool get isCreditBalance => closingCredit >= 0.005;

  static String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final whole = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final fromEnd = whole.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '${buf.toString()}.${parts[1]}';
  }

  static String _humanize(String value) {
    if (value.isEmpty) return '—';
    return value
        .toLowerCase()
        .split('_')
        .map((c) => c.isEmpty ? c : '${c[0].toUpperCase()}${c.substring(1)}')
        .join(' ');
  }

  factory CoaExpenseAccount.fromJson(
    Map<String, dynamic> j, {
    Map<String, String> branchNames = const {},
  }) {
    final branchId = j['branchId']?.toString();
    final code = j['code']?.toString() ?? '';
    final name = j['name']?.toString() ?? '';
    final isAuto =
        j['isAutoLinked'] == true || j['isAutoSeed'] == true;
    // Matches web WORKSHOP_COA_CONTROL_BADGES / petty-cash control codes.
    const controlCodes = {'1280', '6100'};
    final isControl = controlCodes.contains(code);
    return CoaExpenseAccount(
      id: j['id']?.toString() ?? '',
      code: code,
      name: name,
      description: j['description']?.toString(),
      type: j['type']?.toString() ?? 'EXPENSE',
      subType: j['subType']?.toString() ?? '',
      branchId: branchId,
      branchLabel: (branchId != null && branchNames[branchId] != null)
          ? branchNames[branchId]!
          : 'Shared',
      status: j['status']?.toString() ?? 'active',
      isAutoLinked: isAuto,
      isControl: isControl,
      closingDebit: _toDouble(j['closingDebit']),
      closingCredit: _toDouble(j['closingCredit']),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class CoaBranchOption {
  final String id;
  final String name;
  const CoaBranchOption({required this.id, required this.name});
}

class CoaExpensesViewModel extends ChangeNotifier {
  final OwnerRepository _repo;
  final SessionService _session;
  final OwnerDataService _ownerData;

  CoaExpensesViewModel({
    required OwnerRepository ownerRepository,
    required SessionService sessionService,
    required OwnerDataService ownerDataService,
  })  : _repo = ownerRepository,
        _session = sessionService,
        _ownerData = ownerDataService {
    _branchId = _ownerData.selectedBranchId;
    _lastSyncedBranchId = _branchId;
    _ownerData.addListener(_onOwnerDataChanged);
  }

  List<CoaExpenseAccount> _accounts = const [];
  List<CoaBranchOption> _branches = const [];
  String? _branchId;
  String? _lastSyncedBranchId;
  String _search = '';
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  List<CoaExpenseAccount> get accounts {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _accounts;
    return _accounts.where((a) {
      return '${a.code} ${a.name} ${a.description ?? ''}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  List<CoaBranchOption> get branches => _branches;
  String? get branchId => _branchId;
  String get search => _search;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _accounts.length;

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerData.selectedBranchId;
    if (!force && next == _lastSyncedBranchId) return;
    _lastSyncedBranchId = next;
    _branchId = next;
    if (_initialized) await loadAccounts();
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
    await Future.wait([loadBranches(), loadAccounts()]);
  }

  Future<void> loadBranches() async {
    try {
      final token = await _session.getToken(role: 'owner');
      if (token == null || token.isEmpty) return;
      final rows = await _repo.getAccountsBranches(token);
      _branches = rows
          .map((b) => CoaBranchOption(
                id: b['id']?.toString() ?? '',
                name: b['name']?.toString() ?? '',
              ))
          .where((b) => b.id.isNotEmpty)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[CoaExpensesViewModel] loadBranches: $e');
    }
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await _session.getToken(role: 'owner');
      if (token == null || token.isEmpty) {
        _error = 'Not authenticated';
        _accounts = const [];
        return;
      }
      final branchNames = {
        for (final b in _branches) b.id: b.name,
      };
      final rows = await _repo.getChartAccounts(
        token,
        type: 'EXPENSE',
        branchId: _branchId,
      );
      final list = rows
          .map((j) => CoaExpenseAccount.fromJson(j, branchNames: branchNames))
          .where((a) => a.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      _accounts = list;
    } catch (e) {
      debugPrint('[CoaExpensesViewModel] loadAccounts: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _accounts = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setBranchId(String? id) {
    final next = (id == null || id.isEmpty || id == 'all') ? null : id;
    _branchId = next;
    _lastSyncedBranchId = next;
    notifyListeners();
    loadAccounts();
  }

  Future<void> refresh() => loadAccounts();
}
