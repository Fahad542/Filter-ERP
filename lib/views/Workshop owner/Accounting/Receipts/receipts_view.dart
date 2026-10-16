import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/custom_search_bar.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../../owner_shell.dart';
// ReceiptsView — Cash/Bank receipts log
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptsView extends StatefulWidget {
  const ReceiptsView({super.key});

  @override
  State<ReceiptsView> createState() => _ReceiptsViewState();
}

class _ReceiptsViewState extends State<ReceiptsView> {
  String _searchQuery = '';
  String? _selectedMethod; // null = All Methods
  String? _selectedBranch; // null = All branches
  String? _selectedOwner; // null = All users
  DateTime? _fromDate;
  DateTime? _toDate;

  // All unique methods / branches / owners from dummy data
  List<String> get _methods {
    final values = ReceiptsDummyData.entries.map((e) => e.method).toSet().toList()
      ..sort();
    return values;
  }

  List<String> get _branches {
    final values = ReceiptsDummyData.entries.map((e) => e.branch).toSet().toList()
      ..sort();
    return values;
  }

  List<String> get _owners {
    final values = ReceiptsDummyData.entries.map((e) => e.owner).toSet().toList()
      ..sort();
    return values;
  }

  List<ReceiptEntry> get _filteredEntries {
    return ReceiptsDummyData.entries.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.reference.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMethod = _selectedMethod == null || e.method == _selectedMethod;
      final matchesBranch = _selectedBranch == null || e.branch == _selectedBranch;
      final matchesOwner = _selectedOwner == null || e.owner == _selectedOwner;
      final entryDate = _parseDate(e.date);
      final matchesFrom = _fromDate == null ||
          !entryDate.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day));
      final matchesTo = _toDate == null ||
          !entryDate.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day));
      return matchesSearch &&
          matchesMethod &&
          matchesBranch &&
          matchesOwner &&
          matchesFrom &&
          matchesTo;
    }).toList();
  }

  DateTime _parseDate(String date) {
    // Expected format: dd/MM/yyyy
    final parts = date.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedMethod = null;
      _selectedBranch = null;
      _selectedOwner = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptsFilterBottomSheet(
        selectedMethod: _selectedMethod,
        selectedBranch: _selectedBranch,
        selectedOwner: _selectedOwner,
        methods: _methods,
        branches: _branches,
        owners: _owners,
        fromDate: _fromDate,
        toDate: _toDate,
        onMethodChanged: (v) => setState(() => _selectedMethod = v),
        onBranchChanged: (v) => setState(() => _selectedBranch = v),
        onOwnerChanged: (v) => setState(() => _selectedOwner = v),
        onFromDateChanged: (v) => setState(() => _fromDate = v),
        onToDateChanged: (v) => setState(() => _toDate = v),
        onReset: _clearFilters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final totalEntries = ReceiptsDummyData.entries.length;
    final totalIn = entries.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: const OwnerDashboardTitle(subtitle: 'Receipts'),
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
              showFeatured: false,
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              metrics: [
                ReusableKpiMetric(
                  title: 'Total In',
                  value: 'SAR ${totalIn.toStringAsFixed(2)}',
                  subtitle: '$totalEntries total receipts',
                  icon: Icons.south_west_rounded,
                ),
                ReusableKpiMetric(
                  title: 'Rows',
                  value: '${entries.length} / $totalEntries',
                  subtitle: 'Matching filters',
                  icon: Icons.filter_alt_outlined,
                ),
              ],
            ),
          ),

          // ── Search + Filter bar ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    hintText: 'Description / reference...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                _FilterIconButton(
                  hasActiveFilters: _selectedMethod != null ||
                      _selectedBranch != null ||
                      _selectedOwner != null ||
                      _fromDate != null ||
                      _toDate != null,
                  onTap: () => _showFilterBottomSheet(context),
                ),
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 600)),
              color: AppColors.primaryLight,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  if (entries.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyReceiptsState()),

                  SliverList.separated(
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ReceiptEntryCard(entry: entries[i]),
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
// _FilterIconButton — shown next to search bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterIconButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onTap;

  const _FilterIconButton({
    required this.hasActiveFilters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: hasActiveFilters
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasActiveFilters
                ? const Color(0xFF1E293B)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 20,
              color: hasActiveFilters ? Colors.white : Colors.grey.shade600,
            ),
            if (hasActiveFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReceiptsFilterBottomSheet — Expenses-style filter sheet (instant apply)
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptsFilterBottomSheet extends StatefulWidget {
  final String? selectedMethod;
  final String? selectedBranch;
  final String? selectedOwner;
  final List<String> methods;
  final List<String> branches;
  final List<String> owners;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String?> onBranchChanged;
  final ValueChanged<String?> onOwnerChanged;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final VoidCallback onReset;

  const _ReceiptsFilterBottomSheet({
    required this.selectedMethod,
    required this.selectedBranch,
    required this.selectedOwner,
    required this.methods,
    required this.branches,
    required this.owners,
    required this.fromDate,
    required this.toDate,
    required this.onMethodChanged,
    required this.onBranchChanged,
    required this.onOwnerChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onReset,
  });

  @override
  State<_ReceiptsFilterBottomSheet> createState() =>
      _ReceiptsFilterBottomSheetState();
}

class _ReceiptsFilterBottomSheetState
    extends State<_ReceiptsFilterBottomSheet> {
  late String? _method;
  late String? _branch;
  late String? _owner;
  late DateTime? _from;
  late DateTime? _to;

  @override
  void initState() {
    super.initState();
    _method = widget.selectedMethod;
    _branch = widget.selectedBranch;
    _owner = widget.selectedOwner;
    _from = widget.fromDate;
    _to = widget.toDate;
  }

  void _selectMethod(String? value) {
    setState(() => _method = value);
    widget.onMethodChanged(value);
  }

  void _selectBranch(String? value) {
    setState(() => _branch = value);
    widget.onBranchChanged(value);
  }

  void _selectOwner(String? value) {
    setState(() => _owner = value);
    widget.onOwnerChanged(value);
  }

  void _selectFrom(DateTime? value) {
    setState(() => _from = value);
    widget.onFromDateChanged(value);
  }

  void _selectTo(DateTime? value) {
    setState(() => _to = value);
    widget.onToDateChanged(value);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Text(
            'Filter Receipts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // METHOD
          _SheetSectionLabel(label: 'METHOD'),
          const SizedBox(height: 10),
          _ChipRow(
            allLabel: 'All Methods',
            items: widget.methods,
            selected: _method,
            onSelected: _selectMethod,
          ),
          const SizedBox(height: 18),

          // BRANCH
          _SheetSectionLabel(label: 'BRANCH'),
          const SizedBox(height: 10),
          _ChipRow(
            allLabel: 'All Branches',
            items: widget.branches,
            selected: _branch,
            onSelected: _selectBranch,
          ),
          const SizedBox(height: 18),

          // USER
          _SheetSectionLabel(label: 'USER'),
          const SizedBox(height: 10),
          _ChipRow(
            allLabel: 'All Users',
            items: widget.owners,
            selected: _owner,
            onSelected: _selectOwner,
          ),
          const SizedBox(height: 18),

          // DATE RANGE
          _SheetSectionLabel(label: 'DATE RANGE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SheetDateField(
                  hint: 'From',
                  value: _from,
                  onChanged: _selectFrom,
                  formatDate: _formatDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetDateField(
                  hint: 'To',
                  value: _to,
                  onChanged: _selectTo,
                  formatDate: _formatDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                widget.onReset();
                setState(() {
                  _method = null;
                  _branch = null;
                  _owner = null;
                  _from = null;
                  _to = null;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                'Reset',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SheetSectionLabel
// ─────────────────────────────────────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final String label;
  const _SheetSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade400,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChipRow — horizontal scrolling chip selector (instant apply)
// ─────────────────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final String allLabel;
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _ChipRow({
    required this.allLabel,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [null, ...items.map((e) => e as String?)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allItems.map((item) {
          final isSelected = item == selected;
          final label = item ?? allLabel;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SheetDateField
// ─────────────────────────────────────────────────────────────────────────────

class _SheetDateField extends StatelessWidget {
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String Function(DateTime) formatDate;

  const _SheetDateField({
    required this.hint,
    required this.value,
    required this.onChanged,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? formatDate(value!) : hint,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value != null
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReceiptEntryCard
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptEntryCard extends StatelessWidget {
  final ReceiptEntry entry;

  const _ReceiptEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.direction == ReceiptDirection.in_;
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
          // ── Header row ────────────────────────────────────────────────
          Row(
            children: [
              // Icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
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
                        _Badge(
                          label: entry.method.toUpperCase(),
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFEFF6FF),
                        ),
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
              // Direction badge
              _Badge(
                label: isIn ? 'IN' : 'OUT',
                color: directionColor,
                bg: directionBg,
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),

          // ── Description ───────────────────────────────────────────────
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

          // ── Detail row: Branch + Owner ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Branch',
                  value: entry.branch,
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Owner',
                  value: entry.owner,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Amount pill ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _AmountPill(
                  label: 'Amount',
                  amount: entry.amount,
                  highlight: isIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountPill(
                  label: 'Account',
                  amount: null,
                  textValue: entry.account,
                ),
              ),
            ],
          ),

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
      case 'stc pay':
        return Icons.qr_code_2_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }
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
  final String label;
  final double? amount;
  final String? textValue;
  final bool highlight;

  const _AmountPill({
    required this.label,
    this.amount,
    this.textValue,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
    amount != null ? 'SAR ${amount!.toStringAsFixed(2)}' : (textValue ?? '—');

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
            displayValue,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: highlight
                  ? AppColors.secondaryLight
                  : const Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
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

class _EmptyReceiptsState extends StatelessWidget {
  const _EmptyReceiptsState();

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
              'No receipts in this period.',
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
// Models & Dummy Data (receipts_models.dart)
// ─────────────────────────────────────────────────────────────────────────────
// Place these in a separate file: receipts_models.dart

enum ReceiptDirection {
  in_,
  out;

  String get label => switch (this) {
    ReceiptDirection.in_ => 'In',
    ReceiptDirection.out => 'Out',
  };
}

class ReceiptEntry {
  final String date;
  final ReceiptDirection direction;
  final double amount;
  final String method;
  final String account;
  final String branch;
  final String owner;
  final String reference;
  final String description;

  const ReceiptEntry({
    required this.date,
    required this.direction,
    required this.amount,
    required this.method,
    required this.account,
    required this.branch,
    required this.owner,
    required this.reference,
    required this.description,
  });
}

abstract class ReceiptsDummyData {
  static const List<ReceiptEntry> entries = [
    ReceiptEntry(
      date: '11/06/2026',
      direction: ReceiptDirection.in_,
      amount: 350.00,
      method: 'Cash',
      account: 'Cash on Hand',
      branch: 'Main',
      owner: 'Sultan',
      reference: 'RC-0012',
      description: 'Cash receipt against INV-01703',
    ),
    ReceiptEntry(
      date: '10/06/2026',
      direction: ReceiptDirection.in_,
      amount: 881.71,
      method: 'Card',
      account: 'Bank — Al Rajhi',
      branch: 'Main',
      owner: 'Fahad',
      reference: 'RC-0011',
      description: 'Card payment against INV-01698',
    ),
    ReceiptEntry(
      date: '03/06/2026',
      direction: ReceiptDirection.out,
      amount: 624.75,
      method: 'Bank Transfer',
      account: 'Bank — Al Rajhi',
      branch: 'Main',
      owner: 'Sultan',
      reference: 'PV-0007',
      description: 'Payment to local supplier WLPI-12',
    ),
  ];
}