// ─────────────────────────────────────────────────────────────────────────────
// Accounting Models
// ─────────────────────────────────────────────────────────────────────────────

enum AccountType { assets, liabilities, equity, revenue, expenses }

enum AccountSubtype {
  current,
  nonCurrent,
  bank,
  operatingRevenue,
  otherIncome,
  operatingExpense,
  costOfGoodsSold,
  ownersEquity,
  retainedEarnings,
}

class ChartAccount {
  final String id;
  final String code;
  final String name;
  final String? description;
  final AccountType type;
  final String subtype;
  final String branch;
  final String normalBalance; // 'Debit' or 'Credit'
  final double? finalBalance;
  final bool isCredit; // true = Cr, false = Dr
  final bool isActive;
  final bool isAutoLinked;
  final String? parentCode; // for indented child accounts

  const ChartAccount({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    required this.subtype,
    required this.branch,
    required this.normalBalance,
    this.finalBalance,
    required this.isCredit,
    this.isActive = true,
    this.isAutoLinked = false,
    this.parentCode,
  });
}

class TrialBalanceEntry {
  final String code;
  final String accountName;
  final double debit;
  final double credit;
  final String type;
  const TrialBalanceEntry({
    required this.code,
    required this.accountName,
    required this.debit,
    required this.credit,
    required this.type,
  });
}

class PnLEntry {
  final String category;
  final String label;
  final double amount;
  final bool isSubtotal;
  final bool isTotal;

  const PnLEntry({
    required this.category,
    required this.label,
    required this.amount,
    this.isSubtotal = false,
    this.isTotal = false,
  });
}

class BalanceSheetEntry {
  final String section; // 'Assets', 'Liabilities', 'Equity'
  final String label;
  final double amount;
  final bool isTotal;
  final bool isSubtotal;

  const BalanceSheetEntry({
    required this.section,
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isSubtotal = false,
  });
}

// ─── Dummy Data ───────────────────────────────────────────────────────────────

class AccountingDummyData {
  static const List<ChartAccount> accounts = [
    // ── Assets ──
    ChartAccount(
      id: 'a1', code: '1000', name: 'Cash on Hand',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'a2', code: '1001-C18', name: 'Cashier Cash Till — Sultan',
      description: 'Cashier cash till — real cash held in this cashier\'s drawer.',
      type: AccountType.assets, subtype: 'Current', branch: 'MAIN BRANCH',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
      parentCode: '1000',
    ),
    ChartAccount(
      id: 'a3', code: '1003-C18', name: 'Cashier Petty Cash Wallet — Sultan',
      description: 'Cashier petty cash wallet — float issued to this cashier for in-shift petty expenses.',
      type: AccountType.assets, subtype: 'Current', branch: 'MAIN BRANCH',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
      parentCode: '1000',
    ),
    ChartAccount(
      id: 'a4', code: '1004', name: 'Cash in Transit — Locker',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'a5', code: '1010', name: 'Bank Account',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'a6', code: '1100', name: 'Accounts Receivable',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
      finalBalance: 150.0,
    ),
    ChartAccount(
      id: 'a7', code: '1200', name: 'Inventory',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false,
      finalBalance: 2400.0,
    ),
    ChartAccount(
      id: 'a8', code: '1300', name: 'Prepaid Expenses',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false,
    ),
    ChartAccount(
      id: 'a9', code: '1500', name: 'Fixed Assets',
      type: AccountType.assets, subtype: 'Non-Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false,
      finalBalance: 12000.0,
    ),
    ChartAccount(
      id: 'a10', code: '1600', name: 'Accumulated Depreciation',
      type: AccountType.assets, subtype: 'Non-Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true,
    ),
    ChartAccount(
      id: 'a11', code: '1700', name: 'VAT Input Credit',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.assets, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),

    // ── Liabilities ──
    ChartAccount(
      id: 'l1', code: '2000', name: 'Accounts Payable — Trade',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'l2', code: '2001', name: 'Accounts Payable — Affiliated Suppliers',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
      finalBalance: 995.0,
    ),
    ChartAccount(
      id: 'l3', code: '2010', name: 'Accounts Payable — Non-Affiliated Suppliers',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
      finalBalance: 713.75,
    ),
    ChartAccount(
      id: 'l4', code: '2100', name: 'VAT Payable',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
      finalBalance: 9.52,
    ),
    ChartAccount(
      id: 'l5', code: '2200', name: 'Employee Accrued Commission Payable',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
      finalBalance: 2.67,
    ),
    ChartAccount(
      id: 'l6', code: '2300', name: 'POS Bank Fee Payable',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'l7', code: '2310', name: 'POS Workshop Settlement Payable',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.liabilities, subtype: 'Current', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),

    // ── Equity ──
    ChartAccount(
      id: 'e1', code: '3000', name: 'Owner\'s Equity',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.equity, subtype: 'Owners Equity', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'e2', code: '3100', name: 'Retained Earnings',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.equity, subtype: 'Retained Earnings', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'e3', code: '3500', name: 'Opening Balance Equity',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.equity, subtype: 'Owners Equity', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
      finalBalance: 89.0,
    ),

    // ── Revenue ──
    ChartAccount(
      id: 'r1', code: '4000', name: 'Service Revenue',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.revenue, subtype: 'Operating Revenue', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'r2', code: '4010', name: 'Product Revenue',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.revenue, subtype: 'Operating Revenue', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
      finalBalance: 63.48,
    ),
    ChartAccount(
      id: 'r3', code: '4500', name: 'POS Tap-to-Pay Commission Income',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.revenue, subtype: 'Other Income', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'r4', code: '4510', name: 'Penalties',
      description: 'System account — employee payroll penalty deductions.',
      type: AccountType.revenue, subtype: 'Other Income', branch: 'Shared',
      normalBalance: 'Credit', isCredit: true, isAutoLinked: true,
    ),

    // ── Expenses ──
    ChartAccount(
      id: 'ex1', code: '1150', name: 'POS Closing Variance — Cash',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'ex2', code: '1151', name: 'POS Closing Variance — Bank & Card',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
      finalBalance: 73.0,
    ),
    ChartAccount(
      id: 'ex3', code: '1152', name: 'POS Closing Variance — Other Methods',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'ex4', code: '1153', name: 'Locker Collection Variance',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'ex5', code: '5000', name: 'Cost of Goods Sold',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Cost Of Goods Sold', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
      finalBalance: 36.93,
    ),
    ChartAccount(
      id: 'ex6', code: '6000', name: 'Employee Commission Expense',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
      finalBalance: 2.67,
    ),
    ChartAccount(
      id: 'ex7', code: '6100', name: 'Petty Cash Expense',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'ex8', code: '6200', name: 'Employee Salary Advance',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'ex9', code: '6300', name: 'Salary Expense',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
    ChartAccount(
      id: 'ex10', code: '6500', name: 'Bank Charges Expense',
      description: 'System-managed (auto-posted by POS / commissions / SoftPOS).',
      type: AccountType.expenses, subtype: 'Operating Expense', branch: 'Shared',
      normalBalance: 'Debit', isCredit: false, isAutoLinked: true,
    ),
  ];

  static const List<TrialBalanceEntry> trialBalance = [
    TrialBalanceEntry(code: '1000', accountName: 'Cash on Hand',                    debit: 0,       credit: 0,      type: 'Asset'),
    TrialBalanceEntry(code: '1010', accountName: 'Bank Account',                    debit: 14550.0, credit: 0,      type: 'Asset'),
    TrialBalanceEntry(code: '1100', accountName: 'Accounts Receivable',             debit: 150.0,   credit: 0,      type: 'Asset'),
    TrialBalanceEntry(code: '1200', accountName: 'Inventory',                       debit: 2400.0,  credit: 0,      type: 'Asset'),
    TrialBalanceEntry(code: '1500', accountName: 'Fixed Assets',                    debit: 12000.0, credit: 0,      type: 'Asset'),
    TrialBalanceEntry(code: '2001', accountName: 'AP — Affiliated Suppliers',       debit: 0,       credit: 995.0,  type: 'Liability'),
    TrialBalanceEntry(code: '2010', accountName: 'AP — Non-Affiliated Suppliers',   debit: 0,       credit: 713.75, type: 'Liability'),
    TrialBalanceEntry(code: '2100', accountName: 'VAT Payable',                     debit: 0,       credit: 9.52,   type: 'Liability'),
    TrialBalanceEntry(code: '2200', accountName: 'Employee Commission Payable',     debit: 0,       credit: 2.67,   type: 'Liability'),
    TrialBalanceEntry(code: '3000', accountName: 'Owner\'s Equity',                 debit: 0,       credit: 28290.0,type: 'Equity'),
    TrialBalanceEntry(code: '3500', accountName: 'Opening Balance Equity',          debit: 0,       credit: 89.0,   type: 'Equity'),
    TrialBalanceEntry(code: '4000', accountName: 'Service Revenue',                 debit: 0,       credit: 817.0,  type: 'Income'),
    TrialBalanceEntry(code: '4010', accountName: 'Product Revenue',                 debit: 0,       credit: 63.48,  type: 'Income'),
    TrialBalanceEntry(code: '5000', accountName: 'Cost of Goods Sold',              debit: 36.93,   credit: 0,      type: 'Expense'),
    TrialBalanceEntry(code: '6000', accountName: 'Employee Commission Expense',     debit: 2.67,    credit: 0,      type: 'Expense'),
    TrialBalanceEntry(code: '1151', accountName: 'POS Variance — Bank & Card',      debit: 73.0,    credit: 0,      type: 'Expense'),
  ];

  static const List<PnLEntry> profitAndLoss = [
    PnLEntry(category: 'Revenue', label: 'Service Revenue', amount: 817.0),
    PnLEntry(category: 'Revenue', label: 'Product Revenue', amount: 63.48),
    PnLEntry(category: 'Revenue', label: 'POS Commission Income', amount: 0),
    PnLEntry(category: 'Revenue', label: 'Penalties', amount: 0),
    PnLEntry(category: 'Revenue', label: 'Total Revenue', amount: 880.48, isSubtotal: true),
    PnLEntry(category: 'COGS', label: 'Cost of Goods Sold', amount: 36.93),
    PnLEntry(category: 'COGS', label: 'Gross Profit', amount: 843.55, isSubtotal: true),
    PnLEntry(category: 'Expenses', label: 'Employee Commission Expense', amount: 2.67),
    PnLEntry(category: 'Expenses', label: 'Salary Expense', amount: 0),
    PnLEntry(category: 'Expenses', label: 'POS Variance — Bank & Card', amount: 73.0),
    PnLEntry(category: 'Expenses', label: 'Locker Collection Variance', amount: 0),
    PnLEntry(category: 'Expenses', label: 'Bank Charges Expense', amount: 0),
    PnLEntry(category: 'Expenses', label: 'Total Expenses', amount: 75.67, isSubtotal: true),
    PnLEntry(category: 'Net', label: 'Net Income', amount: 767.88, isTotal: true),
  ];

  static const List<BalanceSheetEntry> balanceSheet = [
    // Assets
    BalanceSheetEntry(section: 'Assets', label: 'Cash on Hand', amount: 0),
    BalanceSheetEntry(section: 'Assets', label: 'Bank Account', amount: 14550.0),
    BalanceSheetEntry(section: 'Assets', label: 'Accounts Receivable', amount: 150.0),
    BalanceSheetEntry(section: 'Assets', label: 'Inventory', amount: 2400.0),
    BalanceSheetEntry(section: 'Assets', label: 'Fixed Assets', amount: 12000.0),
    BalanceSheetEntry(section: 'Assets', label: 'Total Assets', amount: 29100.0, isTotal: true),
    // Liabilities
    BalanceSheetEntry(section: 'Liabilities', label: 'AP — Affiliated Suppliers', amount: 995.0),
    BalanceSheetEntry(section: 'Liabilities', label: 'AP — Non-Affiliated Suppliers', amount: 713.75),
    BalanceSheetEntry(section: 'Liabilities', label: 'VAT Payable', amount: 9.52),
    BalanceSheetEntry(section: 'Liabilities', label: 'Employee Commission Payable', amount: 2.67),
    BalanceSheetEntry(section: 'Liabilities', label: 'Total Liabilities', amount: 1720.94, isTotal: true),
    // Equity
    BalanceSheetEntry(section: 'Equity', label: 'Owner\'s Equity', amount: 28290.0),
    BalanceSheetEntry(section: 'Equity', label: 'Opening Balance Equity', amount: 89.0),
    BalanceSheetEntry(section: 'Equity', label: 'Retained Earnings (Net Income)', amount: 767.88),
    BalanceSheetEntry(section: 'Equity', label: 'Total Equity', amount: 29146.88, isTotal: true),
    BalanceSheetEntry(section: 'Equity', label: 'Total Liabilities + Equity', amount: 30867.82, isTotal: true),
  ];
}