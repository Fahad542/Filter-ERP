import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_differences_report_view_model.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

String _money(double v) => NumberFormat('#,##0.00').format(v);

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerDifferencesReportView extends StatelessWidget {
  /// Whether the signed-in user is a supervisor or collector — controls
  /// which sidebar item set [LockerShell] shows. Defaults to true since
  /// this screen is most commonly reached from the supervisor's sidebar.
  final bool isSupervisor;

  const LockerDifferencesReportView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerDifferencesReportViewModel(),
      child: _DifferencesReportBody(isSupervisor: isSupervisor),
    );
  }
}

// ── Body scaffold ─────────────────────────────────────────────────────────────

class _DifferencesReportBody extends StatefulWidget {
  final bool isSupervisor;

  const _DifferencesReportBody({required this.isSupervisor});

  @override
  State<_DifferencesReportBody> createState() => _DifferencesReportBodyState();
}

class _DifferencesReportBodyState extends State<_DifferencesReportBody> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.read<LockerDifferencesReportViewModel>().init(l10n);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LockerDifferencesReportViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final defaultFrom = DateTime(now.year, now.month, now.day);
    final defaultTo = now;

    return LockerShell(
      isSupervisor: widget.isSupervisor,
      currentItem: LockerSidebarItem.differencesReport,
      title: l10n.lockerDifferencesTitle,
      backgroundColor: OwnerUi.scaffoldBackground,
      // Same white elevated date chips as Pending Requests / Owner dashboard.
      bottomOverlap: TechDashboardOverlapFilters(
        startDate: vm.from ?? defaultFrom,
        endDate: vm.to ?? defaultTo,
        dateOnly: true,
        onStartDateChanged: (d) => vm.setDateRange(d, vm.to ?? d),
        onEndDateChanged: (d) => vm.setDateRange(vm.from ?? d, d),
      ),
      body: _buildBody(context, vm),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, LockerDifferencesReportViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    if (vm.isLoading && vm.visibleItems.isEmpty) {
      return const OwnerListPageShimmer(
        showKpi: true,
        kpiCount: 3,
        itemCount: 4,
        padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      );
    }

    if (vm.isError && vm.visibleItems.isEmpty) {
      return _ErrorState(
          message: vm.error ?? l10n.lockerAnErrorOccurred, onRetry: vm.refresh);
    }

    final items = vm.visibleItems;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // ── KPI Grid ──────────────────────────────────────────────────────
          _buildKpiGrid(context, vm),

          // Pull filters up into KPI leftover whitespace — KPI size unchanged.
          Transform.translate(
            offset: const Offset(0, -12),
            child: _buildFilterPanel(context, vm),
          ),
          const SizedBox(height: 6),

          // ── Toolbar ───────────────────────────────────────────────────────
          _buildToolbar(context, vm),
          const SizedBox(height: 8),

          // ── Type chips ────────────────────────────────────────────────────
          _TypeFilterChips(vm: vm),
          const SizedBox(height: 12),

          // ── List ──────────────────────────────────────────────────────────
          if (items.isEmpty)
            _EmptyInline(
              message: vm.hasActiveFilters
                  ? l10n.lockerNoResultsMatchFilters
                  : l10n.lockerNoDifferences,
            )
          else
            ...List.generate(
              items.length,
                  (i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _VarianceCard(entry: items[i]),
              ),
            ),
        ],
      ),
    );
  }

  // ── KPI Grid ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(BuildContext context, LockerDifferencesReportViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final s = vm.summary;
    final cur = s.currency.trim().toUpperCase() == 'SAR'
        ? l10n.lockerSarCurrency
        : s.currency;

    final metrics = [
      ReusableKpiMetric(
        title: l10n.lockerNetDifference,
        value: '${s.netVariance >= 0 ? "+" : ""}$cur ${_money(s.netVariance.abs())}',
        subtitle: s.netVariance < 0
            ? l10n.lockerNetShort
            : s.netVariance > 0
                ? l10n.lockerNetOver
                : l10n.lockerBalanced,
        icon: Icons.compare_arrows_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerTotalShort,
        value: '$cur ${_money(s.totalShort)}',
        subtitle: l10n.lockerCashShortage,
        icon: Icons.trending_down_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerTotalOver,
        value: '$cur ${_money(s.totalOver)}',
        subtitle: l10n.lockerCashSurplus,
        icon: Icons.trending_up_rounded,
      ),
    ];

    return ReusableKpiGrid.owner(
      metrics: metrics,
      crossAxisCount: 3,
      iconOnTop: true,
      padding: EdgeInsets.zero,
    );
  }

  // ── Filter panel — always visible (dates live in app-bar overlap) ─────────

  Widget _buildFilterPanel(
      BuildContext context, LockerDifferencesReportViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
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
                      _searchCtrl.clear();
                      vm.clearFilters();
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
                  child: _FilterDropdown<String>(
                    label: l10n.lockerLabelBranch,
                    value: vm.selectedBranchId ?? 'all',
                    isLoading: vm.branchesLoading,
                    hint: l10n.lockerAllBranches,
                    options: [
                      OwnerDropdownOption(
                          value: 'all', label: l10n.lockerAllBranches),
                      ...vm.branches.map(
                        (b) => OwnerDropdownOption(
                            value: b.id, label: b.name),
                      ),
                    ],
                    onChanged: (v) => vm.setSelectedBranch(
                        v == null || v == 'all' ? null : v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown<String>(
                    label: l10n.lockerLabelCashier,
                    value: vm.selectedCashierId ?? 'all',
                    isLoading: vm.cashiersLoading,
                    hint: l10n.lockerAllCashiers,
                    options: [
                      OwnerDropdownOption(
                          value: 'all', label: l10n.lockerAllCashiers),
                      ...vm.cashiers.map(
                        (c) => OwnerDropdownOption(
                          value: c.userId,
                          label: c.name.isNotEmpty ? c.name : c.email,
                        ),
                      ),
                    ],
                    onChanged: (v) => vm.setSelectedCashier(
                        v == null || v == 'all' ? null : v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Toolbar row ───────────────────────────────────────────────────────────

  Widget _buildToolbar(BuildContext context, LockerDifferencesReportViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.lockerVarianceRecords,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        if (vm.isSuccess)
          Text(
            l10n.lockerRecordsOfTotal(
              '${vm.visibleItems.length}',
              '${vm.totalCount}',
            ),
            style: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ── Filter sub-widgets ────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final bool isLoading;
  final String hint;
  final List<OwnerDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 5),
        if (isLoading)
          const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Colors.black26),
              ),
            ),
          )
        else
          OwnerStyledDropdown<T>(
            value: value,
            options: options,
            onChanged: onChanged,
            hint: hint,
            height: 40,
            backgroundColor: Colors.white,
            borderColor: OwnerListStyle.cardBorder,
            triggerStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight,
            ),
          ),
      ],
    );
  }
}

// ── Type filter (owner-style segmented tabs) ──────────────────────────────────

class _TypeFilterChips extends StatelessWidget {
  final LockerDifferencesReportViewModel vm;
  const _TypeFilterChips({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final filters = [
      (DifferencesTypeFilter.all, l10n.lockerChipAll, vm.totalCount),
      (DifferencesTypeFilter.short, l10n.lockerChipShort, vm.shortCount),
      (DifferencesTypeFilter.over, l10n.lockerChipOver, vm.overCount),
      (DifferencesTypeFilter.pending, l10n.lockerChipPending, vm.pendingCount),
    ];

    return PosSegmentedListTabs(
      tabs: [
        for (final (filter, label, count) in filters)
          PosSegmentedTab(
            id: filter.name,
            label: label,
            count: count,
          ),
      ],
      selectedId: vm.typeFilter.name,
      onSelected: (id) {
        final next = DifferencesTypeFilter.values.firstWhere(
          (f) => f.name == id,
          orElse: () => DifferencesTypeFilter.all,
        );
        vm.setTypeFilter(next);
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
    );
  }
}

// ── Variance card ─────────────────────────────────────────────────────────────

class _VarianceCard extends StatelessWidget {
  final DifferenceVarianceEntry entry;
  const _VarianceCard({required this.entry});

  Color get _typeColor {
    if (entry.isShort) return Colors.red.shade400;
    if (entry.isOver) return Colors.green.shade500;
    return Colors.orange;
  }

  String _typeLabel(AppLocalizations l10n) {
    if (entry.isShort) return l10n.lockerChipShort;
    if (entry.isOver) return l10n.lockerChipOver;
    return l10n.lockerChipPending;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final color = _typeColor;
    final diff = entry.difference;
    final diffColor = diff == 0
        ? Colors.teal
        : (diff > 0 ? Colors.green.shade500 : Colors.red.shade400);
    final diffSign = diff > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: OwnerListStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwnerListIconBox(icon: Icons.compare_arrows_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.referenceCode.isNotEmpty
                          ? entry.referenceCode
                          : 'REF-${entry.id}',
                      style: OwnerListStyle.titleStyle,
                    ),
                    if (entry.isPending) ...[
                      const SizedBox(height: 3),
                      _StatusPill(
                          label: l10n.lockerPendingApproval, color: Colors.orange),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TypeBadge(label: _typeLabel(l10n), color: color),
            ],
          ),

          Divider(height: 22, color: OwnerListStyle.cardBorder),

          // Branch + cashier
          Row(
            children: [
              Expanded(
                child: _MetaItem(
                    icon: Icons.location_on_outlined,
                    value: entry.branchName),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetaItem(
                    icon: Icons.point_of_sale_rounded,
                    value: entry.cashierName),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date row (officer removed per spec)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd MMM, yy', locale).format(entry.date),
                    style: OwnerListStyle.titleStyle.copyWith(fontSize: 11),
                  ),
                  Text(
                    DateFormat('hh:mm a', locale).format(entry.date),
                    style: OwnerListStyle.metaStyle.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Amount row
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: OwnerUi.contentBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatCol(
                    label: l10n.lockerAmountLabel(l10n.lockerSarCurrency),
                    value: '${l10n.lockerSarCurrency} ${_money(entry.amount)}',
                  ),
                ),
                Container(
                    width: 1,
                    height: 32,
                    color: OwnerListStyle.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCol(
                    label: l10n.lockerLabelReceived,
                    value: '${l10n.lockerSarCurrency} ${_money(entry.receivedAmount)}',
                  ),
                ),
                Container(
                    width: 1,
                    height: 32,
                    color: OwnerListStyle.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.lockerLabelDifference,
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.25),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$diffSign ${l10n.lockerSarCurrency} ${_money(diff.abs())}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: diffColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 8,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
        TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MetaItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: OwnerListStyle.mutedText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OwnerListStyle.metaStyle.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.black.withOpacity(0.25),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight),
        ),
      ],
    );
  }
}

// ── Error / empty states ──────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
              BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  size: 32, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.lockerFailedToLoad,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.lockerRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String message;
  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: OwnerListStyle.cardDecoration,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded,
                size: 28, color: OwnerListStyle.mutedText.withOpacity(0.5)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: OwnerListStyle.subtitleStyle),
          ],
        ),
      ),
    );
  }
}