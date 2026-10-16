import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../widgets/owner_sheet_actions.dart';
import '../../widgets/owner_styled_dropdown.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colors (matching HTML design exactly)
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary    = AppColors.primaryLight;   // #FCC247
const _kDark       = AppColors.secondaryLight; // #23262D
const _kBg         = Color(0xFFF0F1F5);
const _kRed        = Color(0xFFFF5C5C);
const _kGreen      = Color(0xFF2DBE7A);
const _kBlue       = Color(0xFF3B82F6);
const _kPurple     = Color(0xFF9C27B0);
const _kOrange     = Color(0xFFF97316);

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class _EmployeeRow {
  final String name;
  final String type; // 'Technician' | 'Cashier'
  final int advances;
  final double totalPaid;
  final double outstanding;
  const _EmployeeRow({
    required this.name,
    required this.type,
    required this.advances,
    required this.totalPaid,
    required this.outstanding,
  });
  String get initials {
    final parts = name.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

enum _AdvanceStatus { pending, approved, repaid, rejected }

class _AdvanceRecord {
  final String empName;
  final String branch;
  final DateTime date;
  final String paidFrom;
  final String reason;
  final double amount;
  final double repaid;
  final _AdvanceStatus status;
  const _AdvanceRecord({
    required this.empName,
    required this.branch,
    required this.date,
    required this.paidFrom,
    required this.reason,
    required this.amount,
    required this.repaid,
    required this.status,
  });
  double get balance => amount - repaid;
  String get initials {
    final parts = empName.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _SalaryPayment {
  final String empName;
  final DateTime date;
  final String period;
  final String paidFrom;
  final double salary;
  final double commission;
  final double deductions;
  final double advanceDeducted;
  const _SalaryPayment({
    required this.empName,
    required this.date,
    required this.period,
    required this.paidFrom,
    required this.salary,
    required this.commission,
    required this.deductions,
    required this.advanceDeducted,
  });
  double get netPaid => salary + commission - deductions - advanceDeducted;
}

enum _LedgerTxType { earning, deduction, advance, salary }

class _LedgerTx {
  final String description;
  final DateTime date;
  final String period;
  final _LedgerTxType type;
  final double amount; // positive = credit, negative = debit
  final double netPosition;
  final List<String> pills;
  const _LedgerTx({
    required this.description,
    required this.date,
    required this.period,
    required this.type,
    required this.amount,
    required this.netPosition,
    required this.pills,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class EmployeeSalaryAdvancesView extends StatefulWidget {
  const EmployeeSalaryAdvancesView({super.key});

  @override
  State<EmployeeSalaryAdvancesView> createState() =>
      _EmployeeSalaryAdvancesViewState();
}

class _EmployeeSalaryAdvancesViewState
    extends State<EmployeeSalaryAdvancesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // ── Tab 1: By Employee filters ────────────────────────────────────────────
  String _empBranch = 'All Branches';

  // ── Tab 2: Advances filters ───────────────────────────────────────────────
  String _advBranch = 'All Branches';
  String _advStatus = 'All';

  // ── Tab 3: Salary filters ─────────────────────────────────────────────────
  String _salMonth   = 'All Months';
  String _salPayDate = 'All Dates';
  String _salPayFrom = 'All Accounts';

  // ── Tab 4: Ledger filters ─────────────────────────────────────────────────
  String _ledEmployee = 'All Employees';
  String _ledMonth    = 'All Months';
  bool   _ledAllPeriods = false;

  // ── Shared options ────────────────────────────────────────────────────────
  final List<String> _branches      = ['All Branches', 'MAIN BRANCH', 'BRANCH 2'];
  final List<String> _statusOptions  = ['All', 'Pending', 'Approved', 'Repaid', 'Rejected'];
  final List<String> _monthOptions   = ['All Months', 'June 2026', 'May 2026', 'April 2026'];
  final List<String> _accountOptions = ['All Accounts', 'Cash On Hand', 'Bank Account'];
  final List<String> _employeeNames  = ['All Employees', 'Arif عريف', 'Bashar بشار', 'jabriel جبريل', 'Sultan'];

  final List<_EmployeeRow> _employees_data = const [
    _EmployeeRow(name: 'Arif عريف',     type: 'Technician', advances: 0, totalPaid: 0, outstanding: 0),
    _EmployeeRow(name: 'Bashar بشار',   type: 'Technician', advances: 0, totalPaid: 0, outstanding: 0),
    _EmployeeRow(name: 'jabriel جبريل', type: 'Technician', advances: 0, totalPaid: 0, outstanding: 0),
    _EmployeeRow(name: 'Sultan',         type: 'Cashier',    advances: 0, totalPaid: 0, outstanding: 0),
  ];

  // Sample data matching HTML
  final List<_AdvanceRecord> _advances = [
    _AdvanceRecord(
      empName: 'Arif عريف', branch: 'Main Branch',
      date: DateTime(2026, 6, 10), paidFrom: 'Cash On Hand',
      reason: 'Medical emergency', amount: 500, repaid: 0,
      status: _AdvanceStatus.pending,
    ),
    _AdvanceRecord(
      empName: 'Sultan', branch: 'Main Branch',
      date: DateTime(2026, 5, 2), paidFrom: 'Bank Account',
      reason: 'Personal', amount: 300, repaid: 300,
      status: _AdvanceStatus.repaid,
    ),
  ];

  final List<_SalaryPayment> _salaryPayments = [
    _SalaryPayment(
      empName: 'Arif عريف', date: DateTime(2026, 6, 15),
      period: 'June 2026', paidFrom: 'Cash On Hand',
      salary: 1500, commission: 320, deductions: 100, advanceDeducted: 500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalPaid => _advances.fold(0, (s, a) => s + a.amount);
  double get _outstanding => _advances.fold(0, (s, a) => s + a.balance);
  int    get _pendingCount => _advances.where((a) => a.status == _AdvanceStatus.pending).length;

  void _showFilterSheet(BuildContext context) {
    final tab = _tabController.index;
    if (tab == 0) {
      _showSheet(context, _ByEmployeeFilterSheet(
        branches: _branches,
        selectedBranch: _empBranch,
        onApply: (branch) => setState(() => _empBranch = branch),
      ));
    } else if (tab == 1) {
      _showSheet(context, _AdvancesFilterSheet(
        branches: _branches,
        selectedBranch: _advBranch,
        statusOptions: _statusOptions,
        selectedStatus: _advStatus,
        onApply: (branch, status) => setState(() {
          _advBranch = branch;
          _advStatus = status;
        }),
      ));
    } else if (tab == 2) {
      _showSheet(context, _SalaryFilterSheet(
        monthOptions: _monthOptions,
        accountOptions: _accountOptions,
        selectedMonth: _salMonth,
        selectedPayDate: _salPayDate,
        selectedPayFrom: _salPayFrom,
        onApply: (month, payDate, payFrom) => setState(() {
          _salMonth   = month;
          _salPayDate = payDate;
          _salPayFrom = payFrom;
        }),
      ));
    } else if (tab == 3) {
      _showSheet(context, _LedgerFilterSheet(
        employeeNames: _employeeNames,
        monthOptions: _monthOptions,
        selectedEmployee: _ledEmployee,
        selectedMonth: _ledMonth,
        allPeriods: _ledAllPeriods,
        onApply: (employee, month, allPeriods) => setState(() {
          _ledEmployee   = employee;
          _ledMonth      = month;
          _ledAllPeriods = allPeriods;
        }),
      ));
    }
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: OwnerAppBar(
        title: 'Salary Advances',
        showDrawer: true,
        showNotification: true,
        showBackButton: false,
      ),
      floatingActionButton: _FABRow(),
      body: Column(
        children: [
          // Control Account Banner
          _ControlBanner(),
          // Summary Cards
          _SummaryRow(total: _totalPaid, outstanding: _outstanding, pending: _pendingCount),
          const SizedBox(height: 10),
          // Tab Bar
          _buildTabBar(),
          // Search + Filter Button
          _SearchFilterRow(
            onSearch: (q) => setState(() => _searchQuery = q),
            onFilterTap: () => _showFilterSheet(context),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _ByEmployeeTab(
                  employees: _employees_data,
                  searchQuery: _searchQuery,
                  selectedBranch: _empBranch,
                ),
                _AdvancesTab(
                  advances: _advances,
                  statusFilter: _advStatus,
                  branchFilter: _advBranch,
                ),
                _SalaryTab(
                  employees: _employees_data,
                  salaryPayments: _salaryPayments,
                  monthFilter: _salMonth,
                  payFromFilter: _salPayFrom,
                ),
                _EmployeeLedgerTab(
                  employees: _employees_data,
                  selectedBranch: _empBranch,
                  employeeFilter: _ledEmployee,
                  monthFilter: _ledMonth,
                  allPeriods: _ledAllPeriods,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _kDark,
        unselectedLabelColor: _kDark.withOpacity(0.45),
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'By Employee'),
          Tab(text: 'Advances'),
          Tab(text: 'Salary'),
          Tab(text: 'Employee Ledger'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB Row
// ─────────────────────────────────────────────────────────────────────────────

class _FABRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'bulk',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const BulkAdvancesSheet(),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _kDark,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.group_rounded, size: 18),
          label: const Text('Bulk Advances', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.extended(
          heroTag: 'pay',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const PayAdvanceSheet(),
          ),
          backgroundColor: _kPrimary,
          foregroundColor: _kDark,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Pay Advance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control Account Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ControlBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.menu_book_rounded, color: _kPrimary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '1250 — Salary Advances',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Control Account',
                    style: TextStyle(color: _kPrimary, fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'View →',
              style: TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Row (3 dark cards)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double total;
  final double outstanding;
  final int pending;
  const _SummaryRow({required this.total, required this.outstanding, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'TOTAL PAID',
            value: 'SAR ${total.toStringAsFixed(2)}',
            valueColor: Colors.white,
          )),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(
            icon: Icons.currency_exchange_rounded,
            label: 'OUTSTANDING',
            value: 'SAR ${outstanding.toStringAsFixed(2)}',
            valueColor: _kRed,
          )),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(
            icon: Icons.access_time_rounded,
            label: 'PENDING',
            value: '$pending',
            valueColor: _kPrimary,
            valueLarge: true,
          )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool valueLarge;
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _kPrimary, size: 17),
          ),
          const SizedBox(height: 9),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: valueLarge ? 18 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search + Filter Button Row
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterRow extends StatelessWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterTap;
  const _SearchFilterRow({
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 13),
                  Icon(Icons.search_rounded, size: 17, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: onSearch,
                      style: const TextStyle(fontSize: 13, color: _kDark),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search employee, branch, reason...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.07)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: _kDark),
                  const SizedBox(width: 6),
                  Text('Filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kDark.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Filter Sheet scaffold + chip group
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterChipGroup({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final active = selected == o;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? _kDark : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? _kDark : Colors.black.withOpacity(0.12), width: 1.5),
            ),
            child: Text(
              o,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : _kDark.withOpacity(0.6),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Widget _sheetHandle() => Center(
  child: Container(
    width: 40, height: 4,
    margin: const EdgeInsets.only(top: 12, bottom: 18),
    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
  ),
);

Widget _sheetLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
      color: _kDark.withOpacity(0.45), letterSpacing: 0.5)),
);

Widget _sheetButtons({
  required VoidCallback onReset,
  required VoidCallback onApply,
  required BuildContext context,
}) {
  return Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: onReset,
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text('Reset', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kDark.withOpacity(0.6))),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: () { onApply(); Navigator.pop(context); },
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Text('Apply Filters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimary)),
          ),
        ),
      ),
    ],
  );
}

// ── Tab 1: By Employee filter sheet ──────────────────────────────────────────

class _ByEmployeeFilterSheet extends StatefulWidget {
  final List<String> branches;
  final String selectedBranch;
  final void Function(String branch) onApply;
  const _ByEmployeeFilterSheet({required this.branches, required this.selectedBranch, required this.onApply});

  @override
  State<_ByEmployeeFilterSheet> createState() => _ByEmployeeFilterSheetState();
}

class _ByEmployeeFilterSheetState extends State<_ByEmployeeFilterSheet> {
  late String _branch;

  @override
  void initState() {
    super.initState();
    _branch = widget.selectedBranch;
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetShell(
      title: 'Filter Employees',
      onReset: () => setState(() => _branch = widget.branches.first),
      onApply: () => widget.onApply(_branch),
      children: [
        _sheetLabel('BRANCH'),
        _FilterChipGroup(options: widget.branches, selected: _branch, onSelect: (v) => setState(() => _branch = v)),
      ],
    );
  }
}

// ── Tab 2: Advances filter sheet ─────────────────────────────────────────────

class _AdvancesFilterSheet extends StatefulWidget {
  final List<String> branches;
  final String selectedBranch;
  final List<String> statusOptions;
  final String selectedStatus;
  final void Function(String branch, String status) onApply;
  const _AdvancesFilterSheet({
    required this.branches,
    required this.selectedBranch,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onApply,
  });

  @override
  State<_AdvancesFilterSheet> createState() => _AdvancesFilterSheetState();
}

class _AdvancesFilterSheetState extends State<_AdvancesFilterSheet> {
  late String _branch;
  late String _status;

  @override
  void initState() {
    super.initState();
    _branch = widget.selectedBranch;
    _status = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetShell(
      title: 'Filter Advances',
      onReset: () => setState(() {
        _branch = widget.branches.first;
        _status = widget.statusOptions.first;
      }),
      onApply: () => widget.onApply(_branch, _status),
      children: [
        _sheetLabel('BRANCH'),
        _FilterChipGroup(options: widget.branches, selected: _branch, onSelect: (v) => setState(() => _branch = v)),
        const SizedBox(height: 18),
        _sheetLabel('STATUS'),
        _FilterChipGroup(options: widget.statusOptions, selected: _status, onSelect: (v) => setState(() => _status = v)),
      ],
    );
  }
}

// ── Tab 3: Salary filter sheet ───────────────────────────────────────────────

class _SalaryFilterSheet extends StatefulWidget {
  final List<String> monthOptions;
  final List<String> accountOptions;
  final String selectedMonth;
  final String selectedPayDate;
  final String selectedPayFrom;
  final void Function(String month, String payDate, String payFrom) onApply;
  const _SalaryFilterSheet({
    required this.monthOptions,
    required this.accountOptions,
    required this.selectedMonth,
    required this.selectedPayDate,
    required this.selectedPayFrom,
    required this.onApply,
  });

  @override
  State<_SalaryFilterSheet> createState() => _SalaryFilterSheetState();
}

class _SalaryFilterSheetState extends State<_SalaryFilterSheet> {
  late String _month;
  late String _payDate;
  late String _payFrom;

  @override
  void initState() {
    super.initState();
    _month   = widget.selectedMonth;
    _payDate = widget.selectedPayDate;
    _payFrom = widget.selectedPayFrom;
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetShell(
      title: 'Filter Salary Payments',
      onReset: () => setState(() {
        _month   = widget.monthOptions.first;
        _payDate = 'All Dates';
        _payFrom = widget.accountOptions.first;
      }),
      onApply: () => widget.onApply(_month, _payDate, _payFrom),
      children: [
        _sheetLabel('MONTH / PERIOD'),
        _FilterChipGroup(options: widget.monthOptions, selected: _month, onSelect: (v) => setState(() => _month = v)),
        const SizedBox(height: 18),
        _sheetLabel('PAY FROM'),
        _FilterChipGroup(options: widget.accountOptions, selected: _payFrom, onSelect: (v) => setState(() => _payFrom = v)),
      ],
    );
  }
}

// ── Tab 4: Ledger filter sheet ───────────────────────────────────────────────

class _LedgerFilterSheet extends StatefulWidget {
  final List<String> employeeNames;
  final List<String> monthOptions;
  final String selectedEmployee;
  final String selectedMonth;
  final bool allPeriods;
  final void Function(String employee, String month, bool allPeriods) onApply;
  const _LedgerFilterSheet({
    required this.employeeNames,
    required this.monthOptions,
    required this.selectedEmployee,
    required this.selectedMonth,
    required this.allPeriods,
    required this.onApply,
  });

  @override
  State<_LedgerFilterSheet> createState() => _LedgerFilterSheetState();
}

class _LedgerFilterSheetState extends State<_LedgerFilterSheet> {
  late String _employee;
  late String _month;
  late bool   _allPeriods;

  @override
  void initState() {
    super.initState();
    _employee   = widget.selectedEmployee;
    _month      = widget.selectedMonth;
    _allPeriods = widget.allPeriods;
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetShell(
      title: 'Filter Ledger',
      onReset: () => setState(() {
        _employee   = widget.employeeNames.first;
        _month      = widget.monthOptions.first;
        _allPeriods = false;
      }),
      onApply: () => widget.onApply(_employee, _month, _allPeriods),
      children: [
        _sheetLabel('EMPLOYEE / TECHNICIAN'),
        _FilterChipGroup(options: widget.employeeNames, selected: _employee, onSelect: (v) => setState(() => _employee = v)),
        const SizedBox(height: 18),
        _sheetLabel('MONTH / PERIOD'),
        _FilterChipGroup(
          options: widget.monthOptions,
          selected: _allPeriods ? 'All Months' : _month,
          onSelect: (v) => setState(() { _month = v; _allPeriods = false; }),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => _allPeriods = !_allPeriods),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _allPeriods ? _kDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _allPeriods ? _kDark : Colors.black.withOpacity(0.2), width: 1.5),
                ),
                child: _allPeriods
                    ? const Icon(Icons.check_rounded, size: 14, color: _kPrimary)
                    : null,
              ),
              const SizedBox(width: 10),
              Text('Show all periods', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kDark)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared sheet shell ────────────────────────────────────────────────────────

class _FilterSheetShell extends StatelessWidget {
  final String title;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final List<Widget> children;
  const _FilterSheetShell({required this.title, required this.onReset, required this.onApply, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHandle(),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kDark)),
          const SizedBox(height: 20),
          ...children,
          const SizedBox(height: 24),
          Builder(builder: (ctx) => _sheetButtons(onReset: onReset, onApply: onApply, context: context)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — By Employee
// ─────────────────────────────────────────────────────────────────────────────

class _ByEmployeeTab extends StatelessWidget {
  final List<_EmployeeRow> employees;
  final String searchQuery;
  final String selectedBranch;
  const _ByEmployeeTab({
    required this.employees,
    required this.searchQuery,
    required this.selectedBranch,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = employees
        .where((e) => e.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Icon(Icons.corporate_fare_rounded, size: 14, color: _kDark.withOpacity(0.6)),
                const SizedBox(width: 7),
                Text(
                  selectedBranch,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kDark),
                ),
                Text(
                  '  ·  ${filtered.length} employees',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kDark.withOpacity(0.45)),
                ),
              ],
            ),
          ),
          if (filtered.isEmpty)
            _EmptyState(message: 'No employees found')
          else
            ...filtered.map((e) => _EmployeeCard(emp: e)),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final _EmployeeRow emp;
  const _EmployeeCard({required this.emp});

  Color get _chipBg => emp.type == 'Cashier'
      ? _kOrange.withOpacity(0.1)
      : _kBlue.withOpacity(0.1);
  Color get _chipFg => emp.type == 'Cashier' ? _kOrange : _kBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(
                    emp.initials,
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _chipBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(emp.type, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _chipFg)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MiniStat(label: 'TOTAL PAID', value: 'SAR ${emp.totalPaid.toStringAsFixed(2)}'),
                          const SizedBox(width: 14),
                          _MiniStat(label: 'OUTSTANDING', value: 'SAR ${emp.outstanding.toStringAsFixed(2)}', valueColor: _kRed),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right side
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text(
                        '${emp.advances}',
                        style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(Icons.chevron_right_rounded, size: 16, color: _kDark.withOpacity(0.25)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _kDark.withOpacity(0.4), letterSpacing: 0.3)),
        const SizedBox(height: 1),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? _kDark)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Advances
// ─────────────────────────────────────────────────────────────────────────────

class _AdvancesTab extends StatelessWidget {
  final List<_AdvanceRecord> advances;
  final String statusFilter;
  final String branchFilter;
  const _AdvancesTab({required this.advances, required this.statusFilter, required this.branchFilter});

  List<_AdvanceRecord> get _filtered {
    return advances.where((a) {
      final statusMatch = statusFilter == 'All' || a.status.name.toLowerCase() == statusFilter.toLowerCase();
      final branchMatch = branchFilter == 'All Branches' || a.branch.toUpperCase().contains(branchFilter.replaceAll(' ', '_').toUpperCase()) || branchFilter == 'All Branches';
      return statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
        children: [
          if (filtered.isEmpty)
            _EmptyState(message: 'No advances found')
          else
            ...filtered.map((a) => _AdvanceCard(record: a)),
        ],
      ),
    );
  }
}

class _AdvanceCard extends StatelessWidget {
  final _AdvanceRecord record;
  const _AdvanceCard({required this.record});

  Color get _statusBg {
    switch (record.status) {
      case _AdvanceStatus.pending:  return const Color(0xFFEE6C00).withOpacity(0.12);
      case _AdvanceStatus.approved: return _kGreen.withOpacity(0.12);
      case _AdvanceStatus.repaid:   return _kBlue.withOpacity(0.12);
      case _AdvanceStatus.rejected: return _kRed.withOpacity(0.12);
    }
  }
  Color get _statusFg {
    switch (record.status) {
      case _AdvanceStatus.pending:  return const Color(0xFFC07900);
      case _AdvanceStatus.approved: return const Color(0xFF1A8C54);
      case _AdvanceStatus.repaid:   return _kBlue;
      case _AdvanceStatus.rejected: return _kRed;
    }
  }
  String get _statusLabel {
    switch (record.status) {
      case _AdvanceStatus.pending:  return 'Pending';
      case _AdvanceStatus.approved: return 'Approved';
      case _AdvanceStatus.repaid:   return 'Repaid';
      case _AdvanceStatus.rejected: return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = record.date;
    final dateStr = '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              // Avatar + name
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(record.initials, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.empName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
                    const SizedBox(height: 1),
                    Text(record.branch, style: TextStyle(fontSize: 11, color: _kDark.withOpacity(0.45))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusFg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Meta tags
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _MetaTag(icon: Icons.calendar_today_rounded, label: dateStr),
              _MetaTag(icon: Icons.credit_card_rounded, label: record.paidFrom),
              _MetaTag(label: record.reason),
            ],
          ),
          const SizedBox(height: 12),
          // Amount boxes
          Row(
            children: [
              Expanded(child: _AmountBox(label: 'AMOUNT', value: 'SAR ${record.amount.toStringAsFixed(0)}', color: _kDark)),
              const SizedBox(width: 6),
              Expanded(child: _AmountBox(label: 'REPAID', value: 'SAR ${record.repaid.toStringAsFixed(0)}', color: _kGreen)),
              const SizedBox(width: 6),
              Expanded(child: _AmountBox(
                label: 'BALANCE',
                value: 'SAR ${record.balance.toStringAsFixed(0)}',
                color: record.balance > 0 ? _kRed : _kDark.withOpacity(0.4),
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

class _MetaTag extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _MetaTag({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: _kDark.withOpacity(0.4)),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, color: _kDark.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _AmountBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AmountBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _kDark.withOpacity(0.4))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Salary
// ─────────────────────────────────────────────────────────────────────────────

class _SalaryTab extends StatefulWidget {
  final List<_EmployeeRow> employees;
  final List<_SalaryPayment> salaryPayments;
  final String monthFilter;
  final String payFromFilter;
  const _SalaryTab({
    required this.employees,
    required this.salaryPayments,
    required this.monthFilter,
    required this.payFromFilter,
  });

  @override
  State<_SalaryTab> createState() => _SalaryTabState();
}

class _SalaryTabState extends State<_SalaryTab> {
  String? _selectedEmployee;
  String? _selectedAccount;
  final _salaryCtrl     = TextEditingController();
  final _basicSalCtrl   = TextEditingController();
  final _deductCtrl     = TextEditingController();
  final _penaltyCtrl    = TextEditingController();
  final _penaltyReason  = TextEditingController();
  final _notesCtrl      = TextEditingController();

  // Simulated auto-loaded values when employee selected
  double get _advanceDue      => _selectedEmployee != null ? 500.00 : 0;
  double get _commPayable     => _selectedEmployee != null ? 320.00 : 0;
  int    get _deductFromAdv   => _selectedEmployee != null ? 500 : 0;
  double get _basicSalary     => double.tryParse(_basicSalCtrl.text) ?? 0;
  double get _penalties       => double.tryParse(_penaltyCtrl.text) ?? 0;
  double get _netPayable      => _basicSalary + _commPayable - _penalties - (_deductFromAdv.toDouble());

  @override
  void dispose() {
    _salaryCtrl.dispose(); _basicSalCtrl.dispose(); _deductCtrl.dispose();
    _penaltyCtrl.dispose(); _penaltyReason.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEmployee = _selectedEmployee != null;
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
        children: [
          // ── Employee selector ──────────────────────────────────────────
          _FormCard(
            child: _FieldBox(
              label: 'EMPLOYEE / TECHNICIAN *',
              child: _DropInput(
                hint: 'Select employee...',
                value: _selectedEmployee,
                items: widget.employees.map((e) => e.name).toList(),
                onChanged: (v) => setState(() => _selectedEmployee = v),
              ),
            ),
          ),

          // ── Details — shown only after employee selected ────────────────
          if (hasEmployee) ...[
            const SizedBox(height: 10),

            // Auto-loaded info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFC07900)),
                  const SizedBox(width: 8),
                  Text(
                    'Advance due & commissions auto-loaded for $_selectedEmployee',
                    style: TextStyle(fontSize: 11.5, color: _kDark.withOpacity(0.7), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Row 1: Basic Salary + Advance Due ─────────────────────────
            _FormCard(
              title: 'PAYMENT DETAILS',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _FieldBox(
                        label: 'BASIC SALARY (SAR) *',
                        child: _TextInput(controller: _basicSalCtrl, hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {})),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _FieldBox(
                        label: 'ADVANCE DUE',
                        child: _ReadonlyField(
                          text: 'SAR ${_advanceDue.toStringAsFixed(2)}',
                          color: _advanceDue > 0 ? _kRed : null,
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _FieldBox(
                        label: 'COMMISSIONS PAYABLE',
                        child: _ReadonlyField(
                          text: 'SAR ${_commPayable.toStringAsFixed(2)}',
                          color: const Color(0xFF1A8C54),
                        ),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _FieldBox(
                        label: 'DEDUCT FROM ADVANCE',
                        child: _TextInput(controller: _deductCtrl,
                            hint: '$_deductFromAdv',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {})),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _FieldBox(
                        label: 'PENALTIES (MANUAL)',
                        child: _TextInput(controller: _penaltyCtrl, hint: '0',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {})),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _FieldBox(
                        label: 'PENALTY REASON',
                        child: _TextInput(controller: _penaltyReason,
                            hint: 'e.g. Late arrival...'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Net Payable highlight
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _netPayable >= 0
                          ? _kGreen.withOpacity(0.08)
                          : _kRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _netPayable >= 0
                            ? _kGreen.withOpacity(0.3)
                            : _kRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NET PAYABLE', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 0.4, color: _kDark.withOpacity(0.5),
                        )),
                        Text(
                          'SAR ${_netPayable.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: _netPayable >= 0 ? _kGreen : _kRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FieldBox(
                    label: 'PAY FROM (CASH / BANK) *',
                    child: _DropInput(
                      hint: 'Select account...',
                      value: _selectedAccount,
                      items: const ['Cash On Hand', 'Bank Account'],
                      onChanged: (v) => setState(() => _selectedAccount = v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FieldBox(
                    label: 'PAYROLL NOTES (OPTIONAL)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kPrimary.withOpacity(0.45), width: 1.5),
                      ),
                      child: TextField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13, color: _kDark),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Internal note for this payout',
                          hintStyle: TextStyle(fontSize: 13, color: _kDark.withOpacity(0.35)),
                          isDense: true, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Post button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDark,
                  foregroundColor: _kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Post Salary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              ),
            ),
          ],

          // ── Recent payments ────────────────────────────────────────────
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 14, color: _kDark.withOpacity(0.6)),
              const SizedBox(width: 7),
              const Text('RECENT SALARY PAYMENTS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kDark, letterSpacing: 0.2)),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.salaryPayments.isEmpty)
            _EmptyState(message: 'No salary payments yet')
          else
            ...widget.salaryPayments.map((p) => _SalaryPaymentCard(payment: p)),
        ],
      ),
    );
  }
}

// Readonly display field
class _ReadonlyField extends StatelessWidget {
  final String text;
  final Color? color;
  const _ReadonlyField({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: color ?? _kDark,
      )),
    );
  }
}

// Text input reusable
class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  const _TextInput({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withOpacity(0.45), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: _kDark),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: _kDark.withOpacity(0.35)),
          isDense: true, contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;
  const _PostRow({required this.label, required this.value, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        Text(value, style: TextStyle(
          fontSize: gold ? 16 : 13,
          fontWeight: FontWeight.w700,
          color: gold ? _kPrimary : Colors.white,
        )),
      ],
    );
  }
}

class _SalaryPaymentCard extends StatelessWidget {
  final _SalaryPayment payment;
  const _SalaryPaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final d = payment.date;
    final dateStr = '${d.day} ${_monthName(d.month)} ${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.empName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
                  const SizedBox(height: 2),
                  Text('$dateStr · ${payment.paidFrom}', style: TextStyle(fontSize: 11, color: _kDark.withOpacity(0.4))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _kDark.withOpacity(0.07), borderRadius: BorderRadius.circular(6)),
                child: Text(payment.period, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _kDark.withOpacity(0.6))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 2x2 grid
          Row(
            children: [
              Expanded(child: _SpStat(label: 'SALARY', value: 'SAR ${payment.salary.toStringAsFixed(0)}')),
              const SizedBox(width: 8),
              Expanded(child: _SpStat(label: 'COMMISSION', value: 'SAR ${payment.commission.toStringAsFixed(0)}', color: const Color(0xFFC07900))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SpStat(label: 'DEDUCTIONS', value: 'SAR ${payment.deductions.toStringAsFixed(0)}', color: _kRed)),
              const SizedBox(width: 8),
              Expanded(child: _SpStat(label: 'ADVANCE DEDUCTED', value: 'SAR ${payment.advanceDeducted.toStringAsFixed(0)}', color: _kRed)),
            ],
          ),
          const SizedBox(height: 10),
          // Net row (dark)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Paid', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                Text(
                  'SAR ${payment.netPaid.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

class _SpStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SpStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _kDark.withOpacity(0.38))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? _kDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — Employee Ledger
// ─────────────────────────────────────────────────────────────────────────────

class _EmployeeLedgerTab extends StatefulWidget {
  final List<_EmployeeRow> employees;
  final String selectedBranch;
  final String employeeFilter;
  final String monthFilter;
  final bool allPeriods;
  const _EmployeeLedgerTab({
    required this.employees,
    required this.selectedBranch,
    required this.employeeFilter,
    required this.monthFilter,
    required this.allPeriods,
  });

  @override
  State<_EmployeeLedgerTab> createState() => _EmployeeLedgerTabState();
}

class _EmployeeLedgerTabState extends State<_EmployeeLedgerTab> {
  // Sample ledger transactions (shown when an employee is selected)
  final List<_LedgerTx> _sampleTxs = [
    _LedgerTx(
      description: 'Commission — Invoice #1042',
      date: DateTime(2026, 6, 14),
      period: 'June 2026',
      type: _LedgerTxType.earning,
      amount: 320,
      netPosition: 320,
      pills: const ['Earning', 'Invoice'],
    ),
    _LedgerTx(
      description: 'Advance Paid',
      date: DateTime(2026, 6, 10),
      period: 'Cash On Hand',
      type: _LedgerTxType.advance,
      amount: -500,
      netPosition: -180,
      pills: const ['Advance', 'Medical emergency'],
    ),
    _LedgerTx(
      description: 'Salary Posted',
      date: DateTime(2026, 6, 15),
      period: 'Cash On Hand',
      type: _LedgerTxType.salary,
      amount: 1500,
      netPosition: 1320,
      pills: const ['Salary', 'June 2026'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
        children: [
          // Selector card
          _FormCard(
            child: Column(
              children: [
                _FieldBox(
                  label: 'EMPLOYEE / TECHNICIAN',
                  child: _DropInput(
                    hint: 'Select employee...',
                    value: widget.employeeFilter == 'All Employees' ? null : widget.employeeFilter,
                    items: widget.employees.map((e) => e.name).toList(),
                    onChanged: (v) {},
                  ),
                ),
                const SizedBox(height: 10),
                _FieldBox(
                  label: 'PERIOD (MONTH)',
                  child: _InputRow(
                    text: widget.allPeriods ? 'All Periods' : widget.monthFilter,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live notice
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.play_circle_outline_rounded, size: 13, color: _kDark.withOpacity(0.3)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Live ledger — commissions accrue automatically when invoices post. Refreshes every 45s.',
                  style: TextStyle(fontSize: 11, color: _kDark.withOpacity(0.42), height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.employeeFilter == 'All Employees') ...[
            _EmptyState(message: 'Select an employee to view\ntheir full transaction ledger'),
          ] else ...[
            // Ledger summary pills
            SizedBox(
              height: 68,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _LedgerStatCard(label: 'EARNINGS',      value: 'SAR 0.00', color: _kGreen),
                  const SizedBox(width: 7),
                  _LedgerStatCard(label: 'DEDUCTIONS',    value: 'SAR 0.00', color: _kRed),
                  const SizedBox(width: 7),
                  _LedgerStatCard(label: 'PAID OUT',      value: 'SAR 0.00', color: _kBlue),
                  const SizedBox(width: 7),
                  _LedgerStatCard(label: 'ADVANCE DUE',   value: 'SAR 0.00', color: _kRed),
                  const SizedBox(width: 7),
                  _LedgerStatCard(label: 'COMM. PENDING', value: 'SAR 0.00', color: _kPurple),
                  const SizedBox(width: 7),
                  _LedgerStatCard(label: 'NET PAYABLE',   value: 'SAR 0.00', color: _kDark),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Transactions section label
            Row(
              children: [
                Icon(Icons.person_rounded, size: 14, color: _kDark.withOpacity(0.6)),
                const SizedBox(width: 7),
                const Text('TRANSACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kDark)),
              ],
            ),
            const SizedBox(height: 8),

            ..._sampleTxs.map((tx) => _LedgerTxCard(tx: tx)),
          ],
        ],
      ),
    );
  }
}

class _LedgerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LedgerStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _kDark.withOpacity(0.38))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _LedgerTxCard extends StatelessWidget {
  final _LedgerTx tx;
  const _LedgerTxCard({required this.tx});

  Color get _iconBg {
    switch (tx.type) {
      case _LedgerTxType.earning:   return _kGreen.withOpacity(0.12);
      case _LedgerTxType.deduction: return _kRed.withOpacity(0.12);
      case _LedgerTxType.advance:   return _kPrimary.withOpacity(0.15);
      case _LedgerTxType.salary:    return _kBlue.withOpacity(0.12);
    }
  }
  Color get _iconFg {
    switch (tx.type) {
      case _LedgerTxType.earning:   return _kGreen;
      case _LedgerTxType.deduction: return _kRed;
      case _LedgerTxType.advance:   return const Color(0xFFC07900);
      case _LedgerTxType.salary:    return _kBlue;
    }
  }
  IconData get _icon {
    switch (tx.type) {
      case _LedgerTxType.earning:   return Icons.currency_exchange_rounded;
      case _LedgerTxType.deduction: return Icons.remove_circle_outline_rounded;
      case _LedgerTxType.advance:   return Icons.account_balance_wallet_rounded;
      case _LedgerTxType.salary:    return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = tx.date;
    final dateStr = '${d.day} ${_monthName(d.month)} ${d.year} · ${tx.period}';
    final isCredit = tx.amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Type icon
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(11)),
                child: Icon(_icon, color: _iconFg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kDark)),
                    const SizedBox(height: 2),
                    Text(dateStr, style: TextStyle(fontSize: 11, color: _kDark.withOpacity(0.4))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : ''}SAR ${tx.amount.abs().toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isCredit ? _kGreen : _kRed),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Net: SAR ${tx.netPosition.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10.5, color: _kDark.withOpacity(0.4)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pills
          Row(
            children: tx.pills.asMap().entries.map((e) {
              final i = e.key;
              final pill = e.value;
              Color bg = Colors.black.withOpacity(0.04);
              Color fg = _kDark.withOpacity(0.5);
              if (i == 0) {
                switch (tx.type) {
                  case _LedgerTxType.earning:
                    bg = _kGreen.withOpacity(0.1); fg = const Color(0xFF1A8C54); break;
                  case _LedgerTxType.advance:
                  case _LedgerTxType.deduction:
                    bg = _kRed.withOpacity(0.1); fg = _kRed; break;
                  case _LedgerTxType.salary:
                    bg = _kGreen.withOpacity(0.1); fg = const Color(0xFF1A8C54); break;
                }
              }
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(pill, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final Widget child;
  final String? title;
  const _FormCard({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: _kDark.withOpacity(0.4))),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _kDark.withOpacity(0.45))),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InputRow({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withOpacity(0.45), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _kDark))),
          Icon(icon, size: 15, color: _kDark.withOpacity(0.3)),
        ],
      ),
    );
  }
}

class _DropInput extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropInput({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withOpacity(0.45), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: _kDark.withOpacity(0.35))),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: _kDark),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _kDark.withOpacity(0.3)),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_search_rounded, size: 44, color: _kDark.withOpacity(0.12)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kDark.withOpacity(0.38), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PAY ADVANCE SHEET
// Fields from screenshot: Employee, Amount (SAR), Date, Pay From, Reason
// Footer note + Cancel / Pay & Post to 1250
// ═════════════════════════════════════════════════════════════════════════════

class PayAdvanceSheet extends StatefulWidget {
  const PayAdvanceSheet({super.key});

  @override
  State<PayAdvanceSheet> createState() => _PayAdvanceSheetState();
}

class _PayAdvanceSheetState extends State<PayAdvanceSheet> {
  String? _employee;
  String? _payFrom;
  final _amountCtrl  = TextEditingController(text: '0.00');
  final _reasonCtrl  = TextEditingController();
  final _dateCtrl    = TextEditingController(text: _todayFormatted());

  static const _employees = ['Arif عريف', 'Bashar بشار', 'jabriel جبريل', 'Sultan'];
  static const _accounts  = ['Cashier Till — Sultan', 'Cash On Hand', 'Petty Cash Wallet — Sultan', 'Bank Account'];

  static String _todayFormatted() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2,'0')}/${n.month.toString().padLeft(2,'0')}/${n.year}';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pay Salary Advance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kDark),
                ),
                const Spacer(),
                _CloseBtn(),
              ],
            ),
            const SizedBox(height: 24),

            // Employee
            _SheetFieldLabel('Employee *'),
            _SheetDropdown(
              hint: 'Select employee',
              value: _employee,
              items: _employees,
              onChanged: (v) => setState(() => _employee = v),
            ),
            const SizedBox(height: 16),

            // Amount + Date row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetFieldLabel('Amount (SAR) *'),
                      _SheetTextInput(
                        controller: _amountCtrl,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetFieldLabel('Date *'),
                      _SheetDateField(controller: _dateCtrl),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pay From
            _SheetFieldLabel('Pay From (Cash / Bank) *'),
            _SheetDropdown(
              hint: 'Select account',
              value: _payFrom,
              items: _accounts,
              onChanged: (v) => setState(() => _payFrom = v),
            ),
            const SizedBox(height: 16),

            // Reason
            _SheetFieldLabel('Reason'),
            _SheetTextArea(controller: _reasonCtrl, hint: 'Purpose of advance...'),
            const SizedBox(height: 14),

            // GL note
            Text(
              'Posts Dr employee receivable (under 1250) · Cr pay-from account',
              style: TextStyle(fontSize: 12, color: _kDark.withOpacity(0.4)),
            ),
            const SizedBox(height: 20),

            // Buttons
            OwnerSheetActions(
              onCancel: () => Navigator.pop(context),
              onPrimary: () => Navigator.pop(context),
              primaryLabel: 'Pay & Post to 1250',
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BULK ADVANCES SHEET
// Fields from screenshot: Employee / Amount / Date / Pay From / Reason per row
// Dynamic rows, + Add Row, Pay N Advance(s)
// ═════════════════════════════════════════════════════════════════════════════

class _BulkRow {
  String? employee;
  String? payFrom;
  final amountCtrl = TextEditingController(text: '0.00');
  final reasonCtrl = TextEditingController();
  String date;
  _BulkRow({this.employee, this.payFrom, required this.date});
  void dispose() {
    amountCtrl.dispose();
    reasonCtrl.dispose();
  }
}

class BulkAdvancesSheet extends StatefulWidget {
  const BulkAdvancesSheet({super.key});

  @override
  State<BulkAdvancesSheet> createState() => _BulkAdvancesSheetState();
}

class _BulkAdvancesSheetState extends State<BulkAdvancesSheet> {
  static const _employees = ['Arif عريف', 'Bashar بشار', 'jabriel جبريل', 'Sultan'];
  static const _accounts  = ['Cash On Hand', 'Bank Account', 'Cashier Till — Sultan', 'Petty Cash Wallet — Sultan'];

  static String _todayFormatted() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2,'0')}/${n.month.toString().padLeft(2,'0')}/${n.year}';
  }

  late List<_BulkRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      _BulkRow(employee: 'Arif عريف', payFrom: 'Cash On Hand', date: _todayFormatted()),
      _BulkRow(date: _todayFormatted()),
    ];
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_BulkRow(date: _todayFormatted())));

  void _removeRow(int i) {
    _rows[i].dispose();
    setState(() => _rows.removeAt(i));
  }

  int get _filledCount => _rows.where((r) => r.employee != null).length;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.group_rounded, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bulk Pay Advances',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kDark),
              ),
              const Spacer(),
              _CloseBtn(),
            ],
          ),
          const SizedBox(height: 20),

          // Column labels
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(flex: 5, child: _ColLabel('Employee *')),
                const SizedBox(width: 6),
                Expanded(flex: 3, child: _ColLabel('Amount *')),
                const SizedBox(width: 6),
                Expanded(flex: 4, child: _ColLabel('Date *')),
                const SizedBox(width: 6),
                Expanded(flex: 5, child: _ColLabel('Pay From *')),
                const SizedBox(width: 6),
                Expanded(flex: 5, child: _ColLabel('Reason')),
                const SizedBox(width: 32), // for delete btn
              ],
            ),
          ),

          // Rows (scrollable if many)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _BulkRowWidget(
                row: _rows[i],
                employees: _employees,
                accounts: _accounts,
                onRemove: _rows.length > 1 ? () => _removeRow(i) : null,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Add Row button
          GestureDetector(
            onTap: _addRow,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: _kDark.withOpacity(0.25), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: _kDark.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text('Add Row', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kDark.withOpacity(0.7))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom buttons
          OwnerSheetActions(
            onCancel: () => Navigator.pop(context),
            onPrimary: () => Navigator.pop(context),
            primaryLabel:
                'Pay ${_filledCount > 0 ? _filledCount : _rows.length} Advance(s)',
          ),
        ],
      ),
    );
  }
}

// ─── Single bulk row widget ───────────────────────────────────────────────────

class _BulkRowWidget extends StatelessWidget {
  final _BulkRow row;
  final List<String> employees;
  final List<String> accounts;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _BulkRowWidget({
    required this.row,
    required this.employees,
    required this.accounts,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Employee
        Expanded(
          flex: 5,
          child: _InlineDropdown(
            hint: 'Select...',
            value: row.employee,
            items: employees,
            onChanged: (v) { row.employee = v; onChanged(); },
          ),
        ),
        const SizedBox(width: 6),
        // Amount
        Expanded(
          flex: 3,
          child: _InlineTextInput(
            controller: row.amountCtrl,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 6),
        // Date
        Expanded(
          flex: 4,
          child: _InlineDateField(date: row.date),
        ),
        const SizedBox(width: 6),
        // Pay From
        Expanded(
          flex: 5,
          child: _InlineDropdown(
            hint: 'Select...',
            value: row.payFrom,
            items: accounts,
            onChanged: (v) { row.payFrom = v; onChanged(); },
          ),
        ),
        const SizedBox(width: 6),
        // Reason
        Expanded(
          flex: 5,
          child: _InlineTextInput(
            controller: row.reasonCtrl,
            hint: 'Reason...',
          ),
        ),
        const SizedBox(width: 6),
        // Delete
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: onRemove != null ? _kRed.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: onRemove != null ? _kRed : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared Sheet Widgets  (app theme — no extra imports needed)
// ═════════════════════════════════════════════════════════════════════════════

// Close button (top-right of sheets)
class _CloseBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 18, color: _kDark.withOpacity(0.5)),
      ),
    );
  }
}

// Field label for Pay Advance sheet
class _SheetFieldLabel extends StatelessWidget {
  final String text;
  const _SheetFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kDark),
      ),
    );
  }
}

// Column header label for Bulk sheet
class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _kDark.withOpacity(0.55), letterSpacing: 0.2),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Full-width dropdown (Pay Advance sheet)
class _SheetDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _SheetDropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return OwnerStyledDropdown<String>(
      value: value,
      hint: hint,
      height: 48,
      options: items
          .map((i) => OwnerDropdownOption(value: i, label: i))
          .toList(),
      onChanged: onChanged,
      triggerStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

// Text input (Pay Advance sheet)
class _SheetTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _SheetTextInput({required this.controller, required this.hint, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: _kDark),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: _kDark.withOpacity(0.35)),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// Date field (Pay Advance sheet) — shows calendar icon
class _SheetDateField extends StatelessWidget {
  final TextEditingController controller;
  const _SheetDateField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(controller.text, style: const TextStyle(fontSize: 14, color: _kDark)),
          ),
          Icon(Icons.calendar_month_rounded, size: 18, color: _kDark.withOpacity(0.4)),
        ],
      ),
    );
  }
}

// Textarea (Pay Advance sheet)
class _SheetTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _SheetTextArea({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: _kDark),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: _kDark.withOpacity(0.35)),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ── Inline compact widgets for Bulk sheet rows ────────────────────────────────

class _InlineDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _InlineDropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return OwnerStyledDropdown<String>(
      value: value,
      hint: hint,
      height: 40,
      options: items
          .map((i) => OwnerDropdownOption(value: i, label: i))
          .toList(),
      onChanged: onChanged,
      triggerStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

class _InlineTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _InlineTextInput({required this.controller, required this.hint, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12, color: _kDark),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: _kDark.withOpacity(0.35)),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _InlineDateField extends StatelessWidget {
  final String date;
  const _InlineDateField({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: Text(date, style: const TextStyle(fontSize: 12, color: _kDark))),
          Icon(Icons.calendar_month_rounded, size: 15, color: _kDark.withOpacity(0.4)),
        ],
      ),
    );
  }
}