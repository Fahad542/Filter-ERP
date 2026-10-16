import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import 'billing_management_view_model.dart';
import '../Corporate/corporate_management_view_model.dart';
import '../../../models/workshop_owner_models.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_shimmer.dart';
import '../owner_shell.dart';

class BillingManagementView extends StatefulWidget {
  const BillingManagementView({super.key});

  @override
  State<BillingManagementView> createState() => _BillingManagementViewState();
}

class _BillingManagementViewState extends State<BillingManagementView> {
  int _currentScreen = 0; // 0: Dashboard, 1: Generate, 2: List

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<BillingManagementViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: _getScreenTitle(l10n),
            showGlobalLeft:   _currentScreen == 0,
            showNotification: _currentScreen == 0,
            showDrawer:       false,
            showBackButton:   _currentScreen != 0,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
            onBackPressed: _currentScreen != 0
                ? () => setState(() => _currentScreen = 0)
                : null,
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
          ),
          body: _buildCurrentScreen(l10n, vm),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getScreenTitle(AppLocalizations l10n) {
    switch (_currentScreen) {
      case 0: return l10n.billingDashboardTitle;
      case 1: return l10n.billingGenerateTitle;
      case 2: return l10n.billingMonthlyTitle;
      case 3: return l10n.billingOverdueTitle;
      default: return l10n.billingDefaultTitle;
    }
  }

  Widget _buildCurrentScreen(AppLocalizations l10n, BillingManagementViewModel vm) {
    if (vm.isLoading && _currentScreen == 0) {
      return const OwnerListPageShimmer(showKpi: true, itemCount: 4);
    }
    switch (_currentScreen) {
      case 0: return _buildDashboard(l10n, vm);
      case 1: return _buildGenerator(l10n, vm);
      case 2: return _buildBillsList(l10n, vm);
      default: return _buildDashboard(l10n, vm);
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Widget _buildDashboard(AppLocalizations l10n, BillingManagementViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(l10n, vm),
          const SizedBox(height: 32),
          Text(l10n.billingQuickActions, style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          _buildActionGrid(l10n),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l10n.billingRecentActivity, style: AppTextStyles.h2.copyWith(fontSize: 18)),
              InkWell(
                onTap: () => setState(() => _currentScreen = 2),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  l10n.billingSeeAll,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(l10n, vm, limit: 3),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AppLocalizations l10n, BillingManagementViewModel vm) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard(l10n.billingSummaryTotalBilled,   'SAR ${vm.totalBilledMonth}',   Icons.receipt_rounded,         Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard(l10n.billingSummaryTotalReceived, 'SAR ${vm.totalReceivedMonth}', Icons.payments_rounded,         Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryCard(l10n.billingSummaryOutstanding, 'SAR ${vm.totalOutstanding}', Icons.pending_actions_rounded,  Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard(l10n.billingSummaryOverdue,     'SAR ${vm.overdueAmount}',    Icons.warning_amber_rounded,    Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text(title,  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount:  2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildActionButton(l10n.billingActionGenerate,       Icons.add_circle_outline_rounded,      () => setState(() => _currentScreen = 1)),
        _buildActionButton(l10n.billingActionViewAll,        Icons.list_alt_rounded,                () => setState(() => _currentScreen = 2)),
        _buildActionButton(l10n.billingActionRecordPayment,  Icons.account_balance_wallet_rounded,  () {}),
        _buildActionButton(l10n.billingActionSendReminders,  Icons.notification_important_rounded,  () {}),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
      AppLocalizations l10n,
      BillingManagementViewModel vm, {
        int? limit,
      }) {
    final count = (limit != null && vm.monthlyBills.length > limit)
        ? limit
        : vm.monthlyBills.length;

    if (count == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n.billingNoRecentActivity,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        final bill = vm.monthlyBills[index];

        // Status colour / icon use the raw API status (locale-agnostic enum).
        // Display text uses the pre-translated field from the VM.
        final rawStatus         = bill.status;
        final displayStatus     = bill.translatedStatus ?? bill.status;
        final displayCustomer   = bill.translatedCustomerName ?? bill.customerName;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              // Icon keyed on rawStatus so it never breaks when locale is AR.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(rawStatus).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIconData(rawStatus),
                  color: _getStatusColor(rawStatus),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayCustomer,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.billingPeriodLabel(
                        bill.month.toString(),
                        bill.year.toString(),
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
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
                    'SAR ${bill.totalAmount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(rawStatus).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      // Remove underscores from translated text, then uppercase.
                      displayStatus.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(rawStatus),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Generator ─────────────────────────────────────────────────────────────

  Widget _buildGenerator(AppLocalizations l10n, BillingManagementViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.billingGeneratorStep1,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: 'January 2026',
            items: ['January 2026', 'December 2025']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {},
          ),
          const SizedBox(height: 32),
          Text(l10n.billingGeneratorStep2,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount:
              context.read<CorporateManagementViewModel>().corporateCustomers.length,
              itemBuilder: (context, index) {
                final c = context
                    .read<CorporateManagementViewModel>()
                    .corporateCustomers[index];
                return CheckboxListTile(
                  title: Text(c.companyName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(l10n.billingGeneratorPendingInvoices),
                  value: true,
                  onChanged: (val) {},
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _currentScreen = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.secondaryLight,
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              l10n.billingGeneratorPostAll,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bills list ────────────────────────────────────────────────────────────

  Widget _buildBillsList(AppLocalizations l10n, BillingManagementViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.billingMonthlyTitle, style: AppTextStyles.h2.copyWith(fontSize: 18)),
              DropdownButton<String>(
                value: 'January 2026',
                style: const TextStyle(
                    color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: ['January 2026', 'December 2025']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(l10n, vm),
        ],
      ),
    );
  }

  // ── Status helpers — always keyed on the RAW English status value ─────────
  //
  // The VM stores the original API value in [MonthlyBill.status].
  // Only [translatedStatus] changes with locale. Colour/icon logic always
  // reads the raw field so UI never breaks after a locale switch to Arabic.

  Color _getStatusColor(String rawStatus) {
    switch (rawStatus) {
      case 'Paid':           return Colors.green;
      case 'Overdue':        return Colors.red;
      case 'Partially Paid': return Colors.orange;
      default:               return Colors.blue;
    }
  }

  IconData _getStatusIconData(String rawStatus) {
    switch (rawStatus) {
      case 'Paid':           return Icons.check_rounded;
      case 'Overdue':        return Icons.priority_high_rounded;
      case 'Partially Paid': return Icons.hourglass_bottom_rounded;
      default:               return Icons.receipt_rounded;
    }
  }
}