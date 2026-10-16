import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/realtime_service.dart';
import '../../../models/pos_order_model.dart';
import '../../../models/pos_technician_model.dart';
import '../../../utils/toast_service.dart';
import '../../../services/locker_translation_mixin.dart';

class TechnicianViewModel extends ChangeNotifier with TranslatableMixin {
  final PosRepository _posRepository;
  final SessionService _sessionService;
  final RealtimeService _realtime = RealtimeService();

  Timer? _technicianCatalogSocketDebounce;

  TechnicianViewModel({
    required PosRepository posRepository,
    required SessionService sessionService,
  })  : _posRepository = posRepository,
        _sessionService = sessionService {
    _realtime.on(
      RealtimeService.eventCashierTechniciansUpdated,
      _onTechniciansCatalogSocket,
    );
  }

  void _onTechniciansCatalogSocket(Map<String, dynamic> _) {
    _technicianCatalogSocketDebounce?.cancel();
    _technicianCatalogSocketDebounce = Timer(const Duration(milliseconds: 400), () {
      refreshTechniciansCatalogQuiet();
    });
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    _technicianCatalogSocketDebounce?.cancel();
    _realtime.off(
      RealtimeService.eventCashierTechniciansUpdated,
      _onTechniciansCatalogSocket,
    );
    super.dispose();
  }

  List<PosTechnician> _technicians = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  bool _isAssigning = false;
  String? _assigningTechnicianId;
  String? _assignmentMessage;
  bool _assignmentSuccess = false;
  List<JobTechnician> _lastCashierAssignTechnicians = [];
  final Set<String> _dutyToggleBusyIds = {};
  final Set<String> _presenceToggleBusyIds = {};

  List<PosTechnician> get technicians {
    if (_searchQuery.isEmpty) return List<PosTechnician>.from(_technicians);
    return _technicians
        .where(
          (t) =>
              t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.employeeType.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  /// Unfiltered cashier catalog (for seeding assign UI from job technicians).
  List<PosTechnician> get rawTechnicians => List.unmodifiable(_technicians);

  // Grouped Technicians (Moved from View)
  Map<String, List<PosTechnician>> get groupedTechnicians {
    final Map<String, List<PosTechnician>> grouped = {};
    for (var tech in technicians) {
      final type =
          tech.technicianType.isEmpty ? 'General' : tech.technicianType;
      grouped.putIfAbsent(type, () => []).add(tech);
    }
    for (final list in grouped.values) {
      sortPosTechniciansList(list);
    }
    final keys = grouped.keys.toList()..sort();
    return {for (final k in keys) k: grouped[k]!};
  }

  void _applyTechnicianCatalog(List<PosTechnician> incoming) {
    _technicians = List<PosTechnician>.from(incoming);
    sortPosTechniciansList(_technicians);
  }
 
  bool get isLoading => _isLoading;
  /// True when [fetchCashierTechnicians] / [fetchTechnicians] has populated `_technicians` (not cleared).
  bool get hasTechnicianList => _technicians.isNotEmpty;
  String? get errorMessage => _errorMessage;
  bool get isAssigning => _isAssigning;
  String? get assigningTechnicianId => _assigningTechnicianId;
  String? get assignmentMessage => _assignmentMessage;
  bool get assignmentSuccess => _assignmentSuccess;
  List<JobTechnician> get lastCashierAssignTechnicians =>
      List.unmodifiable(_lastCashierAssignTechnicians);

  bool isAssigningTechnician(String id) => _isAssigning && _assigningTechnicianId == id;

  bool isDutyToggleBusy(String id) => _dutyToggleBusyIds.contains(id);

  bool isPresenceToggleBusy(String id) => _presenceToggleBusyIds.contains(id);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchTechnicians() async {
    _isLoading = true;
    _errorMessage = null;
    _technicians = [];
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await _posRepository.getCashierTechnicians(token);
      if (response.success) {
        _applyTechnicianCatalog(response.technicians);
      } else {
        _errorMessage = 'Failed to fetch technicians';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// After [refreshTechniciansCatalogQuiet], fixes [slotsUsed] when the list response
  /// still matches pre-refresh counts for techs that were added/removed on this job.
  void reconcileSlotsAfterAssign({
    required Set<String> addedEmployeeIds,
    required Set<String> removedEmployeeIds,
    required Map<String, int> slotsBeforeRefresh,
  }) {
    if (addedEmployeeIds.isEmpty && removedEmployeeIds.isEmpty) return;
    _technicians = _technicians.map((t) {
      final cap = t.totalSlots > 0 ? t.totalSlots : 999;
      final bef = slotsBeforeRefresh[t.id];
      var u = t.slotsUsed;

      if (addedEmployeeIds.contains(t.id)) {
        if (bef != null) {
          if (u <= bef) u = bef + 1;
        } else {
          u += 1;
        }
      }
      if (removedEmployeeIds.contains(t.id)) {
        if (bef != null) {
          if (u >= bef) u = (bef - 1).clamp(0, cap);
        } else if (u > 0) {
          u -= 1;
        }
      }

      u = u.clamp(0, cap);
      if (u == t.slotsUsed) return t;
      return t.copyWith(slotsUsed: u);
    }).toList();
    sortPosTechniciansList(_technicians);
    notifyListeners();
  }

  /// Updates slot counts after assign without clearing the list or showing loading.
  /// Always uses [getCashierTechnicians] so [slotsUsed] / [slots] match the cashier API
  /// (workshop [getTechnicians] does not return the same slot payload).
  Future<void> refreshTechniciansCatalogQuiet({String? departmentId}) async {
    try {
      final token = await _sessionService.getToken();
      if (token == null) return;
      final d = departmentId?.trim() ?? '';
      final response = await _posRepository.getCashierTechnicians(
        token,
        departmentId: d.isNotEmpty ? d : null,
      );
      if (response.success) {
        _applyTechnicianCatalog(response.technicians);
        notifyListeners();
      }
    } catch (_) {
      // Keep existing catalog on failure.
    }
  }

  /// GET /cashier/technicians?departmentId=… — cashier assign picker (Bearer token).
  Future<void> fetchCashierTechnicians({String? departmentId}) async {
    _isLoading = true;
    _errorMessage = null;
    _technicians = [];
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await _posRepository.getCashierTechnicians(
        token,
        departmentId: departmentId,
      );
      if (response.success) {
        _applyTechnicianCatalog(response.technicians);
      } else {
        _errorMessage = 'Failed to fetch technicians';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignTechnician(String jobId, String employeeId) async {
    _isAssigning = true;
    _assigningTechnicianId = employeeId;
    _assignmentMessage = null;
    _assignmentSuccess = false;
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response =
          await _posRepository.assignTechnicians(jobId, [employeeId], token);
      _assignmentMessage = response.message;
      if (response.isEffectiveAssignFailure([employeeId])) {
        _assignmentSuccess = false;
        if (_assignmentMessage == null || _assignmentMessage!.trim().isEmpty) {
          _assignmentMessage =
              'Technician was not assigned. The server may still count old assignments on this job.';
        }
        return false;
      }
      _assignmentSuccess = true;
      return true;
    } catch (e) {
      _assignmentMessage = e.toString();
      _assignmentSuccess = false;
      return false;
    } finally {
      _isAssigning = false;
      _assigningTechnicianId = null;
      notifyListeners();
    }
  }
  Future<bool> assignMultipleTechnicians(String jobId, List<String> employeeIds) async {
    _isAssigning = true;
    _assigningTechnicianId = null; // Don't show specific spinner on list items when doing bulk
    _assignmentMessage = null;
    _assignmentSuccess = false;
    _lastCashierAssignTechnicians = [];
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await _posRepository.assignTechnicians(jobId, employeeIds, token);

      _assignmentMessage = response.message;
      final m = (_assignmentMessage ?? '').toLowerCase();
      if (!response.success &&
          response.sync != true &&
          m.contains('no new assignments') &&
          employeeIds.isNotEmpty) {
        _assignmentMessage =
            'Cannot apply removals: server treats assign as add-only. Backend must sync '
            '`employeeIds` to the full desired list (or honor sync: true).';
      }
      if (response.isEffectiveAssignFailure(employeeIds)) {
        _assignmentSuccess = false;
        if (_assignmentMessage == null || _assignmentMessage!.trim().isEmpty) {
          _assignmentMessage =
              'No technicians were assigned. The server may still count cancelled assignments on this job.';
        }
        return false;
      }
      _assignmentSuccess = true;
      if (response.assignedTechnicians.isNotEmpty) {
        _lastCashierAssignTechnicians = List<JobTechnician>.from(
          response.assignedTechnicians,
        );
      }
      return true;
    } catch (e) {
      _assignmentMessage = e.toString();
      _assignmentSuccess = false;
      return false;
    } finally {
      _isAssigning = false;
      notifyListeners();
    }
  }

  static String _encodeDutyModeForType(
    String technicianType,
    bool workshop,
    bool onCall,
  ) {
    final t = technicianType.toLowerCase();
    if (t == 'workshop') {
      return workshop ? 'workshop' : 'inactive';
    }
    if (t == 'on_call') {
      return onCall ? 'on_call' : 'inactive';
    }
    if (!workshop && !onCall) return 'inactive';
    if (workshop && onCall) return 'workshop';
    if (workshop) return 'workshop';
    return 'on_call';
  }

  Future<void> setTechnicianWorkshopDuty(
    BuildContext context,
    PosTechnician tech,
    bool value,
  ) async {
    await _setTechnicianDutyFlags(
      context,
      tech,
      workshop: value,
      onCall: value ? false : tech.onCallDuty,
    );
  }

  Future<void> setTechnicianOnCallDuty(
    BuildContext context,
    PosTechnician tech,
    bool value,
  ) async {
    await _setTechnicianDutyFlags(
      context,
      tech,
      workshop: value ? false : tech.workshopDuty,
      onCall: value,
    );
  }

  Future<void> _setTechnicianDutyFlags(
    BuildContext context,
    PosTechnician tech, {
    required bool workshop,
    required bool onCall,
  }) async {
    if (!tech.isOnline) {
      if (context.mounted) {
        ToastService.showError(
          context,
          'Mark this technician online before changing workshop or on-call duty.',
        );
      }
      return;
    }
    final id = tech.id;
    if (_dutyToggleBusyIds.contains(id)) return;
    _dutyToggleBusyIds.add(id);
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception('Not signed in');
      }
      final mode = _encodeDutyModeForType(tech.technicianType, workshop, onCall);
      final res = await _posRepository.patchCashierTechnicianDutyMode(
        token,
        id,
        mode,
      );
      if (res['success'] == false) {
        final err = res['message']?.toString();
        throw Exception(
          (err != null && err.isNotEmpty) ? err : 'Failed to update duty',
        );
      }
      await refreshTechniciansCatalogQuiet();
      if (context.mounted) {
        final msg = res['message']?.toString();
        ToastService.showSuccess(
          context,
          (msg != null && msg.isNotEmpty) ? msg : 'Duty updated',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, e.toString());
      }
    } finally {
      _dutyToggleBusyIds.remove(id);
      notifyListeners();
    }
  }

  /// PATCH /cashier/technicians/:employeeId/online-status then refresh catalog.
  Future<void> setTechnicianPresence(
    BuildContext context,
    String technicianId,
    bool online,
  ) async {
    if (_presenceToggleBusyIds.contains(technicianId)) return;
    _presenceToggleBusyIds.add(technicianId);
    notifyListeners();

    try {
      final token = await _sessionService.getToken();
      if (token == null) {
        throw Exception('Not signed in');
      }
      final status = online ? 'online' : 'offline';
      final res = await _posRepository.patchCashierTechnicianOnlineStatus(
        token,
        technicianId,
        status,
      );
      if (res['success'] == false) {
        final err = res['message']?.toString();
        throw Exception(
          (err != null && err.isNotEmpty) ? err : 'Failed to update status',
        );
      }
      await refreshTechniciansCatalogQuiet();
      if (context.mounted) {
        final msg = res['message']?.toString();
        ToastService.showSuccess(
          context,
          (msg != null && msg.isNotEmpty)
              ? msg
              : (online
                  ? 'Technician marked online'
                  : 'Technician marked offline'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, e.toString());
      }
    } finally {
      _presenceToggleBusyIds.remove(technicianId);
      notifyListeners();
    }
  }

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

}
