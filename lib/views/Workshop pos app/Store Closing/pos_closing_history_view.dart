import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/cashier_closing_history_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../utils/pos_tablet_layout.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_filter_tab_dropdown.dart';
import 'closing_history_view_model.dart';

class PosClosingHistoryView extends StatefulWidget {
  const PosClosingHistoryView({super.key});

  @override
  State<PosClosingHistoryView> createState() => _PosClosingHistoryViewState();
}

class _PosClosingHistoryViewState extends State<PosClosingHistoryView> {
  final _scrollController = ScrollController();
  DateFormat? _sessionFmt;
  Locale? _sessionLocale;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<ClosingHistoryViewModel>();
      // Locale switches can remount this view; skip if data is already cached.
      if (vm.hasRawItems || vm.loading) return;
      vm.load(refresh: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_sessionLocale == locale && _sessionFmt != null) return;
    _sessionLocale = locale;
    _sessionFmt = DateFormat(
      'dd MMM yyyy · hh:mm a',
      locale.languageCode == 'ar' ? 'ar' : 'en',
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildDateFilter(
    BuildContext context,
    ClosingHistoryViewModel vm,
    AppLocalizations l10n,
  ) {
    String label(DateTime? d, String empty) {
      if (d == null) return empty;
      return DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString())
          .format(d);
    }

    Future<void> pick({required bool isFrom}) async {
      final initial = (isFrom ? vm.fromDate : vm.toDate) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked == null) return;
      if (isFrom) {
        await vm.setFromDate(picked);
      } else {
        await vm.setToDate(picked);
      }
    }

    Widget chip({
      required String title,
      required String value,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: PosFilterTabDropdown.dateChipHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2124),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          title: l10n.posClosingHistoryFrom,
          value: label(vm.fromDate, '—'),
          onTap: () => pick(isFrom: true),
        ),
        const SizedBox(width: 8),
        chip(
          title: l10n.posClosingHistoryTo,
          value: label(vm.toDate, '—'),
          onTap: () => pick(isFrom: false),
        ),
        const SizedBox(width: 8),
        PosFilterTabDropdown(
          selectedId: switch (vm.filter) {
            ClosingHistoryFilter.all => 'all',
            ClosingHistoryFilter.balanced => 'balanced',
            ClosingHistoryFilter.short => 'short',
          },
          options: [
            PosFilterTabOption(
              id: 'all',
              label: l10n.posClosingHistoryTabAll,
              count: vm.allCount,
            ),
            PosFilterTabOption(
              id: 'balanced',
              label: l10n.posClosingHistoryTabBalanced,
              count: vm.balancedCount,
            ),
            PosFilterTabOption(
              id: 'short',
              label: l10n.posClosingHistoryTabShort,
              count: vm.shortCount,
            ),
          ],
          onSelected: (id) {
            vm.setFilter(switch (id) {
              'balanced' => ClosingHistoryFilter.balanced,
              'short' => ClosingHistoryFilter.short,
              _ => ClosingHistoryFilter.all,
            });
          },
        ),
      ],
    );
  }

  Widget _buildTotalCommissionBar(
    BuildContext context,
    ClosingHistoryViewModel vm,
    AppLocalizations l10n,
  ) {
    Widget stat({
      required IconData icon,
      required String label,
      required double amount,
    }) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SAR ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: stat(
                  icon: Icons.point_of_sale_rounded,
                  label: l10n.posClosingHistoryTotalSales,
                  amount: vm.totalSales,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: stat(
                  icon: Icons.payments_outlined,
                  label: l10n.posClosingHistoryTotalCommission,
                  amount: vm.totalCommission,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final vm = context.read<ClosingHistoryViewModel>();
    if (vm.loading || !vm.hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      vm.loadMore();
    }
  }

  String _fmtSession(DateTime? dt) {
    if (dt == null) return '—';
    return (_sessionFmt ?? DateFormat('dd MMM yyyy · hh:mm a')).format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<ClosingHistoryViewModel>();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: PosScreenAppBar(
          title: l10n.posNavClosingHistory,
          showBackButton: false,
          showHamburger: true,
          onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
        ),
        body: wrapPosShellRailBody(
          context,
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildDateFilter(context, vm, l10n),
              ),
              Expanded(child: _buildBody(context, vm, l10n)),
              _buildTotalCommissionBar(context, vm, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClosingHistoryViewModel vm,
    AppLocalizations l10n,
  ) {
    final visible = vm.items;

    if (vm.showInitialShimmer) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          mainAxisExtent: 268,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const _ClosingHistoryShimmerCard(),
      );
    }

    if (vm.error != null && !vm.hasRawItems) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => vm.load(refresh: true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                ),
                child: Text(l10n.posClosingHistoryRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (visible.isEmpty) {
      return Center(
        child: Text(
          l10n.posClosingHistoryEmpty,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    const cols = 3;
    const spacing = 16.0;
    final extra =
        vm.filter == ClosingHistoryFilter.all && vm.loadingMore ? 1 : 0;
    final totalItems = visible.length + extra;
    final rowCount = (totalItems / cols).ceil();

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        cacheExtent: 320,
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final start = rowIndex * cols;
          final isLast = rowIndex == rowCount - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < cols; col++) ...[
                    if (col > 0) const SizedBox(width: spacing),
                    Expanded(
                      child: start + col >= totalItems
                          ? const SizedBox.shrink()
                          : start + col >= visible.length
                              ? const _ClosingHistoryShimmerCard()
                              : RepaintBoundary(
                                  child: _ClosingHistoryCard(
                                    item: visible[start + col],
                                    formatSession: _fmtSession,
                                    l10n: l10n,
                                  ),
                                ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClosingHistoryShimmerCard extends StatelessWidget {
  const _ClosingHistoryShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PosShimmerBox(width: 36, height: 36, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosShimmerBox(width: 104, height: 12, radius: 6),
                      SizedBox(height: 8),
                      PosShimmerBox(width: 72, height: 10, radius: 5),
                    ],
                  ),
                ),
                PosShimmerBox(width: 52, height: 22, radius: 8),
              ],
            ),
            SizedBox(height: 16),
            PosShimmerBox(width: 148, height: 10, radius: 5),
            SizedBox(height: 8),
            PosShimmerBox(width: 128, height: 10, radius: 5),
            SizedBox(height: 16),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
            SizedBox(height: 12),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
            SizedBox(height: 12),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
            SizedBox(height: 12),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
            SizedBox(height: 16),
            PosShimmerBox(width: 160, height: 12, radius: 6),
          ],
        ),
      ),
    );
  }
}

/// Matches Workshop Owner POS Monitoring closing-report card layout.
class _ClosingHistoryCard extends StatelessWidget {
  const _ClosingHistoryCard({
    required this.item,
    required this.formatSession,
    required this.l10n,
  });

  final CashierClosingHistoryItem item;
  final String Function(DateTime?) formatSession;
  final AppLocalizations l10n;

  /// Owner UI: diff = system − physical (positive = SHORT).
  double _sysMinusPhys(double system, double physical) => system - physical;

  @override
  Widget build(BuildContext context) {
    final netDiff = item.reconciliationTotalDifference;
    final isShort = netDiff > 0.01;
    final isExcess = netDiff < -0.01;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final diffColor = isShort
        ? Colors.red
        : isExcess
            ? const Color(0xFFE65100)
            : Colors.green;
    final diffLabel = isShort
        ? (isAr ? 'عجز' : 'Short')
        : (isExcess ? (isAr ? 'زيادة' : 'Over') : (isAr ? 'متوازن' : 'Balanced'));

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.secondaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cashierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 13,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    Text(
                      item.branchName?.isNotEmpty == true
                          ? item.branchName!
                          : l10n.posClosingHistoryBranchFallback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  diffLabel,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.posClosingHistoryFrom}: ',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: formatSession(item.openedAt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2124),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.posClosingHistoryTo}: ',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: formatSession(item.closedAt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2124),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.ownerPosMonitoringCategory,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        _tableHeader(l10n.ownerPosMonitoringSystem),
                        _tableHeader(l10n.ownerPosMonitoringPhysical),
                        _tableHeader(l10n.ownerPosMonitoringDiff, narrow: true),
                      ],
                    ),
                    Divider(
                      height: 10,
                      color: Colors.grey.shade300,
                    ),
                    _reconcRow(
                      l10n.ownerPosMonitoringCash,
                      item.systemCash,
                      item.physicalCash,
                    ),
                    _reconcRow(
                      l10n.ownerPosMonitoringBankCards,
                      item.systemBank,
                      item.physicalBank,
                    ),
                    _reconcRow(
                      l10n.ownerPosMonitoringCorporate,
                      item.systemCorporate,
                      item.physicalCorporate,
                    ),
                    _reconcRow(
                      l10n.ownerPosMonitoringTamara,
                      item.systemTamara,
                      item.physicalTamara,
                    ),
                    _reconcRow(
                      l10n.ownerPosMonitoringTabby,
                      item.systemTabby,
                      item.physicalTabby,
                    ),
                    _othersRow(
                      l10n.ownerPosMonitoringOthersEmployees,
                      item.systemOthers,
                      item.physicalOthers,
                    ),
                    Divider(
                      height: 10,
                      color: Colors.grey.shade300,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.ownerPosMonitoringTotalSales,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2124),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            'SAR ${item.systemTotalSales.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2124),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            'SAR ${item.physicalTotal.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            isShort
                                ? '−${netDiff.abs().toStringAsFixed(0)}'
                                : (isExcess
                                    ? '+${netDiff.abs().toStringAsFixed(0)}'
                                    : '—'),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: diffColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          if (item.departmentBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildDepartmentSalesTable(l10n, item),
          ],
          if (item.returnItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildReturnItemsTable(l10n, item),
          ],
          const Spacer(),
          if (item.commissionAmount > 0.001 || item.commissionPercent > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFA5D6A7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF2E7D32),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.posClosingHistoryCommission,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  Text(
                    'SAR ${item.commissionAmount.toStringAsFixed(2)}  (${item.commissionPercent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentSalesTable(
    AppLocalizations l10n,
    CashierClosingHistoryItem item,
  ) {
    final totalOrders =
        item.departmentBreakdown.fold<int>(0, (s, r) => s + r.ordersCount);
    final totalRevenue =
        item.departmentBreakdown.fold<double>(0, (s, r) => s + r.revenueSar);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _tableTitle(l10n.posStoreClosingDepartmentCol)),
              _tableHeader(l10n.posStoreClosingOrdersCol, width: 48),
              _tableHeader(l10n.posStoreClosingRevenueCol, width: 80),
            ],
          ),
          Divider(height: 10, color: Colors.grey.shade300),
          ...item.departmentBreakdown.map(
            (row) => _threeColRow(
              row.departmentName,
              '${row.ordersCount}',
              'SAR ${row.revenueSar.toStringAsFixed(2)}',
              midWidth: 48,
              valueWidth: 80,
            ),
          ),
          Divider(height: 10, color: Colors.grey.shade300),
          _threeColRow(
            l10n.ownerPosMonitoringTotalSales,
            '$totalOrders',
            'SAR ${totalRevenue.toStringAsFixed(2)}',
            emphasize: true,
            midWidth: 48,
            valueWidth: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItemsTable(
    AppLocalizations l10n,
    CashierClosingHistoryItem item,
  ) {
    final total = item.returnItems.fold<double>(0, (s, r) => s + r.amountSar);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _tableTitle(l10n.posReceiptItem)),
              _tableHeader(l10n.posCommonQty, width: 44),
              _tableHeader(l10n.posReviewAmountSarCol, width: 80),
            ],
          ),
          Divider(height: 10, color: Colors.grey.shade300),
          ...item.returnItems.map(
            (row) => _threeColRow(
              row.name,
              row.qty % 1 == 0
                  ? row.qty.toStringAsFixed(0)
                  : row.qty.toStringAsFixed(2),
              '− SAR ${row.amountSar.toStringAsFixed(2)}',
              valueColor: const Color(0xFFB91C1C),
              midWidth: 44,
              valueWidth: 80,
            ),
          ),
          Divider(height: 10, color: Colors.grey.shade300),
          _threeColRow(
            l10n.posStoreClosingLessSalesReturn,
            '',
            '− SAR ${total.toStringAsFixed(2)}',
            emphasize: true,
            valueColor: const Color(0xFFB91C1C),
            midWidth: 44,
            valueWidth: 80,
          ),
        ],
      ),
    );
  }

  Widget _tableTitle(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _threeColRow(
    String label,
    String mid,
    String value, {
    bool emphasize = false,
    Color? valueColor,
    double midWidth = 48,
    double valueWidth = 80,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                color: const Color(0xFF1E2124),
              ),
            ),
          ),
          SizedBox(
            width: midWidth,
            child: Text(
              mid,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? const Color(0xFF1E2124) : const Color(0xFF5A5E66),
              ),
            ),
          ),
          SizedBox(
            width: valueWidth,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: valueColor ?? const Color(0xFF1E2124),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _othersRow(String label, double system, double physical) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _reconcRow(label, system, physical),
    );
  }

  Widget _tableHeader(String label, {bool narrow = false, double? width}) {
    return SizedBox(
      width: width ?? (narrow ? 44 : 52),
      child: Text(
        label,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _reconcRow(String label, double system, double physical) {
    final diff = _sysMinusPhys(system, physical);
    final diffColor =
        diff.abs() < 0.01 ? const Color(0xFF2E7D32) : (diff > 0 ? Colors.red : const Color(0xFF2E7D32));
    final diffStr =
        diff.abs() < 0.01 ? '—' : '${diff > 0 ? "−" : "+"}${diff.abs().toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF1E2124),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              system.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF5A5E66),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              physical.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              diffStr,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: diffColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
