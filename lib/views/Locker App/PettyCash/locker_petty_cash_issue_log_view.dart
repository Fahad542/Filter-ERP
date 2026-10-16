import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_petty_cash_issue_log_view_model.dart';

String _money(double v) => NumberFormat('#,##0.00').format(v);

class LockerPettyCashIssueLogView extends StatelessWidget {
  final bool isSupervisor;

  const LockerPettyCashIssueLogView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerPettyCashIssueLogViewModel(),
      child: _IssueLogBody(isSupervisor: isSupervisor),
    );
  }
}

class _IssueLogBody extends StatefulWidget {
  final bool isSupervisor;

  const _IssueLogBody({required this.isSupervisor});

  @override
  State<_IssueLogBody> createState() => _IssueLogBodyState();
}

class _IssueLogBodyState extends State<_IssueLogBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LockerPettyCashIssueLogViewModel>().init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<LockerPettyCashIssueLogViewModel>();

    return LockerShell(
      isSupervisor: widget.isSupervisor,
      currentItem: LockerSidebarItem.pettyCashIssueLog,
      title: l10n.lockerPettyIssueLogTitle,
      backgroundColor: OwnerUi.scaffoldBackground,
      bottomOverlap: TechDashboardOverlapFilters(
        startDate: vm.from,
        endDate: vm.to,
        dateOnly: true,
        onStartDateChanged: (d) => vm.setDateRange(d, vm.to, context),
        onEndDateChanged: (d) => vm.setDateRange(vm.from, d, context),
      ),
      body: _buildBody(context, vm, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LockerPettyCashIssueLogViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.isLoading && vm.issues.isEmpty) {
      return const OwnerListPageShimmer(
        showKpi: true,
        kpiCount: 4,
        itemCount: 4,
        padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      );
    }

    if (vm.isError && vm.issues.isEmpty) {
      return _ErrorState(
        message: vm.error ?? l10n.lockerAnErrorOccurred,
        onRetry: () => vm.refresh(context),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildKpiGrid(vm, l10n),
          const SizedBox(height: 8),
          _buildFilterPanel(context, vm, l10n),
          const SizedBox(height: 12),
          _buildListHeader(vm, l10n),
          const SizedBox(height: 10),
          if (vm.issues.isEmpty)
            _EmptyInline(message: l10n.lockerNoPettyIssues)
          else
            ...vm.issues.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IssueCard(entry: e),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
      LockerPettyCashIssueLogViewModel vm, AppLocalizations l10n) {
    final s = vm.summary;
    final sar = l10n.lockerSarCurrency;
    final metrics = [
      ReusableKpiMetric(
        title: l10n.lockerKpiLockerVault,
        value: '$sar ${_money(s.lockerVaultBalance)}',
        subtitle: l10n.lockerCashInTransit,
        icon: Icons.account_balance_wallet_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiTotalIssued,
        value: '$sar ${_money(s.totalAmount)}',
        subtitle: l10n.lockerSelectedPeriod,
        icon: Icons.payments_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiIssueCount,
        value: '${s.issueCount}',
        subtitle: l10n.lockerAcrossBranches,
        icon: Icons.receipt_long_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiAverageIssue,
        value: '$sar ${_money(s.averageAmount)}',
        subtitle: l10n.lockerPerIssue,
        icon: Icons.trending_flat_rounded,
      ),
    ];

    return ReusableKpiGrid(
      metrics: metrics,
      showFeatured: false,
      crossAxisCount: 2,
      dense: true,
      iconOnTop: true,
      mainAxisExtent: 100,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    LockerPettyCashIssueLogViewModel vm,
    AppLocalizations l10n,
  ) {
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
                    onTap: () => vm.clearFilters(context),
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
                  child: _FilterDropdown(
                    label: l10n.lockerLabelBranch,
                    value: vm.selectedBranchId ?? 'all',
                    isLoading: vm.branchesLoading,
                    hint: l10n.lockerAllBranches,
                    options: [
                      OwnerDropdownOption(
                          value: 'all', label: l10n.lockerAllBranches),
                      ...vm.branches.map(
                        (b) =>
                            OwnerDropdownOption(value: b.id, label: b.name),
                      ),
                    ],
                    onChanged: (v) => vm.setSelectedBranch(
                        v == null || v == 'all' ? null : v, context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown(
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
                        v == null || v == 'all' ? null : v, context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(
      LockerPettyCashIssueLogViewModel vm, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.lockerIssuedFloats,
          style: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        if (vm.isSuccess)
          Text(
            l10n.lockerRecordCount('${vm.issues.length}'),
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

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final String hint;
  final List<OwnerDropdownOption<String>> options;
  final ValueChanged<String?> onChanged;

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
    final validValue =
        options.any((o) => o.value == value) ? value : 'all';

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
          OwnerStyledDropdown<String>(
            value: validValue,
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

class _IssueCard extends StatelessWidget {
  final PettyCashIssueLogEntry entry;

  const _IssueCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OwnerListIconBox(
                  icon: Icons.currency_exchange_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.cashierName.isNotEmpty
                            ? entry.cashierName
                            : l10n.lockerFallbackCashier,
                        style: OwnerListStyle.titleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.branchName.isNotEmpty
                            ? entry.branchName
                            : '—',
                        style: OwnerListStyle.subtitleStyle,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${l10n.lockerSarCurrency} ${_money(entry.amount)}',
                  style: OwnerListStyle.titleStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: OwnerListStyle.cardBorder),
            const SizedBox(height: 12),
            _MetaRow(
                label: l10n.lockerDateLabel,
                value: entry.date.isEmpty ? '—' : entry.date),
            const SizedBox(height: 8),
            _MetaRow(
              label: l10n.lockerReferenceLabel,
              value: entry.description.isNotEmpty ? entry.description : '—',
            ),
            const SizedBox(height: 8),
            _MetaRow(
              label: l10n.lockerJeLabel,
              value: entry.journalEntryNumber.isNotEmpty
                  ? entry.journalEntryNumber
                  : '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            style: OwnerListStyle.subtitleStyle.copyWith(
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

class _EmptyInline extends StatelessWidget {
  final String message;

  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.black.withOpacity(0.35),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

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
            Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.lockerRetry,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
