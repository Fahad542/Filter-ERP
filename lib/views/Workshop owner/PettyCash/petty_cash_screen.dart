import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../widgets/add_button_fab.dart';
import 'petty_cash_employee_statement_sheet.dart';
import 'petty_cash_report_tab.dart';
import 'petty_cash_view_model.dart';
import '../widgets/owner_global_date_filters.dart';

export 'petty_cash_view_model.dart' show StaffWallet, StaffRequest, WalletEntry;

// ─── FAB Form ViewModel (lightweight, just holds form state for the sheet) ────

class _PettyCashFormVm extends ChangeNotifier {
  StaffWallet? selectedStaff;
  String? selectedBranch;
  String? selectedAccount;
  String amount = '';
  String note = '';

  void clear() {
    selectedStaff = null;
    selectedBranch = null;
    selectedAccount = null;
    amount = '';
    note = '';
    notifyListeners();
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({super.key});

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _fabVm = _PettyCashFormVm();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      setState(() {});
      if (_tabController.index == 2) {
        context.read<PettyCashViewModel>().ensureReportLoaded();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PettyCashViewModel>().syncWithSelectedBranch(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : OwnerUi.scaffoldBackground;
    final vm = context.watch<PettyCashViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bg,
      appBar: OwnerAppBar(
        title: l10n.ownerPettyCashTitle,
        showDrawer: true,
        bottomOverlap: _tabController.index == 2
            ? const OwnerGlobalDateOverlapFilters(dateOnly: true)
            : null,
      ),
      body: Column(
        children: [
          if (_tabController.index == 2)
            buildPettyCashReportKpiSection(context, vm)
          else
            _buildKpiSection(context, vm, l10n),
          if (vm.error != null && vm.error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                vm.error!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: _buildTabBar(l10n),
          ),
          Expanded(
            child: vm.isLoading &&
                    vm.wallets.isEmpty &&
                    vm.requests.isEmpty &&
                    _tabController.index != 2
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWalletsTab(vm, l10n),
                      _buildRequestsTab(vm, l10n),
                      const PettyCashReportTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? null
          : AppFabSheetButton<_PettyCashFormVm>(
              label: l10n.ownerPettyCashIssueButton,
              icon: Icons.add_rounded,
              viewModel: _fabVm,
              onClear: _fabVm.clear,
              sheetBuilder: (ctx, formVm) => _IssuePettyCashSheet(
                pettyCashVm: ctx.read<PettyCashViewModel>(),
              ),
            ),
    );
  }

  Widget _buildKpiSection(
    BuildContext context,
    PettyCashViewModel vm,
    AppLocalizations l10n,
  ) {
    return ReusableKpiGrid.owner(
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerPettyCashKpiTotalFloat,
          value: ownerFormatMoney(context, vm.totalFloat),
          subtitle: l10n.ownerPettyCashKpiTotalFloatSubtitle(vm.wallets.length),
          icon: Icons.account_balance_wallet_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.ownerPettyCashKpiPendingRequests,
          value: ownerFormatMoney(context, vm.pendingAmount),
          subtitle: l10n.ownerPettyCashKpiPendingRequestsSubtitle(vm.pendingCount),
          icon: Icons.pending_actions_rounded,
        ),
      ],
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return OwnerSegmentedTabs(
      controller: _tabController,
      tabs: [
        l10n.ownerPettyCashTabWallets,
        l10n.ownerPettyCashTabRequests,
        l10n.ownerPettyCashTabReport,
      ],
      layout: PosSegmentedTabLayout.expanded,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    );
  }

  Widget _buildWalletsTab(PettyCashViewModel vm, AppLocalizations l10n) {
    final wallets = vm.wallets;
    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.fetchAll(),
      child: wallets.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                _EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.ownerPettyCashEmptyWallets,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: wallets.length,
              itemBuilder: (ctx, i) => _WalletCard(
                wallet: wallets[i],
                onTap: () => _showWalletRegisterDialog(context, wallets[i]),
              ),
            ),
    );
  }

  Widget _buildRequestsTab(PettyCashViewModel vm, AppLocalizations l10n) {
    final requests = vm.requests;
    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.fetchAll(),
      child: requests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                _EmptyState(
                  icon: Icons.inbox_outlined,
                  label: l10n.ownerPettyCashEmptyRequests,
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: requests.length,
              itemBuilder: (ctx, i) => _RequestCard(
                request: requests[i],
                onTap: () => showPettyCashEmployeeStatementSheet(
                  context,
                  request: requests[i],
                ),
              ),
            ),
    );
  }

  void _showWalletRegisterDialog(BuildContext context, StaffWallet wallet) {
    showDialog(
      context: context,
      builder: (_) => _WalletRegisterDialog(wallet: wallet),
    );
  }
}

// ─── Wallet Card ──────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final StaffWallet wallet;
  final VoidCallback onTap;

  const _WalletCard({required this.wallet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: OwnerListStyle.cardRadius,
          child: InkWell(
            borderRadius: OwnerListStyle.cardRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: DecoratedBox(
                      decoration: OwnerListStyle.iconBoxDecoration,
                      child: Center(
                        child: Text(
                          wallet.name.isNotEmpty
                              ? wallet.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.displayName,
                          style: OwnerListStyle.titleStyle
                              .copyWith(fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ownerFormatMoney(context, wallet.balance),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _PcMetaLine(
                          icon: Icons.badge_outlined,
                          text: wallet.displayRole,
                        ),
                        _PcMetaLine(
                          icon: Icons.store_outlined,
                          text: wallet.displayBranch,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final StaffRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  static Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return Colors.red;
      case 'pending':
        return AppColors.secondaryLight;
      default:
        return OwnerListStyle.mutedText;
    }
  }

  static Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0x1A43A047);
      case 'rejected':
        return const Color(0x14F44336);
      case 'pending':
        return const Color(0x38FCC247);
      default:
        return OwnerListStyle.actionBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final displayStatus = request.displayStatus;
    final statusLabel = displayStatus.isEmpty
        ? '—'
        : displayStatus[0].toUpperCase() + displayStatus.substring(1).toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: OwnerListStyle.cardRadius,
          child: InkWell(
            borderRadius: OwnerListStyle.cardRadius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: DecoratedBox(
                      decoration: OwnerListStyle.iconBoxDecoration,
                      child: const Icon(
                        Icons.request_page_rounded,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.displayStaffName,
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusBg(status),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: _statusFg(status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.displayType,
                          style: OwnerListStyle.subtitleStyle
                              .copyWith(fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ownerFormatMoney(context, request.amount),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _PcMetaLine(
                          icon: Icons.store_outlined,
                          text: request.displayBranch,
                        ),
                        _PcMetaLine(
                          icon: Icons.access_time_rounded,
                          text:
                              '${request.date.day.toString().padLeft(2, "0")}/'
                              '${request.date.month.toString().padLeft(2, "0")}/'
                              '${request.date.year}',
                        ),
                        _PcMetaLine(
                          icon: Icons.account_balance_outlined,
                          text: request.displayPayFrom,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PcMetaLine extends StatelessWidget {
  const _PcMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: OwnerListStyle.mutedText),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuePettyCashSheet extends StatefulWidget {
  final PettyCashViewModel pettyCashVm;

  const _IssuePettyCashSheet({required this.pettyCashVm});

  @override
  State<_IssuePettyCashSheet> createState() => _IssuePettyCashSheetState();
}

class _IssuePettyCashSheetState extends State<_IssuePettyCashSheet> {
  IssuanceTarget? _selectedStaff;
  String? _selectedBranchId;
  CashBankPayFromOption? _selectedAccount;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loadingForm = true;
  bool _submitting = false;
  String? _formError;

  PettyCashViewModel get _vm => widget.pettyCashVm;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingForm = true;
      _formError = null;
    });
    try {
      await _vm.ensureIssueFormData(force: true);
      if (!mounted) return;
      setState(() => _loadingForm = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingForm = false;
        _formError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final amt = double.tryParse(_amountCtrl.text.trim());
    return !_submitting &&
        !_loadingForm &&
        _selectedStaff != null &&
        _selectedBranchId != null &&
        _selectedBranchId!.isNotEmpty &&
        _selectedAccount != null &&
        amt != null &&
        amt >= 0.01;
  }

  void _onStaffChanged(IssuanceTarget? v) {
    setState(() {
      _selectedStaff = v;
      if (v?.branchId != null && v!.branchId!.isNotEmpty) {
        _selectedBranchId = v.branchId;
      }
      _formError = null;
    });
  }

  Future<void> _onSubmit() async {
    if (!_canSubmit || _submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt < 0.01) {
      setState(() => _formError = l10n.ownerPettyCashEnterValidAmount);
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final msg = await _vm.issuePettyCash(
        userId: _selectedStaff!.id,
        branchId: _selectedBranchId!,
        amount: amt,
        payFromAccountId: _selectedAccount!.id,
        description: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l10n.ownerPettyCashIssuedDefault : msg)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final branches = _vm.branchOptions;
    final targets = _vm.issuanceTargets;
    final accounts = _vm.cashBankAccounts;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ownerPettyCashIssueButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loadingForm)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            )
          else ...[
            if (_formError != null) ...[
              Text(
                _formError!,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _DialogDropdown<IssuanceTarget>(
              label: l10n.ownerPettyCashStaffMemberLabel,
              hint: targets.isEmpty
                  ? l10n.ownerPettyCashNoStaffAvailable
                  : l10n.ownerPettyCashSelectStaffHint,
              value: _selectedStaff,
              items: targets,
              itemLabel: (w) => w.displayName,
              onChanged: _onStaffChanged,
            ),
            const SizedBox(height: 12),
            _DialogDropdown<String>(
              label: l10n.ownerPettyCashBranchLabel,
              hint: branches.isEmpty
                  ? l10n.ownerPettyCashNoBranches
                  : l10n.ownerPettyCashSelectBranchHint,
              value: _selectedBranchId,
              items: branches.map((e) => e.key).toList(),
              itemLabel: (id) {
                for (final b in branches) {
                  if (b.key == id) return b.value;
                }
                return id;
              },
              onChanged: (v) => setState(() {
                _selectedBranchId = v;
                _formError = null;
              }),
            ),
            const SizedBox(height: 12),
            _DialogTextField(
              label: l10n.ownerPettyCashAmountLabel,
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hint: '0.00',
            ),
            const SizedBox(height: 12),
            _DialogDropdown<CashBankPayFromOption>(
              label: l10n.ownerPettyCashPayFromLabel,
              hint: accounts.isEmpty
                  ? l10n.ownerPettyCashNoAccounts
                  : l10n.ownerPettyCashSelectAccountHint,
              value: _selectedAccount,
              items: accounts,
              itemLabel: (a) => a.displayLabel,
              onChanged: (v) => setState(() {
                _selectedAccount = v;
                _formError = null;
              }),
            ),
            const SizedBox(height: 12),
            _DialogTextField(
              label: l10n.ownerPettyCashNoteLabel,
              controller: _noteCtrl,
              hint: l10n.ownerPettyCashNoteHint,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  disabledBackgroundColor:
                      AppColors.secondaryLight.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _submitting ? l10n.ownerPettyCashIssuing : l10n.ownerPettyCashIssueNow,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: Text(
                  l10n.ownerPettyCashCancel,
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Wallet Register Dialog ────────────────────────────────────────────────────

class _WalletRegisterDialog extends StatelessWidget {
  final StaffWallet wallet;
  // In real app, pass wallet entries list
  final List<WalletEntry> entries;

  const _WalletRegisterDialog({
    required this.wallet,
    this.entries = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.ownerPettyCashRegisterDialogTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.secondaryLight)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(wallet.displayName,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.secondaryLight)),
            const SizedBox(height: 2),
            Text(l10n.ownerPettyCashStaffBranchLabel(wallet.displayBranch),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.ownerPettyCashCurrentBalance,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        ownerFormatMoney(context, wallet.balance),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight),
                      ),
                      Text(l10n.ownerPettyCashWalletTag,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.ownerPettyCashRegisterSectionTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.secondaryLight)),
            const SizedBox(height: 12),
            entries.isEmpty
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined,
                    size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  l10n.ownerPettyCashNoRegisterEntries,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.5),
                ),
              ]),
            )
                : Column(
              children: entries
                  .map((e) => _WalletEntryCard(entry: e))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _WalletEntryCard extends StatelessWidget {
  final WalletEntry entry;
  const _WalletEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTopup = entry.type.toLowerCase().contains('top');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (isTopup ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isTopup ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 18,
              color: isTopup ? Colors.green.shade600 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year} · ${entry.source}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '${isTopup ? '+' : '-'}${ownerFormatMoney(context, entry.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isTopup ? Colors.green.shade600 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _DialogDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DialogDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
                color: value != null
                    ? AppColors.primaryLight
                    : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(hint,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLight),
            items: items
                .map((item) => DropdownMenuItem<T>(
                value: item, child: Text(itemLabel(item))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hint;

  const _DialogTextField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.hint = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}