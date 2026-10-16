import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../widgets/owner_styled_dropdown.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/add_button_fab.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../../owner_shell.dart';
import 'cash_bank_view_model.dart';
import 'cash_bank_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CashBankView — Cash, Bank & Petty Cash registers
// ─────────────────────────────────────────────────────────────────────────────

class CashBankView extends StatefulWidget {
  const CashBankView({super.key});

  @override
  State<CashBankView> createState() => _CashBankViewState();
}

class _CashBankViewState extends State<CashBankView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabKinds = <RegisterKind?>[
    null,                   // All Accounts
    RegisterKind.cash,
    RegisterKind.bank,
    RegisterKind.pettyCash,
  ];
  static const _tabLabels = ['All Accounts', 'Cash', 'Bank', 'Petty Cash'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabKinds.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashBankViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: const OwnerDashboardTitle(subtitle: 'Cash & Bank'),
            showDrawer: true,
            showNotification: true,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
          ),
          floatingActionButton: AppFabSheetButton<CashBankViewModel>(
            label: 'New Account',
            icon: Icons.add_rounded,
            viewModel: vm,
            onClear: () {},
            sheetBuilder: (ctx, model) => const _NewAccountSheet(),
          ),
          body: Column(
            children: [
              // ── KPI cards — always visible above tabs ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: ReusableKpiGrid(
                  showFeatured: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.7,
                  metrics: [
                    ReusableKpiMetric(
                      title: 'Cash on Hand',
                      value: 'SAR ${vm.cashBalance.toStringAsFixed(0)}',
                      subtitle: '${vm.cashCount} accounts',
                      icon: RegisterKind.cash.icon,
                    ),
                    ReusableKpiMetric(
                      title: 'Bank Balance',
                      value: 'SAR ${vm.bankBalance.toStringAsFixed(0)}',
                      subtitle: '${vm.bankCount} accounts',
                      icon: RegisterKind.bank.icon,
                    ),
                    ReusableKpiMetric(
                      title: 'Petty Cash',
                      value: 'SAR ${vm.pettyCashBalance.toStringAsFixed(0)}',
                      subtitle: '${vm.pettyCashCount} accounts',
                      icon: RegisterKind.pettyCash.icon,
                    ),
                  ],
                ),
              ),

              // ── Tab bar ────────────────────────────────────────────────
              Container(
                color: OwnerUi.scaffoldBackground,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.secondaryLight,
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  tabs: _tabLabels
                      .map((l) => Tab(text: l, height: 42))
                      .toList(),
                ),
              ),

              // ── Tab views ──────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabKinds.map((_) {
                    return _AccountsTabBody(accounts: vm.allAccounts, vm: vm);
                  }).toList(),
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
// _AccountsTabBody — full scrollable content inside every tab
// ─────────────────────────────────────────────────────────────────────────────

class _AccountsTabBody extends StatelessWidget {
  final List<CashBankAccount> accounts;
  final CashBankViewModel vm;

  const _AccountsTabBody({required this.accounts, required this.vm});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: AppColors.primaryLight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Account cards ───────────────────────────────────────────────
          SliverList.separated(
            itemCount: accounts.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AccountCard(account: accounts[i]),
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
          ),

          if (accounts.isEmpty)
            const SliverToBoxAdapter(child: _EmptyAccountsState()),

          // ── Internal fund transfer ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _InternalTransferCard(vm: vm),
            ),
          ),

          // ── Branch defaults ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              child: _BranchDefaultsCard(vm: vm),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AccountCard — register / account row
// ─────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final CashBankAccount account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final isActive = account.status == RegisterStatus.active;
    final statusColor =
    isActive ? const Color(0xFF059669) : const Color(0xFF6B7280);
    final statusBg =
    isActive ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon + name + status ────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(account.type.icon,
                    size: 18, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Badge(
                          label: account.kindLabel,
                          color: const Color(0xFF059669),
                          bg: const Color(0xFFECFDF5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          account.type.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Badge(
                label: account.status.label.toUpperCase(),
                color: statusColor,
                bg: statusBg,
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),

          // ── Detail grid ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DetailItem(label: 'Branch', value: account.branch),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'POS / SoftPOS',
                  value: account.posSoftPos ?? '—',
                ),
              ),
            ],
          ),
          if (account.coaLink != null) ...[
            const SizedBox(height: 8),
            _DetailItem(label: 'COA Link', value: account.coaLink!),
          ],

          const SizedBox(height: 10),

          // ── Balances ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _BalancePill(
                  label: 'Opening Balance',
                  amount: account.openingBalance,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BalancePill(
                  label: 'Current Balance',
                  amount: account.currentBalance,
                  color: AppColors.secondaryLight,
                  highlight: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Edit action ───────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showEditAccountSheet(context, account),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 5),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAccountSheet(BuildContext context, CashBankAccount account) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewAccountSheet(existing: account),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool highlight;

  const _BalancePill({
    required this.label,
    required this.amount,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.secondaryLight.withOpacity(0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.secondaryLight.withOpacity(0.18)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SAR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.secondaryLight : color,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyAccountsState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyAccountsState extends StatelessWidget {
  const _EmptyAccountsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No accounts in this category',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InternalTransferCard — move funds between registers
// ─────────────────────────────────────────────────────────────────────────────

class _InternalTransferCard extends StatelessWidget {
  final CashBankViewModel vm;

  const _InternalTransferCard({required this.vm});

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.transferDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.secondaryLight,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) vm.setTransferDate(picked);
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final accounts = vm.allAccounts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.swap_horiz_rounded,
                    size: 17, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Internal Fund Transfer',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Move SAR between two registers in this workshop.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // From account
          _AccountDropdownField(
            label: 'From Account',
            hint: 'Select source',
            value: vm.transferFrom,
            accounts: accounts,
            onChanged: vm.setTransferFrom,
          ),
          const SizedBox(height: 10),

          // To account
          _AccountDropdownField(
            label: 'To Account',
            hint: 'Select destination',
            value: vm.transferTo,
            accounts: accounts,
            onChanged: vm.setTransferTo,
          ),
          const SizedBox(height: 10),

          // Amount + Date
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Amount (SAR)',
                  child: TextField(
                    controller: vm.transferAmountCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: _fieldDecoration(hint: '0.00'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Date',
                  child: GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 13, color: AppColors.secondaryLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _fmt(vm.transferDate),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Note
          _LabeledField(
            label: 'Note (optional)',
            child: TextField(
              controller: vm.transferNoteCtrl,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              decoration: _fieldDecoration(hint: 'e.g. Cash moved to main safe'),
            ),
          ),

          const SizedBox(height: 14),

          // Transfer button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Wire to transfer service
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Transfer funds',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle:
    TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400, fontSize: 12.5),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _AccountDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<CashBankAccount> accounts;
  final void Function(String?) onChanged;

  const _AccountDropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            hint: Text(
              hint,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: Colors.grey.shade500),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            items: accounts
                .map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BranchDefaultsCard — Branch default operating registers
// ─────────────────────────────────────────────────────────────────────────────

class _BranchDefaultsCard extends StatelessWidget {
  final CashBankViewModel vm;

  const _BranchDefaultsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.push_pin_outlined,
                    size: 16, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Branch Default Registers',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pin the cash & bank register used for POS card sales, '
                          'locker deposits and direct postings per branch.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...vm.branchDefaults.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BranchDefaultRow(
              branchDefaults: b,
              accounts: vm.allAccounts,
              onCashChanged: (id) =>
                  vm.setBranchDefaultCash(b.branch, id),
              onBankChanged: (id) =>
                  vm.setBranchDefaultBank(b.branch, id),
            ),
          )),
        ],
      ),
    );
  }
}

class _BranchDefaultRow extends StatelessWidget {
  final BranchRegisterDefaults branchDefaults;
  final List<CashBankAccount> accounts;
  final void Function(String?) onCashChanged;
  final void Function(String?) onBankChanged;

  const _BranchDefaultRow({
    required this.branchDefaults,
    required this.accounts,
    required this.onCashChanged,
    required this.onBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branchDefaults.branch.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryLight,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          _BranchAccountPicker(
            label: 'Default Cash',
            value: branchDefaults.defaultCashAccountId,
            accounts: accounts,
            onChanged: onCashChanged,
          ),
          const SizedBox(height: 8),
          _BranchAccountPicker(
            label: 'Default Bank',
            value: branchDefaults.defaultBankAccountId,
            accounts: accounts,
            onChanged: onBankChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Persist branch defaults
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryLight,
                side: BorderSide(color: AppColors.secondaryLight.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchAccountPicker extends StatelessWidget {
  final String label;
  final String? value;
  final List<CashBankAccount> accounts;
  final void Function(String?) onChanged;

  const _BranchAccountPicker({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: Colors.grey.shade500),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— None (use fallback) —'),
                ),
                ...accounts.map((a) => DropdownMenuItem<String?>(
                  value: a.id,
                  child: Text(a.name, overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New / Edit Account Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NewAccountSheet extends StatefulWidget {
  final CashBankAccount? existing;

  const _NewAccountSheet({this.existing});

  @override
  State<_NewAccountSheet> createState() => _NewAccountSheetState();
}

class _NewAccountSheetState extends State<_NewAccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _openingBalanceCtrl;
  RegisterKind _selectedType = RegisterKind.cash;
  String _selectedBranch = CashBankDummyData.branches.first;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _openingBalanceCtrl = TextEditingController(
      text: e != null ? e.openingBalance.toStringAsFixed(2) : '',
    );
    if (e != null) {
      _selectedType = e.type;
      _selectedBranch = e.branch;
      _isActive = e.status == RegisterStatus.active;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existing != null;

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
              isEditing ? 'Edit Account' : 'New Account',
              style: AppTextStyles.h3.copyWith(
                fontSize: 17,
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            _SheetTextField(
              controller: _nameCtrl,
              label: 'Account Name',
              hint: 'e.g. Cash On Hand',
            ),
            const SizedBox(height: 12),

            // Opening balance
            _SheetTextField(
              controller: _openingBalanceCtrl,
              label: 'Opening Balance (SAR)',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Register type
            Text(
              'Register Type',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: RegisterKind.values.map((t) {
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
                      t.label,
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

            // Branch
            Text(
              'Branch',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            OwnerStyledDropdown<String>(
              value: _selectedBranch,
              hint: 'Select branch',
              height: 48,
              options: CashBankDummyData.branches
                  .map((b) => OwnerDropdownOption(value: b, label: b))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedBranch = v ?? _selectedBranch),
              triggerStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLight,
              ),
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
                  isEditing ? 'Save Changes' : 'Create Account',
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
  final TextInputType? keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
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
          keyboardType: keyboardType,
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