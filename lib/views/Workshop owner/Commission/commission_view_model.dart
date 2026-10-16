import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/owner_repository.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommissionViewModel — Ledger + Rules backed by /workshop-staff/commissions/*
// ─────────────────────────────────────────────────────────────────────────────

class CommissionViewModel extends ChangeNotifier {
  final OwnerRepository _repo;
  final SessionService _session;
  final OwnerDataService _ownerData;
  String? _lastSyncedBranchId;

  CommissionViewModel({
    required OwnerRepository ownerRepository,
    required SessionService sessionService,
    required OwnerDataService ownerDataService,
  })  : _repo = ownerRepository,
        _session = sessionService,
        _ownerData = ownerDataService {
    _lastSyncedBranchId = _ownerData.selectedBranchId;
    _ownerData.addListener(_onOwnerDataChanged);
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final next = _ownerData.selectedBranchId;
    if (!force && next == _lastSyncedBranchId) return;
    _lastSyncedBranchId = next;
    await fetchOverview();
  }

  @override
  void dispose() {
    _ownerData.removeListener(_onOwnerDataChanged);
    super.dispose();
  }

  bool isLoading = false;
  String? error;

  CommissionOverviewResponse overview = CommissionOverviewResponse.empty();
  CommissionRulesResponse rulesResponse = CommissionRulesResponse.empty();

  String statusFilter = 'All Status';
  String employeeFilter = 'All Employees';
  String? employeeFilterId;
  DateTime? fromDate;
  DateTime? toDate;
  final Set<String> selectedEntryIds = {};
  String rulesSearchQuery = '';

  List<String> get statusFilterOptions =>
      const ['All Status', 'accrued', 'paid'];

  List<String> get employeeFilterOptions {
    final names = overview.entries.map((e) => e.employeeName).toSet().toList()
      ..sort();
    return ['All Employees', ...names];
  }

  List<CommissionLedgerEntry> get filteredEntries => overview.entries;

  List<CommissionLedgerEntry> get selectableAccruedEntries =>
      filteredEntries.where((e) => e.isAccrued).toList();

  double get selectedTotal {
    return overview.entries
        .where((e) => selectedEntryIds.contains(e.id))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  bool isEntrySelected(String id) => selectedEntryIds.contains(id);

  String? _iso(DateTime? d) {
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _token() => _session.getToken(role: 'owner');

  void toggleEntrySelection(String id) {
    if (selectedEntryIds.contains(id)) {
      selectedEntryIds.remove(id);
    } else {
      selectedEntryIds.add(id);
    }
    notifyListeners();
  }

  void selectAllAccrued() {
    final ids = selectableAccruedEntries.map((e) => e.id).toSet();
    if (selectedEntryIds.length == ids.length &&
        selectedEntryIds.containsAll(ids)) {
      selectedEntryIds.clear();
    } else {
      selectedEntryIds
        ..clear()
        ..addAll(ids);
    }
    notifyListeners();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    notifyListeners();
    fetchOverview();
  }

  void setEmployeeFilter(String value) {
    employeeFilter = value;
    if (value == 'All Employees') {
      employeeFilterId = null;
    } else {
      final match = overview.entries
          .where((e) => e.employeeName == value)
          .map((e) => e.employeeId)
          .where((id) => id.isNotEmpty)
          .toSet();
      employeeFilterId = match.isEmpty ? null : match.first;
    }
    notifyListeners();
    fetchOverview();
  }

  void setFromDate(DateTime? value) {
    fromDate = value;
    notifyListeners();
    fetchOverview();
  }

  void setToDate(DateTime? value) {
    toDate = value;
    notifyListeners();
    fetchOverview();
  }

  void setRulesSearchQuery(String value) {
    rulesSearchQuery = value;
    notifyListeners();
  }

  List<CommissionRule> get filteredRules {
    final q = rulesSearchQuery.trim().toLowerCase();
    final list = [...rulesResponse.rules]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    if (q.isEmpty) return list;
    return list.where((r) {
      return r.displayService.toLowerCase().contains(q) ||
          r.displayRole.toLowerCase().contains(q) ||
          r.type.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> init() async {
    await Future.wait([fetchOverview(), fetchRules()]);
  }

  Future<void> fetchOverview() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        error = 'Not authenticated';
        overview = CommissionOverviewResponse.empty();
        return;
      }
      final start = _iso(fromDate);
      final end = _iso(toDate);
      final status =
          statusFilter == 'All Status' ? null : statusFilter.toLowerCase();

      final results = await Future.wait([
        _repo.getCommissionsSummary(
          token,
          startDate: start,
          endDate: end,
          branchId: _ownerData.selectedBranchId,
        ),
        _repo.getCommissionsPendingByEmployee(
          token,
          startDate: start,
          endDate: end,
          branchId: _ownerData.selectedBranchId,
        ),
        _repo.getCommissionsList(
          token,
          status: status,
          employeeId: employeeFilterId,
          startDate: start,
          endDate: end,
          branchId: _ownerData.selectedBranchId,
          pageSize: 100,
        ),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final pending = results[1] as List<Map<String, dynamic>>;
      final listRaw = results[2] as Map<String, dynamic>;
      final itemsRaw = listRaw['items'] ??
          (listRaw['data'] is Map ? (listRaw['data'] as Map)['items'] : null) ??
          const [];
      final items = (itemsRaw is List ? itemsRaw : const [])
          .whereType<Map>()
          .map((e) =>
              CommissionLedgerEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      overview = CommissionOverviewResponse(
        success: true,
        kpis: CommissionKpis.fromJson(summary),
        pendingByEmployee:
            pending.map(CommissionEmployeeSummary.fromJson).toList(),
        entries: items,
      );
      selectedEntryIds.removeWhere(
        (id) => !overview.entries.any((e) => e.id == id && e.isAccrued),
      );
    } catch (e) {
      debugPrint('[CommissionViewModel] fetchOverview: $e');
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRules() async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return;
      final rulesRaw = await _repo.getCommissionRules(token);
      final servicesRaw = await _repo.getCommissionRuleServices(token);
      rulesResponse = CommissionRulesResponse(
        success: true,
        rules: rulesRaw.map(CommissionRule.fromJson).toList(),
        serviceOptions: servicesRaw
            .map((s) => CommissionServiceOption(
                  id: s['id']?.toString(),
                  name: s['name']?.toString() ??
                      s['serviceName']?.toString() ??
                      '',
                ))
            .where((s) => s.name.isNotEmpty)
            .toList(),
        employeeRoles: const [
          'Technician',
          'Senior Technician',
          'Master Technician',
          'Supervisor',
          'Manager',
        ],
      );
    } catch (e) {
      debugPrint('[CommissionViewModel] fetchRules: $e');
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> markEntriesPaid(List<String> entryIds) async {
    if (entryIds.isEmpty) return false;
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return false;

      final accounts = await _repo.getCommissionPayoutAccounts(token);
      if (accounts.isEmpty) {
        error = 'No cash/bank payout account found';
        notifyListeners();
        return false;
      }
      final payoutAccountId =
          accounts.first['id']?.toString() ?? accounts.first['accountId']?.toString();
      if (payoutAccountId == null || payoutAccountId.isEmpty) {
        error = 'Invalid payout account';
        notifyListeners();
        return false;
      }

      await _repo.postCommissionsPayout(
        token,
        commissionLineIds: entryIds,
        payoutAccountId: payoutAccountId,
      );
      selectedEntryIds.clear();
      await fetchOverview();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createRule(CommissionRule rule) async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return false;
      await _repo.createCommissionRule(token, rule.toJson());
      await fetchRules();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRule(CommissionRule rule) async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return false;
      await _repo.updateCommissionRule(token, rule.id, rule.toJson());
      await fetchRules();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRule(String ruleId) async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return false;
      await _repo.deleteCommissionRule(token, ruleId);
      await fetchRules();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
