import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/custom_search_bar.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../../owner_shell.dart';

// ExpensesView — Expense entry log
// ─────────────────────────────────────────────────────────────────────────────

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  String _searchQuery = '';
  String? _selectedBranch;
  String? _selectedUser;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<String> get _branches =>
      ExpensesDummyData.entries.map((e) => e.branch).toSet().toList()..sort();

  List<String> get _users =>
      ExpensesDummyData.entries.map((e) => e.user).toSet().toList()..sort();

  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('/');
      return DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }

  List<Expense> get _filteredExpenses {
    return ExpensesDummyData.entries.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesBranch =
          _selectedBranch == null || e.branch == _selectedBranch;
      final matchesUser = _selectedUser == null || e.user == _selectedUser;
      final eDate = _parseDate(e.date);
      final afterFrom = _fromDate == null ||
          (eDate != null && !eDate.isBefore(_fromDate!));
      final beforeTo =
          _toDate == null || (eDate != null && !eDate.isAfter(_toDate!));
      return matchesSearch && matchesBranch && matchesUser && afterFrom && beforeTo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _filteredExpenses;
    final allEntries = ExpensesDummyData.entries;
    final approvedList =
        allEntries.where((e) => e.status == ExpenseStatus.approved).toList();
    final totalApproved = approvedList.fold(0.0, (sum, e) => sum + e.amount);
    final pendingCount =
        allEntries.where((e) => e.status == ExpenseStatus.pending).length;
    final totalAmount = allEntries.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: const OwnerDashboardTitle(subtitle: 'Expenses'),
        showDrawer: true,
        showNotification: true,
        onNotificationPressed: () => OwnerShell.goToNotifications(context),
      ),
      body: Column(
        children: [
          // ── KPI cards ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: ReusableKpiGrid(
              showFeatured: true,
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              metrics: [
                ReusableKpiMetric(
                  title: 'Total Approved',
                  value: 'SAR ${totalApproved.toStringAsFixed(2)}',
                  subtitle:
                      '${approvedList.length} of ${allEntries.length} rows',
                  icon: Icons.wallet_rounded,
                ),
                ReusableKpiMetric(
                  title: 'All Expenses',
                  value: '${allEntries.length}',
                  subtitle: 'SAR ${totalAmount.toStringAsFixed(2)}',
                  icon: Icons.receipt_long_rounded,
                ),
                ReusableKpiMetric(
                  title: 'Pending',
                  value: '$pendingCount',
                  subtitle: 'Awaiting approval',
                  icon: Icons.pending_actions_rounded,
                ),
              ],
            ),
          ),

          // ── Search + Filter row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    hintText: 'Category / description...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                _ExpenseFilterButton(
                  selectedBranch: _selectedBranch,
                  selectedUser: _selectedUser,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  branches: _branches,
                  users: _users,
                  onApply: (branch, user, from, to) {
                    setState(() {
                      _selectedBranch = branch;
                      _selectedUser = user;
                      _fromDate = from;
                      _toDate = to;
                    });
                  },
                ),
              ],
            ),
          ),

          // ── Entry list ────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  await Future.delayed(const Duration(milliseconds: 600)),
              color: AppColors.primaryLight,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _EntriesHeader(
                      count: expenses.length,
                      onRefresh: () => setState(() {}),
                    ),
                  ),

                  if (expenses.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyExpensesState()),

                  SliverList.separated(
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ExpenseCard(expense: expenses[i]),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
// _ExpenseFilterButton
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseFilterButton extends StatelessWidget {
  final String? selectedBranch;
  final String? selectedUser;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> branches;
  final List<String> users;
  final void Function(
      String? branch, String? user, DateTime? from, DateTime? to) onApply;

  const _ExpenseFilterButton({
    required this.selectedBranch,
    required this.selectedUser,
    required this.fromDate,
    required this.toDate,
    required this.branches,
    required this.users,
    required this.onApply,
  });

  int get _activeCount {
    int count = 0;
    if (selectedBranch != null) count++;
    if (selectedUser != null) count++;
    if (fromDate != null || toDate != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = _activeCount > 0;

    return GestureDetector(
      onTap: () => _showFilterSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFiltered ? AppColors.secondaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isFiltered ? AppColors.secondaryLight : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color:
                  isFiltered ? AppColors.primaryLight : Colors.grey.shade500,
            ),
            const SizedBox(width: 5),
            Text(
              isFiltered ? 'Filters ($_activeCount)' : 'Filters',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isFiltered
                    ? AppColors.primaryLight
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color:
                  isFiltered ? AppColors.primaryLight : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExpenseFilterSheet(
        selectedBranch: selectedBranch,
        selectedUser: selectedUser,
        fromDate: fromDate,
        toDate: toDate,
        branches: branches,
        users: users,
        onApply: onApply,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExpenseFilterSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseFilterSheet extends StatefulWidget {
  final String? selectedBranch;
  final String? selectedUser;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> branches;
  final List<String> users;
  final void Function(
      String? branch, String? user, DateTime? from, DateTime? to) onApply;

  const _ExpenseFilterSheet({
    required this.selectedBranch,
    required this.selectedUser,
    required this.fromDate,
    required this.toDate,
    required this.branches,
    required this.users,
    required this.onApply,
  });

  @override
  State<_ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<_ExpenseFilterSheet> {
  String? _branch;
  String? _user;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _branch = widget.selectedBranch;
    _user = widget.selectedUser;
    _from = widget.fromDate;
    _to = widget.toDate;
  }

  void _reset() => setState(() {
        _branch = null;
        _user = null;
        _from = null;
        _to = null;
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Filter Expenses',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 18),

            // ── Branch ────────────────────────────────────────────────────
            _sheetSectionLabel('BRANCH'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(context, null, 'All Branches', _branch,
                    (v) => setState(() => _branch = v)),
                ...widget.branches.map(
                  (b) => _filterChip(
                      context, b, b, _branch, (v) => setState(() => _branch = v)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── User ──────────────────────────────────────────────────────
            _sheetSectionLabel('USER'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(context, null, 'All Users', _user,
                    (v) => setState(() => _user = v)),
                ...widget.users.map(
                  (u) => _filterChip(
                      context, u, u, _user, (v) => setState(() => _user = v)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Date range ────────────────────────────────────────────────
            _sheetSectionLabel('DATE RANGE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: 'From',
                    value: _from,
                    onPicked: (d) => setState(() => _from = d),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DatePickerTile(
                    label: 'To',
                    value: _to,
                    onPicked: (d) => setState(() => _to = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Buttons ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      widget.onApply(_branch, _user, _from, _to);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String label) => Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade400,
          letterSpacing: 0.8,
        ),
      );

  Widget _filterChip(
    BuildContext context,
    String? value,
    String label,
    String? selected,
    ValueChanged<String?> onChange,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryLight
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primaryLight : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DatePickerTile
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.secondaryLight,
                onPrimary: AppColors.primaryLight,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.secondaryLight.withOpacity(0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppColors.secondaryLight.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: hasValue
                  ? AppColors.secondaryLight
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasValue ? _format(value!) : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasValue
                      ? AppColors.primaryLight
                      : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: () => onPicked(null),
                child: Icon(Icons.close_rounded,
                    size: 12, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EntriesHeader
// ─────────────────────────────────────────────────────────────────────────────

class _EntriesHeader extends StatelessWidget {
  final int count;
  final VoidCallback onRefresh;

  const _EntriesHeader({required this.count, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count ${count == 1 ? 'entry' : 'entries'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
// _ExpenseCard
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final Expense expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(expense.status);
    final statusBg = _statusBg(expense.status);

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
          // ── Header row ────────────────────────────────────────────────
          Row(
            children: [
              // Category icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _iconForCategory(expense.category),
                  size: 18,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              // ID + category badge + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.id,
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
                          label: _formatCategory(expense.category),
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFEFF6FF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          expense.date,
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
              // Status badge
              _Badge(
                label: expense.status.label.toUpperCase(),
                color: statusColor,
                bg: statusBg,
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),

          // ── Description ───────────────────────────────────────────────
          Text(
            expense.description,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ── User + Branch ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'User',
                  value: expense.user,
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Branch',
                  value: expense.branch,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Approved By ───────────────────────────────────────────────
          _DetailItem(
            label: 'Approved By',
            value: expense.approvedBy,
          ),

          const SizedBox(height: 10),

          // ── Amount pill ───────────────────────────────────────────────
          _AmountPill(amount: expense.amount),

          const SizedBox(height: 10),

          // ── Actions row ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.print_outlined,
                label: 'Print',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ExpenseStatus s) => switch (s) {
        ExpenseStatus.approved => const Color(0xFF059669),
        ExpenseStatus.pending => const Color(0xFFD97706),
        ExpenseStatus.rejected => const Color(0xFFDC2626),
      };

  Color _statusBg(ExpenseStatus s) => switch (s) {
        ExpenseStatus.approved => const Color(0xFFD1FAE5),
        ExpenseStatus.pending => const Color(0xFFFEF3C7),
        ExpenseStatus.rejected => const Color(0xFFFEE2E2),
      };

  IconData _iconForCategory(String category) => switch (category) {
        'rent' => Icons.home_work_rounded,
        'utilities' => Icons.bolt_rounded,
        'salaries' => Icons.people_rounded,
        'supplies' => Icons.inventory_2_rounded,
        'maintenance' => Icons.build_rounded,
        'marketing' => Icons.campaign_rounded,
        'transport' => Icons.local_shipping_rounded,
        'insurance' => Icons.verified_user_rounded,
        _ => Icons.payments_rounded,
      };

  String _formatCategory(String category) =>
      category.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

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
  final Color? valueColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AmountPill extends StatelessWidget {
  final double amount;

  const _AmountPill({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AMOUNT',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'SAR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryLight,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpensesState extends StatelessWidget {
  const _EmptyExpensesState();

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
            Icon(Icons.receipt_long_outlined,
                size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No expenses found.',
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
// Models & Dummy Data
// ─────────────────────────────────────────────────────────────────────────────
// Place these in a separate file: expenses_models.dart

enum ExpenseStatus {
  approved,
  pending,
  rejected;

  String get label => switch (this) {
        ExpenseStatus.approved => 'Approved',
        ExpenseStatus.pending => 'Pending',
        ExpenseStatus.rejected => 'Rejected',
      };
}

class Expense {
  final String id;
  final String date;
  final double amount;
  final String category;
  final String user;
  final String branch;
  final String approvedBy;
  final String description;
  final ExpenseStatus status;

  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.user,
    required this.branch,
    required this.approvedBy,
    required this.description,
    required this.status,
  });
}

abstract class ExpensesDummyData {
  static const List<Expense> entries = [
    Expense(
      id: 'EXP-009',
      date: '14/06/2026',
      amount: 4500.00,
      category: 'salaries',
      user: 'Ahmed Al-Rashid',
      branch: 'Main Branch',
      approvedBy: 'Manager · Khalid',
      description: 'Monthly staff salaries — June 2026',
      status: ExpenseStatus.approved,
    ),
    Expense(
      id: 'EXP-008',
      date: '12/06/2026',
      amount: 850.00,
      category: 'rent',
      user: 'Sultan Al-Otaibi',
      branch: 'North Branch',
      approvedBy: 'Manager · Khalid',
      description: 'Monthly workshop rent — North Branch · June',
      status: ExpenseStatus.approved,
    ),
    Expense(
      id: 'EXP-007',
      date: '11/06/2026',
      amount: 215.75,
      category: 'utilities',
      user: 'Fahad Al-Qahtani',
      branch: 'Main Branch',
      approvedBy: 'Manager · Khalid',
      description: 'Electricity & water bill — May 2026',
      status: ExpenseStatus.approved,
    ),
    Expense(
      id: 'EXP-006',
      date: '10/06/2026',
      amount: 390.00,
      category: 'supplies',
      user: 'Ahmed Al-Rashid',
      branch: 'Main Branch',
      approvedBy: 'Pending',
      description: 'Workshop consumables — oils, filters, rags',
      status: ExpenseStatus.pending,
    ),
    Expense(
      id: 'EXP-005',
      date: '08/06/2026',
      amount: 125.50,
      category: 'transport',
      user: 'Sultan Al-Otaibi',
      branch: 'North Branch',
      approvedBy: 'Pending',
      description: 'Parts delivery & courier charges — week 23',
      status: ExpenseStatus.pending,
    ),
    Expense(
      id: 'EXP-004',
      date: '05/06/2026',
      amount: 1200.00,
      category: 'maintenance',
      user: 'Fahad Al-Qahtani',
      branch: 'Main Branch',
      approvedBy: 'Manager · Khalid',
      description: 'Hydraulic lift service & calibration',
      status: ExpenseStatus.approved,
    ),
    Expense(
      id: 'EXP-003',
      date: '03/06/2026',
      amount: 320.00,
      category: 'marketing',
      user: 'Ahmed Al-Rashid',
      branch: 'Main Branch',
      approvedBy: 'Rejected · Over budget',
      description: 'Social media ads — June campaign',
      status: ExpenseStatus.rejected,
    ),
    Expense(
      id: 'EXP-002',
      date: '02/06/2026',
      amount: 540.00,
      category: 'insurance',
      user: 'Sultan Al-Otaibi',
      branch: 'North Branch',
      approvedBy: 'Manager · Khalid',
      description: 'Workshop liability insurance — Q2 premium',
      status: ExpenseStatus.approved,
    ),
    Expense(
      id: 'EXP-001',
      date: '01/06/2026',
      amount: 88.00,
      category: 'utilities',
      user: 'Fahad Al-Qahtani',
      branch: 'Main Branch',
      approvedBy: 'Manager · Khalid',
      description: 'Internet & phone bill — June 2026',
      status: ExpenseStatus.approved,
    ),
  ];
}