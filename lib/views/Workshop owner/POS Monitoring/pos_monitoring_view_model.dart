import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../Workshop pos app/More Tab/settings_view_model.dart';

class PosMonitoringViewModel extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final OwnerDataService ownerDataService;
  final SettingsViewModel? settingsViewModel;
  String? _lastSyncedBranchId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PosMonitoringResponse? _monitoringResponse;
  PosMonitoringResponse? get monitoringResponse => _monitoringResponse;

  late DateTime _filterFrom;
  late DateTime _filterTo;
  String? _filterBranch; // null = all branches (header scope)
  int _lastSyncedDateGeneration = -1;

  DateTime get filterFrom => ownerDataService.filterFrom;
  DateTime get filterTo => ownerDataService.filterTo;
  String? get filterBranch => _filterBranch;

  PosMonitoringViewModel({
    required this.ownerRepository,
    required this.sessionService,
    required this.ownerDataService,
    this.settingsViewModel,
  }) {
    _filterFrom = ownerDataService.filterFrom;
    _filterTo = ownerDataService.filterTo;
    _filterBranch = ownerDataService.selectedBranch?.name;
    _lastSyncedBranchId = ownerDataService.selectedBranchId;
    _lastSyncedDateGeneration = ownerDataService.dateGeneration;
    ownerDataService.addListener(_onOwnerDataChanged);
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
  }

  void _onOwnerDataChanged() {
    // Selection UI only — visible-tab reload is orchestrated by OwnerShell.
  }

  Future<void> syncWithSelectedBranch({bool force = false}) async {
    final nextId = ownerDataService.selectedBranchId;
    final nextDateGen = ownerDataService.dateGeneration;
    if (!force &&
        nextId == _lastSyncedBranchId &&
        nextDateGen == _lastSyncedDateGeneration) {
      return;
    }
    _lastSyncedBranchId = nextId;
    _lastSyncedDateGeneration = nextDateGen;
    _filterBranch = ownerDataService.selectedBranch?.name;
    _filterFrom = ownerDataService.filterFrom;
    _filterTo = ownerDataService.filterTo;
    notifyListeners();
    await fetchPosMonitoring();
  }

  // ── Locale re-translation ─────────────────────────────────────────────────

  Future<void> retranslate() async {
    final response = _monitoringResponse;
    if (response == null) return;
    _monitoringResponse = response.copyWith(
      liveCounters: await Future.wait(response.liveCounters.map(_translateCounter)),
      closingReports: await Future.wait(response.closingReports.map(_translateCounter)),
    );
    notifyListeners();
  }

  Future<PosCounter> _translateCounter(PosCounter c) async {
    return c.copyWith(
      translatedCashierName: await tPerson(c.cashierName),
      translatedBranchName: await tBranch(c.branchName),
    );
  }

  @override
  void dispose() {
    ownerDataService.removeListener(_onOwnerDataChanged);
    unbindLocaleRetranslation();
    super.dispose();
  }

  Future<void> applyFilterStartDate(DateTime d) async {
    ownerDataService.setFilterFrom(d);
  }

  Future<void> applyFilterEndDate(DateTime d) async {
    ownerDataService.setFilterTo(d);
  }

  /// Fetches monitoring for the current global date range.
  Future<void> fetchPosMonitoring({
    DateTime? from,
    DateTime? to,
  }) async {
    // Optional overrides only update the local fetch window without bumping
    // the global generation (used by rare call sites); default = global.
    if (from != null) _filterFrom = from;
    if (to != null) _filterTo = to;
    if (from == null && to == null) {
      _filterFrom = ownerDataService.filterFrom;
      _filterTo = ownerDataService.filterTo;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token != null) {
        final response = await ownerRepository.getPosMonitoring(
          token,
          from: _filterFrom,
          to: _filterTo,
          viewerUtcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
        );
        if (response != null && response['success'] == true) {
          _monitoringResponse = PosMonitoringResponse.fromJson(response);
          await retranslate();
        }
      }
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static bool _sameDayInRange(DateTime t, DateTime from, DateTime to) {
    final d = DateTime(t.year, t.month, t.day);
    final f = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    return !d.isBefore(f) && !d.isAfter(end);
  }

  /// Filter live rows by session start day and optional header branch name.
  List<PosCounter> filterLiveCounters(List<PosCounter> base) {
    var result = base;
    if (_filterBranch != null) {
      result = result.where((c) => c.branchName == _filterBranch).toList();
    }
    return result
        .where((c) => _sameDayInRange(c.sessionStart, _filterFrom, _filterTo))
        .toList();
  }

  /// Closing rows: API may already scope by date; still apply header branch.
  List<PosCounter> filterClosingReports(List<PosCounter> base) {
    var result = base;
    if (_filterBranch != null) {
      result = result.where((c) => c.branchName == _filterBranch).toList();
    }
    if (_monitoringResponse?.dateRangeFilter != null) return result;
    return result.where((c) {
      final anchor = c.closedAt ?? c.endTime ?? c.openedAt;
      return _sameDayInRange(anchor, _filterFrom, _filterTo);
    }).toList();
  }
}
