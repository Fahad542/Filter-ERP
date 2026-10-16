import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

class StaffWallet {
  final String id;
  final String name;
  final String nameAr;
  final String role;
  final String branch;
  final double balance;
  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedRole;
  final String? translatedBranch;

  const StaffWallet({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.role,
    required this.branch,
    required this.balance,
    this.translatedName,
    this.translatedRole,
    this.translatedBranch,
  });

  String get displayName {
    final base = translatedName ?? name;
    return nameAr.isNotEmpty ? '$base $nameAr' : base;
  }

  String get displayRole => translatedRole ?? role;
  String get displayBranch => translatedBranch ?? branch;

  StaffWallet copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? role,
    String? branch,
    double? balance,
    String? translatedName,
    String? translatedRole,
    String? translatedBranch,
  }) {
    return StaffWallet(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      balance: balance ?? this.balance,
      translatedName: translatedName ?? this.translatedName,
      translatedRole: translatedRole ?? this.translatedRole,
      translatedBranch: translatedBranch ?? this.translatedBranch,
    );
  }
}

class StaffRequest {
  final String id;
  /// Wallet / user id for ledger filter (`walletUserId`).
  final String userId;
  final DateTime date;
  final String staffName;
  final String type;
  final String branch;
  final double amount;
  final String status;
  final String payFrom;
  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedStaffName;
  final String? translatedType;
  final String? translatedBranch;
  final String? translatedStatus;
  final String? translatedPayFrom;

  const StaffRequest({
    required this.id,
    this.userId = '',
    required this.date,
    required this.staffName,
    required this.type,
    required this.branch,
    required this.amount,
    required this.status,
    required this.payFrom,
    this.translatedStaffName,
    this.translatedType,
    this.translatedBranch,
    this.translatedStatus,
    this.translatedPayFrom,
  });

  String get displayStaffName => translatedStaffName ?? staffName;
  String get displayType => translatedType ?? type;
  String get displayBranch => translatedBranch ?? branch;
  String get displayStatus => translatedStatus ?? status;
  String get displayPayFrom => translatedPayFrom ?? payFrom;

  StaffRequest copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? staffName,
    String? type,
    String? branch,
    double? amount,
    String? status,
    String? payFrom,
    String? translatedStaffName,
    String? translatedType,
    String? translatedBranch,
    String? translatedStatus,
    String? translatedPayFrom,
  }) {
    return StaffRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      staffName: staffName ?? this.staffName,
      type: type ?? this.type,
      branch: branch ?? this.branch,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      payFrom: payFrom ?? this.payFrom,
      translatedStaffName: translatedStaffName ?? this.translatedStaffName,
      translatedType: translatedType ?? this.translatedType,
      translatedBranch: translatedBranch ?? this.translatedBranch,
      translatedStatus: translatedStatus ?? this.translatedStatus,
      translatedPayFrom: translatedPayFrom ?? this.translatedPayFrom,
    );
  }
}

class WalletEntry {
  final DateTime date;
  final String type;
  final double amount;
  final String description;
  final String source;
  final String reference;

  const WalletEntry({
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    required this.source,
    required this.reference,
  });
}

class IssuanceTarget {
  final String id;
  final String name;
  final String role;
  final String? branchId;
  final String? branchName;
  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedRole;
  final String? translatedBranchName;

  const IssuanceTarget({
    required this.id,
    required this.name,
    this.role = '',
    this.branchId,
    this.branchName,
    this.translatedName,
    this.translatedRole,
    this.translatedBranchName,
  });

  String get displayName {
    final n = translatedName ?? name;
    final r = (translatedRole ?? role).trim();
    if (r.isEmpty) return n;
    return '$n (${r.replaceAll('_', ' ')})';
  }

  IssuanceTarget copyWith({
    String? id,
    String? name,
    String? role,
    String? branchId,
    String? branchName,
    String? translatedName,
    String? translatedRole,
    String? translatedBranchName,
  }) {
    return IssuanceTarget(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      translatedName: translatedName ?? this.translatedName,
      translatedRole: translatedRole ?? this.translatedRole,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
    );
  }
}

class CashBankPayFromOption {
  final String id;
  final String name;
  final String type;
  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;

  const CashBankPayFromOption({
    required this.id,
    required this.name,
    this.type = '',
    this.translatedName,
  });

  String get displayLabel {
    final n = translatedName ?? name;
    if (type.trim().isEmpty) return n;
    return '$n (${type.replaceAll('_', ' ')})';
  }

  CashBankPayFromOption copyWith({
    String? id,
    String? name,
    String? type,
    String? translatedName,
  }) {
    return CashBankPayFromOption(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      translatedName: translatedName ?? this.translatedName,
    );
  }
}

class PettyCashReportRow {
  final String id;
  final String date;
  final String walletUserLabel;
  final String expenseCategoryLabel;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;
  final bool hasExpenseProof;
  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedWalletUserLabel;
  final String? translatedExpenseCategoryLabel;
  final String? translatedDescription;

  const PettyCashReportRow({
    required this.id,
    required this.date,
    required this.walletUserLabel,
    required this.expenseCategoryLabel,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.hasExpenseProof = false,
    this.translatedWalletUserLabel,
    this.translatedExpenseCategoryLabel,
    this.translatedDescription,
  });

  String get displayWalletUserLabel =>
      translatedWalletUserLabel ?? walletUserLabel;
  String get displayExpenseCategoryLabel =>
      translatedExpenseCategoryLabel ?? expenseCategoryLabel;
  String get displayDescription => translatedDescription ?? description;

  PettyCashReportRow copyWith({
    String? id,
    String? date,
    String? walletUserLabel,
    String? expenseCategoryLabel,
    String? description,
    double? debit,
    double? credit,
    double? runningBalance,
    bool? hasExpenseProof,
    String? translatedWalletUserLabel,
    String? translatedExpenseCategoryLabel,
    String? translatedDescription,
  }) {
    return PettyCashReportRow(
      id: id ?? this.id,
      date: date ?? this.date,
      walletUserLabel: walletUserLabel ?? this.walletUserLabel,
      expenseCategoryLabel:
          expenseCategoryLabel ?? this.expenseCategoryLabel,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      runningBalance: runningBalance ?? this.runningBalance,
      hasExpenseProof: hasExpenseProof ?? this.hasExpenseProof,
      translatedWalletUserLabel:
          translatedWalletUserLabel ?? this.translatedWalletUserLabel,
      translatedExpenseCategoryLabel: translatedExpenseCategoryLabel ??
          this.translatedExpenseCategoryLabel,
      translatedDescription:
          translatedDescription ?? this.translatedDescription,
    );
  }
}

class PettyCashReportFilterOption {
  final String id;
  final String label;
  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedLabel;

  const PettyCashReportFilterOption({
    required this.id,
    required this.label,
    this.translatedLabel,
  });

  String get displayLabel => translatedLabel ?? label;

  PettyCashReportFilterOption copyWith({
    String? id,
    String? label,
    String? translatedLabel,
  }) {
    return PettyCashReportFilterOption(
      id: id ?? this.id,
      label: label ?? this.label,
      translatedLabel: translatedLabel ?? this.translatedLabel,
    );
  }
}

/// Snapshot for employee statement sheet (does not mutate Report tab filters).
class PettyCashEmployeeStatement {
  final String companyName;
  final String accountCode;
  final String accountName;
  final DateTime dateFrom;
  final DateTime dateTo;
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final List<PettyCashReportRow> rows;

  const PettyCashEmployeeStatement({
    required this.companyName,
    required this.accountCode,
    required this.accountName,
    required this.dateFrom,
    required this.dateTo,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.rows,
  });
}

/// Workshop Petty Cash management — mirrors web
/// `WorkshopPettyCashManagement.jsx` (wallets + requests by branch).
class PettyCashViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  final SettingsViewModel? settingsViewModel;

  PettyCashViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    this.settingsViewModel,
  }) {
    _branchId = ownerDataService.selectedBranchId;
    _lastSyncedBranchId = _branchId;
    _lastSyncedDateGeneration = ownerDataService.dateGeneration;
    _reportBranchFilter = _branchId;
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
  }

  // ── Locale re-translation ─────────────────────────────────────────────────

  Future<void> retranslate() async {
    await Future.wait([
      _applyWalletTranslations(),
      _applyRequestTranslations(),
      _applyIssuanceTargetTranslations(),
      _applyCashBankTranslations(),
      _applyReportRowTranslations(),
      _applyReportFilterTranslations(),
    ]);
    notifyListeners();
  }

  Future<void> _applyWalletTranslations() async {
    _wallets = await Future.wait(_wallets.map((w) async => w.copyWith(
          translatedName: await tPerson(w.name),
          translatedRole: await tUiStatus(w.role),
          translatedBranch: await tBranch(w.branch),
        )));
  }

  Future<void> _applyRequestTranslations() async {
    _requests = await Future.wait(_requests.map((r) async => r.copyWith(
          translatedStaffName: await tPerson(r.staffName),
          translatedType: await tUiStatus(r.type),
          translatedBranch: await tBranch(r.branch),
          translatedStatus: await tUiStatus(r.status),
          translatedPayFrom: await t(r.payFrom),
        )));
  }

  Future<void> _applyIssuanceTargetTranslations() async {
    _issuanceTargets = await Future.wait(_issuanceTargets.map((tgt) async => tgt.copyWith(
          translatedName: await tPerson(tgt.name),
          translatedRole: await tUiStatus(tgt.role),
          translatedBranchName:
              tgt.branchName != null ? await tBranch(tgt.branchName!) : null,
        )));
  }

  Future<void> _applyCashBankTranslations() async {
    _cashBankAccounts = await Future.wait(_cashBankAccounts.map((a) async => a.copyWith(
          translatedName: await t(a.name),
        )));
  }

  Future<void> _applyReportRowTranslations() async {
    _reportRows = await Future.wait(_reportRows.map((r) async => r.copyWith(
          translatedWalletUserLabel: await tPerson(r.walletUserLabel),
          translatedExpenseCategoryLabel: await t(r.expenseCategoryLabel),
          translatedDescription: await tNotes(r.description),
        )));
  }

  Future<void> _applyReportFilterTranslations() async {
    _reportWalletUsers = await Future.wait(_reportWalletUsers.map((o) async => o.copyWith(
          translatedLabel: await tPerson(o.label),
        )));
    _reportCategories = await Future.wait(_reportCategories.map((o) async => o.copyWith(
          translatedLabel: await t(o.label),
        )));
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    super.dispose();
  }

  String? _branchId;
  String? _lastSyncedBranchId;
  int _lastSyncedDateGeneration = -1;

  bool _isLoading = false;
  String? _error;
  List<StaffWallet> _wallets = [];
  List<StaffRequest> _requests = [];
  List<IssuanceTarget> _issuanceTargets = [];
  List<CashBankPayFromOption> _cashBankAccounts = [];
  bool _issueFormLoading = false;
  bool _issueSubmitting = false;

  // ── Report (Employee Petty Cash Expense [6100] ledger) ─────────────────
  bool _reportLoading = false;
  bool _reportLoadedOnce = false;
  String? _reportError;
  String? _reportAccountId;
  /// Cached [1280] fund account id for per-employee statement screen.
  String? _fundAccountId;
  String _reportAccountCode = '6100';
  String _reportAccountName = 'Employee Petty Cash Expense';
  String _reportAccountType = 'EXPENSE';
  String _reportCompanyName = '';
  String? _reportBranchFilter;
  String? _reportWalletUserId;
  String? _reportExpenseCategory;
  double _reportOpeningBalance = 0;
  double _reportTotalDebit = 0;
  double _reportTotalCredit = 0;
  double _reportClosingBalance = 0;
  List<PettyCashReportRow> _reportRows = [];
  List<PettyCashReportFilterOption> _reportWalletUsers = [];
  List<PettyCashReportFilterOption> _reportCategories = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<StaffWallet> get wallets => List.unmodifiable(_wallets);
  List<StaffRequest> get requests => List.unmodifiable(_requests);
  List<IssuanceTarget> get issuanceTargets =>
      List.unmodifiable(_issuanceTargets);
  List<CashBankPayFromOption> get cashBankAccounts =>
      List.unmodifiable(_cashBankAccounts);
  bool get issueFormLoading => _issueFormLoading;
  bool get issueSubmitting => _issueSubmitting;
  String? get branchId => _branchId;

  bool get reportLoading => _reportLoading;
  bool get reportLoadedOnce => _reportLoadedOnce;
  String? get reportError => _reportError;
  DateTime get reportDateFrom => DateTime(
        ownerDataService.filterFrom.year,
        ownerDataService.filterFrom.month,
        ownerDataService.filterFrom.day,
      );
  DateTime get reportDateTo => DateTime(
        ownerDataService.filterTo.year,
        ownerDataService.filterTo.month,
        ownerDataService.filterTo.day,
      );
  String? get reportBranchFilter => _reportBranchFilter;
  String? get reportWalletUserId => _reportWalletUserId;
  String? get reportExpenseCategory => _reportExpenseCategory;
  String get reportAccountCode => _reportAccountCode;
  String get reportAccountName => _reportAccountName;
  String get reportAccountType => _reportAccountType;
  String get reportCompanyName => _reportCompanyName;
  double get reportOpeningBalance => _reportOpeningBalance;
  double get reportTotalDebit => _reportTotalDebit;
  double get reportTotalCredit => _reportTotalCredit;
  double get reportClosingBalance => _reportClosingBalance;
  List<PettyCashReportRow> get reportRows => List.unmodifiable(_reportRows);
  List<PettyCashReportFilterOption> get reportWalletUsers =>
      List.unmodifiable(_reportWalletUsers);
  List<PettyCashReportFilterOption> get reportCategories =>
      List.unmodifiable(_reportCategories);

  List<MapEntry<String, String>> get branchOptions {
    final opts = <MapEntry<String, String>>[];
    for (final b in ownerDataService.branches) {
      if (b.id.trim().isEmpty) continue;
      opts.add(MapEntry(b.id, b.name));
    }
    return opts;
  }

  double get totalFloat =>
      _wallets.fold(0.0, (sum, w) => sum + w.balance);

  int get pendingCount =>
      _requests.where((r) => r.status.toLowerCase() == 'pending').length;

  double get pendingAmount => _requests
      .where((r) => r.status.toLowerCase() == 'pending')
      .fold(0.0, (sum, r) => sum + r.amount);

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = ownerDataService.selectedBranchId;
    final nextDateGen = ownerDataService.dateGeneration;
    final dateChanged = nextDateGen != _lastSyncedDateGeneration;
    if (!force &&
        next == _lastSyncedBranchId &&
        !dateChanged &&
        _wallets.isNotEmpty) {
      return;
    }
    _branchId = next;
    _lastSyncedBranchId = next;
    _lastSyncedDateGeneration = nextDateGen;
    _reportBranchFilter = next;
    await fetchAll();
    if (_reportLoadedOnce || dateChanged || force) {
      await fetchReport();
    }
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      final results = await Future.wait([
        ownerRepository.getWorkshopPettyCashWallets(
          token,
          branchId: _branchId,
        ),
        ownerRepository.getWorkshopExpenseRequests(
          token,
          branchId: _branchId,
          limit: 100,
        ),
      ]);

      _wallets = results[0]
          .map(_walletFromJson)
          .where((w) => !_isTechnicianRole(w.role))
          .toList();
      _requests = results[1].map(_requestFromJson).toList();
      await Future.wait([_applyWalletTranslations(), _applyRequestTranslations()]);
    } catch (e) {
      _error = e.toString();
      debugPrint('[PettyCashVM] fetchAll error: $e');
      _wallets = [];
      _requests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads staff targets + cash/bank pay-from options for the Issue sheet.
  Future<void> ensureIssueFormData({bool force = false}) async {
    if (_issueFormLoading) return;
    if (!force &&
        _issuanceTargets.isNotEmpty &&
        _cashBankAccounts.isNotEmpty) {
      return;
    }

    _issueFormLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      final results = await Future.wait([
        ownerRepository.getExpenseIssuanceTargets(token),
        ownerRepository.getWorkshopAccountingCashBankAccounts(
          token,
          branchId: _branchId,
        ),
      ]);

      _issuanceTargets = results[0]
          .map(_targetFromJson)
          .where((t) => t.id.isNotEmpty && !_isTechnicianRole(t.role))
          .toList();
      _cashBankAccounts = results[1]
          .map(_cashBankFromJson)
          .where((a) => a.id.isNotEmpty && !_isPettyCashRegister(a.type))
          .toList();
      await Future.wait(
          [_applyIssuanceTargetTranslations(), _applyCashBankTranslations()]);
    } catch (e) {
      debugPrint('[PettyCashVM] ensureIssueFormData error: $e');
      rethrow;
    } finally {
      _issueFormLoading = false;
      notifyListeners();
    }
  }

  /// Issues petty cash — same payload as web `POST /employee-expense/issue`.
  Future<String> issuePettyCash({
    required String userId,
    required String branchId,
    required double amount,
    required String payFromAccountId,
    String? description,
  }) async {
    if (_issueSubmitting) return '';
    _issueSubmitting = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      final res = await ownerRepository.issuePettyCash(
        token,
        userId: userId,
        branchId: branchId,
        amount: amount,
        payFromAccountId: payFromAccountId,
        description: description,
      );
      await fetchAll();
      return res['message']?.toString() ?? 'Petty cash issued successfully';
    } finally {
      _issueSubmitting = false;
      notifyListeners();
    }
  }

  void setReportDateFrom(DateTime d) {
    ownerDataService.setFilterFrom(DateTime(d.year, d.month, d.day));
  }

  void setReportDateTo(DateTime d) {
    ownerDataService.setFilterTo(DateTime(d.year, d.month, d.day));
  }

  void setReportBranchFilter(String? branchId) {
    _reportBranchFilter = (branchId == null || branchId.isEmpty) ? null : branchId;
    notifyListeners();
  }

  void setReportWalletUserId(String? userId) {
    _reportWalletUserId =
        (userId == null || userId.isEmpty) ? null : userId;
    notifyListeners();
  }

  void setReportExpenseCategory(String? category) {
    _reportExpenseCategory =
        (category == null || category.isEmpty) ? null : category;
    notifyListeners();
  }

  void clearReportFilters() {
    _reportBranchFilter = _branchId;
    _reportWalletUserId = null;
    _reportExpenseCategory = null;
    notifyListeners();
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<String?> _resolvePettyCashExpenseAccountId(String token) async {
    if (_reportAccountId != null && _reportAccountId!.isNotEmpty) {
      return _reportAccountId;
    }
    final accounts = await ownerRepository.getChartAccounts(
      token,
      type: 'EXPENSE',
    );
    Map<String, dynamic>? match;
    for (final a in accounts) {
      final code = a['code']?.toString().trim() ?? '';
      if (code == '6100') {
        match = a;
        break;
      }
    }
    if (match == null) {
      for (final a in accounts) {
        final name = (a['name']?.toString() ?? '').toLowerCase();
        if (name.contains('employee petty cash expense')) {
          match = a;
          break;
        }
      }
    }
    if (match == null) return null;
    _reportAccountId = match['id']?.toString();
    _reportAccountCode = match['code']?.toString() ?? _reportAccountCode;
    _reportAccountName = match['name']?.toString() ?? _reportAccountName;
    _reportAccountType = match['type']?.toString() ?? _reportAccountType;
    return _reportAccountId;
  }

  /// Resolve control account [1280] Employee Petty Cash Fund (ASSET).
  Future<String?> _resolvePettyCashFundAccountId(String token) async {
    if (_fundAccountId != null && _fundAccountId!.isNotEmpty) {
      return _fundAccountId;
    }
    final accounts = await ownerRepository.getChartAccounts(
      token,
      type: 'ASSET',
    );
    Map<String, dynamic>? match;
    for (final a in accounts) {
      final code = a['code']?.toString().trim() ?? '';
      if (code == '1280') {
        match = a;
        break;
      }
    }
    if (match == null) {
      for (final a in accounts) {
        final name = (a['name']?.toString() ?? '').toLowerCase();
        if (name.contains('employee petty cash fund')) {
          match = a;
          break;
        }
      }
    }
    if (match == null) {
      // Some COA seeds list fund under EXPENSE or without type filter.
      final all = await ownerRepository.getChartAccounts(token);
      for (final a in all) {
        final code = a['code']?.toString().trim() ?? '';
        if (code == '1280') {
          match = a;
          break;
        }
      }
    }
    if (match == null) return null;
    _fundAccountId = match['id']?.toString();
    return _fundAccountId;
  }

  Future<void> ensureReportLoaded() async {
    if (_reportLoadedOnce || _reportLoading) return;
    await fetchReport();
  }

  /// Resolve wallet user id for a request (API id, else match staff name / wallets).
  String resolveRequestWalletUserId(StaffRequest request) {
    final direct = request.userId.trim();
    if (direct.isNotEmpty) return direct;
    final name = request.staffName.trim().toLowerCase();
    if (name.isEmpty || name == '—') return '';
    for (final u in _reportWalletUsers) {
      if (u.label.trim().toLowerCase() == name) return u.id;
    }
    for (final w in _wallets) {
      if (w.name.trim().toLowerCase() == name ||
          w.displayName.trim().toLowerCase() == name) {
        return w.id;
      }
    }
    return '';
  }

  /// Employee Petty Cash Fund [1280] statement for one staff member.
  Future<PettyCashEmployeeStatement> fetchStatementForEmployee(
    String walletUserId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final token = await sessionService.getToken(role: 'owner') ?? '';
    if (token.isEmpty) throw Exception('Not authenticated');

    final accountId = await _resolvePettyCashFundAccountId(token);
    if (accountId == null || accountId.isEmpty) {
      throw Exception(
        'Employee Petty Cash Fund account [1280] not found in Chart of Accounts.',
      );
    }

    final from = dateFrom ?? reportDateFrom;
    final to = dateTo ?? reportDateTo;
    final payload = await ownerRepository.getAccountLedger(
      token,
      accountId,
      dateFrom: _isoDate(from),
      dateTo: _isoDate(to),
      branchId: _reportBranchFilter ?? _branchId,
      walletUserId: walletUserId,
      limit: 10000,
    );

    final header = (payload['header'] is Map)
        ? Map<String, dynamic>.from(payload['header'] as Map)
        : <String, dynamic>{};
    final account = (payload['account'] is Map)
        ? Map<String, dynamic>.from(payload['account'] as Map)
        : <String, dynamic>{};
    final totals = (payload['totals'] is Map)
        ? Map<String, dynamic>.from(payload['totals'] as Map)
        : <String, dynamic>{};

    final rows = <PettyCashReportRow>[];
    final rawRows = payload['rows'];
    if (rawRows is List) {
      for (final r in rawRows.whereType<Map>()) {
        final m = Map<String, dynamic>.from(r);
        rows.add(
          PettyCashReportRow(
            id: m['id']?.toString() ?? '',
            date: (m['date']?.toString() ?? '').length >= 10
                ? m['date'].toString().substring(0, 10)
                : m['date']?.toString() ?? '',
            walletUserLabel:
                m['walletUserLabel']?.toString().trim().isNotEmpty == true
                    ? m['walletUserLabel'].toString()
                    : (m['employeeName']?.toString() ?? '—'),
            expenseCategoryLabel:
                m['expenseCategoryLabel']?.toString().trim().isNotEmpty == true
                    ? m['expenseCategoryLabel'].toString()
                    : (m['expenseCategory']?.toString() ?? '—'),
            description: m['description']?.toString() ?? '',
            debit: double.tryParse(m['debit']?.toString() ?? '0') ?? 0,
            credit: double.tryParse(m['credit']?.toString() ?? '0') ?? 0,
            runningBalance:
                double.tryParse(m['runningBalance']?.toString() ?? '0') ?? 0,
            hasExpenseProof: m['hasExpenseProof'] == true ||
                m['expenseProofUrl']?.toString().trim().isNotEmpty == true,
          ),
        );
      }
    }

    final translatedRows = await Future.wait(rows.map((r) async => r.copyWith(
          translatedWalletUserLabel: await tPerson(r.walletUserLabel),
          translatedExpenseCategoryLabel: await t(r.expenseCategoryLabel),
          translatedDescription: await tNotes(r.description),
        )));

    return PettyCashEmployeeStatement(
      companyName: header['companyName']?.toString() ?? '',
      accountCode: header['accountCode']?.toString() ??
          account['code']?.toString() ??
          '1280',
      accountName: header['accountName']?.toString() ??
          account['name']?.toString() ??
          'Employee Petty Cash Fund',
      dateFrom: from,
      dateTo: to,
      openingBalance:
          double.tryParse(payload['openingBalance']?.toString() ?? '0') ?? 0,
      totalDebit: double.tryParse(totals['totalDebit']?.toString() ?? '0') ?? 0,
      totalCredit:
          double.tryParse(totals['totalCredit']?.toString() ?? '0') ?? 0,
      closingBalance:
          double.tryParse(totals['closingBalance']?.toString() ?? '0') ?? 0,
      rows: translatedRows,
    );
  }

  Future<void> fetchReport() async {
    _reportLoading = true;
    _reportError = null;
    notifyListeners();

    try {
      final token = await sessionService.getToken(role: 'owner') ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      final accountId = await _resolvePettyCashExpenseAccountId(token);
      if (accountId == null || accountId.isEmpty) {
        throw Exception(
          'Employee Petty Cash Expense account [6100] not found in Chart of Accounts.',
        );
      }

      final payload = await ownerRepository.getAccountLedger(
        token,
        accountId,
        dateFrom: _isoDate(reportDateFrom),
        dateTo: _isoDate(reportDateTo),
        branchId: _reportBranchFilter,
        expenseCategory: _reportExpenseCategory,
        walletUserId: _reportWalletUserId,
        limit: 10000,
      );

      final header = (payload['header'] is Map)
          ? Map<String, dynamic>.from(payload['header'] as Map)
          : <String, dynamic>{};
      final account = (payload['account'] is Map)
          ? Map<String, dynamic>.from(payload['account'] as Map)
          : <String, dynamic>{};
      final totals = (payload['totals'] is Map)
          ? Map<String, dynamic>.from(payload['totals'] as Map)
          : <String, dynamic>{};
      final filterOptions = (payload['filterOptions'] is Map)
          ? Map<String, dynamic>.from(payload['filterOptions'] as Map)
          : <String, dynamic>{};

      _reportAccountCode =
          header['accountCode']?.toString() ??
          account['code']?.toString() ??
          _reportAccountCode;
      _reportAccountName =
          header['accountName']?.toString() ??
          account['name']?.toString() ??
          _reportAccountName;
      _reportAccountType =
          header['accountType']?.toString() ??
          account['type']?.toString() ??
          _reportAccountType;
      _reportCompanyName = header['companyName']?.toString() ?? '';

      _reportOpeningBalance =
          double.tryParse(payload['openingBalance']?.toString() ?? '0') ?? 0;
      _reportTotalDebit =
          double.tryParse(totals['totalDebit']?.toString() ?? '0') ?? 0;
      _reportTotalCredit =
          double.tryParse(totals['totalCredit']?.toString() ?? '0') ?? 0;
      _reportClosingBalance =
          double.tryParse(totals['closingBalance']?.toString() ?? '0') ??
          _reportOpeningBalance;

      final rawRows = payload['rows'];
      final rows = <PettyCashReportRow>[];
      if (rawRows is List) {
        for (final r in rawRows.whereType<Map>()) {
          final m = Map<String, dynamic>.from(r);
          rows.add(
            PettyCashReportRow(
              id: m['id']?.toString() ?? '',
              date: (m['date']?.toString() ?? '').length >= 10
                  ? m['date'].toString().substring(0, 10)
                  : (m['date']?.toString() ?? '—'),
              walletUserLabel:
                  m['walletUserLabel']?.toString().trim().isNotEmpty == true
                      ? m['walletUserLabel'].toString()
                      : '—',
              expenseCategoryLabel:
                  m['expenseCategoryLabel']?.toString().trim().isNotEmpty ==
                          true
                      ? m['expenseCategoryLabel'].toString()
                      : '—',
              description: m['description']?.toString().trim().isNotEmpty == true
                  ? m['description'].toString()
                  : '—',
              debit: double.tryParse(m['debit']?.toString() ?? '0') ?? 0,
              credit: double.tryParse(m['credit']?.toString() ?? '0') ?? 0,
              runningBalance:
                  double.tryParse(m['runningBalance']?.toString() ?? '0') ?? 0,
              hasExpenseProof: m['hasExpenseProof'] == true,
            ),
          );
        }
      }
      _reportRows = rows;

      final users = <PettyCashReportFilterOption>[];
      final rawUsers = filterOptions['walletUsers'];
      if (rawUsers is List) {
        for (final u in rawUsers.whereType<Map>()) {
          final id = u['key']?.toString() ?? u['id']?.toString() ?? '';
          final label = u['label']?.toString() ?? '';
          if (id.isEmpty || label.isEmpty) continue;
          // Skip technician labels if role is embedded; keep employee names.
          users.add(PettyCashReportFilterOption(id: id, label: label));
        }
      }
      _reportWalletUsers = users;

      final cats = <PettyCashReportFilterOption>[];
      final rawCats = filterOptions['expenseCategories'];
      if (rawCats is List) {
        for (final c in rawCats.whereType<Map>()) {
          final id = c['key']?.toString() ?? c['id']?.toString() ?? '';
          final label = c['label']?.toString() ?? id;
          if (id.isEmpty) continue;
          cats.add(PettyCashReportFilterOption(id: id, label: label));
        }
      }
      _reportCategories = cats;
      _reportLoadedOnce = true;
      await Future.wait(
          [_applyReportRowTranslations(), _applyReportFilterTranslations()]);
    } catch (e) {
      _reportError = e.toString();
      debugPrint('[PettyCashVM] fetchReport error: $e');
      _reportRows = [];
    } finally {
      _reportLoading = false;
      notifyListeners();
    }
  }

  /// Petty cash is for cashiers / non-tech staff — hide technician wallets.
  static bool _isTechnicianRole(String role) {
    final normalized =
        role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return normalized == 'technician' ||
        normalized == 'workshoptechnician' ||
        normalized == 'oncalltechnician' ||
        normalized.startsWith('technician');
  }

  static bool _isPettyCashRegister(String type) {
    final t = type.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return t.contains('petty');
  }

  IssuanceTarget _targetFromJson(Map<String, dynamic> j) {
    return IssuanceTarget(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Staff',
      role: j['role']?.toString() ?? j['userType']?.toString() ?? '',
      branchId: j['branchId']?.toString(),
      branchName: j['branchName']?.toString(),
    );
  }

  CashBankPayFromOption _cashBankFromJson(Map<String, dynamic> j) {
    return CashBankPayFromOption(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Account',
      type: j['type']?.toString() ?? j['kind']?.toString() ?? '',
    );
  }

  StaffWallet _walletFromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map?) ?? const {};
    final branch = (j['branch'] as Map?) ?? const {};
    final name = user['name']?.toString() ?? 'Staff';
    final role = user['role']?.toString() ??
        user['userType']?.toString() ??
        'Staff';
    return StaffWallet(
      id: user['id']?.toString() ?? j['walletId']?.toString() ?? '',
      name: name,
      role: role.replaceAll('_', ' '),
      branch: branch['name']?.toString() ?? '—',
      balance: double.tryParse(j['currentBalance']?.toString() ?? '0') ?? 0,
    );
  }

  StaffRequest _requestFromJson(Map<String, dynamic> j) {
    final branch = (j['branch'] as Map?) ?? const {};
    final requestedBy = (j['requestedBy'] as Map?) ?? const {};
    final payFrom = j['payFromAccountName']?.toString() ??
        j['payFromAccountId']?.toString() ??
        '—';
    final createdAt = DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
        DateTime.tryParse(j['expenseDate']?.toString() ?? '') ??
        DateTime.now();
    final kind = j['kind']?.toString() ?? 'expense';
    return StaffRequest(
      id: j['id']?.toString() ?? '',
      userId: requestedBy['id']?.toString() ??
          j['requestedByUserId']?.toString() ??
          j['walletUserId']?.toString() ??
          '',
      date: createdAt,
      staffName: requestedBy['name']?.toString() ?? '—',
      type: kind == 'fund_request' ? 'Fund top-up' : 'Expense',
      branch: branch['name']?.toString() ?? '—',
      amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      status: j['status']?.toString() ?? 'pending',
      payFrom: payFrom,
    );
  }
}
