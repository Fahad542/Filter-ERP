import 'package:flutter/material.dart';
import '../models/workshop_owner_models.dart';
import '../models/department_model.dart';
import '../data/repositories/owner_repository.dart';
import '../utils/riyadh_business_range.dart';
import '../views/Workshop pos app/More Tab/settings_view_model.dart';
import 'session_service.dart';
import 'locker_translation_mixin.dart';

class OwnerDataService extends ChangeNotifier with TranslatableMixin {
  final OwnerRepository ownerRepository;
  final SessionService sessionService;
  final SettingsViewModel? settingsViewModel;

  /// Raw API branches (English / source language).
  List<Branch> _rawBranches = [];

  /// Display branches (translated when locale is Arabic).
  List<Branch> _branches = [];
  List<Branch> get branches => _branches;

  /// Global workshop-owner branch scope.
  /// `null` = all branches aggregated.
  Branch? _selectedBranch;
  Branch? get selectedBranch => _selectedBranch;
  String? get selectedBranchId => _selectedBranch?.id;

  /// Bumps whenever the selected branch changes (for UI listeners).
  int _branchGeneration = 0;
  int get branchGeneration => _branchGeneration;

  /// App-wide date/time range (same idea as branch scope).
  /// Fields are Asia/Riyadh wall clock (not device TZ).
  /// Default: start of current Riyadh month 00:00 → Riyadh now.
  DateTime _filterFrom = riyadhStartOfMonthWall();
  DateTime _filterTo = riyadhNowWall();
  DateTime get filterFrom => _filterFrom;
  DateTime get filterTo => _filterTo;

  /// Bumps whenever the global date/time range changes.
  int _dateGeneration = 0;
  int get dateGeneration => _dateGeneration;

  static DateTime _minuteFloor(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute);

  List<Department> _departments = [];
  List<Department> get departments => _departments;

  bool _isLoadingBranches = false;
  bool get isLoadingBranches => _isLoadingBranches;

  bool _isLoadingDepartments = false;
  bool get isLoadingDepartments => _isLoadingDepartments;

  /// Per-shell-tab reload callbacks. Only the **current** tab is invoked on
  /// branch change; on tab switch the newly visible tab is invoked and may
  /// no-op if it already loaded for the selected branch.
  final Map<int, Future<void> Function()> _tabReloaders = {};

  OwnerDataService({
    required this.ownerRepository,
    required this.sessionService,
    this.settingsViewModel,
  }) {
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel!, retranslate);
    }
  }

  Future<void> retranslate() async {
    await _applyBranchTranslations();
    notifyListeners();
  }

  Future<void> _applyBranchTranslations() async {
    if (_rawBranches.isEmpty) {
      _branches = [];
      return;
    }
    _branches = await translateBranches(_rawBranches);
    // Keep selection pointing at the translated copy of the same id.
    if (_selectedBranch != null) {
      final id = _selectedBranch!.id;
      final match = _branches.where((b) => b.id == id);
      if (match.isNotEmpty) {
        _selectedBranch = match.first;
      }
    }
  }

  void registerTabReloader(int tabIndex, Future<void> Function() reload) {
    _tabReloaders[tabIndex] = reload;
  }

  void unregisterTabReloader(int tabIndex) {
    _tabReloaders.remove(tabIndex);
  }

  Future<void> reloadTab(int tabIndex) async {
    final fn = _tabReloaders[tabIndex];
    if (fn == null) return;
    await fn();
  }

  /// Updates the app-wide branch filter used by the owner app bar.
  /// Does **not** fan-out API calls — [OwnerShell] reloads only the visible tab.
  void setSelectedBranch(Branch? branch) {
    if (_selectedBranch?.id == branch?.id) return;
    _selectedBranch = branch;
    _branchGeneration++;
    notifyListeners();
  }

  /// Updates the app-wide start bound. Shell reloads only the visible tab.
  void setFilterFrom(DateTime d) {
    var next = _minuteFloor(d);
    if (next.isAfter(_filterTo)) next = _minuteFloor(_filterTo);
    if (_minuteFloor(_filterFrom) == next) return;
    _filterFrom = next;
    _dateGeneration++;
    notifyListeners();
  }

  /// Updates the app-wide end bound (capped at Riyadh now). Shell reloads visible tab.
  void setFilterTo(DateTime d) {
    var next = _minuteFloor(d);
    if (next.isBefore(_filterFrom)) next = _minuteFloor(_filterFrom);
    final now = riyadhNowWall();
    if (next.isAfter(now)) next = now;
    if (_minuteFloor(_filterTo) == next) return;
    _filterTo = next;
    _dateGeneration++;
    notifyListeners();
  }

  /// Sets both ends of the global range in one generation bump.
  void setFilterRange(DateTime from, DateTime to) {
    var nextFrom = _minuteFloor(from);
    var nextTo = _minuteFloor(to);
    final now = riyadhNowWall();
    if (nextTo.isAfter(now)) nextTo = now;
    if (nextFrom.isAfter(nextTo)) nextFrom = nextTo;
    if (_minuteFloor(_filterFrom) == nextFrom &&
        _minuteFloor(_filterTo) == nextTo) {
      return;
    }
    _filterFrom = nextFrom;
    _filterTo = nextTo;
    _dateGeneration++;
    notifyListeners();
  }

  Future<void> fetchBranches({bool silent = false}) async {
    if (!silent) {
      _isLoadingBranches = true;
      notifyListeners();
    }

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      final response = await ownerRepository.getBranches(token);
      if (response != null &&
          response['success'] == true &&
          response['branches'] != null) {
        _rawBranches = (response['branches'] as List)
            .map((json) => Branch.fromJson(json))
            .toList();
        await _applyBranchTranslations();

        // Drop selection if the branch no longer exists.
        if (_selectedBranch != null &&
            !_branches.any((b) => b.id == _selectedBranch!.id)) {
          _selectedBranch = null;
          _branchGeneration++;
        } else if (_selectedBranch != null) {
          final id = _selectedBranch!.id;
          _selectedBranch = _branches.firstWhere(
            (b) => b.id == id,
            orElse: () => _selectedBranch!,
          );
        }
      }
    } catch (e) {
    } finally {
      if (!silent) {
        _isLoadingBranches = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchDepartments({bool silent = false}) async {
    if (!silent) {
      _isLoadingDepartments = true;
      notifyListeners();
    }

    try {
      final token = await sessionService.getToken(role: 'owner');
      if (token == null) return;

      final response = await ownerRepository.getDepartments(token);
      if (response != null &&
          response['success'] == true &&
          response['departments'] != null) {
        _departments = (response['departments'] as List)
            .map((json) => Department.fromJson(json))
            .toList();
      }
    } catch (e) {
    } finally {
      if (!silent) {
        _isLoadingDepartments = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshAll({bool silent = false}) async {
    await Future.wait([
      fetchBranches(silent: silent),
      fetchDepartments(silent: silent),
    ]);
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    super.dispose();
  }
}
