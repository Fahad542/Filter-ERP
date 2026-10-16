import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_global_date_filters.dart';
import 'pos_monitoring_view_model.dart';

class PosMonitoringView extends StatefulWidget {
  const PosMonitoringView({super.key});

  @override
  State<PosMonitoringView> createState() => _PosMonitoringViewState();
}

class _PosMonitoringViewState extends State<PosMonitoringView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<PosCounter> _liveCounters = [
    PosCounter(id: '1', cashierName: 'Ali Hassan', branchName: 'Riyadh Main', status: 'open', shiftSales: 4250, openOrders: 3, openedAt: DateTime.now().subtract(const Duration(hours: 4))),
    PosCounter(id: '2', cashierName: 'Omar Saeed', branchName: 'Jeddah Center', status: 'open', shiftSales: 2100, openOrders: 1, openedAt: DateTime.now().subtract(const Duration(hours: 2))),
    PosCounter(id: '3', cashierName: 'Sami Khalid', branchName: 'Riyadh Main', status: 'closing', shiftSales: 6800, openOrders: 0, openedAt: DateTime.now().subtract(const Duration(hours: 8))),
  ];

  final List<PosCounter> _closingReports = [
    PosCounter(
      id: '4',
      cashierName: 'Rami Yousef',
      branchName: 'Dammam Branch',
      status: 'closed',
      shiftSales: 5200,
      openOrders: 0,
      openedAt: DateTime.now().subtract(const Duration(hours: 10)),
      closedAt: DateTime.now().subtract(const Duration(hours: 1)),
      systemTotalSales: 5200,
      physicalCash: 5150,
      schemaVersion: 6,
      systemOthers: 150,
      physicalOthers: 150,
    ),
    PosCounter(
      id: '5',
      cashierName: 'Tariq Nasser',
      branchName: 'Jeddah Center',
      status: 'closed',
      shiftSales: 3100,
      openOrders: 0,
      openedAt: DateTime.now().subtract(const Duration(hours: 11)),
      closedAt: DateTime.now().subtract(const Duration(hours: 2)),
      systemTotalSales: 3100,
      physicalCash: 3100,
      schemaVersion: 6,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = Provider.of<PosMonitoringViewModel>(context, listen: false);
        vm.fetchPosMonitoring();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PosMonitoringViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: l10n.ownerPosMonitoringTitle,
        showDrawer: true,
        bottomOverlap: const OwnerGlobalDateOverlapFilters(),
      ),
      body: vm.isLoading
          ? const OwnerListPageShimmer(
              showKpi: true,
              showTabs: true,
              showSearch: false,
            )
          : Column(
              children: [
                _buildSummaryBar(vm, l10n),
                const SizedBox(height: 6),
                _buildTabBar(l10n),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLiveCounters(vm, l10n),
                      _buildClosingReports(vm, l10n),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBar(PosMonitoringViewModel vm, AppLocalizations l10n) {
    final liveRaw = vm.monitoringResponse?.liveCounters ?? _liveCounters;
    final closingRaw = vm.monitoringResponse?.closingReports ?? _closingReports;
    final liveFiltered = vm.filterLiveCounters(liveRaw);
    final closingFiltered = vm.filterClosingReports(closingRaw);

    final int activeCounters = liveFiltered.length;

    final int openOrders =
        liveFiltered.fold<int>(0, (s, c) => s + c.openOrders);

    final rangeSalesApi = vm.monitoringResponse?.salesInDateRange;
    final double totalSalesShown = rangeSalesApi ??
        [...liveFiltered, ...closingFiltered]
            .fold<double>(0.0, (s, c) => s + c.shiftSales);

    return ReusableKpiGrid(
      layout: KpiGridLayout.singleRow,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      showFeatured: false,
      iconOnTop: true,
      mainAxisExtent: 108,
      singleRowCardWidth: 112,
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerPosMonitoringKpiSalesInRange,
          value: formatKpiAmount(totalSalesShown),
          icon: Icons.payments_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.ownerPosMonitoringKpiLiveCounters,
          value: '$activeCounters',
          icon: Icons.point_of_sale_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.ownerPosMonitoringKpiOpenOrders,
          value: '$openOrders',
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return OwnerSegmentedTabs(
      controller: _tabController,
      tabs: [l10n.ownerPosMonitoringTabLive, l10n.ownerPosMonitoringTabClosing],
      layout: PosSegmentedTabLayout.expanded,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    );
  }

  Widget _buildLiveCounters(PosMonitoringViewModel vm, AppLocalizations l10n) {
    final counters =
    vm.filterLiveCounters(vm.monitoringResponse?.liveCounters ?? _liveCounters);

    if (counters.isEmpty) {
      return Center(
        child: Text(l10n.ownerPosMonitoringEmptyLive, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: counters.length,
      itemBuilder: (context, index) => _buildLiveCounterCard(counters[index], l10n),
    );
  }

  Widget _buildLiveCounterCard(PosCounter counter, AppLocalizations l10n) {
    final isOpen = counter.status == 'open';
    final isClosing = counter.status == 'closing';
    final color = isOpen ? Colors.green : isClosing ? Colors.orange : Colors.grey;

    final elapsed = DateTime.now().difference(counter.sessionStart);
    final hours = elapsed.inHours;
    final mins = elapsed.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(counter.displayCashierName, style: AppTextStyles.h2.copyWith(fontSize: 15, color: AppColors.secondaryLight)),
                    const SizedBox(height: 2),
                    Text(counter.displayBranchName, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(counter.status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 20, thickness: 1, color: Colors.grey.withOpacity(0.15)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.play_circle_outline_rounded, size: 17, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: l10n.ownerPosMonitoringStart,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey),
                            ),
                            TextSpan(
                              text: _fmtSession(counter.sessionStart),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2124)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.stop_circle_outlined,
                      size: 17,
                      color: counter.sessionEnd != null ? Colors.grey.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: l10n.ownerPosMonitoringEnd,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey),
                            ),
                            TextSpan(
                              text: counter.sessionEnd != null
                                  ? _fmtSession(counter.sessionEnd!)
                                  : l10n.ownerPosMonitoringStillOpen,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: counter.sessionEnd != null ? const Color(0xFF1E2124) : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounterStat(l10n.ownerPosMonitoringStatShiftSales, 'SAR ${counter.shiftSales.toInt()}', AppColors.primaryLight),
              _buildCounterStat(l10n.ownerPosMonitoringStatOpenOrders, '${counter.openOrders}', Colors.orange),
              _buildCounterStat(l10n.ownerPosMonitoringStatElapsed, '${hours}h ${mins}m', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtSession(DateTime d) =>
      DateFormat('dd/MM/yyyy hh:mm a').format(d.toLocal());

  Widget _buildCounterStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildClosingReports(PosMonitoringViewModel vm, AppLocalizations l10n) {
    final reports = vm.filterClosingReports(
        vm.monitoringResponse?.closingReports ?? _closingReports);

    if (reports.isEmpty) {
      return Center(
        child: Text(l10n.ownerPosMonitoringEmptyClosing, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      itemBuilder: (context, index) => _buildClosingCard(reports[index], l10n),
    );
  }

  Widget _buildClosingCard(PosCounter counter, AppLocalizations l10n) {
    final netDiff = counter.effectiveDiff;
    final isShort = netDiff > 0.01;
    final isExcess = netDiff < -0.01;
    final hasDiff = isShort || isExcess;
    final diffColor = hasDiff ? (isShort ? Colors.red : Colors.green) : Colors.green;
    final diffLabel = isShort
        ? l10n.ownerPosMonitoringShort
        : (isExcess ? l10n.ownerPosMonitoringExcess : l10n.ownerPosMonitoringBalanced);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasDiff ? Colors.red.withOpacity(0.18) : Colors.grey.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.grey, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(counter.displayCashierName, style: AppTextStyles.h2.copyWith(fontSize: 15, color: AppColors.secondaryLight)),
                    Text(counter.displayBranchName, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l10n.ownerPosMonitoringStarted, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                          TextSpan(
                            text: _fmtSession(counter.sessionStart),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2124)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l10n.ownerPosMonitoringEnded, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                          TextSpan(
                            text: counter.sessionEnd != null
                                ? _fmtSession(counter.sessionEnd!)
                                : '—',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2124)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: diffColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  diffLabel,
                  style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Reconciliation table ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: OwnerUi.scaffoldBackground, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Table header
                Row(
                  children: [
                    Expanded(child: Text(l10n.ownerPosMonitoringCategory, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey))),
                    _tableHeader(l10n.ownerPosMonitoringSystem, narrow: false),
                    _tableHeader(l10n.ownerPosMonitoringPhysical, narrow: false),
                    _tableHeader(l10n.ownerPosMonitoringDiff, narrow: true),
                  ],
                ),
                const Divider(height: 12),
                _reconcRow(l10n.ownerPosMonitoringCash,      counter.systemCash,      counter.physicalCash,      counter.diffCash),
                _reconcRow(l10n.ownerPosMonitoringBankCards, counter.systemBank,     counter.physicalBank,      counter.diffBank),
                _reconcRow(l10n.ownerPosMonitoringCorporate, counter.systemCorporate, counter.physicalCorporate, counter.diffCorporate),
                _reconcRow(l10n.ownerPosMonitoringTamara,    counter.systemTamara,    counter.physicalTamara,    counter.diffTamara),
                _reconcRow(l10n.ownerPosMonitoringTabby,     counter.systemTabby,     counter.physicalTabby,     counter.diffTabby),
                _reconcRowOthersEmployees(counter, l10n),
                const Divider(height: 12),
                // Total sales row
                Row(
                  children: [
                    Expanded(child: Text(l10n.ownerPosMonitoringTotalSales, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    SizedBox(
                      width: 64,
                      child: Text(
                        'SAR ${counter.effectiveSystemTotal.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondaryLight),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        'SAR ${counter.effectivePhysicalTotal.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        isShort ? '− SAR ${netDiff.abs().toStringAsFixed(0)}' : (isExcess ? '+ SAR ${netDiff.abs().toStringAsFixed(0)}' : '—'),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: diffColor),
                      ),
                    ),
                  ],
                ),
                if (!counter.isV2) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.ownerPosMonitoringBreakdownUnavailable,
                      style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Employee / branch-staff sales bucket — highlighted so owners always spot this row after deploy.
  Widget _reconcRowOthersEmployees(PosCounter counter, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FCC247),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FCC247)),
      ),
      child: _reconcRow(
        l10n.ownerPosMonitoringOthersEmployees,
        counter.systemOthers,
        counter.physicalOthers,
        counter.diffOthers,
      ),
    );
  }

  Widget _tableHeader(String label, {bool narrow = false}) {
    return SizedBox(
      width: narrow ? 52 : 64,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
      ),
    );
  }

  Widget _reconcRow(String label, double system, double physical, double diff) {
    // diff = system − physical: positive = short (red), negative = excess (green)
    final diffColor = diff.abs() < 0.01 ? Colors.green : (diff > 0 ? Colors.red : Colors.green);
    final diffStr = diff.abs() < 0.01 ? '—' : '${diff > 0 ? "−" : "+"}${diff.abs().toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500))),
          SizedBox(
            width: 64,
            child: Text(
              system.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              physical.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              diffStr,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: diffColor),
            ),
          ),
        ],
      ),
    );
  }
}