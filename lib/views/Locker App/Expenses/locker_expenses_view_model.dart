import 'package:flutter/material.dart';

import '../../../data/network/base_api_service.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/session_service.dart';
import '../../../utils/debug_log.dart';

enum LockerExpensesState { idle, loading, success, error }

enum LockerExpensesTab { record, log }

/// Fallback categories when the API call fails (same list as web).
/// English API names — display via [pettyCashExpenseCategoryLabel].
const List<String> kLockerExpenseCategoriesFallback = [
  'Advertising and promotion',
  'Bank charges',
  'Charity / Donations / Reward Expenses',
  'Customer Compensation Expenses',
  'Customer services expenses',
  'Development & Renovation Expenses',
  'Food & Entertainment',
  'Fuel Allowance Expenses',
  'Information Technology Expenses',
  'Labour uniform & shoes Expenses',
  'Medical Expenses',
  'Misc Accommodation Expenses',
  'Misc Expenses',
  'Misc Government Expenses',
  'Motor vehicle Repair Expenses',
  'Municipal / Garbage Expenses - شركة الهلب للتجارية و المقاولات',
  'POL Expenses',
  'Printing and stationery',
  'Repair & maintenance Expenses - Accomodation',
  'Repair & maintenance Expenses - Car Wash',
  'Salary Advances',
];

class ExpenseLineDraft {
  final String key;
  String? branchId;
  String category;
  String amount;
  DateTime expenseDate;
  String description;
  String proofUrl;

  ExpenseLineDraft({
    String? key,
    this.branchId,
    String? category,
    this.amount = '',
    DateTime? expenseDate,
    this.description = '',
    this.proofUrl = '',
  })  : key = key ??
            '${DateTime.now().microsecondsSinceEpoch}-'
                '${identityHashCode(Object())}',
        category = category ?? kLockerExpenseCategoriesFallback.first,
        expenseDate = expenseDate ?? DateTime.now();

  ExpenseLineDraft copyWith({
    String? branchId,
    String? category,
    String? amount,
    DateTime? expenseDate,
    String? description,
    String? proofUrl,
  }) {
    return ExpenseLineDraft(
      key: key,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      proofUrl: proofUrl ?? this.proofUrl,
    );
  }
}

class LockerExpensesViewModel extends ChangeNotifier {
  final LockerRepository _repo;
  final SessionService _session;

  LockerExpensesViewModel({
    LockerRepository? repository,
    SessionService? session,
  })  : _repo = repository ?? LockerRepository(),
        _session = session ?? SessionService();

  String? _token;

  LockerExpensesState _state = LockerExpensesState.idle;
  String? _error;
  LockerExpensesSummary _summary = LockerExpensesSummary.empty();
  List<LockerExpenseEntry> _expenses = const [];

  LockerExpensesState get state => _state;
  String? get error => _error;
  LockerExpensesSummary get summary => _summary;
  List<LockerExpenseEntry> get expenses => List.unmodifiable(_expenses);

  bool get isLoading => _state == LockerExpensesState.loading;
  bool get isSuccess => _state == LockerExpensesState.success;
  bool get isError => _state == LockerExpensesState.error;

  LockerExpensesTab _tab = LockerExpensesTab.record;
  LockerExpensesTab get tab => _tab;

  // ── Log filters (default = last 30 days, matching web) ─────────────────────
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  String? _selectedBranchId;
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';

  DateTime get from => _from;
  DateTime get to => _to;
  String? get selectedBranchId => _selectedBranchId;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;

  bool get hasActiveFilters =>
      _selectedBranchId != null ||
      _selectedCategory != 'all' ||
      _selectedStatus != 'all';

  List<LockerBranch> _branches = [];
  bool _branchesLoading = false;
  List<String> _categories = List.from(kLockerExpenseCategoriesFallback);
  bool _categoriesLoading = false;

  List<LockerBranch> get branches => List.unmodifiable(_branches);
  bool get branchesLoading => _branchesLoading;
  List<String> get categories => List.unmodifiable(_categories);
  bool get categoriesLoading => _categoriesLoading;

  // ── Record tab ─────────────────────────────────────────────────────────────
  List<ExpenseLineDraft> _lines = [ExpenseLineDraft()];
  bool _submitting = false;
  String? _submitError;
  String? _submitSuccess;

  List<ExpenseLineDraft> get lines => List.unmodifiable(_lines);
  bool get submitting => _submitting;
  String? get submitError => _submitError;
  String? get submitSuccess => _submitSuccess;

  double get linesTotal => _lines.fold<double>(
        0,
        (sum, ln) => sum + (double.tryParse(ln.amount.trim()) ?? 0),
      );

  AppLocalizations? _l10n(BuildContext? context) =>
      context != null ? AppLocalizations.of(context) : null;

  Future<void> init([BuildContext? context]) async {
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
    notifyListeners();

    final l10n = _l10n(context);
    try {
      _token = await _session.getToken(role: 'locker');
      if (_token == null) {
        _setError(l10n?.lockerSessionExpired ??
            'Session expired. Please log in again.');
        return;
      }
    } catch (e) {
      _setError(
        '${l10n?.lockerFailedLoadSession ?? 'Failed to load session.'} ${_friendly(e)}'
            .trim(),
      );
      return;
    }

    await Future.wait([
      _loadLog(context),
      _loadBranches(),
      _loadCategories(),
    ]);
    _ensureDefaultBranchOnLines();
  }

  void setTab(LockerExpensesTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  Future<void> setDateRange(DateTime from, DateTime to,
      [BuildContext? context]) async {
    final nextFrom = DateTime(from.year, from.month, from.day);
    final nextTo = DateTime(to.year, to.month, to.day);
    if (_from == nextFrom && _to == nextTo) return;
    _from = nextFrom;
    _to = nextTo;
    await _loadLog(context);
  }

  Future<void> setSelectedBranch(String? branchId,
      [BuildContext? context]) async {
    final next = branchId == 'all' ? null : branchId;
    if (_selectedBranchId == next) return;
    _selectedBranchId = next;
    notifyListeners();
    await _loadLog(context);
  }

  Future<void> setSelectedCategory(String? category,
      [BuildContext? context]) async {
    final next = category ?? 'all';
    if (_selectedCategory == next) return;
    _selectedCategory = next;
    notifyListeners();
    await _loadLog(context);
  }

  Future<void> setSelectedStatus(String? status,
      [BuildContext? context]) async {
    final next = status ?? 'all';
    if (_selectedStatus == next) return;
    _selectedStatus = next;
    notifyListeners();
    await _loadLog(context);
  }

  Future<void> clearFilters([BuildContext? context]) async {
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
    _selectedBranchId = null;
    _selectedCategory = 'all';
    _selectedStatus = 'all';
    notifyListeners();
    await _loadLog(context);
  }

  Future<void> refresh([BuildContext? context]) => _loadLog(context);

  void addLine() {
    final base = _lines.isNotEmpty ? _lines.first : null;
    _lines = [
      ..._lines,
      ExpenseLineDraft(
        branchId: base?.branchId,
        category: base?.category ??
            (_categories.isNotEmpty
                ? _categories.first
                : kLockerExpenseCategoriesFallback.first),
        expenseDate: base?.expenseDate,
      ),
    ];
    _submitError = null;
    _submitSuccess = null;
    notifyListeners();
  }

  void removeLine(String key) {
    if (_lines.length <= 1) return;
    _lines = _lines.where((ln) => ln.key != key).toList();
    _submitError = null;
    notifyListeners();
  }

  void updateLine(String key, {
    String? branchId,
    bool clearBranch = false,
    String? category,
    String? amount,
    DateTime? expenseDate,
    String? description,
    String? proofUrl,
  }) {
    _lines = _lines.map((ln) {
      if (ln.key != key) return ln;
      return ExpenseLineDraft(
        key: ln.key,
        branchId: clearBranch ? null : (branchId ?? ln.branchId),
        category: category ?? ln.category,
        amount: amount ?? ln.amount,
        expenseDate: expenseDate ?? ln.expenseDate,
        description: description ?? ln.description,
        proofUrl: proofUrl ?? ln.proofUrl,
      );
    }).toList();
    _submitError = null;
    notifyListeners();
  }

  /// Returns null on success (or user cancelled), or a validation / API error.
  Future<String?> submitBulk({BuildContext? context}) async {
    final l10n = _l10n(context);
    _submitError = null;
    _submitSuccess = null;

    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _lines.length; i++) {
      final ln = _lines[i];
      final amt = double.tryParse(ln.amount.trim()) ?? 0;
      final n = '${i + 1}';
      if (ln.branchId == null || ln.branchId!.isEmpty) {
        _submitError = l10n?.lockerLineSelectBranch(n) ??
            'Line ${i + 1}: select a branch';
        notifyListeners();
        return _submitError;
      }
      if (ln.category.trim().isEmpty) {
        _submitError = l10n?.lockerLineSelectCategory(n) ??
            'Line ${i + 1}: select a category';
        notifyListeners();
        return _submitError;
      }
      if (!(amt > 0)) {
        _submitError = l10n?.lockerLineEnterAmount(n) ??
            'Line ${i + 1}: enter a valid amount';
        notifyListeners();
        return _submitError;
      }
      final d = ln.expenseDate;
      final dateStr =
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      items.add({
        'branchId': ln.branchId,
        'category': ln.category, // English API name
        'amount': amt,
        if (ln.description.trim().isNotEmpty) 'description': ln.description.trim(),
        'expenseDate': dateStr,
        if (ln.proofUrl.trim().isNotEmpty) 'proofUrl': ln.proofUrl.trim(),
      });
    }

    if (_token == null) {
      _submitError = l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.';
      notifyListeners();
      return _submitError;
    }

    _submitting = true;
    notifyListeners();

    try {
      final res = await _repo.createExpensesBulk(token: _token!, items: items);
      final keep = _lines.first;
      _lines = [
        ExpenseLineDraft(
          branchId: keep.branchId,
          category: keep.category,
          expenseDate: keep.expenseDate,
        ),
      ];
      _submitSuccess = res.message.isNotEmpty
          ? res.message
          : (l10n?.lockerExpensesSubmitted ??
              'Expenses submitted for approval');
      _submitting = false;
      _tab = LockerExpensesTab.log;
      notifyListeners();
      await _loadLog(context);
      return null;
    } on UnauthorisedException {
      _submitError = l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.';
    } on BadRequestException catch (e) {
      _submitError = _friendly(e);
    } on FetchDataException catch (e) {
      _submitError = _friendly(e);
    } catch (e, st) {
      _submitError =
          l10n?.lockerOperationFailed ?? 'Operation failed.';
      debugLog('[LockerExpensesVM] submit $e\n$st');
    }
    _submitting = false;
    notifyListeners();
    return _submitError;
  }

  Future<void> _loadLog([BuildContext? context]) async {
    if (_token == null) return;
    final l10n = _l10n(context);
    _state = LockerExpensesState.loading;
    _error = null;
    notifyListeners();

    try {
      final page = await _repo.getExpenses(
        token: _token!,
        from: _from,
        to: _to,
        branchId: _selectedBranchId,
        category: _selectedCategory,
        status: _selectedStatus,
        limit: 100,
      );
      _summary = page.summary;
      _expenses = page.expenses;
      _state = LockerExpensesState.success;
      notifyListeners();
      debugLog(
        '[LockerExpensesVM] ${page.expenses.length} expenses '
        'posted=${page.summary.totalAmount} pending=${page.summary.pendingCount}',
      );
    } on UnauthorisedException {
      _setError(l10n?.lockerSessionExpired ??
          'Session expired. Please log in again.');
    } on BadRequestException catch (e) {
      _setError(l10n != null
          ? l10n.lockerBadRequest(_friendly(e))
          : 'Bad request: ${_friendly(e)}');
    } on FetchDataException catch (e) {
      _setError(_friendly(e));
    } catch (e, st) {
      _setError(
          l10n?.lockerSomethingWentWrong ?? 'Something went wrong.');
      debugLog('[LockerExpensesVM] $e\n$st');
    }
  }

  Future<void> _loadBranches() async {
    if (_token == null) return;
    _branchesLoading = true;
    notifyListeners();
    try {
      _branches = await _repo.getBranches(token: _token!);
    } catch (e) {
      debugLog('[LockerExpensesVM] branches load failed: $e');
    } finally {
      _branchesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    if (_token == null) return;
    _categoriesLoading = true;
    notifyListeners();
    try {
      final cats = await _repo.getExpenseCategories(token: _token!);
      if (cats.isNotEmpty) {
        _categories = cats;
        // Keep first line category valid if still using fallback first.
        _lines = _lines.map((ln) {
          if (_categories.contains(ln.category)) return ln;
          return ExpenseLineDraft(
            key: ln.key,
            branchId: ln.branchId,
            category: _categories.first,
            amount: ln.amount,
            expenseDate: ln.expenseDate,
            description: ln.description,
            proofUrl: ln.proofUrl,
          );
        }).toList();
      }
    } catch (e) {
      debugLog('[LockerExpensesVM] categories load failed: $e');
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  void _ensureDefaultBranchOnLines() {
    if (_branches.isEmpty) return;
    final preferred = _branches.first.id;
    var changed = false;
    _lines = _lines.map((ln) {
      if (ln.branchId != null && ln.branchId!.isNotEmpty) return ln;
      changed = true;
      return ExpenseLineDraft(
        key: ln.key,
        branchId: preferred,
        category: ln.category,
        amount: ln.amount,
        expenseDate: ln.expenseDate,
        description: ln.description,
        proofUrl: ln.proofUrl,
      );
    }).toList();
    if (changed) notifyListeners();
  }

  void _setError(String msg) {
    _state = LockerExpensesState.error;
    _error = msg;
    notifyListeners();
    debugLog('[LockerExpensesVM] error: $msg');
  }

  String _friendly(Object e) {
    final raw = e.toString();
    for (final p in [
      'Error During Communication: ',
      'Invalid Request: ',
      'Unauthorised: ',
    ]) {
      if (raw.startsWith(p)) return raw.substring(p.length);
    }
    return raw;
  }
}
