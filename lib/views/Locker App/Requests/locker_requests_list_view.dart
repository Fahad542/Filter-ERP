import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/locker_models.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';
import '../Collection/record_collection_view.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_request_details_view.dart';
import 'locker_requests_view_model.dart';

/// Sentinel for filter "All" when the real status value is `null`.
const String _kAllDropdownValue = '__all__';

// ── Filter mode enum ──────────────────────────────────────────────────────────

enum LockerListFilterMode {
  normal,
  assignPending,

  /// "View All" from dashboard Recent Collections (collector tab) —
  /// opens with status=collected, scoped to logged-in user's own requests.
  collected,

  /// "View All" from dashboard Recent Collections (supervisor tab) —
  /// opens with status=collected, shows ALL users' requests (no user filter).
  allCollected,

  /// "My Pending Requests" quick action — opens with status=pending,
  /// scoped to the logged-in user's own requests (collector view).
  myPending,
}

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerRequestsListView extends StatelessWidget {
  final LockerListFilterMode filterMode;

  /// Which API view this screen should use.
  ///
  /// - supervisor: show all workshop requests / supervisor actions
  /// - collector: show only current user's assigned collection requests
  ///
  /// When null, the ViewModel will decide from the logged-in locker role.
  final String? initialView;

  /// Controls which sidebar item set [LockerShell] shows and the AppBar
  /// title. Collector-specific modes (myPending, collected) auto-set this
  /// to false; pass explicitly for ambiguous cases (e.g. normal / allCollected).
  ///
  /// Defaults to null so collector-specific filterModes (myPending, collected)
  /// can auto-resolve to false without the caller having to pass the flag.
  /// Supervisor-specific modes (allCollected, normal with initialView:supervisor)
  /// should pass [isSupervisor: true] explicitly.
  final bool? isSupervisor;

  const LockerRequestsListView({
    super.key,
    this.filterMode = LockerListFilterMode.normal,
    this.initialView,
    this.isSupervisor,
  });

  /// Resolves [isSupervisor] from the filterMode when not explicitly passed.
  /// Collector-specific modes always return false; everything else defaults
  /// to true so supervisor screens that omit the flag keep working.
  bool get _resolvedIsSupervisor {
    if (isSupervisor != null) return isSupervisor!;
    switch (filterMode) {
      case LockerListFilterMode.myPending:
      case LockerListFilterMode.collected:
        return false;
      case LockerListFilterMode.allCollected:
      case LockerListFilterMode.assignPending:
      case LockerListFilterMode.normal:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerRequestsViewModel(
        filterMode: filterMode,
        initialView: initialView,
      ),
      child: _LockerRequestsBody(
        filterMode: filterMode,
        isSupervisor: _resolvedIsSupervisor,
      ),
    );
  }
}

// ── Inner StatefulWidget ──────────────────────────────────────────────────────

class _LockerRequestsBody extends StatefulWidget {
  final LockerListFilterMode filterMode;
  final bool isSupervisor;

  const _LockerRequestsBody({
    required this.filterMode,
    required this.isSupervisor,
  });

  @override
  State<_LockerRequestsBody> createState() => _LockerRequestsBodyState();
}

class _LockerRequestsBodyState extends State<_LockerRequestsBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.read<LockerRequestsViewModel>().init(l10n);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<LockerRequestsViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LockerRequestsViewModel>(
      builder: (context, vm, _) {
        final now = DateTime.now();
        final defaultFrom = DateTime(now.year, now.month, now.day);
        final defaultTo = now;

        final l10n = AppLocalizations.of(context)!;
        return LockerShell(
          isSupervisor: widget.isSupervisor,
          currentItem: _sidebarItemForMode(widget.filterMode),
          title: _titleForMode(l10n, widget.filterMode, widget.isSupervisor),
          backgroundColor: OwnerUi.scaffoldBackground,
          // Same white elevated date chips as Workshop Owner dashboard.
          bottomOverlap: vm.isPendingOnlyMode
              ? TechDashboardOverlapFilters(
                  startDate: vm.fromDate ?? defaultFrom,
                  endDate: vm.toDate ?? defaultTo,
                  dateOnly: true,
                  onStartDateChanged: (d) => vm.setFromDate(d),
                  onEndDateChanged: (d) => vm.setToDate(d),
                )
              : null,
          body: Column(
            children: [
              // ── Branch / cashier / amount (dates live in app-bar overlap)
              if (vm.isPendingOnlyMode) _InlineFilterPanel(vm: vm),

              // ── Status tabs (collected / allCollected modes only) ──────────
              if (!vm.isPendingOnlyMode) _buildStatusTabs(context, vm),

              // ── Requests list ─────────────────────────────────────────────
              Expanded(child: _buildBody(context, vm)),

              // ── Total expected — fixed bottom bar ─────────────────────────
              if (vm.isPendingOnlyMode && vm.isSuccess)
                _buildTotalExpectedBar(context, vm),
            ],
          ),
        );
      },
    );
  }

  static String _titleForMode(
      AppLocalizations l10n, LockerListFilterMode mode, bool isSupervisor) {
    switch (mode) {
      case LockerListFilterMode.myPending:
        return l10n.lockerTitleMyPending;
      case LockerListFilterMode.collected:
        return l10n.lockerTitleMyCollections;
      case LockerListFilterMode.allCollected:
        return l10n.lockerTitleAllCollections;
      case LockerListFilterMode.assignPending:
        return l10n.lockerTitleAssignOfficers;
      case LockerListFilterMode.normal:
        return isSupervisor
            ? l10n.lockerTitlePendingRequests
            : l10n.lockerTitleRequests;
    }
  }

  /// Maps this screen's filter mode to the matching sidebar entry, so the
  /// drawer highlights the right row. "View All" / "Assign Officers" modes
  /// have no dedicated sidebar entry of their own, so they fall back to
  /// dashboard (no highlight) rather than falsely highlighting an unrelated
  /// item.
  static LockerSidebarItem _sidebarItemForMode(LockerListFilterMode mode) {
    switch (mode) {
      case LockerListFilterMode.myPending:
      // Collector sidebar calls this "Assigned Requests"
        return LockerSidebarItem.assignedRequests;
      case LockerListFilterMode.normal:
      // Supervisor sidebar calls this "Pending Requests"
        return LockerSidebarItem.pendingRequests;
      case LockerListFilterMode.collected:
      case LockerListFilterMode.allCollected:
      case LockerListFilterMode.assignPending:
        return LockerSidebarItem.dashboard;
    }
  }

  // ── Total expected — fixed bottom bar ─────────────────────────────────────

  Widget _buildTotalExpectedBar(
      BuildContext context, LockerRequestsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.attach_money_rounded,
              color: AppColors.secondaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.lockerTotalExpectedFiltered,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.lockerRequestsInRange(vm.totalItems.toString()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${l10n.lockerSarCurrency} ${vm.totalExpected.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status tabs — only for collected/allCollected modes ─────────────────

  Widget _buildStatusTabs(BuildContext context, LockerRequestsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final filters = vm.activeFilters(l10n);
    if (filters.isEmpty) return const SizedBox.shrink();

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final selectedId = vm.selectedStatus ?? _kAllDropdownValue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: PosSegmentedListTabs(
        tabs: [
          for (final f in filters)
            PosSegmentedTab(
              id: f.value ?? _kAllDropdownValue,
              label: f.label,
            ),
        ],
        selectedId: filters.any((f) => (f.value ?? _kAllDropdownValue) == selectedId)
            ? selectedId
            : (filters.first.value ?? _kAllDropdownValue),
        onSelected: (id) {
          vm.setStatus(id == _kAllDropdownValue ? null : id);
        },
        layout: PosSegmentedTabLayout.scrollable,
        padding: EdgeInsets.zero,
        outerRadius: OwnerUi.segmentedTabOuterRadius,
        innerRadius: OwnerUi.segmentedTabInnerRadius,
        tabGap: OwnerUi.segmentedTabGap,
        containerInnerPadding: OwnerUi.segmentedTabContainerPad,
        tabVerticalPadding: OwnerUi.segmentedTabVerticalPad(isTablet),
        tabHorizontalPadding: OwnerUi.segmentedTabHorizontalPad(isTablet),
        fontSize: OwnerUi.segmentedTabFontSize(isTablet),
      ),
    );
  }

  // ── Body dispatcher ───────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, LockerRequestsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;

    if (vm.isLoading) {
      return OwnerListPageShimmer(
        showKpi: vm.isPendingOnlyMode,
        kpiCount: 1,
        itemCount: 6,
      );
    }

    if (vm.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.wifi_off_rounded,
                    size: 40, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.lockerFailedLoadRequests,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage ?? l10n.lockerUnexpectedError,
                textAlign: TextAlign.center,
                style:
                const TextStyle(color: Colors.black45, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: vm.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.lockerRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded,
                  size: 56,
                  color: Colors.black.withOpacity(0.12)),
              const SizedBox(height: 16),
              Text(
                l10n.lockerNoRequestsFound,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.35),
                    fontWeight: FontWeight.w900,
                    fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.lockerAdjustFilters,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.25),
                    fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: vm.requests.length + (vm.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == vm.requests.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: OwnerCardRowShimmer(),
            );
          }
          return _RequestCard(
            request: vm.requests[index],
            isSupervisor: vm.isSupervisor,
          );
        },
      ),
    );
  }
}

// ── Inline filters panel ──────────────────────────────────────────────────────
//
// Always visible on the pending-requests screen (no FILTERS toggle).
// Uses local state for the min/max text fields so they don't re-render
// while the user is typing (the VM debounces the actual API calls).

class _InlineFilterPanel extends StatefulWidget {
  final LockerRequestsViewModel vm;

  const _InlineFilterPanel({required this.vm});

  @override
  State<_InlineFilterPanel> createState() => _InlineFilterPanelState();
}

class _InlineFilterPanelState extends State<_InlineFilterPanel> {
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = widget.vm;
    if (vm.minExpected != null) {
      _minCtrl.text = vm.minExpected!.toStringAsFixed(0);
    }
    if (vm.maxExpected != null) {
      _maxCtrl.text = vm.maxExpected!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final l10n = AppLocalizations.of(context)!;
    final currency = l10n.lockerSarCurrency;

    // Same horizontal inset as the request list cards below.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.hasActiveFilters)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        _minCtrl.clear();
                        _maxCtrl.clear();
                        vm.clearAdvancedFilters();
                      },
                      child: Text(
                        l10n.lockerClearAll,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: _DropdownFilterField(
                      label: l10n.lockerLabelBranch,
                      value: vm.branchId,
                      options: [
                        OwnerDropdownOption(
                          value: _kAllDropdownValue,
                          label: l10n.lockerFilterAll,
                        ),
                        ...vm.branches.map(
                          (b) => OwnerDropdownOption(
                            value: b.id,
                            label: b.name,
                          ),
                        ),
                      ],
                      onChanged: vm.setBranch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DropdownFilterField(
                      label: l10n.lockerLabelCashier,
                      value: vm.cashierId,
                      options: [
                        OwnerDropdownOption(
                          value: _kAllDropdownValue,
                          label: l10n.lockerFilterAll,
                        ),
                        ...vm.cashiers.map(
                          (c) => OwnerDropdownOption(
                            value: c.userId,
                            label: c.name.isNotEmpty ? c.name : c.email,
                          ),
                        ),
                      ],
                      onChanged: vm.setCashier,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _NumberFilterField(
                      label: l10n.lockerMinSar(currency),
                      hint: '0',
                      controller: _minCtrl,
                      onChanged: vm.setMinExpected,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberFilterField(
                      label: l10n.lockerMaxSar(currency),
                      hint: l10n.lockerAny,
                      controller: _maxCtrl,
                      onChanged: vm.setMaxExpected,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final LockerRequest request;
  final bool isSupervisor;

  const _RequestCard({
    required this.request,
    required this.isSupervisor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    // Supervisor-only — the two approve actions only make sense before
    // anyone has been assigned yet, i.e. while the request is still pending.
    final showActions =
        isSupervisor && request.status == LockerStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The info area is its own tap target (→ details). Action
              // buttons below are siblings, not nested inside it, so a tap
              // on a button never also triggers the card-level navigation.
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LockerRequestDetailsView(requestId: request.id),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1 — icon + request # + branch, status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const OwnerListIconBox(
                          icon: Icons.lock_outline_rounded,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.referenceCode,
                                style: OwnerListStyle.titleStyle,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                request.branchName,
                                style: OwnerListStyle.subtitleStyle,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                        height: 1, color: OwnerListStyle.cardBorder),
                    const SizedBox(height: 12),
                    // Info rows — cashier / officer / requested / expected
                    _InfoRow(
                        label: l10n.lockerLabelCashier, value: request.cashierName),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: l10n.lockerLabelOfficer,
                      value: request.assignedOfficerName ?? '—',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: l10n.lockerLabelRequested,
                      value:
                          '${DateFormat('dd/MM/yyyy', locale).format(request.closingDate)}, '
                          '${DateFormat('HH:mm:ss', locale).format(request.closingDate)}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: l10n.lockerLabelExpected,
                      value:
                          '${l10n.lockerSarCurrency} ${request.lockedCashAmount.toStringAsFixed(0)}',
                      valueStyle: OwnerListStyle.titleStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // Action — supervisor, pending only.
              if (showActions) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _openOfficerSheet(
                            context,
                            context.read<LockerRequestsViewModel>(),
                            request,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryLight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.lockerApproveAndForward,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1.15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordCollectionView(request: request),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.secondaryLight,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.lockerApproveAndRecord,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              height: 1.15,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick-assign officer bottom sheet ─────────────────────────────────────

  Future<void> _openOfficerSheet(
      BuildContext context,
      LockerRequestsViewModel vm,
      LockerRequest request,
      ) async {
    await vm.loadOfficersIfNeeded();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<LockerRequestsViewModel>(
          builder: (ctx, vm2, _) {
            final l10n = AppLocalizations.of(ctx)!;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      l10n.lockerSelectOfficer,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryLight,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.lockerSelectOfficerSubtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.4)),
                    ),
                    const SizedBox(height: 16),
                    if (vm2.assignError != null)
                      _ErrorBanner(message: vm2.assignError!),
                    if (vm2.isOfficersLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryLight))
                    else if (vm2.officersState == ListOfficersState.error)
                      _OfficersErrorState(
                        message: vm2.officersError ??
                            l10n.lockerOfficersLoadError,
                        onRetry: vm2.loadOfficersIfNeeded,
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: vm2.officers.length,
                          separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final officer = vm2.officers[i];
                            final isAssigning =
                                vm2.isAssigning &&
                                    vm2.assigningOfficerId == officer.id;
                            final isDisabled = vm2.isAssigning;

                            return _OfficerTile(
                              officer: officer,
                              isAssigning: isAssigning,
                              isDisabled: isDisabled,
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(
                                      l10n.lockerAssignCollectionOfficer,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.secondaryLight,
                                      ),
                                    ),
                                    content: Text(
                                      '${l10n.lockerAssignedTo} ${officer.name}?',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, false),
                                        child: Text(l10n.lockerCancel),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          AppColors.secondaryLight,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.lockerAssignCollectionOfficer,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                final success = await vm2.assignOfficer(
                                  requestId: request.id,
                                  officerId: officer.id,
                                );
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${l10n.lockerAssignedTo} ${officer.name.toUpperCase()}'),
                                      backgroundColor:
                                      AppColors.secondaryLight,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).whenComplete(() => vm.resetAssignState());
  }
}

// ── Officer tile ──────────────────────────────────────────────────────────────

class _OfficerTile extends StatelessWidget {
  final LockerOfficer officer;
  final bool isAssigning;
  final bool isDisabled;
  final VoidCallback onTap;

  const _OfficerTile({
    required this.officer,
    required this.isAssigning,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !isDisabled,
      leading: CircleAvatar(
        backgroundColor: AppColors.secondaryLight.withOpacity(0.05),
        child: const Icon(Icons.person_3_outlined,
            color: AppColors.secondaryLight, size: 20),
      ),
      title: Text(
        officer.name,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: isDisabled
              ? AppColors.secondaryLight.withOpacity(0.4)
              : AppColors.secondaryLight,
        ),
      ),
      subtitle: Text(
        officer.displayCode,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      trailing: isAssigning
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primaryLight),
      )
          : const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.black12),
      onTap: isDisabled ? null : onTap,
    );
  }
}

// ── Error banner (quick-assign sheet) ───────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Officers error state (quick-assign sheet) ───────────────────────────────

class _OfficersErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _OfficersErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: Colors.red.shade300, size: 36),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 12)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.lockerRetry),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryLight),
          ),
        ],
      ),
    );
  }
}

// ── Labeled info row ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: OwnerListStyle.metaStyle.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: OwnerListStyle.labelGrey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle ?? OwnerListStyle.subtitleStyle.copyWith(
              color: AppColors.secondaryLight,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final LockerStatus status;
  const _StatusBadge({required this.status});

  Color get _bg {
    switch (status) {
      case LockerStatus.pending:
        return Colors.orange.shade800;
      case LockerStatus.assigned:
        return Colors.blue.shade800;
      case LockerStatus.awaitingApproval:
        return Colors.purple.shade800;
      case LockerStatus.collected:
        return Colors.green.shade700;
      case LockerStatus.approved:
        return Colors.green.shade800;
      case LockerStatus.rejected:
        return Colors.red.shade800;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case LockerStatus.pending:
        return l10n.lockerStatusPending;
      case LockerStatus.assigned:
        return l10n.lockerStatusAssigned;
      case LockerStatus.awaitingApproval:
        return l10n.lockerStatusAwaiting;
      case LockerStatus.collected:
        return l10n.lockerStatusCollected;
      case LockerStatus.approved:
        return l10n.lockerStatusApproved;
      case LockerStatus.rejected:
        return l10n.lockerStatusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(l10n),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 8,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Advanced filter field widgets ─────────────────────────────────────────────

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DropdownFilterField extends StatelessWidget {
  final String label;
  final String? value;
  final List<OwnerDropdownOption<String>> options;
  final ValueChanged<String?> onChanged;

  const _DropdownFilterField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a stale selected value that's no longer in `options`
    // (e.g. branch/cashier list still loading).
    final raw = value ?? _kAllDropdownValue;
    final validValue =
        options.any((o) => o.value == raw) ? raw : _kAllDropdownValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label),
        OwnerStyledDropdown<String>(
          value: validValue,
          options: options,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          backgroundColor: Colors.white,
          borderColor: OwnerListStyle.cardBorder,
          onChanged: (val) {
            if (val == null) return;
            onChanged(val == _kAllDropdownValue ? null : val);
          },
        ),
      ],
    );
  }
}

class _NumberFilterField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<double?> onChanged;

  const _NumberFilterField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OwnerListStyle.cardBorder),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.3),
                  fontSize: 11.5),
              border: InputBorder.none,
            ),
            // Debounced in the ViewModel — safe to call on every keystroke.
            onChanged: (val) => onChanged(
              val.trim().isEmpty ? null : double.tryParse(val.trim()),
            ),
          ),
        ),
      ],
    );
  }
}