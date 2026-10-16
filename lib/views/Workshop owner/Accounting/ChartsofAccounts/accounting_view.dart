import 'package:filter_service_providers/views/Workshop%20owner/Accounting/ChartsofAccounts/profit_loss_tab.dart';
import 'package:filter_service_providers/views/Workshop%20owner/Accounting/ChartsofAccounts/trial_balance_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/repositories/owner_repository.dart';
import '../../../../services/owner_data_service.dart';
import '../../../../services/session_service.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/add_button_fab.dart';
import '../../owner_shell.dart';
import '../accounting_models.dart';
import '../../widgets/owner_segmented_tabs.dart';
import 'accounting_view_model.dart';
import 'balance_sheet_tab.dart';
import 'chart_of_accounts_tab.dart';
import 'profit_loss_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AccountingView — Main screen
// Tabs: Chart of Accounts | Trial Balance | P&L | Balance Sheet
// ─────────────────────────────────────────────────────────────────────────────

class AccountingView extends StatefulWidget {
  const AccountingView({super.key});

  @override
  State<AccountingView> createState() => _AccountingViewState();
}

class _AccountingViewState extends State<AccountingView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _TabMeta(label: 'Accounts', icon: Icons.list_alt_rounded),
    _TabMeta(label: 'Trial Bal.', icon: Icons.balance_rounded),
    _TabMeta(label: 'P&L', icon: Icons.trending_up_rounded),
    _TabMeta(label: 'Balance Sheet', icon: Icons.account_balance_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<AccountingViewModel>().setTab(_tabController.index);
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
    return Consumer<AccountingViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: const OwnerDashboardTitle(subtitle: 'Accounting'),
            showBackButton: false,
            showNotification: true,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
            onMenuPressed: () => OwnerShell.openDrawer(context),
          ),

          // ── FAB: only show on Chart of Accounts tab ───────────────────
          floatingActionButton: vm.selectedTab == 0
              ? FloatingActionButton.extended(
            onPressed: () => _showNewAccountSheet(context),
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.secondaryLight,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'New Account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          )
              : null,

          body: Column(
            children: [
              // ── Tab bar ────────────────────────────────────────────────
              _AccountingTabBar(controller: _tabController),

              // ── Tab views ──────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.refresh,
                  color: AppColors.primaryLight,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Builder(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: context.read<AccountingViewModel>(),
                          child: const ChartOfAccountsTab(),
                        ),
                      ),
                      Builder(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: context.read<AccountingViewModel>(),
                          child: const TrialBalanceTab(),
                        ),
                      ),
                      Builder(
                        builder: (context) => ChangeNotifierProvider(
                          create: (ctx) => ProfitLossViewModel(
                            ownerRepository: ctx.read<OwnerRepository>(),
                            sessionService: ctx.read<SessionService>(),
                            ownerDataService: ctx.read<OwnerDataService>(),
                          ),
                          child: const ProfitAndLossTab(),
                        ),
                      ),
                      Builder(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: context.read<AccountingViewModel>(),
                          child: const BalanceSheetTab(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNewAccountSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewAccountSheet(),
    );
  }
}

// ─── Tab Meta ─────────────────────────────────────────────────────────────────

class _TabMeta {
  final String label;
  final IconData icon;
  const _TabMeta({required this.label, required this.icon});
}

// ─────────────────────────────────────────────────────────────────────────────
// AccountingTabBar
// Styled to match app design — dark pill tabs on light background
// ─────────────────────────────────────────────────────────────────────────────

class _AccountingTabBar extends StatelessWidget {
  final TabController controller;
  const _AccountingTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return OwnerSegmentedTabs(
      controller: controller,
      tabs: const [
        'Chart of Accounts',
        'Trial Balance',
        'P&L',
        'Balance Sheet',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Account Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NewAccountSheet extends StatefulWidget {
  const _NewAccountSheet();

  @override
  State<_NewAccountSheet> createState() => _NewAccountSheetState();
}

class _NewAccountSheetState extends State<_NewAccountSheet> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  AccountType _selectedType = AccountType.assets;
  String _normalBalance = 'Debit';
  bool _isActive = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'New Account',
              style: AppTextStyles.h3.copyWith(
                fontSize: 17,
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            // Code
            _SheetTextField(
                controller: _codeCtrl, label: 'Account Code', hint: 'e.g. 1000'),
            const SizedBox(height: 12),

            // Name
            _SheetTextField(
                controller: _nameCtrl,
                label: 'Account Name',
                hint: 'e.g. Cash on Hand'),
            const SizedBox(height: 12),

            // Description
            _SheetTextField(
              controller: _descCtrl,
              label: 'Description (optional)',
              hint: 'Brief description…',
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Type
            Text(
              'Account Type',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AccountType.values.map((t) {
                final labels = {
                  AccountType.assets: 'Assets',
                  AccountType.liabilities: 'Liabilities',
                  AccountType.equity: 'Equity',
                  AccountType.revenue: 'Revenue',
                  AccountType.expenses: 'Expenses',
                };
                final isSelected = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondaryLight
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondaryLight
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      labels[t]!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primaryLight
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Normal balance
            Text(
              'Normal Balance',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['Debit', 'Credit'].map((val) {
                final isSelected = _normalBalance == val;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _normalBalance = val),
                    child: Container(
                      margin: val == 'Credit'
                          ? const EdgeInsets.only(left: 6)
                          : EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondaryLight
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          val,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primaryLight
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Active toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight),
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: AppColors.primaryLight,
                  activeTrackColor: AppColors.secondaryLight,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}