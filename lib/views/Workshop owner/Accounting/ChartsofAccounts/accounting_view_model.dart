import 'package:flutter/material.dart';
import '../accounting_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AccountingViewModel
// ─────────────────────────────────────────────────────────────────────────────

class AccountingViewModel extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedBranch;
  String? get selectedBranch => _selectedBranch;

  AccountType? _filterType;
  AccountType? get filterType => _filterType;

  // ── Data ───────────────────────────────────────────────────────────────────

  List<ChartAccount> get allAccounts => AccountingDummyData.accounts;
  List<TrialBalanceEntry> get trialBalance => AccountingDummyData.trialBalance;
  List<PnLEntry> get profitAndLoss => AccountingDummyData.profitAndLoss;
  List<BalanceSheetEntry> get balanceSheet => AccountingDummyData.balanceSheet;

  // ── Filtered / grouped accounts ────────────────────────────────────────────

  List<ChartAccount> get filteredAccounts {
    return allAccounts.where((a) {
      final matchQuery = _searchQuery.isEmpty ||
          a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (a.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchBranch = _selectedBranch == null ||
          _selectedBranch == 'All Branches' ||
          a.branch == _selectedBranch;

      final matchType = _filterType == null || a.type == _filterType;

      return matchQuery && matchBranch && matchType;
    }).toList();
  }

  Map<AccountType, List<ChartAccount>> get groupedAccounts {
    final filtered = filteredAccounts;
    final result = <AccountType, List<ChartAccount>>{};
    for (final type in AccountType.values) {
      final group = filtered.where((a) => a.type == type).toList();
      if (group.isNotEmpty) {
        result[type] = group;
      }
    }
    return result;
  }

  // ── Counts per type ────────────────────────────────────────────────────────

  int countByType(AccountType type) =>
      allAccounts.where((a) => a.type == type).length;

  // ── Methods ────────────────────────────────────────────────────────────────

  void setTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(AccountType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setBranch(String? branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedBranch = null;
    _filterType = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
  }

  // ── P&L helpers ────────────────────────────────────────────────────────────

  double get totalRevenue => profitAndLoss
      .where((e) => e.category == 'Revenue' && !e.isSubtotal)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalExpenses => profitAndLoss
      .where((e) => e.category == 'Expenses' && !e.isSubtotal)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get netIncome {
    final entry = profitAndLoss.where((e) => e.isTotal).firstOrNull;
    return entry?.amount ?? 0.0;
  }

  // ── Trial Balance helpers ──────────────────────────────────────────────────

  double get totalDebits =>
      trialBalance.fold(0.0, (sum, e) => sum + e.debit);

  double get totalCredits =>
      trialBalance.fold(0.0, (sum, e) => sum + e.credit);

  // ── Balance Sheet helpers ──────────────────────────────────────────────────

  double get totalAssets {
    final entry = balanceSheet
        .where((e) => e.section == 'Assets' && e.isTotal)
        .firstOrNull;
    return entry?.amount ?? 0.0;
  }

  double get totalLiabilities {
    final entry = balanceSheet
        .where((e) => e.section == 'Liabilities' && e.isTotal)
        .firstOrNull;
    return entry?.amount ?? 0.0;
  }

  double get totalEquity {
    final entries = balanceSheet
        .where((e) => e.section == 'Equity' && e.isTotal)
        .toList();
    // The first total in equity section
    return entries.isNotEmpty ? entries.first.amount : 0.0;
  }
}
