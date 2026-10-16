import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/technician_advance_model.dart';
import '../../../models/technician_salary_payment_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/pos_filter_tab_dropdown.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_widgets.dart';
import '../../Technician App/widgets/tech_list_shimmer.dart';
import 'pos_salaries_view_model.dart';

class PosSalariesView extends StatefulWidget {
  const PosSalariesView({super.key});

  @override
  State<PosSalariesView> createState() => _PosSalariesViewState();
}

class _PosSalariesViewState extends State<PosSalariesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _expandedIds = {};

  DateFormat _paymentDateFormat(BuildContext context) =>
      DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString());

  DateFormat _advanceDateFormat(BuildContext context) => DateFormat(
        'dd MMM yyyy · hh:mm a',
        Localizations.localeOf(context).toString(),
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PosSalariesViewModel>().fetchAll();
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: PosScreenAppBar(
          title: l10n.posNavSalaries,
          showBackButton: false,
          showHamburger: true,
          onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
        ),
        body: wrapPosShellRailBody(
          context,
          Consumer<PosSalariesViewModel>(
            builder: (context, vm, _) {
              final onSalaries = _tabController.index == 0;
              final showSalariesBar = onSalaries &&
                  !vm.isLoadingSalaryPayments &&
                  (vm.salaryPaymentsTotalNet > 0 || vm.salaryPayments.isNotEmpty);
              final showAdvancesBar = !onSalaries &&
                  !vm.isLoadingSalaryAdvances &&
                  (vm.salaryAdvancesTotalOutstanding > 0 ||
                      vm.salaryAdvanceTransactions.isNotEmpty ||
                      vm.salaryAdvancesTotalIssued > 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildDateFilter(context, vm, l10n),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSalariesTab(context, vm, l10n),
                        _buildAdvancesTab(context, vm, l10n),
                      ],
                    ),
                  ),
                  if (showSalariesBar) _buildTotalReceivedBar(l10n, vm),
                  if (showAdvancesBar) _buildAdvancesSummaryBar(l10n, vm),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(
    BuildContext context,
    PosSalariesViewModel vm,
    AppLocalizations l10n,
  ) {
    String label(DateTime d) =>
        DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString())
            .format(d);

    Future<void> pick({required bool isFrom}) async {
      final initial = isFrom ? vm.fromDate : vm.toDate;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked == null) return;
      if (isFrom) {
        await vm.applyStartDate(picked);
      } else {
        await vm.applyEndDate(picked);
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
          value: label(vm.fromDate),
          onTap: () => pick(isFrom: true),
        ),
        const SizedBox(width: 8),
        chip(
          title: l10n.posClosingHistoryTo,
          value: label(vm.toDate),
          onTap: () => pick(isFrom: false),
        ),
        const SizedBox(width: 8),
        PosFilterTabDropdown(
          selectedId: _tabController.index == 0 ? 'salaries' : 'advances',
          options: [
            PosFilterTabOption(
              id: 'salaries',
              label: l10n.techSalariesTab,
              count: vm.salaryPayments.length,
            ),
            PosFilterTabOption(
              id: 'advances',
              label: l10n.techAdvancesTab,
              count: vm.salaryAdvanceTransactions.length,
            ),
          ],
          onSelected: (id) {
            final next = id == 'advances' ? 1 : 0;
            if (_tabController.index == next) return;
            _tabController.animateTo(next);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildSalariesTab(
    BuildContext context,
    PosSalariesViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.isLoadingSalaryPayments && vm.salaryPayments.isEmpty) {
      return const TechListCardShimmer();
    }
    return RefreshIndicator(
      color: AppColors.secondaryLight,
      backgroundColor: Colors.white,
      onRefresh: vm.fetchAll,
      child: vm.salaryPayments.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.28,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.techSalariesNoneInRange,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.techTryDifferentDateRange,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildThreeColList(
              itemCount: vm.salaryPayments.length,
              itemBuilder: (index) => _buildSalaryCard(
                context,
                vm,
                vm.salaryPayments[index],
                l10n,
              ),
            ),
    );
  }

  Widget _buildAdvancesTab(
    BuildContext context,
    PosSalariesViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.isLoadingSalaryAdvances && vm.salaryAdvanceTransactions.isEmpty) {
      return const TechListCardShimmer();
    }
    final txs = vm.salaryAdvanceTransactions;
    return RefreshIndicator(
      color: AppColors.secondaryLight,
      backgroundColor: Colors.white,
      onRefresh: vm.fetchAll,
      child: txs.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.28,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 48,
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.techAdvancesNoneInRange,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.techTryDifferentDateRange,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildThreeColList(
              itemCount: txs.length,
              itemBuilder: (index) =>
                  _buildAdvanceTransactionCard(txs[index], l10n),
            ),
    );
  }

  Widget _buildThreeColList({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
  }) {
    const cols = 3;
    const spacing = 12.0;
    final rowCount = (itemCount / cols).ceil();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final start = rowIndex * cols;
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : spacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < cols; col++) ...[
                  if (col > 0) const SizedBox(width: spacing),
                  Expanded(
                    child: start + col >= itemCount
                        ? const SizedBox.shrink()
                        : itemBuilder(start + col),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalReceivedBar(AppLocalizations l10n, PosSalariesViewModel vm) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.techTotalReceived(
                        l10n.ownerCurrencySar,
                        vm.salaryPaymentsTotalNet.toStringAsFixed(2),
                      ),
                      style: const TextStyle(
                        color: AppColors.onSecondaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${vm.salaryPaymentsTotal} · ${l10n.techSelectedDateRange}',
                      style: TextStyle(
                        color: AppColors.onSecondaryLight.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildAdvancesSummaryBar(
    AppLocalizations l10n,
    PosSalariesViewModel vm,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.techBalanceLabel(
                        l10n.ownerCurrencySar,
                        vm.salaryAdvancesTotalOutstanding.toStringAsFixed(2),
                      ),
                      style: const TextStyle(
                        color: AppColors.onSecondaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+${vm.salaryAdvancesTotalIssued.toStringAsFixed(2)} ${l10n.techAdvanceLabel}  ·  −${vm.salaryAdvancesTotalDeducted.toStringAsFixed(2)} ${l10n.techDeductedLabel}',
                      style: TextStyle(
                        color: AppColors.onSecondaryLight.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n.techSelectedDateRange,
                      style: TextStyle(
                        color: AppColors.onSecondaryLight.withValues(alpha: 0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

  Widget _buildSalaryCard(
    BuildContext context,
    PosSalariesViewModel vm,
    TechSalaryPayment payment,
    AppLocalizations l10n,
  ) {
    final expanded = _expandedIds.contains(payment.id);
    final paidOn = payment.paymentDate != null
        ? _paymentDateFormat(context).format(payment.paymentDate!)
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              if (expanded) {
                _expandedIds.remove(payment.id);
              } else {
                _expandedIds.add(payment.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.periodLabel,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.techPaidOn(paidOn),
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.techMoneyAmount(
                            l10n.ownerCurrencySar,
                            payment.netSalary.toStringAsFixed(2),
                          ),
                          style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          l10n.techNetCash,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.black38,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _detailRow(l10n, l10n.techBasicSalary, payment.basicSalary),
                  _detailRow(
                    l10n,
                    l10n.techOrdersCommission,
                    payment.commissionAmount,
                  ),
                  if (payment.advanceDeduction > 0)
                    _detailRow(
                      l10n,
                      l10n.techAdvanceDeduction,
                      payment.advanceDeduction,
                      isDeduction: true,
                    ),
                  if (payment.penalties > 0)
                    _detailRow(
                      l10n,
                      l10n.techPenalties,
                      payment.penalties,
                      isDeduction: true,
                    ),
                  _detailRow(l10n, l10n.techGrossPayable, payment.grossSalary),
                  _detailRow(
                    l10n,
                    l10n.techTotalDeductions,
                    payment.totalDeductions,
                    isDeduction: true,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    l10n,
                    l10n.techNetPaid,
                    payment.netSalary,
                    emphasize: true,
                  ),
                  if (payment.payFromAccountName?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _infoLine(
                      Icons.account_balance_rounded,
                      l10n.techPaidFrom(payment.payFromAccountName!),
                    ),
                  ],
                  if (payment.method?.trim().isNotEmpty == true)
                    _infoLine(
                      Icons.payment_rounded,
                      l10n.techMethod(payment.method!),
                    ),
                  if (payment.penaltyNotes?.trim().isNotEmpty == true)
                    _infoLine(
                      Icons.warning_amber_rounded,
                      l10n.techPenaltyNote(payment.penaltyNotes!),
                    ),
                  if (payment.notes?.trim().isNotEmpty == true)
                    _infoLine(Icons.notes_rounded, payment.notes!),
                ],
                const SizedBox(height: 10),
                _buildAckSection(context, vm, payment, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    AppLocalizations l10n,
    String label,
    double amount, {
    bool isDeduction = false,
    bool emphasize = false,
  }) {
    final money = l10n.techMoneyAmount(
      l10n.ownerCurrencySar,
      amount.toStringAsFixed(2),
    );
    final value = isDeduction ? '− $money' : money;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: emphasize ? AppColors.secondaryLight : Colors.black54,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              fontSize: emphasize ? 13 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize
                  ? AppColors.secondaryLight
                  : isDeduction
                      ? Colors.red.shade700
                      : AppColors.secondaryLight,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              fontSize: emphasize ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAckSection(
    BuildContext context,
    PosSalariesViewModel vm,
    TechSalaryPayment payment,
    AppLocalizations l10n,
  ) {
    final rejectBusy = vm.isSalaryRejectInFlight(payment.id);
    final acceptBusy = vm.isSalaryAcceptInFlight(payment.id);
    final anyBusy = rejectBusy || acceptBusy;

    if (!payment.isAckPending) {
      final color =
          payment.isAckAccepted ? Colors.green.shade700 : Colors.red.shade700;
      final icon = payment.isAckAccepted
          ? Icons.check_circle_rounded
          : Icons.cancel_rounded;
      final respondedAt = payment.technicianAckAt != null
          ? DateFormat(
              'dd MMM yyyy · hh:mm a',
              Localizations.localeOf(context).toString(),
            ).format(payment.technicianAckAt!)
          : null;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: (payment.isAckAccepted ? Colors.green : Colors.red)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (payment.isAckAccepted ? Colors.green : Colors.red)
                .withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.techYouAckedSalary(
                      payment.isAckAccepted
                          ? l10n.techAckAccepted
                          : l10n.techAckRejected,
                    ),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  if (respondedAt != null)
                    Text(
                      respondedAt,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.45),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: anyBusy
                ? null
                : () => _submitAck(context, vm, payment.id, 'rejected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.secondaryLight,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).merge(
              ButtonStyle(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.transparent;
                  }
                  return null;
                }),
              ),
            ),
            child: rejectBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.techBroadcastReject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: anyBusy
                ? null
                : () => _submitAck(context, vm, payment.id, 'accepted'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.shade600,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).merge(
              ButtonStyle(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.transparent;
                  }
                  return null;
                }),
              ),
            ),
            child: acceptBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.techBroadcastAccept,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAck(
    BuildContext context,
    PosSalariesViewModel vm,
    String paymentId,
    String response,
  ) async {
    final err = await vm.respondToSalaryPayment(
      paymentId,
      response,
      context: context,
    );
    if (!context.mounted) return;
    if (err != null) {
      ToastService.showError(context, err);
    }
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceTransactionCard(
    TechAdvanceTransaction tx,
    AppLocalizations l10n,
  ) {
    final dateLabel = tx.date != null
        ? _advanceDateFormat(context).format(tx.date!)
        : '—';
    final isPlus = tx.isIssued;
    final accent = isPlus ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final money = l10n.techMoneyAmount(
      l10n.ownerCurrencySar,
      tx.amount.toStringAsFixed(2),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPlus ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.title,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                if (tx.description?.trim().isNotEmpty == true &&
                    tx.description!.trim() != tx.title) ...[
                  const SizedBox(height: 3),
                  Text(
                    tx.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  isPlus ? l10n.techAdvanceLabel : l10n.techDeductedLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPlus ? '+' : '−'} $money',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
