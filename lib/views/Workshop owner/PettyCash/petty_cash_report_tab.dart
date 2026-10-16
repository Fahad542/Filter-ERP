import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../widgets/pos_shimmer.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../widgets/reusable_kpi_grid.dart';
import 'petty_cash_view_model.dart';

Widget buildPettyCashReportKpiSection(BuildContext context, PettyCashViewModel vm) {
  final l10n = AppLocalizations.of(context)!;
  if (vm.reportLoading) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _ReportKpiShimmer(),
    );
  }

  return ReusableKpiGrid(
    metrics: [
      ReusableKpiMetric(
        title: l10n.ownerPettyTotalDebit,
        value: ownerFormatMoney(context, vm.reportTotalDebit),
        icon: Icons.arrow_downward_rounded,
        accentColor: AppColors.primaryLight,
      ),
      ReusableKpiMetric(
        title: l10n.ownerPettyTotalCredit,
        value: ownerFormatMoney(context, vm.reportTotalCredit),
        icon: Icons.arrow_upward_rounded,
        accentColor: AppColors.primaryLight,
      ),
      ReusableKpiMetric(
        title: l10n.ownerPettyClosingBalance,
        value: _ownerFmtBal(context, vm.reportClosingBalance),
        icon: Icons.account_balance_rounded,
        accentColor: AppColors.primaryLight,
      ),
    ],
    showFeatured: false,
    crossAxisCount: 3,
    dense: true,
    iconOnTop: true,
    mainAxisExtent: 112,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
  );
}

String _ownerFmtBal(BuildContext context, double v) {
  if (v.abs() < 0.005) return ownerFormatMoney(context, 0);
  final side = v >= 0 ? ' Dr' : ' Cr';
  return '${ownerFormatMoney(context, v.abs())}$side';
}

String _ownerIsoDate(BuildContext context, DateTime d) {
  final raw =
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return ownerLocalizeDigits(context, raw);
}

/// Employee Petty Cash Expense [6100] statement — Owner UI patterns
/// (same cards / KPIs / field chrome as Staff Wallets & Issue sheet).
class PettyCashReportTab extends StatefulWidget {
  const PettyCashReportTab({super.key});

  @override
  State<PettyCashReportTab> createState() => _PettyCashReportTabState();
}

class _PettyCashReportTabState extends State<PettyCashReportTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PettyCashViewModel>().ensureReportLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<PettyCashViewModel>();
    final rows = vm.reportRows;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.fetchReport(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          _buildFilterCard(context, vm, l10n),
          const SizedBox(height: 8),
          if (vm.reportLoading)
            const _ReportBodyShimmer()
          else if (vm.reportError != null && vm.reportError!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                vm.reportError!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else ...[
            _buildStatementIntro(context, vm, l10n),
            const SizedBox(height: 10),
            _OpeningBalanceCard(
              label: l10n.ownerPettyOpeningBalance,
              balanceText: _ownerFmtBal(context, vm.reportOpeningBalance),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: _ReportEmptyState(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.ownerPettyNoTransactions,
                ),
              )
            else
              for (final r in rows) ...[
                _ReportLineCard(row: r),
              ],
            const SizedBox(height: 8),
            _buildClosingSummary(context, vm, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    PettyCashViewModel vm,
    AppLocalizations l10n,
  ) {
    final employeeValue = vm.reportWalletUserId ?? 'all';
    var employeeLabel = l10n.ownerPettyAllEmployees;
    if (vm.reportWalletUserId != null) {
      for (final e in vm.reportWalletUsers) {
        if (e.id == vm.reportWalletUserId) {
          employeeLabel = e.displayLabel;
          break;
        }
      }
    }

    final categoryValue = vm.reportExpenseCategory ?? 'all';
    var categoryLabel = l10n.ownerPettyAllCategories;
    if (vm.reportExpenseCategory != null) {
      for (final e in vm.reportCategories) {
        if (e.id == vm.reportExpenseCategory) {
          categoryLabel = e.displayLabel;
          break;
        }
      }
    }

    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ownerPettyUserEmployee,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      OwnerStyledDropdown<String>(
                        value: employeeValue,
                        displayLabel: employeeValue == 'all'
                            ? l10n.ownerPettyAllEmployees
                            : employeeLabel,
                        hint: l10n.ownerPettyAllEmployees,
                        options: [
                          OwnerDropdownOption(
                            value: 'all',
                            label: l10n.ownerPettyAllEmployees,
                          ),
                          ...vm.reportWalletUsers.map(
                            (e) => OwnerDropdownOption(
                              value: e.id,
                              label: e.displayLabel,
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          vm.setReportWalletUserId(v == 'all' ? null : v);
                          vm.fetchReport();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ownerPettyAccountCategory,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      OwnerStyledDropdown<String>(
                        value: categoryValue,
                        displayLabel: categoryValue == 'all'
                            ? l10n.ownerPettyAllCategories
                            : categoryLabel,
                        hint: l10n.ownerPettyAllCategories,
                        options: [
                          OwnerDropdownOption(
                            value: 'all',
                            label: l10n.ownerPettyAllCategories,
                          ),
                          ...vm.reportCategories.map(
                            (e) => OwnerDropdownOption(
                              value: e.id,
                              label: e.displayLabel,
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          vm.setReportExpenseCategory(v == 'all' ? null : v);
                          vm.fetchReport();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementIntro(
    BuildContext context,
    PettyCashViewModel vm,
    AppLocalizations l10n,
  ) {
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OwnerListIconBox(icon: Icons.receipt_long_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ownerPettyStatement,
                    style: OwnerListStyle.titleStyle.copyWith(fontSize: 15.5),
                  ),
                  if (vm.reportCompanyName.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    LocalizedApiText(
                      vm.reportCompanyName,
                      style: OwnerListStyle.subtitleStyle.copyWith(
                        fontSize: 13,
                        color: AppColors.secondaryLight.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '[${ownerLocalizeDigits(context, vm.reportAccountCode)}] ',
                        style: OwnerListStyle.metaStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight.withValues(alpha: 0.7),
                        ),
                      ),
                      Expanded(
                        child: LocalizedApiText(
                          vm.reportAccountName,
                          style: OwnerListStyle.metaStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                AppColors.secondaryLight.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.ownerPettyFromTo(
                      _ownerIsoDate(context, vm.reportDateFrom),
                      _ownerIsoDate(context, vm.reportDateTo),
                    ),
                    style: OwnerListStyle.metaStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosingSummary(
    BuildContext context,
    PettyCashViewModel vm,
    AppLocalizations l10n,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.08),
        borderRadius: OwnerListStyle.cardRadius,
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            _SummaryLine(
              label: l10n.ownerPettyOpeningBalance,
              value: _ownerFmtBal(context, vm.reportOpeningBalance),
            ),
            _SummaryLine(
              label: l10n.ownerPettyTotalDebit,
              value: '${ownerFormatMoney(context, vm.reportTotalDebit)} Dr',
            ),
            _SummaryLine(
              label: l10n.ownerPettyTotalCredit,
              value: ownerFormatMoney(context, vm.reportTotalCredit),
            ),
            const Divider(height: 16),
            _SummaryLine(
              label: l10n.ownerPettyClosingBalance,
              value: _ownerFmtBal(context, vm.reportClosingBalance),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportKpiShimmer extends StatelessWidget {
  const _ReportKpiShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 5,
                right: i == 2 ? 0 : 5,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const PosShimmer(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 14, 10, 14),
                    child: Column(
                      children: [
                        PosShimmerCircle(size: 28),
                        SizedBox(height: 12),
                        PosShimmerBox(
                          width: double.infinity,
                          height: 10,
                          radius: 5,
                        ),
                        SizedBox(height: 8),
                        PosShimmerBox(
                          width: double.infinity,
                          height: 14,
                          radius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ReportBodyShimmer extends StatelessWidget {
  const _ReportBodyShimmer();

  static BoxDecoration get _card => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: _card,
          child: const PosShimmer(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(width: 44, height: 44, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosShimmerBox(width: 110, height: 14, radius: 6),
                        SizedBox(height: 8),
                        PosShimmerBox(
                          width: double.infinity,
                          height: 12,
                          radius: 6,
                        ),
                        SizedBox(height: 6),
                        PosShimmerBox(width: 180, height: 12, radius: 6),
                        SizedBox(height: 6),
                        PosShimmerBox(width: 160, height: 11, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: _card,
          child: const PosShimmer(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  PosShimmerBox(width: 44, height: 44, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 6,
                    ),
                  ),
                  SizedBox(width: 12),
                  PosShimmerBox(width: 88, height: 14, radius: 6),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 4; i++) ...[
          DecoratedBox(
            decoration: _card,
            child: const PosShimmer(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PosShimmerBox(width: 44, height: 44, radius: 12),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PosShimmerBox(
                            width: double.infinity,
                            height: 14,
                            radius: 6,
                          ),
                          SizedBox(height: 8),
                          PosShimmerBox(
                            width: double.infinity,
                            height: 12,
                            radius: 6,
                          ),
                          SizedBox(height: 6),
                          PosShimmerBox(width: 140, height: 12, radius: 6),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    PosShimmerBox(width: 56, height: 14, radius: 6),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          decoration: _card,
          child: const PosShimmer(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  _ShimmerSummaryLine(),
                  SizedBox(height: 8),
                  _ShimmerSummaryLine(),
                  SizedBox(height: 8),
                  _ShimmerSummaryLine(),
                  SizedBox(height: 12),
                  _ShimmerSummaryLine(bold: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerSummaryLine extends StatelessWidget {
  final bool bold;

  const _ShimmerSummaryLine({this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PosShimmerBox(
          width: bold ? 120 : 100,
          height: bold ? 14 : 12,
          radius: 6,
        ),
        const Spacer(),
        PosShimmerBox(
          width: bold ? 96 : 80,
          height: bold ? 14 : 12,
          radius: 6,
        ),
      ],
    );
  }
}

class _OpeningBalanceCard extends StatelessWidget {
  final String label;
  final String balanceText;

  const _OpeningBalanceCard({
    required this.label,
    required this.balanceText,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            const OwnerListIconBox(icon: Icons.play_arrow_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: OwnerListStyle.titleStyle.copyWith(fontSize: 14),
              ),
            ),
            Text(
              balanceText,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportLineCard extends StatelessWidget {
  final PettyCashReportRow row;

  const _ReportLineCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final amountText = row.debit > 0.005
        ? ownerFormatMoney(context, row.debit)
        : (row.credit > 0.005
            ? ownerFormatMoney(context, row.credit)
            : '—');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwnerListIconBox(icon: Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedApiText(
                      row.displayWalletUserLabel,
                      style: OwnerListStyle.titleStyle.copyWith(fontSize: 14.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: row.debit > 0.005
                            ? AppColors.secondaryLight
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _MetaLine(
                      icon: Icons.category_outlined,
                      child: LocalizedApiText(
                        row.displayExpenseCategoryLabel,
                        style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _MetaLine(
                      icon: Icons.calendar_today_outlined,
                      child: Text(
                        ownerLocalizeDigits(context, row.date),
                        style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
                      ),
                    ),
                    _MetaLine(
                      icon: Icons.notes_outlined,
                      child: LocalizedApiText(
                        row.displayDescription,
                        style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _MetaLine(
                      icon: Icons.account_balance_wallet_outlined,
                      child: Text(
                        _ownerFmtBal(context, row.runningBalance),
                        style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _MetaLine({
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: OwnerListStyle.mutedText),
          const SizedBox(width: 5),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      color: AppColors.secondaryLight,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ReportEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReportEmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 42, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
