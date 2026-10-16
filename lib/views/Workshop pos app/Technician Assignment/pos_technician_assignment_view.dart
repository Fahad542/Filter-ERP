import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import 'package:filter_service_providers/views/Workshop pos app/Navbar/pos_shell.dart';
import '../Home Screen/pos_view_model.dart';
import '../Technician Screen/technician_view_model.dart';
import 'technician_assignment_view_model.dart';
import '../Broadcast/cashier_broadcast_view_model.dart';
import '../../../utils/toast_service.dart';
import '../../../models/pos_order_model.dart';
import '../../../models/pos_technician_model.dart';

Color _assignmentStatusDotColor(String assignmentStatus) {
  switch (assignmentStatus) {
    case 'active':
      return Colors.green;
    case 'on_call':
      return Colors.deepOrange;
    case 'inactive':
      return Colors.amber.shade700;
    case 'offline':
      return Colors.grey.shade400;
    default:
      return Colors.blueGrey;
  }
}

Color _assignmentStatusAccentColor(String assignmentStatus) {
  switch (assignmentStatus) {
    case 'active':
      return Colors.green.shade700;
    case 'on_call':
      return Colors.deepOrange.shade700;
    case 'inactive':
      return Colors.amber.shade900;
    case 'offline':
      return Colors.grey.shade600;
    default:
      return Colors.blueGrey.shade600;
  }
}

List<JobTechnician> _jobTechniciansFromSelection(
  Set<String> selectedIds,
  List<PosTechnician> catalog,
) {
  final out = <JobTechnician>[];
  for (final t in catalog) {
    if (!selectedIds.contains(t.id)) continue;
    final pct = double.tryParse(t.commissionPercent) ?? 0;
    out.add(
      JobTechnician(
        id: t.id,
        employeeId: t.id,
        name: t.name,
        commissionPercent: pct,
        commissionAmount: 0,
      ),
    );
  }
  return out;
}

/// POST assign used to omit [JobTechnician.commissionPercent]; the roster then showed 0% until GET orders.
/// Server now echoes percent; this still fills from the picker/catalog when the API sends 0 but catalog has a rate.
List<JobTechnician> _mergeAssignServerTechniciansWithCatalog(
  List<JobTechnician> fromServer,
  List<JobTechnician> fromSelection,
) {
  final byEmployee = <String, JobTechnician>{
    for (final t in fromSelection) t.pickerEmployeeId: t,
  };
  return [
    for (final s in fromServer) _mergeSingleAssignTechnician(s, byEmployee[s.pickerEmployeeId]),
  ];
}

JobTechnician _mergeSingleAssignTechnician(JobTechnician server, JobTechnician? catalogRow) {
  if (catalogRow == null) return server;
  if (server.commissionPercent > 0) return server;
  final catPct = catalogRow.commissionPercent;
  if (catPct <= 0) return server;
  return JobTechnician(
    id: server.id,
    employeeId: server.employeeId ?? catalogRow.employeeId,
    name: server.name.isNotEmpty ? server.name : catalogRow.name,
    commissionPercent: catPct,
    commissionAmount: server.commissionAmount,
    status: server.status,
    assignedAt: server.assignedAt,
  );
}

/// Runs under [ChangeNotifierProvider]<[TechnicianAssignmentViewModel]> so
/// [context.read] for the assignment VM is valid (parent [State] context is above the provider).
class _AssignmentCatalogBootstrap extends StatefulWidget {
  final String? departmentId;
  final List<JobTechnician> initialAssignedTechnicians;
  final Widget child;

  const _AssignmentCatalogBootstrap({
    required this.departmentId,
    required this.initialAssignedTechnicians,
    required this.child,
  });

  @override
  State<_AssignmentCatalogBootstrap> createState() =>
      _AssignmentCatalogBootstrapState();
}

class _AssignmentCatalogBootstrapState extends State<_AssignmentCatalogBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalogAndSeed());
  }

  Future<void> _loadCatalogAndSeed() async {
    if (!mounted) return;
    final dept = widget.departmentId?.trim() ?? '';
    final techVm = context.read<TechnicianViewModel>();
    final assignVm = context.read<TechnicianAssignmentViewModel>();
    if (dept.isNotEmpty) {
      await techVm.fetchCashierTechnicians(departmentId: dept);
    } else {
      await techVm.fetchCashierTechnicians();
    }
    if (!mounted) return;
    assignVm.applyInitialSelectionFromJob(
      widget.initialAssignedTechnicians,
      techVm.rawTechnicians,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PosTechnicianAssignmentView extends StatefulWidget {
  final String jobId;
  final String? departmentName;
  final String? departmentId; // needed for walk-in order API
  final bool isWalkIn; // true = walk-in flow, call walk-in API on assign
  /// Technicians already on this job (pre-checks rows after catalog loads).
  final List<JobTechnician> initialAssignedTechnicians;

  /// Opened from [PosOrdersView] overlay — no app bar; parent dialog has close (×).
  final bool embeddedInOrdersHubDialog;

  const PosTechnicianAssignmentView({
    super.key,
    required this.jobId,
    this.departmentName,
    this.departmentId,
    this.isWalkIn = false,
    this.initialAssignedTechnicians = const [],
    this.embeddedInOrdersHubDialog = false,
  });

  @override
  State<PosTechnicianAssignmentView> createState() =>
      _PosTechnicianAssignmentViewState();
}

class _PosTechnicianAssignmentViewState
    extends State<PosTechnicianAssignmentView> {
  /// Existing job on server, or walk-in/edit flow (order saved when broadcasting / assigning).
  bool get _canTapBroadcast =>
      widget.jobId.isNotEmpty || widget.isWalkIn;

  /// `workshop` / `on_call` while that broadcast is in progress (null = idle).
  String? _broadcastingDuty;

  /// After first save in walk-in mode, reuse this job for another broadcast tap (avoid duplicate POST).
  String? _cachedJobIdFromSave;

  /// True from tap through walk-in/edit save, assign API, refresh, orders fetch, until orders shell is pushed (or flow fails).
  bool _saveFlowInProgress = false;

  bool _saveFlowBusy(TechnicianViewModel vm) =>
      vm.isAssigning || _saveFlowInProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CashierBroadcastViewModel>().fetchActive(silent: true);
    });
  }

  void _handleMultiAssign(
    BuildContext context,
    TechnicianAssignmentViewModel assignVm,
  ) async {
    final vm = context.read<TechnicianViewModel>();
    final posVm = context.read<PosViewModel>();

    setState(() => _saveFlowInProgress = true);
    var didNavigateToOrders = false;

    String jobIdToUse = widget.jobId;

    try {
    // Walk-in / Edit-order flow: call appropriate API first
    if (widget.isWalkIn) {
      final deptId = widget.departmentId ?? '';
      final isEditMode = posVm.editingOrder != null;

      if (isEditMode) {
        // Edit order: call PATCH edit API, reuse existing jobId
        final existingJobId = posVm.editingCompletingOrderId ?? '';
        if (existingJobId.isEmpty) {
          ToastService.showError(context, AppLocalizations.of(context)!.posTechnicianFailedJobEdit);
          return;
        }
        final success = await posVm.submitEditOrder(
          deptId.isNotEmpty ? [deptId] : [],
          context,
        );
        if (!mounted) return;
        if (!success) return;
        jobIdToUse = existingJobId;
      } else {
        // New walk-in order: call walk-in API, get new jobId from response
        final success = await posVm.submitWalkInOrder(
          deptId.isNotEmpty ? [deptId] : [],
          context,
          clearCustomerOnSuccess: false,
        );
        if (!mounted) return;
        if (!success) return;
        jobIdToUse = posVm.currentJobId ?? '';
        if (jobIdToUse.isEmpty) {
          ToastService.showError(context, AppLocalizations.of(context)!.posTechnicianFailedOrderId);
          return;
        }
      }
    }

    if (jobIdToUse.trim().isEmpty) {
      ToastService.showError(context, AppLocalizations.of(context)!.posTechnicianJobNotFound);
      return;
    }

    PosOrderJob? jobSnapshotPreAssign;
    if (!widget.isWalkIn) {
      final ordPre = posVm.selectedOrder ?? posVm.editingOrder;
      if (ordPre != null) {
        for (final j in ordPre.jobs) {
          if (j.id == jobIdToUse) {
            jobSnapshotPreAssign = j;
            break;
          }
        }
      }
    }

    // POST /assign on a **completed** job often fails or behaves as "add-only" (→ "No new
    // assignments" when removing someone). Unlock first: completed → edited via mark-edited.
    if (!widget.isWalkIn && jobSnapshotPreAssign != null) {
      final catalog = vm.rawTechnicians;
      final initialIds = catalogIdsForJobTechnicians(
        widget.initialAssignedTechnicians,
        catalog,
      );
      final selectedIds = Set<String>.from(assignVm.selectedTechnicianIds);
      final techsChanged = initialIds.length != selectedIds.length ||
          initialIds.difference(selectedIds).isNotEmpty ||
          selectedIds.difference(initialIds).isNotEmpty;
      final st =
          PosViewModel.normalizeCashierJobStatus(jobSnapshotPreAssign.status);
      if (techsChanged && st == 'completed') {
        final oid = (posVm.selectedOrder?.id ?? posVm.editingOrder?.id)?.trim();
        if (oid != null && oid.isNotEmpty) {
          final marked = await posVm.tryMarkCashierJobEditedAfterMeaningfulChange(
            context,
            jobId: jobIdToUse,
            orderId: oid,
            refreshOrdersOnSuccess: false,
          );
          if (!mounted) return;
          if (!marked) {
            ToastService.showError(
              context,
              posVm.errorMessage ??
                  AppLocalizations.of(context)!.posTechnicianUnlockFailed,
            );
            return;
          }
        }
      }
    }

    final success = await vm.assignMultipleTechnicians(
      jobIdToUse,
      assignVm.selectedTechnicianIds.toList(),
    );

    if (!mounted) return;

    if (success) {
      final oid = (posVm.selectedOrder?.id ?? posVm.editingOrder?.id)?.trim();
      final catalog = vm.rawTechnicians;
      final initialIds = catalogIdsForJobTechnicians(
        widget.initialAssignedTechnicians,
        catalog,
      );
      final selectedIds = Set<String>.from(assignVm.selectedTechnicianIds);
      final List<JobTechnician> techs;
      if (assignVm.selectedTechnicianIds.isEmpty) {
        techs = [];
      } else {
        final fromSelection = _jobTechniciansFromSelection(
          assignVm.selectedTechnicianIds,
          vm.rawTechnicians,
        );
        final fromServer = vm.lastCashierAssignTechnicians;
        // POST may echo only a delta in `assigned` while sync applied the full roster — if counts
        // disagree, trust the picker selection so Jabbar + Taha both show after re-adding someone.
        if (fromServer.isNotEmpty &&
            fromServer.length == fromSelection.length) {
          techs = _mergeAssignServerTechniciansWithCatalog(fromServer, fromSelection);
        } else {
          techs = fromSelection;
        }
      }
      if (oid != null && oid.isNotEmpty) {
        posVm.applyJobTechniciansFromAssign(
          orderId: oid,
          jobId: jobIdToUse,
          technicians: techs,
        );
      }
      final addedIds = selectedIds.difference(initialIds);
      final removedIds = initialIds.difference(selectedIds);
      final slotsBeforeRefresh = <String, int>{
        for (final t in vm.rawTechnicians) t.id: t.slotsUsed,
      };
      await vm.refreshTechniciansCatalogQuiet(
        departmentId: widget.departmentId,
      );
      if (!mounted) return;
      vm.reconcileSlotsAfterAssign(
        addedEmployeeIds: addedIds,
        removedEmployeeIds: removedIds,
        slotsBeforeRefresh: slotsBeforeRefresh,
      );
      if (!mounted) return;
      final serverMsg = vm.assignmentMessage?.trim() ?? '';
      ToastService.showSuccess(
        context,
        serverMsg.isNotEmpty
            ? serverMsg
            : (assignVm.selectedTechnicianIds.isEmpty
                ? AppLocalizations.of(context)!.posTechAssignSuccessEmpty
                : AppLocalizations.of(context)!.posTechAssignSuccess),
      );
      if (oid != null && oid.isNotEmpty) {
        await posVm.refreshOrdersAfterPlacement(preferredOrderId: oid);
      } else {
        await posVm.refreshOrdersScreen();
      }
      if (!mounted) return;
      // GET /cashier/orders can still include old assignments briefly (or if the server lags behind
      // POST assign). Re-apply the list we just persisted so removals / empty state show correctly.
      if (oid != null && oid.isNotEmpty) {
        posVm.applyJobTechniciansFromAssign(
          orderId: oid,
          jobId: jobIdToUse,
          technicians: techs,
        );
      }
      // Realtime debounce refetches ~400ms later and can restore stale technicians; re-apply once more.
      if (oid != null && oid.isNotEmpty) {
        final oidDelayed = oid;
        final jid = jobIdToUse;
        final techsDelayed = List<JobTechnician>.from(techs);
        Future<void>.delayed(const Duration(milliseconds: 550), () {
          posVm.applyJobTechniciansFromAssign(
            orderId: oidDelayed,
            jobId: jid,
            technicians: techsDelayed,
          );
        });
      }
      if (!mounted) return;
      didNavigateToOrders = true;
      if (widget.embeddedInOrdersHubDialog) {
        Navigator.of(context).pop();
      } else {
        navigateToPosShellOrdersTab(context);
      }
    } else {
      ToastService.showError(
        context,
        vm.assignmentMessage ?? AppLocalizations.of(context)!.posTechnicianAssignFailed,
      );
    }
    } finally {
      if (mounted && !didNavigateToOrders) {
        setState(() => _saveFlowInProgress = false);
      }
    }
  }

  /// Same persistence as multi-assign: walk-in POST or edit PATCH, then returns real `jobId`.
  Future<String?> _resolveJobIdForBroadcast(BuildContext context) async {
    if (widget.jobId.isNotEmpty) return widget.jobId;
    final cached = _cachedJobIdFromSave;
    if (cached != null && cached.isNotEmpty) return cached;
    if (!widget.isWalkIn) return null;

    final posVm = context.read<PosViewModel>();
    final deptId = widget.departmentId ?? '';
    final isEditMode = posVm.editingOrder != null;

    if (isEditMode) {
      final existingJobId = posVm.editingCompletingOrderId ?? '';
      if (existingJobId.isEmpty) {
        ToastService.showError(context, AppLocalizations.of(context)!.posTechnicianFailedJobEdit);
        return null;
      }
      final success = await posVm.submitEditOrder(
        deptId.isNotEmpty ? [deptId] : [],
        context,
      );
      if (!mounted) return null;
      if (!success) return null;
      _cachedJobIdFromSave = existingJobId;
      return existingJobId;
    }

    final success = await posVm.submitWalkInOrder(
      deptId.isNotEmpty ? [deptId] : [],
      context,
      clearCustomerOnSuccess: false,
    );
    if (!mounted) return null;
    if (!success) return null;
    final jobIdToUse = posVm.currentJobId ?? '';
    if (jobIdToUse.isEmpty) {
      ToastService.showError(context, AppLocalizations.of(context)!.posTechnicianFailedOrderId);
      return null;
    }
    _cachedJobIdFromSave = jobIdToUse;
    return jobIdToUse;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final hub = widget.embeddedInOrdersHubDialog;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: ChangeNotifierProvider(
        create: (_) =>
            TechnicianAssignmentViewModel()
              ..setDepartmentName(widget.departmentName),
        child: _AssignmentCatalogBootstrap(
          departmentId: widget.departmentId,
          initialAssignedTechnicians: widget.initialAssignedTechnicians,
          child: Builder(
            builder: (context) {
              final assignVm = context.watch<TechnicianAssignmentViewModel>();
              return Scaffold(
              backgroundColor: const Color(0xFFFBF9F6),
              appBar: widget.embeddedInOrdersHubDialog
                  ? null
                  : PosScreenAppBar(
                      title: AppLocalizations.of(context)!
                          .posTechnicianAssignmentTitle,
                      titleFontWeight: FontWeight.w800,
                    ),
              body: Stack(
                children: [
                  Consumer<TechnicianViewModel>(

                builder: (context, vm, child) {
                  final listLoading =
                      vm.isLoading && !vm.hasTechnicianList;

                  if (vm.errorMessage != null &&
                      !vm.isLoading &&
                      !vm.hasTechnicianList) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.posTechnicianErrorPrefix(vm.errorMessage ?? '')),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final d = widget.departmentId?.trim() ?? '';
                              if (d.isNotEmpty) {
                                vm.fetchCashierTechnicians(departmentId: d);
                              } else {
                                vm.fetchCashierTechnicians();
                              }
                            },
                            child: Text(AppLocalizations.of(context)!.posTechAssignRetry),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter by search + department + online toggle. Selected techs
                  // must stay visible so the user can always uncheck them (otherwise
                  // they vanish under "Online only" or dept mismatch).
                  final query = assignVm.searchQuery.toLowerCase();
                  bool matchesSearch(PosTechnician tech) {
                    if (query.isEmpty) return true;
                    return tech.name.toLowerCase().contains(query) ||
                        tech.employeeType.toLowerCase().contains(query);
                  }

                  bool passesDeptAndCatalogVisibility(PosTechnician tech) {
                    final deptName = assignVm.departmentName?.trim() ?? '';
                    if (deptName.isNotEmpty) {
                      final inDept = tech.departments.any(
                        (d) => d.name.toLowerCase() == deptName.toLowerCase(),
                      );
                      if (!inDept) return false;
                    }
                    if (!assignVm.showAllTechnicians) {
                      /// Default: only workshop-floor eligible (online + workshop duty
                      /// + active). Hides "Not available", on-call, offline, etc.
                      if (!tech.isEligibleWorkshopAssignmentRow) return false;
                    }
                    return true;
                  }

                  final selectedIds = assignVm.selectedTechnicianIds;
                  final seen = <String>{};
                  final technicians = <PosTechnician>[];
                  for (final tech in vm.rawTechnicians) {
                    if (!selectedIds.contains(tech.id)) continue;
                    if (!matchesSearch(tech)) continue;
                    if (seen.add(tech.id)) technicians.add(tech);
                  }
                  for (final tech in vm.rawTechnicians) {
                    if (selectedIds.contains(tech.id)) continue;
                    if (!matchesSearch(tech)) continue;
                    if (!passesDeptAndCatalogVisibility(tech)) continue;
                    if (seen.add(tech.id)) technicians.add(tech);
                  }
                  sortPosTechniciansList(technicians);

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isTablet ? (hub ? 14.0 : 24.0) : 12.0,
                                isTablet ? (hub ? 10.0 : 20.0) : 10.0,
                                hub ? 8 : 6,
                                6,
                              ),
                              child: PosWorkshopSearchBar(
                                onChanged: assignVm.setSearchQuery,
                                hintText: AppLocalizations.of(context)!.posTechnicianSearchHint,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: assignVm.toggleShowAllTechnicians,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: isTablet ? (hub ? 14.0 : 24.0) : 12,
                                top: isTablet ? (hub ? 10.0 : 20.0) : 10.0,
                                bottom: 6,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hub ? 8 : 12,
                                  vertical: hub ? 6 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(
                                    alpha: 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  assignVm.showAllTechnicians
                                      ? AppLocalizations.of(context)!.posTechAssignOnlineOnly
                                      : AppLocalizations.of(context)!.posTechAssignShowAll,
                                  style: TextStyle(
                                    color: AppColors.secondaryLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: hub ? 11 : 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: listLoading
                            ? _TechnicianAssignmentListShimmer(hub: hub)
                            : technicians.isEmpty
                                ? Center(
                                    child: Text(AppLocalizations.of(context)!.posTechAssignNoResults),
                                  )
                                : GridView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? (hub ? 10 : 24) : 12,
                                  vertical: 4,
                                ),
                                itemCount: technicians.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isLandscape
                                          ? (hub ? 4 : 3)
                                          : (isTablet ? 2 : 1),
                                      mainAxisExtent: isTablet
                                          ? (hub ? 108 : 156)
                                          : (hub ? 104 : 138),
                                      crossAxisSpacing: hub ? 8 : 16,
                                      mainAxisSpacing: hub ? 6 : 10,
                                    ),
                                itemBuilder: (context, index) {
                                  final tech = technicians[index];
                                  final aStatus = tech.effectiveAssignmentStatus;
                                  final isSelected = assignVm
                                      .selectedTechnicianIds
                                      .contains(tech.id);
                                  // Checkbox only for presence-online; hide when slots full (no new pick).
                                  // Already-selected rows stay actionable via card tap if needed.
                                  final slotsAllowNewPick =
                                      tech.slotsUsed < tech.totalSlots;
                                  final rowWorkshop = tech.isEligibleWorkshopAssignmentRow;
                                  final showCheckbox = rowWorkshop &&
                                      (isSelected || slotsAllowNewPick);
                                  final canPickNew = rowWorkshop &&
                                      tech.assignable &&
                                      slotsAllowNewPick;
                                  final canInteract = !_saveFlowBusy(vm) &&
                                      (canPickNew || isSelected);
                                  final checkboxEnabled = !_saveFlowBusy(vm) &&
                                      (isSelected || canPickNew);

                                  return InkWell(
                                    onTap: canInteract
                                        ? () =>
                                            assignVm.toggleSelection(tech)
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Opacity(
                                      opacity: tech.isEligible ? 1.0 : 0.5,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: hub ? 8 : 14,
                                          vertical: hub ? 6 : 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryLight
                                                    .withValues(alpha: 0.1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            hub ? 10 : 12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryLight
                                                : Colors.grey.shade200,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.02,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: isTablet
                                                      ? (hub ? 18 : 25)
                                                      : (hub ? 17 : 22),
                                                  backgroundColor: AppColors
                                                      .primaryLight
                                                      .withValues(alpha: 0.1),
                                                  child: Icon(
                                                    Icons.person,
                                                    size: isTablet
                                                        ? (hub ? 20 : 25)
                                                        : (hub ? 18 : 21),
                                                    color: AppColors
                                                        .secondaryLight,
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    width: isTablet
                                                        ? (hub ? 10 : 12)
                                                        : 10,
                                                    height: isTablet
                                                        ? (hub ? 10 : 12)
                                                        : 10,
                                                    decoration: BoxDecoration(
                                                      color: _assignmentStatusDotColor(
                                                        aStatus,
                                                      ),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: hub ? 8 : 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  LocalizedApiText(
                                                    tech.assignmentStatusDisplayLabel,
                                                    style: TextStyle(
                                                      fontSize: isTablet
                                                          ? (hub ? 11 : 13)
                                                          : 10,
                                                      color:
                                                          _assignmentStatusAccentColor(
                                                        aStatus,
                                                      ),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (!tech.isOnline &&
                                                      tech.formattedLastSeen
                                                          .isNotEmpty)
                                                    Text(
                                                      AppLocalizations.of(context)!.posTechnicianLastSeen(AppTranslationService.localizeDigitsForLanguage(tech.formattedLastSeen, Localizations.localeOf(context).languageCode)),
                                                      style: TextStyle(
                                                        fontSize: isTablet
                                                            ? 11
                                                            : 10,
                                                        color: Colors.grey.shade600,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: LocalizedApiText(
                                                          tech.name,
                                                          style: TextStyle(
                                                            fontSize: isTablet
                                                                ? (hub ? 13 : 16)
                                                                : 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: const Color(
                                                              0xFF1E2124,
                                                            ),
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (tech
                                                      .departments
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    LocalizedApiText(
                                                      tech.departments
                                                          .map((d) => d.name)
                                                          .join(' • '),
                                                      style: TextStyle(
                                                        fontSize: isTablet
                                                            ? (hub ? 11 : 13)
                                                            : 11,
                                                        color: Colors.blueGrey,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.work_history_outlined,
                                                        size: isTablet ? 14 : 12,
                                                        color:
                                                            tech.slotsUsed >=
                                                                tech.totalSlots
                                                            ? Colors
                                                                  .red
                                                                  .shade400
                                                            : Colors
                                                                  .green
                                                                  .shade400,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        AppTranslationService.localizeDigitsForLanguage(AppLocalizations.of(context)!.posTechnicianSlots(tech.slotsUsed, tech.totalSlots), Localizations.localeOf(context).languageCode),
                                                        style: TextStyle(
                                                          fontSize: isTablet
                                                              ? 12
                                                              : 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              tech.slotsUsed >=
                                                                  tech.totalSlots
                                                              ? Colors
                                                                    .red
                                                                    .shade600
                                                              : Colors
                                                                    .green
                                                                    .shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (showCheckbox)
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: checkboxEnabled
                                                    ? (_) => assignVm
                                                        .toggleSelection(tech)
                                                    : null,
                                                activeColor:
                                                    AppColors.secondaryLight,
                                                checkColor:
                                                    AppColors.primaryLight,
                                                visualDensity:
                                                    const VisualDensity(
                                                      horizontal: 0.2,
                                                      vertical: 0.2,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
              if (context.watch<TechnicianViewModel>().isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: _TechnicianAssignmentListShimmer(hub: hub),
                  ),
                ),
            ],
          ),

              bottomNavigationBar: SafeArea(
                child: Container(
                  padding: EdgeInsets.all(hub ? 10 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(hub ? 14 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0, -4),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Consumer<TechnicianViewModel>(
                        builder: (context, vm, _) {
                          final posVm = context.watch<PosViewModel>();
                          final busy = _saveFlowBusy(vm);
                          final effectiveJobId = widget.jobId.isNotEmpty
                              ? widget.jobId
                              : (_cachedJobIdFromSave ?? '');
                          final broadcastCooldown =
                              posVm.isBroadcastCooldownActive(
                            departmentId: widget.departmentId,
                            jobId: effectiveJobId,
                          );
                          final cooldownKey = posVm.broadcastCooldownKey(
                            departmentId: widget.departmentId,
                            jobId: effectiveJobId,
                          );
                          final cooldownLabel = broadcastCooldown &&
                                  cooldownKey.isNotEmpty
                              ? posVm
                                  .broadcastCooldownTimerLabelForKey(cooldownKey)
                              : '';
                          return Row(
                            children: [
                              if (_canTapBroadcast) ...[
                                Expanded(
                                  child: SizedBox(
                                    height: hub ? 38 : 50,
                                    child: ElevatedButton(
                                      onPressed: (_broadcastingDuty == null &&
                                              !busy &&
                                              !broadcastCooldown)
                                          ? () => _broadcastOnCall(context)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryLight,
                                        foregroundColor: AppColors.secondaryLight,
                                        // Keep the same visual tone even when disabled during save flow.
                                        disabledBackgroundColor: AppColors.primaryLight,
                                        disabledForegroundColor: AppColors.secondaryLight,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: (_broadcastingDuty == 'on_call')
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryLight),
                                              ),
                                            )
                                          : broadcastCooldown
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.schedule_rounded,
                                                      size: 16,
                                                      color:
                                                          AppColors.secondaryLight,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        AppLocalizations.of(context)!.posTechnicianWait(AppTranslationService.localizeDigitsForLanguage(cooldownLabel, Localizations.localeOf(context).languageCode)),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  AppLocalizations.of(context)!.posTechnicianBroadcast,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: SizedBox(
                                  height: hub ? 38 : 50,
                                  child: ElevatedButton(
                                    onPressed: busy
                                        ? null
                                        : () => _handleMultiAssign(context, assignVm),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondaryLight,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AppColors.secondaryLight,
                                      disabledForegroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: busy ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ) : Text(
                                      AppLocalizations.of(context)!.posTechnicianSave,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Future<void> _broadcastOnCall(BuildContext context) async {
    if (!_canTapBroadcast || _broadcastingDuty != null) return;
    setState(() => _broadcastingDuty = 'on_call');
    try {
      final jobId = await _resolveJobIdForBroadcast(context);
      if (!mounted) return;
      if (jobId == null || jobId.isEmpty) return;
      await context.read<PosViewModel>().broadcastJob(
            context,
            jobId,
            dutyMode: 'on_call',
            departmentId: widget.departmentId,
          );
    } finally {
      if (mounted) setState(() => _broadcastingDuty = null);
    }
  }
}


class _TechnicianAssignmentListShimmer extends StatelessWidget {
  const _TechnicianAssignmentListShimmer({this.hub = false});

  final bool hub;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final hPad = isTablet ? (hub ? 14.0 : 24.0) : 12.0;
    final topPad = isTablet ? (hub ? 10.0 : 20.0) : 10.0;
    final gridPadH = isTablet ? (hub ? 10.0 : 24.0) : 12.0;
    final crossAxisCount =
        isLandscape ? (hub ? 4 : 3) : (isTablet ? 2 : 1);
    final mainAxisExtent =
        isTablet ? (hub ? 108.0 : 156.0) : (hub ? 104.0 : 138.0);
    final crossAxisSpacing = hub ? 8.0 : 16.0;
    final mainAxisSpacing = hub ? 6.0 : 10.0;
    final searchHeight = hub ? (isTablet ? 36.0 : 40.0) : (isTablet ? 50.0 : 44.0);
    final searchRadius = hub ? 10.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, topPad, hub ? 8 : 6, 6),
          child: PosShimmer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: PosShimmerLine(
                    width: double.infinity,
                    height: searchHeight,
                    radius: searchRadius,
                  ),
                ),
                SizedBox(width: hub ? 8 : 6),
                PosShimmerBox(
                  width: hub ? 72 : 96,
                  height: hub ? 30 : 38,
                  radius: 10,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: gridPadH, vertical: 4),
            itemCount: crossAxisCount * (hub ? 3 : 2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: mainAxisExtent,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
            ),
            itemBuilder: (_, __) => _TechnicianAssignmentCardShimmer(
              hub: hub,
              isTablet: isTablet,
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for one technician row card (matches assignment grid tile layout).
class _TechnicianAssignmentCardShimmer extends StatelessWidget {
  const _TechnicianAssignmentCardShimmer({
    required this.hub,
    required this.isTablet,
  });

  final bool hub;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isTablet ? (hub ? 36.0 : 50.0) : (hub ? 34.0 : 44.0);
    final statusDot = isTablet ? (hub ? 10.0 : 12.0) : 10.0;
    final cardRadius = hub ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: hub ? 8 : 14,
        vertical: hub ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: PosShimmer(
        child: Row(
          children: [
            SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PosShimmerCircle(size: avatarSize),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: statusDot,
                      height: statusDot,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFDFDF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: hub ? 8 : 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PosShimmerLine(
                    width: hub ? 52 : 68,
                    height: hub ? 10 : 12,
                    radius: 6,
                  ),
                  const SizedBox(height: 2),
                  PosShimmerLine(
                    width: double.infinity,
                    height: hub ? 12 : (isTablet ? 14 : 13),
                    radius: 6,
                  ),
                  const SizedBox(height: 2),
                  PosShimmerLine(
                    width: hub ? 88 : 110,
                    height: hub ? 10 : 11,
                    radius: 6,
                  ),
                  SizedBox(height: hub ? 3 : 4),
                  Row(
                    children: [
                      PosShimmerBox(
                        width: hub ? 12 : 14,
                        height: hub ? 12 : 14,
                        radius: 4,
                      ),
                      const SizedBox(width: 3),
                      PosShimmerLine(
                        width: hub ? 50 : 64,
                        height: hub ? 10 : 11,
                        radius: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PosShimmerBox(
              width: hub ? 20 : 22,
              height: hub ? 20 : 22,
              radius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
