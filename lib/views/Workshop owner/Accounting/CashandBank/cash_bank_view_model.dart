import 'package:flutter/material.dart';
import 'cash_bank_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CashBankViewModel
// ─────────────────────────────────────────────────────────────────────────────

class CashBankViewModel extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RegisterKind? _filterType; // null = All Accounts
  RegisterKind? get filterType => _filterType;

  // ── Transfer form state ───────────────────────────────────────────────────

  String? _transferFrom;
  String? get transferFrom => _transferFrom;

  String? _transferTo;
  String? get transferTo => _transferTo;

  final TextEditingController transferAmountCtrl = TextEditingController();
  final TextEditingController transferNoteCtrl = TextEditingController();
  DateTime transferDate = DateTime.now();

  // ── Data ───────────────────────────────────────────────────────────────────

  List<CashBankAccount> get allAccounts => CashBankDummyData.accounts;
  List<BranchRegisterDefaults> get branchDefaults =>
      CashBankDummyData.branchDefaults;
  List<String> get branches => CashBankDummyData.branches;

  // ── Filtered accounts ──────────────────────────────────────────────────────

  List<CashBankAccount> get filteredAccounts {
    if (_filterType == null) return allAccounts;
    return allAccounts.where((a) => a.type == _filterType).toList();
  }

  // ── KPI helpers ────────────────────────────────────────────────────────────

  double _sumFor(RegisterKind kind) => allAccounts
      .where((a) => a.type == kind)
      .fold(0.0, (sum, a) => sum + a.currentBalance);

  int _countFor(RegisterKind kind) =>
      allAccounts.where((a) => a.type == kind).length;

  double get cashBalance => _sumFor(RegisterKind.cash);
  double get bankBalance => _sumFor(RegisterKind.bank);
  double get pettyCashBalance => _sumFor(RegisterKind.pettyCash);

  int get cashCount => _countFor(RegisterKind.cash);
  int get bankCount => _countFor(RegisterKind.bank);
  int get pettyCashCount => _countFor(RegisterKind.pettyCash);

  // ── Methods ────────────────────────────────────────────────────────────────

  void setFilterType(RegisterKind? type) {
    _filterType = type;
    notifyListeners();
  }

  void setTransferFrom(String? id) {
    _transferFrom = id;
    notifyListeners();
  }

  void setTransferTo(String? id) {
    _transferTo = id;
    notifyListeners();
  }

  void setTransferDate(DateTime date) {
    transferDate = date;
    notifyListeners();
  }

  void clearTransferForm() {
    _transferFrom = null;
    _transferTo = null;
    transferAmountCtrl.clear();
    transferNoteCtrl.clear();
    transferDate = DateTime.now();
    notifyListeners();
  }

  void setBranchDefaultCash(String branch, String? accountId) {
    final entry = branchDefaults.firstWhere((b) => b.branch == branch);
    entry.defaultCashAccountId = accountId;
    notifyListeners();
  }

  void setBranchDefaultBank(String branch, String? accountId) {
    final entry = branchDefaults.firstWhere((b) => b.branch == branch);
    entry.defaultBankAccountId = accountId;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    transferAmountCtrl.dispose();
    transferNoteCtrl.dispose();
    super.dispose();
  }
}
