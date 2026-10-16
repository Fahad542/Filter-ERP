import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/app_colors.dart';
import '../accounting_models.dart';
import 'accounting_view_model.dart';
// ─────────────────────────────────────────────────────────────────────────────
// NOTE: TrialBalanceEntry in accounting_models.dart must have a `String type`
// field (e.g. "Asset", "Liability", "Equity", "Income", "Expense").
// If using an enum, call `.name` on it when passing to _TbEntryCard.
// ─────────────────────────────────────────────────────────────────────────────

// ── Per-type design tokens ────────────────────────────────────────────────────

const _kTypeAccent = {
  'Asset':     Color(0xFF2563EB),
  'Liability': Color(0xFFD97706),
  'Equity':    Color(0xFF7C3AED),
  'Income':    Color(0xFF059669),
  'Expense':   Color(0xFFDC2626),
};

const _kTypeSurface = {
  'Asset':     Color(0xFFEFF6FF),
  'Liability': Color(0xFFFFFBEB),
  'Equity':    Color(0xFFF5F3FF),
  'Income':    Color(0xFFECFDF5),
  'Expense':   Color(0xFFFEF2F2),
};

const _kTypeIcon = {
  'Asset':     Icons.account_balance_wallet_rounded,
  'Liability': Icons.receipt_long_rounded,
  'Equity':    Icons.pie_chart_rounded,
  'Income':    Icons.trending_up_rounded,
  'Expense':   Icons.trending_down_rounded,
};

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _typeAccent(String type) => _kTypeAccent[type] ?? const Color(0xFF6B7280);
Color _typeSurface(String type) => _kTypeSurface[type] ?? const Color(0xFFF3F4F6);
IconData _typeIcon(String type) => _kTypeIcon[type] ?? Icons.circle_outlined;

/// Derives the display type string from an account code prefix.
/// Used as a fallback when [TrialBalanceEntry.type] is empty.
String _typeFromEntry(TrialBalanceEntry e) {
  if (e.type.isNotEmpty) return e.type;
  final code = e.code;
  if (code.startsWith('1') || code.startsWith('2') == false &&
      int.tryParse(code.substring(0, 1)) == 1) return 'Asset';
  final n = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 4).padRight(4, '0')) ?? 0;
  if (n >= 1000 && n < 2000) return 'Asset';
  if (n >= 2000 && n < 3000) return 'Liability';
  if (n >= 3000 && n < 4000) return 'Equity';
  if (n >= 4000 && n < 5000) return 'Income';
  return 'Expense';
}

// ─────────────────────────────────────────────────────────────────────────────
// TrialBalanceTab  (StatefulWidget – owns filter state)
// ─────────────────────────────────────────────────────────────────────────────

class TrialBalanceTab extends StatefulWidget {
  const TrialBalanceTab({super.key});

  @override
  State<TrialBalanceTab> createState() => _TrialBalanceTabState();
}

class _TrialBalanceTabState extends State<TrialBalanceTab>
    with SingleTickerProviderStateMixin {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedBranch = 'All Branches';

  static const _branches = [
    'All Branches',
    'Branch A',
    'Branch B',
    'Branch C',
  ];

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? now);
    final first = isFrom ? DateTime(2020) : (_fromDate ?? DateTime(2020));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
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

    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
      } else {
        _toDate = picked;
      }
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountingViewModel>(
      builder: (context, vm, _) {
        final isBalanced = (vm.totalDebits - vm.totalCredits).abs() < 0.01;
        final entries = vm.trialBalance;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Filter card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterCard(
                fromDate: _fromDate,
                toDate: _toDate,
                fmtDate: _fmt,
                selectedBranch: _selectedBranch,
                branches: _branches,
                isBalanced: isBalanced,
                onFromTap: () => _pickDate(isFrom: true),
                onToTap: () => _pickDate(isFrom: false),
                onBranchChanged: (v) =>
                    setState(() => _selectedBranch = v ?? 'All Branches'),
                onApply: () {
                  // Wire date range + branch to VM when backend filtering is added
                },
                onPrint: () {
                  // Wire to print/export service
                },
              ),
            ),

            // ── KPI row ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: 'Total Debits',
                        amount: vm.totalDebits,
                        startColor: const Color(0xFF047857),
                        endColor: const Color(0xFF10B981),
                        icon: Icons.south_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KpiCard(
                        label: 'Total Credits',
                        amount: vm.totalCredits,
                        startColor: const Color(0xFFB45309),
                        endColor: const Color(0xFFF59E0B),
                        icon: Icons.north_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Legend row ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _TypeLegend(entries: entries),
              ),
            ),

            // ── Table header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TableHeader(),
              ),
            ),

            // ── Account rows ───────────────────────────────────────────────
            SliverList.separated(
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final e = entries[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TbEntryCard(
                    code: e.code,
                    name: e.accountName,
                    type: _typeFromEntry(e),
                    debit: e.debit,
                    credit: e.credit,
                    isAlt: i.isOdd,
                  ),
                );
              },
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Colors.grey.shade100),
              ),
            ),

            // ── Totals footer ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _TotalsFooter(
                  totalDebit: vm.totalDebits,
                  totalCredit: vm.totalCredits,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterCard
// ─────────────────────────────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String Function(DateTime?) fmtDate;
  final String selectedBranch;
  final List<String> branches;
  final bool isBalanced;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final void Function(String?) onBranchChanged;
  final VoidCallback onApply;
  final VoidCallback onPrint;

  const _FilterCard({
    required this.fromDate,
    required this.toDate,
    required this.fmtDate,
    required this.selectedBranch,
    required this.branches,
    required this.isBalanced,
    required this.onFromTap,
    required this.onToTap,
    required this.onBranchChanged,
    required this.onApply,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  value: fmtDate(fromDate),
                  hasValue: fromDate != null,
                  onTap: onFromTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Colors.grey.shade400),
              ),
              Expanded(
                child: _DateField(
                  label: 'To',
                  value: fmtDate(toDate),
                  hasValue: toDate != null,
                  onTap: onToTap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Branch + Actions + Balanced badge
          Row(
            children: [
              // Branch
              Expanded(child: _BranchPicker(
                value: selectedBranch,
                items: branches,
                onChanged: onBranchChanged,
              )),
              const SizedBox(width: 8),
              // Apply
              _ActionChip(
                label: 'Apply',
                icon: Icons.tune_rounded,
                color: AppColors.secondaryLight,
                onTap: onApply,
              ),
              const SizedBox(width: 6),
              // Print
              _ActionChip(
                label: 'Print',
                icon: Icons.print_outlined,
                color: Colors.grey.shade600,
                onTap: onPrint,
              ),
              const SizedBox(width: 8),
              // Balanced pill
              _BalancedPill(isBalanced: isBalanced),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hasValue ? AppColors.secondaryLight : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.secondaryLight.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: hasValue
                ? AppColors.secondaryLight.withValues(alpha: 0.35)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: accent),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasValue
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchPicker extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _BranchPicker({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.unfold_more_rounded,
              size: 16, color: Colors.grey.shade500),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          items: items
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _BalancedPill extends StatelessWidget {
  final bool isBalanced;
  const _BalancedPill({required this.isBalanced});

  @override
  Widget build(BuildContext context) {
    final color =
    isBalanced ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bg =
    isBalanced ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final icon = isBalanced
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;
    final text = isBalanced ? 'Balanced' : 'Off';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _KpiCard
// ─────────────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color startColor;
  final Color endColor;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.amount,
    required this.startColor,
    required this.endColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('SAR',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypeLegend  – scannable type-colour key above the table
// ─────────────────────────────────────────────────────────────────────────────

class _TypeLegend extends StatelessWidget {
  final List<TrialBalanceEntry> entries;
  const _TypeLegend({required this.entries});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    for (final e in entries) {
      final t = _typeFromEntry(e);
      if (t.isNotEmpty) seen.add(t);
    }
    if (seen.isEmpty) return const SizedBox.shrink();

    final ordered = ['Asset', 'Liability', 'Equity', 'Income', 'Expense']
        .where(seen.contains)
        .toList();

    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ordered.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final type = ordered[i];
          final color = _typeAccent(type);
          final bg = _typeSurface(type);
          final count = entries.where((e) => _typeFromEntry(e) == type).length;
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('$type · $count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TableHeader
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          _th('Code', width: 44, align: TextAlign.left),
          const SizedBox(width: 8),
          Expanded(child: _th('Account Name', align: TextAlign.left)),
          const SizedBox(width: 8),
          _th('Type', width: 60, align: TextAlign.center),
          _th('Debit', width: 72, align: TextAlign.right),
          _th('Credit', width: 72, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _th(String text, {double? width, required TextAlign align}) {
    final w = Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: Colors.white.withValues(alpha: 0.65),
        letterSpacing: 0.4,
      ),
    );
    if (width == null) return w;
    return SizedBox(width: width, child: w);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TbEntryCard  – two-line mobile row
// ─────────────────────────────────────────────────────────────────────────────

class _TbEntryCard extends StatelessWidget {
  final String code;
  final String name;
  final String type;
  final double debit;
  final double credit;
  final bool isAlt;

  const _TbEntryCard({
    required this.code,
    required this.name,
    required this.type,
    required this.debit,
    required this.credit,
    required this.isAlt,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _typeAccent(type);
    final surface = _typeSurface(type);

    return Container(
      color: isAlt ? const Color(0xFFF8FAFC) : Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left type-colour accent bar ──────────────────────────
            Container(width: 3, color: accent.withValues(alpha: 0.55)),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Code | Name | Type badge
                    Row(
                      children: [
                        // Code monospace label
                        Container(
                          constraints: const BoxConstraints(maxWidth: 80),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            code,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Account name
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(20),
                            border:
                            Border.all(color: accent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_typeIcon(type), size: 8, color: accent),
                              const SizedBox(width: 3),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // Line 2: Debit | divider | Credit
                    Row(
                      children: [
                        // Debit
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFF2563EB).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Dr',
                                    style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB))),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'SAR ${debit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: debit > 0
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey.shade400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: Colors.grey.shade200,
                        ),

                        // Credit
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFFDC2626).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Cr',
                                    style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626))),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'SAR ${credit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: credit > 0
                                        ? const Color(0xFFDC2626)
                                        : Colors.grey.shade400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
// _TotalsFooter
// ─────────────────────────────────────────────────────────────────────────────

class _TotalsFooter extends StatelessWidget {
  final double totalDebit;
  final double totalCredit;

  const _TotalsFooter(
      {required this.totalDebit, required this.totalCredit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.07),
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Divider with label
          Row(
            children: [
              Expanded(child: Divider(height: 1, color: Colors.grey.shade200)),
            ],
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // TOTAL label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TOTALS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const Spacer(),

                // Debit total
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Dr',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SAR ${totalDebit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.grey.shade300,
                ),

                // Credit total
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Cr',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626))),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SAR ${totalCredit.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}