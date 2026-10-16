import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/technician_advance_model.dart';
import '../../../models/technician_salary_payment_model.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/global_locale_toolbar_icon.dart';
import '../../../widgets/notification_toolbar_icon.dart';
import '../Notifications/notifications_view.dart';
import '../technician_view_model.dart';
import '../widgets/tech_dashboard_filter_bar.dart';
import '../widgets/tech_list_shimmer.dart';

class TechSalariesView extends StatefulWidget {
  const TechSalariesView({super.key});

  @override
  State<TechSalariesView> createState() => _TechSalariesViewState();
}

class _TechSalariesViewState extends State<TechSalariesView>
    with SingleTickerProviderStateMixin {
  DateFormat _paymentDateFormat(BuildContext context) =>
      DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString());
  DateFormat _advanceDateFormat(BuildContext context) =>
      DateFormat(
        'dd MMM yyyy · hh:mm a',
        Localizations.localeOf(context).toString(),
      );
  final Set<String> _expandedIds = {};
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechAppViewModel>().fetchSalaryScreenData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FD),
      child: Consumer<TechAppViewModel>(
        builder: (context, vm, _) {
          final onSalariesTab = _tabController.index == 0;
          final showSalariesBar = onSalariesTab &&
              !vm.isLoadingSalaryPayments &&
              (vm.salaryPaymentsTotalNet > 0 || vm.salaryPayments.isNotEmpty);
          final showAdvancesBar = !onSalariesTab &&
              !vm.isLoadingSalaryAdvances &&
              (vm.salaryAdvancesTotalOutstanding > 0 ||
                  vm.salaryAdvanceTransactions.isNotEmpty ||
                  vm.salaryAdvancesTotalIssued > 0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, vm),
              _buildTabBar(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalariesTab(context, vm),
                    _buildAdvancesTab(context, vm),
                  ],
                ),
              ),
              if (showSalariesBar) _buildTotalReceivedBar(context, vm),
              if (showAdvancesBar) _buildAdvancesSummaryBar(context, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          indicator: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.onPrimaryLight,
          unselectedLabelColor: AppColors.secondaryLight,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: l10n.techSalariesTab),
            Tab(text: l10n.techAdvancesTab),
          ],
        ),
      ),
    );
  }

  Widget _buildSalariesTab(BuildContext context, TechAppViewModel vm) {
    if (vm.isLoadingSalaryPayments) {
      return const TechListCardShimmer();
    }
    return RefreshIndicator(
      color: AppColors.secondaryLight,
      backgroundColor: Colors.white,
      onRefresh: vm.fetchSalaryPayments,
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
                          color: Colors.black.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.techSalariesNoneInRange,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)!.techTryDifferentDateRange,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: vm.salaryPayments.length,
              itemBuilder: (context, index) {
                return _buildSalaryCard(context, vm.salaryPayments[index]);
              },
            ),
    );
  }

  Widget _buildAdvancesTab(BuildContext context, TechAppViewModel vm) {
    if (vm.isLoadingSalaryAdvances) {
      return const TechListCardShimmer();
    }
    final txs = vm.salaryAdvanceTransactions;
    return RefreshIndicator(
      color: AppColors.secondaryLight,
      backgroundColor: Colors.white,
      onRefresh: vm.fetchSalaryAdvances,
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
                          color: Colors.black.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.techAdvancesNoneInRange,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)!.techTryDifferentDateRange,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: txs.length,
              itemBuilder: (context, index) {
                return _buildAdvanceTransactionCard(txs[index]);
              },
            ),
    );
  }

  Widget _buildAdvancesSummaryBar(BuildContext context, TechAppViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final net = vm.salaryAdvancesTotalOutstanding;
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
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
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
                            net.toStringAsFixed(2),
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
                            color: AppColors.onSecondaryLight.withOpacity(0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          l10n.techSelectedDateRange,
                          style: TextStyle(
                            color: AppColors.onSecondaryLight.withOpacity(0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildAdvanceTransactionCard(TechAdvanceTransaction tx) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = tx.date != null
        ? _advanceDateFormat(context).format(tx.date!)
        : '—';
    final isPlus = tx.isIssued;
    final accent = isPlus ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final money = l10n.techMoneyAmount(
      l10n.ownerCurrencySar,
      tx.amount.toStringAsFixed(2),
    );
    final amountLabel = '${isPlus ? '+' : '−'} $money';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accent.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
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
                    color: Colors.black.withOpacity(0.45),
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
            amountLabel,
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

  Widget _buildTotalReceivedBar(BuildContext context, TechAppViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
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
                color: Colors.black.withOpacity(0.12),
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
                  color: Colors.white.withOpacity(0.12),
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
                        color: AppColors.onSecondaryLight.withOpacity(0.72),
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

  Widget _buildHeader(BuildContext context, TechAppViewModel vm) {
    const filterOverlap = 36.0;
    const headerBodyHeight = 112.0;
    final topPad = MediaQuery.paddingOf(context).top;
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context).name == 'rtl';

    return SizedBox(
      height: topPad + headerBodyHeight + filterOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + headerBodyHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 32),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Center(
                      child: Text(
                        l10n.techSalariesTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: _menuButton(context),
                  ),
                  Align(
                    alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GlobalLocaleToolbarIcon(inCluster: true),
                        const SizedBox(width: 6),
                        NotificationToolbarIcon(
                          inCluster: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationsView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: TechDashboardOverlapFilters(
              startDate: vm.salaryScreenFrom,
              endDate: vm.salaryScreenTo,
              onStartDateChanged: vm.applySalaryScreenStartDate,
              onEndDateChanged: vm.applySalaryScreenEndDate,
              dateOnly: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildSalaryCard(BuildContext context, TechSalaryPayment payment) {
    final l10n = AppLocalizations.of(context)!;
    final expanded = _expandedIds.contains(payment.id);
    final paidOn = payment.paymentDate != null
        ? _paymentDateFormat(context).format(payment.paymentDate!)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
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
                              color: Colors.black.withOpacity(0.45),
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
                            color: Colors.black.withOpacity(0.45),
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
                  _detailRow(context, l10n.techBasicSalary, payment.basicSalary),
                  _detailRow(
                    context,
                    l10n.techOrdersCommission,
                    payment.commissionAmount,
                  ),
                  if (payment.advanceDeduction > 0)
                    _detailRow(
                      context,
                      l10n.techAdvanceDeduction,
                      payment.advanceDeduction,
                      isDeduction: true,
                    ),
                  if (payment.penalties > 0)
                    _detailRow(
                      context,
                      l10n.techPenalties,
                      payment.penalties,
                      isDeduction: true,
                    ),
                  _detailRow(context, l10n.techGrossPayable, payment.grossSalary),
                  _detailRow(
                    context,
                    l10n.techTotalDeductions,
                    payment.totalDeductions,
                    isDeduction: true,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    context,
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
                _buildAckSection(context, payment),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    double amount, {
    bool isDeduction = false,
    bool emphasize = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
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

  Widget _buildAckSection(BuildContext context, TechSalaryPayment payment) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.read<TechAppViewModel>();
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
              .withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (payment.isAckAccepted ? Colors.green : Colors.red)
                .withOpacity(0.25),
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
                        color: Colors.black.withOpacity(0.45),
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
                : () => _submitAck(context, payment.id, 'rejected'),
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
                : () => _submitAck(context, payment.id, 'accepted'),
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
    String paymentId,
    String response,
  ) async {
    final vm = context.read<TechAppViewModel>();
    final err = await vm.respondToSalaryPayment(
      paymentId,
      response,
      context: context,
    );
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
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
                color: Colors.black.withOpacity(0.55),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
