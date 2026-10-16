// ════════════════════════════════════════════════════════════════════════════
// owner_shell.dart  —  updated to include Branches (index 1) and
//                      Petty Cash (index 21)
//
// Changes from previous version:
//   • Added _PettyCashTab wrapper (index 21)
//   • Added petty_cash_screen.dart import
//   • Added goToBranches() static helper
//   • Added goToPettyCash() static helper
//   • Added drawer items for Branches and Petty Cash
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_colors.dart';
import 'widgets/owner_shimmer.dart';
import '../Workshop owner/Suppliers/non_affiliated/non_affiliated_suppliers_view.dart';
import '../Workshop owner/Suppliers/affiliated_suppliers_view_model.dart';
import '../Workshop owner/Suppliers/filter_affiliated_suppliers_view.dart';
import '../Workshop owner/SuppliersAndPurchases/suppliers_view.dart';
import '../Workshop owner/SuppliersAndPurchases/suppliers_view_model.dart';
import 'Accounting/Advances/employee_salary_advances_view.dart';
import 'Accounting/ApprovalLimits/approval_limits_screen.dart';
import 'Accounting/CashandBank/cash_bank_view.dart';
import 'Accounting/CashandBank/cash_bank_view_model.dart';
import 'Accounting/ChartsofAccounts/accounting_view.dart';
import 'Accounting/ChartsofAccounts/accounting_view_model.dart';
import 'Accounting/ChartsofAccounts/coa_expenses_view.dart';
import 'Accounting/ChartsofAccounts/profit_loss_view.dart';
import 'Accounting/Expenses/expenses_view.dart';
import 'Accounting/Payments/payments_view.dart';
import 'Accounting/Payroll/payroll_run_screen.dart';
import 'Accounting/Receipts/receipts_view.dart';
import 'Approvals/approvals_view.dart';
import 'Approvals/approvals_view_model.dart';
import 'Dashboard/owner_dashboard_view.dart';
import 'Dashboard/owner_dashboard_view_model.dart';
import 'Branches/branch_management_view.dart';
import 'Branches/branch_management_view_model.dart';
import 'Departments/branch_catalog_view.dart';
import 'Discount/discounts_view.dart';
import 'Discount/discounts_view_model.dart';
import 'LockerManagement/locker_management_view.dart';
import 'LockerManagement/locker_management_view_model.dart';
import 'MasterCatalog/master_catalog_view.dart';
import 'Employees/employee_management_view.dart';
import 'Employees/employee_management_view_model.dart';
import 'Corporate/corporate_management_view.dart';
import 'Corporate/corporate_management_view_model.dart';
import 'Inventory/inventory_management_view.dart';
import 'Billing/billing_management_screen.dart';
import 'Billing/billing_management_view_model.dart';
import 'Reports/reports_management_view.dart';
import 'Reports/reports_management_view_model.dart';
import 'POS Monitoring/pos_monitoring_view.dart';
import 'POS Monitoring/pos_monitoring_view_model.dart';
import 'SalesReturn/sales_returns_view.dart';
import 'SalesReturn/sales_returns_view_model.dart';
import 'Promo/owner_promo_view.dart';
import 'Promo/owner_promo_view_model.dart';
import 'Notifications/owner_notifications_view.dart';
import 'Settings/owner_settings_view.dart';
import 'widgets/owner_bottom_bar.dart';
import 'widgets/owner_branch_reload_registrar.dart';
import 'widgets/owner_ui_constants.dart';
import '../../services/session_service.dart';
import '../../data/repositories/owner_repository.dart';
import '../../services/owner_data_service.dart';
import '../../utils/restart_widget.dart';
import '../Workshop pos app/More Tab/settings_view_model.dart';
// ── NEW ──────────────────────────────────────────────────────────────────────
import 'PurchaseInvoices/purchase_invoices_view.dart';
import 'PurchaseInvoices/purchase_invoices_view_model.dart';
import 'PettyCash/petty_cash_screen.dart';
import 'PettyCash/petty_cash_view_model.dart';
import 'Commission/commission_screen.dart';
import 'Commission/commission_view_model.dart';
import 'Accounting/GeneralJournal/general_journal_view.dart';
import 'Accounting/TransactionEntry/transaction_entry_view.dart';
import 'Accounting/TransactionEntry/transaction_entry_view_model.dart';
// ── NEW: Ledger, Salary Advances, Payroll Run, Approval Limits ─────────────
import 'Accounting/Ledger/ledger_view.dart';

// =============================================================================
// Scoped-provider wrapper widgets
// =============================================================================

class _BranchesTab extends StatelessWidget {
  const _BranchesTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => BranchManagementViewModel(
      ownerRepository:   ctx.read<OwnerRepository>(),
      sessionService:    ctx.read<SessionService>(),
      ownerDataService:  ctx.read<OwnerDataService>(),
      settingsViewModel: ctx.read<SettingsViewModel>(),
    ),
    child: const BranchManagementView(),
  );
}


class _CorporateManagementTab extends StatelessWidget {
  const _CorporateManagementTab();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => CorporateManagementViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService: ctx.read<SessionService>(),
    ),
    child: const CorporateManagementView(),
  );
}

class _BillingTab extends StatelessWidget {
  const _BillingTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => BillingManagementViewModel(
      ownerRepository:   ctx.read<OwnerRepository>(),
      sessionService:    ctx.read<SessionService>(),
      settingsViewModel: ctx.read<SettingsViewModel>(),
    ),
    child: const BillingManagementView(),
  );
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => ReportsManagementViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService:  ctx.read<SessionService>(),
      ownerDataService: ctx.read<OwnerDataService>(),
    ),
    child: OwnerBranchReloadRegistrar(
      tabIndex: 5,
      onReload: (ctx) =>
          ctx.read<ReportsManagementViewModel>().syncWithSelectedBranch(),
      child: const ReportsManagementView(),
    ),
  );
}

class _SuppliersTab extends StatelessWidget {
  const _SuppliersTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => SuppliersViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService:  ctx.read<SessionService>(),
    ),
    child: const SuppliersView(),
  );
}

class _AccountingTab extends StatelessWidget {
  const _AccountingTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AccountingViewModel(),
    child: const AccountingView(),
  );
}

class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => ApprovalsViewModel(
      ownerRepository:   ctx.read<OwnerRepository>(),
      sessionService:    ctx.read<SessionService>(),
      settingsViewModel: ctx.read<SettingsViewModel>(),
      ownerDataService:  ctx.read<OwnerDataService>(),
    ),
    child: OwnerBranchReloadRegistrar(
      tabIndex: 10,
      onReload: (ctx) =>
          ctx.read<ApprovalsViewModel>().syncWithSelectedBranch(),
      child: const ApprovalsView(),
    ),
  );
}

class _SalesReturnsTab extends StatelessWidget {
  const _SalesReturnsTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => SalesReturnsViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService:  ctx.read<SessionService>(),
      ownerDataService: ctx.read<OwnerDataService>(),
      settingsViewModel: ctx.read<SettingsViewModel>(),
    ),
    child: OwnerBranchReloadRegistrar(
      tabIndex: 16,
      onReload: (ctx) =>
          ctx.read<SalesReturnsViewModel>().syncWithSelectedBranch(),
      child: const SalesReturnsView(),
    ),
  );
}

class _DiscountsTab extends StatelessWidget {
  const _DiscountsTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (ctx) => DiscountsViewModel(
          ownerRepository: ctx.read<OwnerRepository>(),
          sessionService: ctx.read<SessionService>(),
          ownerDataService: ctx.read<OwnerDataService>(),
        ),
        child: OwnerBranchReloadRegistrar(
          tabIndex: 17,
          onReload: (ctx) =>
              ctx.read<DiscountsViewModel>().syncWithSelectedBranch(),
          child: const DiscountsView(),
        ),
      );
}

// ── NEW ───────────────────────────────────────────────────────────────────────
// PurchaseInvoicesTab is lightweight — the ViewModel uses dummy data and
// requires no repository injection. When you wire up a real API, add the
// repository/sessionService params here exactly as the other tabs do above.
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseInvoicesTab extends StatelessWidget {
  const _PurchaseInvoicesTab();

  @override
  Widget build(BuildContext context) {
    final repository = context.read<OwnerRepository>();
    final sessionService = context.read<SessionService>();
    final ownerData = context.read<OwnerDataService>();

    return ChangeNotifierProvider(
      create: (_) => PurchaseInvoicesViewModel(
        repository: repository,
        sessionService: sessionService,
        ownerDataService: ownerData,
      ),
      child: OwnerBranchReloadRegistrar(
        tabIndex: 18,
        onReload: (ctx) =>
            ctx.read<PurchaseInvoicesViewModel>().syncWithSelectedBranch(),
        child: const PurchaseInvoicesView(),
      ),
    );
  }
}

// ── NEW ───────────────────────────────────────────────────────────────────────
// InventoryManagementV2 is self-contained — it creates its own ViewModel
// internally, so no scoped-provider wrapper is needed here.
// ─────────────────────────────────────────────────────────────────────────────
class _InventoryV2Tab extends StatelessWidget {
  const _InventoryV2Tab();
  @override
  Widget build(BuildContext context) => const InventoryManagementV2();
}


class _AffiliatedSuppliersTab extends StatelessWidget {
  const _AffiliatedSuppliersTab();

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (ctx) => AffiliatedSuppliersViewModel(
          repository: AffiliatedSuppliersRepository(),
          sessionService: ctx.read<SessionService>(),
          ownerDataService: ctx.read<OwnerDataService>(),
        ),
        child: OwnerBranchReloadRegistrar(
          tabIndex: 20,
          onReload: (ctx) =>
              ctx.read<AffiliatedSuppliersViewModel>().syncWithSelectedBranch(),
          child: Builder(
            builder: (ctx) => FilterAffiliatedSuppliersView(
              viewModel: ctx.watch<AffiliatedSuppliersViewModel>(),
            ),
          ),
        ),
      );
}

class _NonAffiliatedSuppliersTab extends StatefulWidget {
  const _NonAffiliatedSuppliersTab();

  @override
  State<_NonAffiliatedSuppliersTab> createState() =>
      _NonAffiliatedSuppliersTabState();
}

class _NonAffiliatedSuppliersTabState extends State<_NonAffiliatedSuppliersTab> {
  String? _branchId;
  bool _branchReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_branchReady) {
      _branchId = context.read<OwnerDataService>().selectedBranchId;
      _branchReady = true;
    }
  }

  Future<void> _syncWithSelectedBranch() async {
    final next = context.read<OwnerDataService>().selectedBranchId;
    if (!mounted) return;
    setState(() => _branchId = next);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionService>();
    return OwnerBranchReloadRegistrar(
      tabIndex: 21,
      onReload: (_) => _syncWithSelectedBranch(),
      child: FutureBuilder<String?>(
        future: session.getToken(role: 'owner'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const OwnerListPageShimmer(itemCount: 5);
          }
          final token = snapshot.data;
          if (token == null) {
            return const Center(
              child: Text('Session expired. Please log in again.'),
            );
          }
          return NonAffiliatedSuppliersView(
            key: ValueKey('non-aff-$_branchId'),
            token: token,
            defaultBranchId: _branchId,
            branchId: _branchId,
          );
        },
      ),
    );
  }
}

class _PettyCashTab extends StatelessWidget {
  const _PettyCashTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (ctx) => PettyCashViewModel(
          ownerRepository: ctx.read<OwnerRepository>(),
          sessionService: ctx.read<SessionService>(),
          ownerDataService: ctx.read<OwnerDataService>(),
          settingsViewModel: ctx.read<SettingsViewModel>(),
        ),
        child: OwnerBranchReloadRegistrar(
          tabIndex: 22,
          onReload: (ctx) =>
              ctx.read<PettyCashViewModel>().syncWithSelectedBranch(),
          child: const PettyCashScreen(),
        ),
      );
}

class _CommissionTab extends StatelessWidget {
  const _CommissionTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => CommissionViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService: ctx.read<SessionService>(),
      ownerDataService: ctx.read<OwnerDataService>(),
    ),
    child: OwnerBranchReloadRegistrar(
      tabIndex: 24,
      onReload: (ctx) =>
          ctx.read<CommissionViewModel>().syncWithSelectedBranch(),
      child: const CommissionScreen(),
    ),
  );
}

class _CashBankTab extends StatelessWidget {
  const _CashBankTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CashBankViewModel(),
    child: const CashBankView(),
  );
}

class _GeneralJournalTab extends StatelessWidget {
  const _GeneralJournalTab();
  @override
  Widget build(BuildContext context) => const GeneralJournalView();
}

class _TransactionEntryTab extends StatelessWidget {
  const _TransactionEntryTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => TransactionEntryViewModel(),
    child: const TransactionEntryView(),
  );
}

class _PosMonitoringTab extends StatelessWidget {
  const _PosMonitoringTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => PosMonitoringViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService:  ctx.read<SessionService>(),
      ownerDataService: ctx.read<OwnerDataService>(),
      settingsViewModel: ctx.read<SettingsViewModel>(),
    ),
    child: OwnerBranchReloadRegistrar(
      tabIndex: 7,
      onReload: (ctx) =>
          ctx.read<PosMonitoringViewModel>().syncWithSelectedBranch(),
      child: const PosMonitoringView(),
    ),
  );
}

class _LockerManagementTab extends StatelessWidget {
  const _LockerManagementTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => LockerManagementViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService:  ctx.read<SessionService>(),
    ),
    child: const LockerManagementView(),
  );
}

class _PromoTab extends StatelessWidget {
  const _PromoTab();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (ctx) => OwnerPromoViewModel(
      ownerRepository: ctx.read<OwnerRepository>(),
      sessionService:  ctx.read<SessionService>(),
    ),
    child: const OwnerPromoView(),
  );
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();
  @override
  Widget build(BuildContext context) => const ExpensesView();
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();
  @override
  Widget build(BuildContext context) => const PaymentsView();
}

class _ReceiptsTab extends StatelessWidget {
  const _ReceiptsTab();
  @override
  Widget build(BuildContext context) => const ReceiptsView();
}

// ── NEW ───────────────────────────────────────────────────────────────────────
// LedgerTab, SalaryAdvancesTab, PayrollRunTab, ApprovalLimitsTab — all four are
// self-contained StatefulWidgets with no required constructor params and no
// Provider/ChangeNotifier dependency, so (like MasterCatalogView /
// EmployeeManagementView above) they're used directly with no scoped-provider
// wrapper needed.
// ─────────────────────────────────────────────────────────────────────────────

// =============================================================================
// OwnerShell
// =============================================================================

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  static void goHome(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    if (state != null) {
      state.goHome();
    } else {
      Navigator.maybePop(context);
    }
  }

  static void goToNotifications(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(11, withBack: true);
  }

  static void goToApprovals(BuildContext context, {bool withBack = false}) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(10, withBack: withBack);
  }

  static void goToMasterCatalog(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(15);
  }

  static void goToSalesReturns(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(16);
  }

  static void goToDiscount(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(17);
  }

  static void goToCorporateManagement(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(3);
  }

  static void goToSuppliers(BuildContext context, {bool withBack = false}) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(8, withBack: withBack);
  }

  /// Whether the current shell tab was opened with a back affordance
  /// (Quick Actions / deep link) instead of the drawer.
  static bool openedWithBack(BuildContext context) {
    return context.findAncestorStateOfType<OwnerShellState>()?.openedWithBack ??
        false;
  }

  // ── NEW ────────────────────────────────────────────────────────────────────
  static void goToPurchaseInvoices(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(18);
  }
  // ──────────────────────────────────────────────────────────────────────────

  // ── NEW ────────────────────────────────────────────────────────────────────
  static void goToInventoryManagement(
    BuildContext context, {
    bool withBack = false,
    bool lowStockOnly = false,
  }) {
    if (lowStockOnly) {
      InventoryManagementV2.pendingLowStockOnly = true;
    }
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(19, withBack: withBack);
  }

  static void goToAffiliatedSuppliers(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(20);
  }

  static void goToNonAffiliatedSuppliers(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(21);
  }

  static void goToBranches(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(1);
  }

  static void goToPettyCash(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(22);
  }

  static void goToCommission(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(24);
  }

  static void goToLockerManagement(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(23);
  }

  static void goToCashBank(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(25);
  }
  // ──────────────────────────────────────────────────────────────────────────

  static void goToGeneralJournal(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(26);
  }

  static void goToTransactionEntry(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(27);
  }

  static void goToExpenses(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(28);
  }

  static void goToPayments(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(29);
  }

  static void goToReceipts(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(30);
  }

  // ── NEW ────────────────────────────────────────────────────────────────────
  static void goToLedger(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(31);
  }

  static void goToSalaryAdvances(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(32);
  }

  static void goToPayrollRun(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(33);
  }

  static void goToApprovalLimits(BuildContext context) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(34);
  }

  static void goToPnL(BuildContext context, {bool withBack = false}) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(35, withBack: withBack);
  }

  static void goToCoaExpenses(BuildContext context, {bool withBack = false}) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(36, withBack: withBack);
  }
  // ──────────────────────────────────────────────────────────────────────────

  static void goToTab(BuildContext context, int index,
      {bool withBack = false}) {
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?.goToIndex(index, withBack: withBack);
  }

  static void openDrawer(BuildContext context) {
    // Try static key first (always works regardless of context position)
    if (OwnerShellState.scaffoldKey.currentState != null) {
      OwnerShellState.scaffoldKey.currentState!.openDrawer();
      return;
    }
    // Fallback: walk up the tree
    final state = context.findAncestorStateOfType<OwnerShellState>();
    state?._scaffoldKey.currentState?.openDrawer();
  }

  @override
  State<OwnerShell> createState() => OwnerShellState();
}

class OwnerShellState extends State<OwnerShell> {
  static final GlobalKey<ScaffoldState> scaffoldKey =
  GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> get _scaffoldKey => scaffoldKey;

  int _selectedIndex = 0;
  bool _notificationsHasBack = false;
  /// When true, current shell tab should show a back button (e.g. opened
  /// from Home Quick Actions) instead of the drawer hamburger.
  bool _openedWithBack = false;
  bool get openedWithBack => _openedWithBack;
  String _ownerName = '';

  List<String> _branches = [
    'All Branches',
    'Riyadh Branch',
    'Jeddah Branch',
    'Dammam Branch',
    'Makkah Branch',
  ];

  String _selectedBranch = 'All Branches';
  bool _accountingExpanded = false;

  /// Set `true` to show Promo / Corporate / Commissions / Accounting /
  /// Branches & Access again in the Admin Workshop drawer.
  static const bool _showDrawerItemsAfterPettyCash = false;

  /// Set `true` to show the yellow branch dropdown in the drawer again.
  static const bool _showDrawerBranchDropdown = false;

  // Lazy loading — only build tabs the user has visited.
  final Set<int> _visitedTabs = {0};

  // Tracks the order in which tabs/screens were visited within the shell,
  // so the hardware/system back button can step back through them instead
  // of closing the app immediately.
  final List<int> _history = [0];

  void _pushHistory(int index) {
    if (_history.isEmpty || _history.last != index) {
      _history.add(index);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = context.read<OwnerDataService>();
      _ownerData = data;
      _lastBranchGeneration = data.branchGeneration;
      _lastDateGeneration = data.dateGeneration;
      data.addListener(_onOwnerDataChanged);
    });
  }

  OwnerDataService? _ownerData;
  int _lastBranchGeneration = 0;
  int _lastDateGeneration = 0;

  void _onOwnerDataChanged() {
    final data = _ownerData;
    if (data == null || !mounted) return;
    final branchChanged = data.branchGeneration != _lastBranchGeneration;
    final dateChanged = data.dateGeneration != _lastDateGeneration;
    if (!branchChanged && !dateChanged) return;
    _lastBranchGeneration = data.branchGeneration;
    _lastDateGeneration = data.dateGeneration;
    // Only the currently visible tab should hit APIs.
    data.reloadTab(_selectedIndex);
  }

  @override
  void dispose() {
    _ownerData?.removeListener(_onOwnerDataChanged);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await SessionService().getUser(role: 'owner');
    if (user != null && mounted) {
      setState(() => _ownerName = user.name ?? '');
    }
  }

  void goHome() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _openedWithBack = false;
        _notificationsHasBack = false;
        _visitedTabs.add(0);
        _pushHistory(0);
      });
      _syncVisibleTabAfterSwitch();
    }
  }

  void goToIndex(int index, {bool withBack = false}) {
    final tabs = _buildTabs();
    if (index < 0 || index >= tabs.length) return;
    setState(() {
      _selectedIndex = index;
      _openedWithBack = withBack;
      _visitedTabs.add(index);
      if (index == 11) _notificationsHasBack = withBack;
      _pushHistory(index);
    });
    _syncVisibleTabAfterSwitch();
  }

  void _syncVisibleTabAfterSwitch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OwnerDataService>().reloadTab(_selectedIndex);
    });
  }

  // ─── Tab Index Map ───────────────────────────────────────────────────────
  //  0  OwnerDashboardView
  //  1  _BranchesTab
  //  2  EmployeeManagementView
  //  3  _CorporateManagementTab
  //  4  SizedBox.shrink  (reserved)
  //  5  ReportsManagementView
  //  6  _BillingTab
  //  7  _PosMonitoringTab
  //  8  _SuppliersTab
  //  9  _AccountingTab
  // 10  _ApprovalsTab
  // 11  SizedBox.shrink  (notifications overlay)
  // 12  OwnerSettingsView
  // 13  BranchCatalogView  (built inline)
  // 14  _PromoTab
  // 15  MasterCatalogView
  // 16  _SalesReturnsTab
  // 17  _DiscountsTab
  // 18  _PurchaseInvoicesTab
  // 19  _InventoryV2Tab
  // 20  _AffiliatedSuppliersTab
  // 21  _NonAffiliatedSuppliersTab
  // 22  _PettyCashTab
  // 23  _LockerManagementTab
  // 24  _CommissionTab
  // 25  _CashBankTab
  // 26  _GeneralJournalTab
  // 27  _TransactionEntryTab
  // 28  _ExpensesTab
  // 29  _PaymentsTab
  // 30  _ReceiptsTab
  // 31  LedgerView
  // 32  EmployeeSalaryAdvancesView
  // 33  PayrollRunScreen
  // 34  ApprovalLimitsScreen
  // 35  ProfitLossShellTab  (P&L — Chart of Accounts P&L tab)
  // 36  CoaExpensesShellTab  (Chart of Accounts → Expenses)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildTabs() => [
    OwnerBranchReloadRegistrar(
      tabIndex: 0,
      onReload: (ctx) =>
          ctx.read<OwnerDashboardViewModel>().syncWithSelectedBranch(),
      child: const OwnerDashboardView(),
    ), //  0
    const _BranchesTab(),                //  1
    OwnerBranchReloadRegistrar(
      tabIndex: 2,
      onReload: (ctx) =>
          ctx.read<EmployeeManagementViewModel>().syncWithSelectedBranch(),
      child: const EmployeeManagementView(),
    ), //  2
    const _CorporateManagementTab(),     //  3
    const SizedBox.shrink(),             //  4
    const _ReportsTab(),                 //  5
    const _BillingTab(),                 //  6
    const _PosMonitoringTab(),           //  7
    const _SuppliersTab(),               //  8
    const _AccountingTab(),              //  9
    const _ApprovalsTab(),               // 10
    const SizedBox.shrink(),             // 11 — notifications (Stack overlay)
    const OwnerSettingsView(),           // 12
    const SizedBox.shrink(),             // 13 — Branch Catalog (built inline)
    const _PromoTab(),                   // 14
    const MasterCatalogView(),           // 15
    const _SalesReturnsTab(),            // 16
    const _DiscountsTab(),               // 17
    const _PurchaseInvoicesTab(),        // 18
    const _InventoryV2Tab(),             // 19
    const _AffiliatedSuppliersTab(),     // 20
    const _NonAffiliatedSuppliersTab(),  // 21
    const _PettyCashTab(),               // 22
    const _LockerManagementTab(),        // 23
    const _CommissionTab(),              // 24
    const _CashBankTab(),                // 25
    const _GeneralJournalTab(),          // 26
    const _TransactionEntryTab(),        // 27
    const _ExpensesTab(),                // 28
    const _PaymentsTab(),                // 29
    const _ReceiptsTab(),                // 30
    const LedgerView(),                  // 31
    const EmployeeSalaryAdvancesView(),  // 32
    const PayrollRunScreen(),            // 33
    const ApprovalLimitsScreen(),        // 34
    const ProfitLossShellTab(),          // 35
    const CoaExpensesShellTab(),         // 36
  ];

  @override
  Widget build(BuildContext context) {
    final bool showBottomBar = [0, 5, 13, 12].contains(_selectedIndex);

    final List<Widget> tabs = _buildTabs();
    tabs[13] = BranchCatalogView(
      repository:     CatalogRepository(),
      sessionService: SessionService(),
    );

    return PopScope(
      // We always handle the back press ourselves: if there's shell-internal
      // history to step back through, use it; otherwise (we're on Home) close
      // the app directly — rather than letting the system pop reveal whatever
      // route happens to sit beneath this shell (e.g. a login screen).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
            if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            _selectedIndex = _history.last;
          });
          _syncVisibleTabAfterSwitch();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: OwnerUi.scaffoldBackground,
        drawer: _buildDrawer(context),
        body: Stack(
          children: [
            IndexedStack(
              index: (_selectedIndex == 11 ? 11 : _selectedIndex)
                  .clamp(0, tabs.length - 1),
              children: List.generate(tabs.length, (i) {
                if (_visitedTabs.contains(i)) return tabs[i];
                return const SizedBox.shrink();
              }),
            ),
            if (_selectedIndex == 11)
              OwnerNotificationsView(showBackButton: _notificationsHasBack),
          ],
        ),
        bottomNavigationBar: showBottomBar
            ? OwnerBottomBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _openedWithBack = false;
              _visitedTabs.add(index);
              _pushHistory(index);
            });
            _syncVisibleTabAfterSwitch();
          },
        )
            : null,
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBranch,
          isExpanded: true,
          dropdownColor: AppColors.primaryLight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _branches.map((branch) {
            return DropdownMenuItem<String>(
              value: branch,
              child: Text(
                branch,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedBranch = value;
            });
          },
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      width: 292,
      backgroundColor: AppColors.secondaryLight,
      child: Column(
        children: [
          _buildDrawerHeader(l10n),

          // Temporarily hidden — restore with `_showDrawerBranchDropdown = true`.
          if (_showDrawerBranchDropdown) _buildBranchDropdown(),

          Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
                  _drawerItem(context, 0, l10n.ownerShellDashboard, Icons.dashboard_rounded),
                  const SizedBox(height: 4),

                  _drawerItem(context, 2, l10n.ownerShellEmployees, Icons.people_alt_rounded),
                  const SizedBox(height: 4),

                  // Reports (5) & Departments (13) live on the bottom navbar —
                  // keep them out of the drawer to avoid duplicate entries.

                  _drawerItem(
                    context,
                    15,
                    l10n.ownerShellMasterCatalog,
                    Icons.menu_book_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    19,
                    l10n.ownerShellManageInventory,
                    Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    18,
                    l10n.ownerShellPurchaseInvoices,
                    Icons.shopping_cart_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    10,
                    l10n.ownerShellApprovalsQueue,
                    Icons.approval_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    16,
                    l10n.ownerShellSalesReturns,
                    Icons.assignment_return_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    35,
                    l10n.ownerShellChartOfAccountPnL,
                    Icons.trending_up_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    36,
                    l10n.ownerShellChartOfAccountExpense,
                    Icons.money_off_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    24,
                    l10n.ownerShellCommissions,
                    Icons.monetization_on_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    17,
                    l10n.ownerShellDiscounts,
                    Icons.percent_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    8,
                    l10n.ownerShellSuppliersPurchases,
                    Icons.storefront_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    20,
                    l10n.ownerShellFilterAffiliatedSuppliers,
                    Icons.handshake_outlined,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    21,
                    l10n.ownerShellNonAffiliatedSuppliers,
                    Icons.store_outlined,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    7,
                    l10n.ownerShellPosMonitoring,
                    Icons.point_of_sale_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    23,
                    l10n.ownerShellLockerManagement,
                    Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 4),

                  _drawerItem(
                    context,
                    22,
                    l10n.ownerShellMyPettyCash,
                    Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(height: 4),

                  // Temporarily hide everything after My Petty Cash in the
                  // Admin Workshop drawer. Flip [_showDrawerItemsAfterPettyCash]
                  // to restore.
                  if (_showDrawerItemsAfterPettyCash) ...[
                    _drawerItem(
                      context,
                      14,
                      l10n.ownerShellPromoCodes,
                      Icons.local_offer_rounded,
                    ),
                    const SizedBox(height: 4),
                    _drawerItem(
                      context,
                      3,
                      l10n.ownerShellCorporateManagement,
                      Icons.business_rounded,
                    ),
                    const SizedBox(height: 4),
                    _drawerExpandable(
                      title: l10n.ownerShellAccounting,
                      icon: Icons.account_balance_rounded,
                      isExpanded: _accountingExpanded,
                      hasSelectedChild: [
                        9,
                        25,
                        27,
                        26,
                        28,
                        30,
                        29,
                        32,
                        33,
                        34,
                        31,
                        35,
                        36,
                      ].contains(_selectedIndex),
                      onTap: () => setState(
                        () => _accountingExpanded = !_accountingExpanded,
                      ),
                      children: [
                        _drawerSubItem(
                          context,
                          9,
                          l10n.ownerShellChartOfAccounts,
                          Icons.table_chart_outlined,
                        ),
                        _drawerSubItem(
                          context,
                          35,
                          l10n.ownerShellChartOfAccountPnL,
                          Icons.trending_up_rounded,
                        ),
                        _drawerSubItem(
                          context,
                          36,
                          l10n.ownerShellChartOfAccountExpense,
                          Icons.money_off_rounded,
                        ),
                        _drawerSubItem(
                          context,
                          25,
                          l10n.ownerShellCashBank,
                          Icons.account_balance_wallet_outlined,
                        ),
                        _drawerSubItem(
                          context,
                          27,
                          l10n.ownerShellTransactions,
                          Icons.receipt_long_outlined,
                        ),
                        _drawerSubItem(
                          context,
                          26,
                          l10n.ownerShellJournalEntries,
                          Icons.book_outlined,
                        ),
                        _drawerSubItem(
                          context,
                          28,
                          l10n.ownerShellExpenseEntries,
                          Icons.receipt_long_rounded,
                        ),
                        _drawerSubItem(
                          context,
                          30,
                          l10n.ownerShellReceipts,
                          Icons.receipt_rounded,
                        ),
                        _drawerSubItem(
                          context,
                          29,
                          l10n.ownerShellPayments,
                          Icons.payments_rounded,
                        ),
                        _drawerSubItem(
                          context,
                          32,
                          l10n.ownerShellAdvances,
                          Icons.account_balance_wallet_outlined,
                        ),
                        _drawerSubItem(
                          context,
                          33,
                          l10n.ownerShellPayrollRun,
                          Icons.payments_outlined,
                        ),
                        _drawerSubItem(
                          context,
                          34,
                          l10n.ownerShellApprovalLimits,
                          Icons.rule_rounded,
                        ),
                        _drawerSubItem(
                          context,
                          31,
                          l10n.ownerShellLedger,
                          Icons.menu_book_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _drawerItem(
                      context,
                      1,
                      l10n.ownerShellBranchesAccess,
                      Icons.store_mall_directory_rounded,
                    ),
                    const SizedBox(height: 4),
                  ],

                  _drawerItem(
                    context,
                    100,
                    l10n.ownerShellLogout,
                    Icons.logout_rounded,
                    isLogout: true,
                  ),
                ],
            ),
          ),
          _buildDrawerFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AppLocalizations l10n) {
    final displayName =
    _ownerName.isNotEmpty ? _ownerName : l10n.lockerDefaultUser;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=FCC247&color=23262D',
                width: 48,
                height: 48,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  l10n.ownerShellRoleLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white24, size: 16),
          const SizedBox(width: 8),
          Text(
            l10n.ownerShellVersion,
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerExpandable({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required bool hasSelectedChild,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hasSelectedChild && !isExpanded
                    ? AppColors.primaryLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: hasSelectedChild && !isExpanded
                          ? Colors.black
                          : Colors.white70),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: hasSelectedChild && !isExpanded
                            ? Colors.black
                            : Colors.white70,
                        fontWeight: hasSelectedChild
                            ? FontWeight.w800
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Column(children: children),
          ),
          crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _drawerSubItem(
      BuildContext context, int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _openedWithBack = false;
            _visitedTabs.add(index);
            _pushHistory(index);
          });
          Navigator.pop(context);
          _syncVisibleTabAfterSwitch();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 17,
                  color: isSelected ? Colors.black : Colors.white54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context,
      int index,
      String title,
      IconData icon, {
        bool isLogout = false,
      }) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isLogout) {
            Navigator.pop(context);
            _showLogoutDialog(context);
            return;
          }
          setState(() {
            _selectedIndex = index;
            _openedWithBack = false;
            _visitedTabs.add(index);
            _pushHistory(index);
          });
          Navigator.pop(context);
          _syncVisibleTabAfterSwitch();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.black : Colors.white70),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.ownerShellLogoutTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.ownerShellLogoutBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        l10n.ownerShellLogoutCancel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final session = SessionService();
                        await session.clearSession(role: 'owner');
                        await session.saveLastPortal('');
                        if (mounted) RestartWidget.restartApp(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        disabledBackgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        disabledForegroundColor: AppColors.secondaryLight,
                        minimumSize: const Size.fromHeight(56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        l10n.ownerShellLogoutConfirm,
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
}