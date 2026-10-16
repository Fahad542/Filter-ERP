import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../widgets/owner_styled_dropdown.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../../owner_shell.dart';

// CashBookView — Cash ledger with filters + table
// ─────────────────────────────────────────────────────────────────────────────

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key});

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  // ── Filter state ──────────────────────────────────────────────────────────
  String? _selectedMethod;   // null = All Methods
  String? _selectedBranch;   // null = All Branches
  String? _selectedUser;     // null = All Users
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';

  static const List<String> _methods = ['Cash', 'Card', 'Bank Transfer', 'Cheque'];
  static const List<String> _branches = ['Main Branch', 'North Branch', 'East Branch'];
  static const List<String> _users = ['Sultan', 'Ahmed', 'Fahad', 'Omar'];

  List<CashBookEntry> get _filteredEntries {
    return CashBookDummyData.entries.where((e) {
      final matchesMethod = _selectedMethod == null || e.method == _selectedMethod;
      final matchesBranch = _selectedBranch == null || e.branch == _selectedBranch;
      final matchesUser  = _selectedUser  == null || e.owner == _selectedUser;
      final matchesSearch = _searchQuery.isEmpty ||
          e.reference.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.account.toLowerCase().contains(_searchQuery.toLowerCase());
      DateTime? entryDate;
      try {
        final parts = e.date.split('/');
        entryDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (_) {}
      final matchesFrom = _fromDate == null ||
          (entryDate != null && !entryDate.isBefore(_fromDate!));
      final matchesTo = _toDate == null ||
          (entryDate != null && !entryDate.isAfter(_toDate!));
      return matchesMethod && matchesBranch && matchesUser &&
          matchesSearch && matchesFrom && matchesTo;
    }).toList();
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primaryLight),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final totalOut = entries
        .where((e) => e.direction == CashDirection.out)
        .fold(0.0, (s, e) => s + e.amount);
    final totalIn = entries
        .where((e) => e.direction == CashDirection.inflow)
        .fold(0.0, (s, e) => s + e.amount);
    final totalAll = CashBookDummyData.entries.length;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: const OwnerDashboardTitle(subtitle: 'Cash Book'),
        showDrawer: true,
        showNotification: true,
        onNotificationPressed: () => OwnerShell.goToNotifications(context),
      ),
      body: Column(
        children: [
          // ── KPI cards ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ReusableKpiGrid(
              showFeatured: false,
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              metrics: [
                ReusableKpiMetric(
                  title: 'Total Out',
                  value: 'SAR ${totalOut.toStringAsFixed(2)}',
                  subtitle: '',
                  icon: Icons.arrow_upward_rounded,
                ),
                ReusableKpiMetric(
                  title: 'Total In',
                  value: 'SAR ${totalIn.toStringAsFixed(2)}',
                  subtitle: '',
                  icon: Icons.arrow_downward_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Filter card ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Search (full width)
                  _SearchField(
                    value: _searchQuery,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 10),
                  // Row 2: three dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          label: 'METHOD',
                          value: _selectedMethod,
                          items: _methods,
                          hint: 'All Methods',
                          onChanged: (v) => setState(() => _selectedMethod = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'BRANCH',
                          value: _selectedBranch,
                          items: _branches,
                          hint: 'All Branches',
                          onChanged: (v) => setState(() => _selectedBranch = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'USER',
                          value: _selectedUser,
                          items: _users,
                          hint: 'All Users',
                          onChanged: (v) => setState(() => _selectedUser = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 3: From / To dates
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'FROM',
                          value: _fromDate,
                          onTap: () => _pickDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DatePickerField(
                          label: 'TO',
                          value: _toDate,
                          onTap: () => _pickDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Card list ────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 600)),
              color: AppColors.primaryLight,
              child: entries.isEmpty
                  ? _EmptyTableState()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                physics: const BouncingScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) =>
                    _PaymentCard(entry: entries[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PaymentCard — card view for each cash book entry
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final CashBookEntry entry;
  const _PaymentCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.direction == CashDirection.inflow;
    final directionColor =
    isIn ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final directionBg =
    isIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

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
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              // Method icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _iconForMethod(entry.method),
                  size: 18,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.reference,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _MethodBadge(method: entry.method),
                        const SizedBox(width: 6),
                        Text(
                          entry.date,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // In / Out badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: directionBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: directionColor.withOpacity(0.2)),
                ),
                child: Text(
                  isIn ? 'IN' : 'OUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: directionColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),

          // ── Description ────────────────────────────────────────────────
          Text(
            entry.description,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ── Detail row: Branch + Owner ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DetailItem(label: 'BRANCH', value: entry.branch),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'OWNER',
                  value: entry.owner.isEmpty ? '—' : entry.owner,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Amount + Account ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'AMOUNT',
                  value: 'SAR ${entry.amount.toStringAsFixed(2)}',
                  highlight: isIn,
                  highlightColor: directionColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  label: 'ACCOUNT',
                  value: entry.account,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
      case 'mada':
        return Icons.credit_card_rounded;
      case 'bank transfer':
      case 'transfer':
        return Icons.account_balance_rounded;
      case 'cheque':
        return Icons.receipt_long_outlined;
      default:
        return Icons.attach_money_rounded;
    }
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.25)),
      ),
      child: Text(
        method,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD97706),
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
          label,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const _InfoPill({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlightColor ?? AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? color.withOpacity(0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? color.withOpacity(0.18)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: highlight ? color : const Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value ?? '__all__';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        OwnerStyledDropdown<String>(
          value: selected,
          displayLabel: value ?? hint,
          hint: hint,
          height: 38,
          backgroundColor: OwnerUi.scaffoldBackground,
          borderColor: Colors.grey.shade200,
          options: [
            OwnerDropdownOption(value: '__all__', label: hint),
            ...items.map((i) => OwnerDropdownOption(value: i, label: i)),
          ],
          onChanged: (v) => onChanged(v == '__all__' ? null : v),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? 'dd/mm/yyyy'
        : '${value!.day.toString().padLeft(2, '0')}/'
        '${value!.month.toString().padLeft(2, '0')}/'
        '${value!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: OwnerUi.scaffoldBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: value == null
                          ? Colors.grey.shade400
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEARCH',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: OwnerUi.scaffoldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Description / reference...',
              hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTableState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'No entries found',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models & Dummy Data
// ─────────────────────────────────────────────────────────────────────────────

enum CashDirection { inflow, out }

class CashBookEntry {
  final String date;
  final CashDirection direction;
  final double amount;
  final String method;
  final String account;
  final String accountCode;
  final String branch;
  final String owner;
  final String reference;
  final String description;

  const CashBookEntry({
    required this.date,
    required this.direction,
    required this.amount,
    required this.method,
    required this.account,
    required this.accountCode,
    required this.branch,
    required this.owner,
    required this.reference,
    required this.description,
  });
}

abstract class CashBookDummyData {
  static const List<CashBookEntry> entries = [
    CashBookEntry(
      date: '11/06/2026',
      direction: CashDirection.inflow,
      amount: 850.00,
      method: 'Cash',
      account: 'Cash On Hand',
      accountCode: 'CB-8-1780508546110-0',
      branch: 'Main Branch',
      owner: 'Sultan',
      reference: 'RCP-0012',
      description: 'Customer payment',
    ),
    CashBookEntry(
      date: '10/06/2026',
      direction: CashDirection.out,
      amount: 50.00,
      method: 'Cash',
      account: 'Cash On Hand',
      accountCode: 'CB-8-1780508546110-0',
      branch: 'Main Branch',
      owner: '',
      reference: 'test-inv-3-june',
      description: 'ok',
    ),
    CashBookEntry(
      date: '10/06/2026',
      direction: CashDirection.inflow,
      amount: 1230.75,
      method: 'Card',
      account: 'POS Terminal',
      accountCode: 'CB-8-178050854611-1',
      branch: 'Main Branch',
      owner: 'Ahmed',
      reference: 'RCP-0011',
      description: 'Card payment received',
    ),
    CashBookEntry(
      date: '09/06/2026',
      direction: CashDirection.out,
      amount: 624.75,
      method: 'Bank Transfer',
      account: 'Bank Al-Rajhi',
      accountCode: 'CB-8-178050854611-2',
      branch: 'North Branch',
      owner: 'Fahad',
      reference: 'WLPI-12',
      description: 'Supplier payment',
    ),
    CashBookEntry(
      date: '08/06/2026',
      direction: CashDirection.inflow,
      amount: 3100.00,
      method: 'Cheque',
      account: 'Cheque Clearing',
      accountCode: 'CB-8-178050854611-3',
      branch: 'Main Branch',
      owner: 'Omar',
      reference: 'RCP-0009',
      description: 'Post-dated cheque deposit',
    ),
    CashBookEntry(
      date: '07/06/2026',
      direction: CashDirection.out,
      amount: 415.50,
      method: 'Cash',
      account: 'Petty Cash',
      accountCode: 'CB-8-178050854611-4',
      branch: 'East Branch',
      owner: '',
      reference: 'PC-EXP-018',
      description: 'Office supplies',
    ),
    CashBookEntry(
      date: '06/06/2026',
      direction: CashDirection.inflow,
      amount: 980.00,
      method: 'Card',
      account: 'POS Terminal',
      accountCode: 'CB-8-178050854611-1',
      branch: 'North Branch',
      owner: 'Ahmed',
      reference: 'RCP-0007',
      description: 'Service payment',
    ),
    CashBookEntry(
      date: '03/06/2026',
      direction: CashDirection.out,
      amount: 235.75,
      method: 'Bank Transfer',
      account: 'Bank Al-Rajhi',
      accountCode: 'CB-8-178050854611-2',
      branch: 'Main Branch',
      owner: 'Sultan',
      reference: 'WPI-SI-47',
      description: 'Supplier invoice approved',
    ),
  ];
}