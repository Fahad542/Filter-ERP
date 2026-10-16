import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../owner_shell.dart';
import 'commission_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommissionScreen
//
// Three tabs:
//   • Ledger  — KPI summary + filterable ledger list
//   • Pending — pending payout by employee
//   • Rules   — commission rules list with create / edit / delete
//
// Visual language mirrors the POS Monitoring screen: OwnerAppBar header,
// dark KPI tiles via ReusableKpiGrid, soft rounded cards, primary-yellow
// accents, and a FAB for "New Rule" while on the Rules tab.
// ─────────────────────────────────────────────────────────────────────────────

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommissionViewModel>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: l10n.ownerCommissionsTitle),
        showBackButton: false,
        showNotification: true,
        onNotificationPressed: () => OwnerShell.goToNotifications(context),
        onMenuPressed: () => OwnerShell.openDrawer(context),
      ),
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _LedgerTab(),
                _PendingPayoutTab(),
                _RulesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.secondaryLight,
        onPressed: () => _openRuleEditor(context, null),
        icon: const Icon(Icons.add_rounded, color: AppColors.secondaryLight),
        label: Text(
          AppLocalizations.of(context)!.ownerCommissionsNewRule,
          style: AppTextStyles.button.copyWith(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerSegmentedTabs(
      controller: _tabController,
      tabs: [
        l10n.ownerCommissionsTabLedger,
        l10n.ownerCommissionsTabPending,
        l10n.ownerCommissionsTabRules,
      ],
      layout: PosSegmentedTabLayout.expanded,
    );
  }

  void _openRuleEditor(BuildContext context, CommissionRule? rule) {
    // Capture vm before the modal route loses access to the parent provider.
    final vm = context.read<CommissionViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<CommissionViewModel>.value(
        value: vm,
        child: _RuleEditorSheet(rule: rule),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEDGER TAB
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerTab extends StatelessWidget {
  const _LedgerTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CommissionViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.overview.entries.isEmpty) {
          return const OwnerListPageShimmer(showKpi: true, showSearch: true);
        }

        return RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: vm.fetchOverview,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _buildKpiGrid(context, vm),
              const SizedBox(height: 16),
              _buildFilters(context, vm),
              const SizedBox(height: 12),
              _buildEntriesList(context, vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(BuildContext context, CommissionViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final k = vm.overview.kpis;
    return ReusableKpiGrid(
      layout: KpiGridLayout.singleRow,
      showFeatured: false,
      iconOnTop: true,
      mainAxisExtent: 108,
      singleRowCardWidth: 120,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerCommissionsTotalAccrued,
          value: formatKpiAmount(k.totalAccrued, context: context),
          icon: Icons.hourglass_top_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerCommissionsTotalPaid,
          value: formatKpiAmount(k.totalPaid, context: context),
          icon: Icons.check_circle_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerCommissionsPendingEmployees,
          value: ownerLocalizeDigits(context, '${k.pendingEmployees}'),
          icon: Icons.people_alt_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerCommissionsSelectedForPayout,
          value: formatKpiAmount(vm.selectedTotal, context: context),
          icon: Icons.payments_rounded,
          accentColor: AppColors.primaryLight,
        ),
      ],
    );
  }

  String _statusFilterLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'All Status':
        return l10n.ownerCommissionsAllStatus;
      case 'accrued':
        return l10n.ownerCommissionsAccrued;
      default:
        return value[0].toUpperCase() + value.substring(1);
    }
  }

  String _employeeFilterLabel(AppLocalizations l10n, String value) =>
      value == 'All Employees' ? l10n.ownerCommissionsAllEmployees : value;

  Widget _buildFilters(BuildContext context, CommissionViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdownField(
                  value: vm.statusFilter,
                  items: vm.statusFilterOptions,
                  onChanged: (v) => vm.setStatusFilter(v ?? 'All Status'),
                  labelBuilder: (v) => _statusFilterLabel(l10n, v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdownField(
                  value: vm.employeeFilter,
                  items: vm.employeeFilterOptions,
                  onChanged: (v) => vm.setEmployeeFilter(v ?? 'All Employees'),
                  labelBuilder: (v) => _employeeFilterLabel(l10n, v),
                  localizeItems: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dateField(
                  context: context,
                  label: l10n.ownerCommonFrom,
                  value: vm.fromDate,
                  onPicked: vm.setFromDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateField(
                  context: context,
                  label: l10n.ownerCommonTo,
                  value: vm.toDate,
                  onPicked: vm.setToDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: vm.selectableAccruedEntries.isEmpty ? null : vm.selectAllAccrued,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryLight, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.checklist_rounded, color: AppColors.primaryLight, size: 18),
              label: Text(
                l10n.ownerCommissionsSelectAllAccrued(
                    vm.selectableAccruedEntries.length),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
          ),
          if (vm.selectedEntryIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text:
                    '${l10n.ownerCommissionsPay} · ${ownerFormatMoney(context, vm.selectedTotal)}',
                backgroundColor: AppColors.primaryLight,
                textColor: AppColors.secondaryLight,
                onPressed: () async {
                  final ok = await vm.markEntriesPaid(vm.selectedEntryIds.toList());
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selected commissions marked as paid.')),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String Function(String) labelBuilder,
    bool localizeItems = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: localizeItems && e != 'All Employees'
                      ? LocalizedApiText(
                          labelBuilder(e),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(labelBuilder(e)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: OwnerUi.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondaryLight.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColors.secondaryLight.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: value == null
                      ? AppColors.secondaryLight.withOpacity(0.4)
                      : AppColors.secondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, CommissionViewModel vm) {
    final entries = vm.filteredEntries;

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context)!.ownerCommissionsNoEntriesMatch,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondaryLight.withOpacity(0.5),
          ),
        ),
      );
    }

    return Column(
      children: entries.map((entry) => _LedgerEntryCard(entry: entry, vm: vm)).toList(),
    );
  }
}


class _LedgerEntryCard extends StatelessWidget {
  final CommissionLedgerEntry entry;
  final CommissionViewModel vm;

  const _LedgerEntryCard({required this.entry, required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial = entry.employeeName.isNotEmpty
        ? entry.employeeName.trim()[0].toUpperCase()
        : '?';
    final isPaid = entry.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: vm.isEntrySelected(entry.id)
            ? Border.all(color: AppColors.primaryLight, width: 1.6)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 2),
              child: Checkbox(
                value: vm.isEntrySelected(entry.id),
                activeColor: AppColors.primaryLight,
                onChanged: (_) => vm.toggleEntrySelection(entry.id),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            )
          else
            const SizedBox(width: 4),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight.withOpacity(0.18),
            child: Text(
              initial,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LocalizedApiText(
                        entry.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                    _statusChip(context, entry),
                  ],
                ),
                const SizedBox(height: 4),
                LocalizedApiText(
                  entry.service,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryLight.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _miniInfo(
                      context,
                      l10n.ownerCommissionsJobCard,
                      entry.jobCardNumber,
                      link: true,
                    ),
                    _miniInfo(
                      context,
                      l10n.ownerCommissionsDate,
                      '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
                    ),
                    _miniInfo(
                      context,
                      l10n.ownerCommissionsRate,
                      entry.displayRate,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      ownerFormatMoney(context, entry.amount),
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const Spacer(),
                    if (!isPaid)
                      SizedBox(
                        height: 34,
                        child: CustomButton(
                          text: l10n.ownerCommissionsPay,
                          backgroundColor: const Color(0xFF2ECC71).withOpacity(0.12),
                          textColor: const Color(0xFF1E9E58),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E9E58),
                          ),
                          onPressed: () async {
                            final ok = await vm.markEntriesPaid([entry.id]);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                  Text('${entry.employeeName} marked as paid.'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, CommissionLedgerEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = entry.isPaid;
    final color = isPaid ? const Color(0xFF2ECC71) : AppColors.primaryLight;
    final statusLabel = entry.status.toLowerCase() == 'accrued'
        ? l10n.ownerCommissionsAccrued
        : entry.status[0].toUpperCase() + entry.status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.access_time_rounded,
            size: 12,
            color: isPaid ? const Color(0xFF1E9E58) : AppColors.secondaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isPaid ? const Color(0xFF1E9E58) : AppColors.secondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(
    BuildContext context,
    String label,
    String value, {
    bool link = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.secondaryLight.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: link ? AppColors.primaryLight : AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING PAYOUT TAB
// ─────────────────────────────────────────────────────────────────────────────

class _PendingPayoutTab extends StatelessWidget {
  const _PendingPayoutTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CommissionViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.overview.pendingByEmployee.isEmpty) {
          return const OwnerListPageShimmer(
            showKpi: true,
            kpiCount: 3,
            itemCount: 6,
          );
        }

        final employees = vm.overview.pendingByEmployee;
        final k = vm.overview.kpis;
        final l10n = AppLocalizations.of(context)!;
        return RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: vm.fetchOverview,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              ReusableKpiGrid(
                layout: KpiGridLayout.singleRow,
                showFeatured: false,
                iconOnTop: true,
                mainAxisExtent: 108,
                singleRowCardWidth: 120,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                metrics: [
                  ReusableKpiMetric(
                    title: l10n.ownerCommissionsTotalAccrued,
                    value: formatKpiAmount(k.totalAccrued, context: context),
                    icon: Icons.hourglass_top_rounded,
                    accentColor: AppColors.primaryLight,
                  ),
                  ReusableKpiMetric(
                    title: l10n.ownerCommissionsTotalPaid,
                    value: formatKpiAmount(k.totalPaid, context: context),
                    icon: Icons.check_circle_rounded,
                    accentColor: AppColors.primaryLight,
                  ),
                  ReusableKpiMetric(
                    title: l10n.ownerCommissionsPendingEmployees,
                    value: ownerLocalizeDigits(context, '${k.pendingEmployees}'),
                    icon: Icons.people_alt_rounded,
                    accentColor: AppColors.primaryLight,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryLight.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.groups_2_rounded,
                            color: AppColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.ownerCommissionsPendingPayoutByEmployee,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (employees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          AppLocalizations.of(context)!.ownerCommissionsNoPendingPayouts,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryLight.withOpacity(0.5),
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: employees.map((e) {
                              final initial = e.employeeName.isNotEmpty
                                  ? e.employeeName.trim()[0].toUpperCase()
                                  : '?';
                              return Container(
                                width: itemWidth,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: OwnerUi.scaffoldBackground,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primaryLight
                                          .withOpacity(0.2),
                                      child: Text(
                                        initial,
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.secondaryLight,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          LocalizedApiText(
                                            e.employeeName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTextStyles.bodySmall.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondaryLight,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppLocalizations.of(context)!.ownerCommissionsEntriesAmount(
                                              ownerLocalizeDigits(context, '${e.entriesCount}'),
                                              formatKpiAmount(e.totalAmount, context: context),
                                            ),
                                            style:
                                                AppTextStyles.bodySmall.copyWith(
                                              fontSize: 10.5,
                                              color: AppColors.secondaryLight
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RULES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _RulesTab extends StatelessWidget {
  const _RulesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CommissionViewModel>(
      builder: (context, vm, _) {
        return RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: vm.fetchRules,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            children: [
              _buildHeaderCard(context, vm),
              const SizedBox(height: 12),
              if (vm.filteredRules.isEmpty)
                _buildEmptyState(context)
              else
                ...vm.filteredRules.map((rule) => _RuleCard(rule: rule, vm: vm)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, CommissionViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.ownerCommissionsRulesHeading,
            style: AppTextStyles.h3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.ownerCommissionsRulesHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryLight.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: vm.setRulesSearchQuery,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.ownerCommissionsSearchRules,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryLight.withOpacity(0.4),
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.secondaryLight.withOpacity(0.4), size: 20),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.rule_folder_outlined,
              size: 36, color: AppColors.secondaryLight.withOpacity(0.25)),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.ownerCommissionsNoRulesYet,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryLight.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final CommissionRule rule;
  final CommissionViewModel vm;

  const _RuleCard({required this.rule, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${rule.priority}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rule.displayService,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              _statusChip(rule),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _miniInfo('Role', rule.displayRole),
              _miniInfo('Type', rule.isPercentage ? 'Percentage' : 'Fixed'),
              _miniInfo('Value', rule.displayValue),
            ],
          ),
          if (rule.notes != null && rule.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rule.notes!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryLight.withOpacity(0.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _RuleEditorSheet(rule: rule),
                ),
                icon: Icon(Icons.edit_outlined,
                    color: AppColors.secondaryLight.withOpacity(0.6), size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _confirmDelete(context, vm, rule),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.errorLight, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(CommissionRule rule) {
    final isActive = rule.isActive;
    final color = isActive ? const Color(0xFF2ECC71) : AppColors.secondaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rule.status,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isActive ? const Color(0xFF1E9E58) : AppColors.secondaryLight.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.secondaryLight.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, CommissionViewModel vm, CommissionRule rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete rule?',
          style: AppTextStyles.h3.copyWith(fontSize: 16, color: AppColors.secondaryLight),
        ),
        content: Text(
          'This commission rule for "${rule.displayService}" will be permanently removed.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryLight.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteRule(rule.id);
            },
            child: Text('Delete',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.errorLight, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RULE EDITOR (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _RuleEditorSheet extends StatefulWidget {
  final CommissionRule? rule;
  const _RuleEditorSheet({this.rule});

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  late TextEditingController _priorityController;
  late TextEditingController _valueController;
  late TextEditingController _notesController;
  late TextEditingController _customServiceController;

  String _status = 'active';
  String? _selectedServiceId; // null => custom
  String? _selectedRole;
  String _type = 'percentage';

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _priorityController = TextEditingController(text: '${r?.priority ?? 1}');
    _valueController = TextEditingController(text: '${r?.value ?? 0}');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _customServiceController = TextEditingController(text: r?.serviceName ?? '');
    _status = r?.status ?? 'active';
    _selectedServiceId = r?.serviceId;
    _selectedRole = r?.employeeRole;
    _type = r?.type ?? 'percentage';
  }

  @override
  void dispose() {
    _priorityController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    _customServiceController.dispose();
    super.dispose();
  }

  // Cache services/roles once — they don't change while the sheet is open,
  // and we don't want vm notifications to rebuild the entire sheet on every
  // keystroke or dropdown tap (which was causing the keyboard-animation lag).
  late final List<dynamic> _services;
  late final List<String> _roles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      final vm = context.read<CommissionViewModel>();
      _services = vm.rulesResponse.serviceOptions;
      _roles = vm.rulesResponse.employeeRoles;
      _depsInitialized = true;
    }
  }

  bool _depsInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Use read — the sheet only needs vm at submit time, not for rendering.
    // Watching would rebuild the full sheet on every notifyListeners() call
    // from the parent (e.g. ledger filter changes) causing visible jank.
    final services = _services;
    final roles = _roles;
    final l10n = AppLocalizations.of(context)!;
    final currency = l10n.ownerCurrencySar;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? l10n.ownerCommissionsEditRule
                          : l10n.ownerCommissionsNewRuleTitle,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.secondaryLight.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _labeledField(
                      label: l10n.ownerCommissionsPriority,
                      child: TextField(
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _labeledField(
                      label: l10n.ownerCommissionsStatus,
                      child: OwnerStyledDropdown<String>(
                        value: _status,
                        hint: l10n.ownerCommissionsStatus,
                        height: 48,
                        options: [
                          OwnerDropdownOption(
                            value: 'active',
                            label: l10n.ownerCommonActiveLabel,
                          ),
                          OwnerDropdownOption(
                            value: 'inactive',
                            label: l10n.ownerCommonInactive,
                          ),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? 'active'),
                        triggerStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _labeledField(
                label: l10n.ownerCommissionsService,
                child: OwnerStyledDropdown<String>(
                  value: _selectedServiceId ?? '__custom__',
                  hint: l10n.ownerCommissionsService,
                  height: 48,
                  options: [
                    OwnerDropdownOption(
                      value: '__custom__',
                      label: l10n.ownerCommissionsCustomService,
                    ),
                    ...services.map(
                      (s) => OwnerDropdownOption(value: s.id, label: s.name),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _selectedServiceId =
                        (v == null || v == '__custom__') ? null : v,
                  ),
                  triggerStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              if (_selectedServiceId == null) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customServiceController,
                  decoration: _inputDecoration(
                      hint: l10n.ownerCommissionsServiceNameHint),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeledField(
                      label: l10n.ownerCommissionsEmployeeRole,
                      child: OwnerStyledDropdown<String>(
                        value: _selectedRole ??
                            (roles.isNotEmpty ? roles.first : null),
                        hint: l10n.ownerCommissionsRoleHint,
                        height: 48,
                        options: roles
                            .map((r) => OwnerDropdownOption(value: r, label: r))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRole = v),
                        triggerStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _labeledField(
                      label: l10n.ownerCommissionsType,
                      child: OwnerStyledDropdown<String>(
                        value: _type,
                        hint: l10n.ownerCommissionsType,
                        height: 48,
                        options: [
                          OwnerDropdownOption(
                            value: 'percentage',
                            label: l10n.ownerCommissionsTypePercentage,
                          ),
                          OwnerDropdownOption(
                            value: 'fixed',
                            label: l10n.ownerCommissionsTypeFixed(currency),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _type = v ?? 'percentage'),
                        triggerStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _labeledField(
                label: _type == 'percentage'
                    ? l10n.ownerCommissionsValuePercent
                    : l10n.ownerCommissionsValueSar(currency),
                child: TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(),
                ),
              ),
              const SizedBox(height: 10),
              _labeledField(
                label: l10n.ownerCommissionsNotes,
                child: TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.secondaryLight.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.ownerCommonCancel,
                          style: AppTextStyles.button.copyWith(color: AppColors.secondaryLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: _isEditing
                          ? l10n.ownerCommissionsSaveRule
                          : l10n.ownerCommissionsCreateRule,
                      backgroundColor: AppColors.primaryLight,
                      textColor: AppColors.secondaryLight,
                      onPressed: () => _submit(context),
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

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryLight.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.backgroundLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );
  }

  Future<void> _submit(BuildContext context) async {
    final vm = context.read<CommissionViewModel>();
    final priority = int.tryParse(_priorityController.text.trim()) ?? 1;
    final value = double.tryParse(_valueController.text.trim()) ?? 0.0;

    String? serviceName;
    if (_selectedServiceId == null) {
      serviceName = _customServiceController.text.trim();
    } else {
      final match = vm.rulesResponse.serviceOptions
          .where((s) => s.id == _selectedServiceId)
          .toList();
      serviceName = match.isNotEmpty ? match.first.name : null;
    }

    final rule = CommissionRule(
      id: widget.rule?.id ?? '',
      priority: priority,
      status: _status,
      serviceId: _selectedServiceId,
      serviceName: serviceName,
      employeeRole: _selectedRole,
      type: _type,
      value: value,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final ok = _isEditing ? await vm.updateRule(rule) : await vm.createRule(rule);

    if (ok && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Rule updated.' : 'Rule created.')),
      );
    }
  }
}