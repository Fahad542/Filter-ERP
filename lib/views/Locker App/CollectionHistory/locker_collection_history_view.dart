import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../data/repositories/locker_repository.dart'
    show CollectionHistoryEntry;
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_collection_history_view_model.dart';

// ── Shared formatting helper ────────────────────────────────────────────────

String _money(double v) => NumberFormat('#,##0.00').format(v);

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerCollectionHistoryView extends StatelessWidget {
  /// Whether the signed-in user is a supervisor or collector — controls
  /// which sidebar item set [LockerShell] shows. Defaults to true since
  /// this screen is most commonly reached from the supervisor's sidebar.
  final bool isSupervisor;

  const LockerCollectionHistoryView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerCollectionHistoryViewModel(),
      child: _CollectionHistoryBody(isSupervisor: isSupervisor),
    );
  }
}

class _CollectionHistoryBody extends StatefulWidget {
  final bool isSupervisor;

  const _CollectionHistoryBody({required this.isSupervisor});

  @override
  State<_CollectionHistoryBody> createState() => _CollectionHistoryBodyState();
}

class _CollectionHistoryBodyState extends State<_CollectionHistoryBody> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      context.read<LockerCollectionHistoryViewModel>().init(l10n);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<LockerCollectionHistoryViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LockerCollectionHistoryViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final defaultFrom = DateTime(now.year, now.month, now.day);
    final defaultTo = now;

    return LockerShell(
      isSupervisor: widget.isSupervisor,
      currentItem: LockerSidebarItem.collectionHistory,
      title: l10n.lockerTitleCollectionsHistory,
      backgroundColor: OwnerUi.scaffoldBackground,
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

  Widget _buildBody(BuildContext context, LockerCollectionHistoryViewModel vm) {
    final l10n = AppLocalizations.of(context)!;

    if (vm.isLoading && vm.items.isEmpty) {
      return const OwnerListPageShimmer(
        showKpi: true,
        kpiCount: 3,
        itemCount: 4,
        padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
      );
    }
    if (vm.isError && vm.items.isEmpty) {
      return _ErrorState(
        message: vm.error ?? l10n.lockerAnErrorOccurred,
        onRetry: vm.refresh,
      );
    }

    final items = vm.visibleItems;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _buildKpiGrid(context, vm),
          // Pull filters up into KPI grid leftover whitespace — KPI size unchanged.
          Transform.translate(
            offset: const Offset(0, -12),
            child: _buildFilterPanel(context, vm),
          ),
          _buildToolbarRow(context, vm),
          const SizedBox(height: 8),
          if (items.isEmpty)
            _EmptyInline(
              message: vm.hasActiveFilters
                  ? l10n.lockerNoResultsMatchFilters
                  : l10n.lockerNoAuditLogsFound,
            )
          else
            ...List.generate(items.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CollectionHistoryCard(entry: items[i]),
              );
            }),
          if (vm.isLoadingMore) const OwnerPaginationShimmer(),
        ],
      ),
    );
  }

  // ── KPI Grid ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(BuildContext context, LockerCollectionHistoryViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final summary = vm.summary;
    final cur = summary.currency.trim().toUpperCase() == 'SAR'
        ? l10n.lockerSarCurrency
        : summary.currency;

    final metrics = [
      ReusableKpiMetric(
        title: l10n.lockerKpiTotalExpected,
        value: '$cur ${_money(summary.totalExpected)}',
        subtitle: vm.totalItems == 1
            ? l10n.lockerOneCollection
            : l10n.lockerNCollections(vm.totalItems),
        icon: Icons.account_balance_wallet_outlined,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiTotalReceived,
        value: '$cur ${_money(summary.totalReceived)}',
        subtitle: l10n.lockerCashCollected,
        icon: Icons.payments_outlined,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiNetDifference,
        value: '${summary.totalDifference >= 0 ? "+" : ""}$cur ${_money(summary.totalDifference)}',
        subtitle: l10n.lockerOverMinusShort,
        icon: Icons.compare_arrows_rounded,
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
      BuildContext context, LockerCollectionHistoryViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
                      _searchController.clear();
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
                    hint: l10n.lockerFilterAll,
                    options: [
                      OwnerDropdownOption(value: 'all', label: l10n.lockerFilterAll),
                      ...vm.branches.map(
                        (b) => OwnerDropdownOption(value: b.id, label: b.name),
                      ),
                    ],
                    onChanged: (v) =>
                        vm.setSelectedBranch(v == null || v == 'all' ? null : v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterDropdown<String>(
                    label: l10n.lockerLabelCashier,
                    value: vm.selectedCashierId ?? 'all',
                    isLoading: vm.cashiersLoading,
                    hint: l10n.lockerFilterAll,
                    options: [
                      OwnerDropdownOption(value: 'all', label: l10n.lockerFilterAll),
                      ...vm.cashiers.map(
                        (c) => OwnerDropdownOption(value: c.userId, label: c.name),
                      ),
                    ],
                    onChanged: (v) =>
                        vm.setSelectedCashier(v == null || v == 'all' ? null : v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarRow(
      BuildContext context, LockerCollectionHistoryViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.lockerAuditLogs,
          style: TextStyle(
              color: Colors.black.withOpacity(0.3),
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 1.5),
        ),
        Row(
          children: [
            if (vm.isSuccess)
              Text(
                l10n.lockerRecordsCount(vm.totalItems),
                style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            const SizedBox(width: 10),
            _HistorySortButton(vm: vm),
          ],
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

// ── Sort button ───────────────────────────────────────────────────────────────

class _HistorySortButton extends StatelessWidget {
  final LockerCollectionHistoryViewModel vm;
  const _HistorySortButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSortSheet(context),
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: const Icon(Icons.sort_rounded,
            color: AppColors.secondaryLight, size: 16),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const _HistorySortSheet(),
      ),
    );
  }
}

class _SortOption {
  final CollectionHistorySortField field;
  final String label;
  const _SortOption(this.field, this.label);
}

class _HistorySortSheet extends StatelessWidget {
  const _HistorySortSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<LockerCollectionHistoryViewModel>();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.lockerSortBy,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 2,
              )),
          const SizedBox(height: 16),
          ..._sortOptions(context, vm, l10n),
        ],
      ),
    );
  }

  List<Widget> _sortOptions(BuildContext context,
      LockerCollectionHistoryViewModel vm, AppLocalizations l10n) {
    final options = <_SortOption>[
      _SortOption(CollectionHistorySortField.date, l10n.lockerSortDate),
      _SortOption(CollectionHistorySortField.expected, l10n.lockerSortExpectedAmount),
      _SortOption(CollectionHistorySortField.received, l10n.lockerSortReceivedAmount),
      _SortOption(CollectionHistorySortField.difference, l10n.lockerSortDifference),
    ];
    return options.map((opt) {
      final isActive = vm.sortField == opt.field;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isActive
              ? (vm.sortOrder == CollectionHistorySortOrder.asc
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded)
              : Icons.swap_vert_rounded,
          color: isActive ? AppColors.secondaryLight : Colors.black26,
          size: 20,
        ),
        title: Text(opt.label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: isActive ? AppColors.secondaryLight : Colors.black54,
              fontSize: 13,
            )),
        trailing: isActive
            ? Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            vm.sortOrder == CollectionHistorySortOrder.asc
                ? l10n.lockerSortAsc
                : l10n.lockerSortDesc,
            style: const TextStyle(
                color: AppColors.secondaryLight,
                fontSize: 9,
                fontWeight: FontWeight.w900),
          ),
        )
            : null,
        onTap: () {
          vm.toggleSort(opt.field);
          Navigator.pop(context);
        },
      );
    }).toList();
  }
}

// ── List card ────────────────────────────────────────────────────────────────

class _CollectionHistoryCard extends StatelessWidget {
  final CollectionHistoryEntry entry;
  const _CollectionHistoryCard({required this.entry});

  Color _statusColor(String status) {
    switch (status) {
      case 'MATCHED':
        return Colors.teal;
      case 'OVER':
        return Colors.green;
      case 'SHORT':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final color = _statusColor(entry.matchStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: OwnerListStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwnerListIconBox(icon: Icons.receipt_long_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.referenceCode.isNotEmpty
                          ? entry.referenceCode
                          : entry.transactionRef,
                      style: OwnerListStyle.titleStyle,
                    ),
                    if (entry.transactionRef.isNotEmpty)
                      Text(entry.transactionRef,
                          style: OwnerListStyle.subtitleStyle.copyWith(
                              fontSize: 9, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MatchStatusBadge(status: entry.matchStatus, color: color),
            ],
          ),
          Divider(height: 22, color: OwnerListStyle.cardBorder),
          Row(
            children: [
              Expanded(
                child: _HistoryMetaItem(
                    icon: Icons.location_on_outlined,
                    value: entry.branchName),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryMetaItem(
                    icon: Icons.point_of_sale_rounded,
                    value: entry.cashierName),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HistoryMetaItem(
                    icon: Icons.person_outline_rounded,
                    value: entry.officerName),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormat('dd MMM, yy', locale).format(entry.collectedAt),
                      style: OwnerListStyle.titleStyle.copyWith(fontSize: 11)),
                  Text(DateFormat('hh:mm a', locale).format(entry.collectedAt),
                      style: OwnerListStyle.metaStyle.copyWith(fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: OwnerUi.contentBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                      label: l10n.lockerLabelExpected,
                      value:
                      '${entry.currency} ${_money(entry.expectedAmount)}'),
                ),
                Container(
                    width: 1,
                    height: 28,
                    color: OwnerListStyle.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatColumn(
                      label: l10n.lockerLabelReceived,
                      value:
                      '${entry.currency} ${_money(entry.receivedAmount)}'),
                ),
                Container(
                    width: 1,
                    height: 28,
                    color: OwnerListStyle.cardBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: _DifferenceColumn(
                      difference: entry.difference,
                      currency: entry.currency),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchStatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _MatchStatusBadge({required this.status, required this.color});

  String _label(AppLocalizations l10n) {
    switch (status) {
      case 'MATCHED':
        return l10n.lockerStatusMatched;
      case 'SHORT':
        return l10n.lockerShortLabel;
      case 'OVER':
        return l10n.lockerOverLabel;
      case 'PENDING_APPROVAL':
        return l10n.lockerStatusPending;
      default:
        return l10n.lockerStatusUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_label(l10n),
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 0.5)),
    );
  }
}

class _HistoryMetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  const _HistoryMetaItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = value.trim();
    final style = OwnerListStyle.metaStyle.copyWith(fontSize: 10);
    return Row(
      children: [
        Icon(icon, size: 12, color: OwnerListStyle.mutedText),
        const SizedBox(width: 4),
        Expanded(
          child: display.isEmpty
              ? Text('—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style)
              : LocalizedApiText(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight)),
      ],
    );
  }
}

class _DifferenceColumn extends StatelessWidget {
  final double difference;
  final String currency;
  const _DifferenceColumn({required this.difference, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isZero = difference == 0;
    final isPositive = difference > 0;
    final color =
    isZero ? Colors.teal : (isPositive ? Colors.green : Colors.red);
    final sign = isPositive ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.lockerLabelDifference,
            style: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text('$sign$currency ${_money(difference)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

// ── Error / empty states ─────────────────────────────────────────────────────

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
              child:
              Icon(Icons.wifi_off_rounded, size: 32, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(l10n.lockerFailedToLoad,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight)),
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
      padding: const EdgeInsets.all(20),
      decoration: OwnerListStyle.cardDecoration,
      child: Center(
        child: Text(message,
            style: OwnerListStyle.subtitleStyle),
      ),
    );
  }
}