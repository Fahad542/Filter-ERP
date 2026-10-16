import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/app_colors.dart';
import 'accounting_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BalanceSheetTab — redesigned to match TrialBalanceTab's filter card +
// pretty section cards, optimized for mobile.
// ─────────────────────────────────────────────────────────────────────────────

// ── Per-section design tokens ──────────────────────────────────────────────

const _kSecAccent = {
  'Assets':      Color(0xFF2563EB),
  'Liabilities': Color(0xFFD97706),
  'Equity':      Color(0xFF7C3AED),
};

const _kSecSurface = {
  'Assets':      Color(0xFFEFF6FF),
  'Liabilities': Color(0xFFFFFBEB),
  'Equity':      Color(0xFFF5F3FF),
};

const _kSecIcon = {
  'Assets':      Icons.account_balance_wallet_rounded,
  'Liabilities': Icons.receipt_long_rounded,
  'Equity':      Icons.pie_chart_rounded,
};

Color _secAccent(String s) => _kSecAccent[s] ?? const Color(0xFF6B7280);
Color _secSurface(String s) => _kSecSurface[s] ?? const Color(0xFFF3F4F6);
IconData _secIcon(String s) => _kSecIcon[s] ?? Icons.circle_outlined;

// ─────────────────────────────────────────────────────────────────────────────
// BalanceSheetTab  (StatefulWidget – owns filter state)
// ─────────────────────────────────────────────────────────────────────────────

class BalanceSheetTab extends StatefulWidget {
  const BalanceSheetTab({super.key});

  @override
  State<BalanceSheetTab> createState() => _BalanceSheetTabState();
}

class _BalanceSheetTabState extends State<BalanceSheetTab> {
  DateTime _asOfDate = DateTime.now();
  String _selectedBranch = 'All Branches';

  static const _branches = [
    'All Branches',
    'Branch A',
    'Branch B',
    'Branch C',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
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

    if (picked == null || !mounted) return;
    setState(() => _asOfDate = picked);
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountingViewModel>();
    final entries = vm.balanceSheet;
    final isBalanced =
        (vm.totalAssets - (vm.totalLiabilities + vm.totalEquity)).abs() < 1.0;

    // Group entries by top-level section (Assets / Liabilities / Equity)
    final sections = <_BsSection>[];
    _BsSection? current;

    for (final entry in entries) {
      final section = entry.section as String;
      final label = entry.label as String;
      final amount = entry.amount as double;
      final isTotal = entry.isTotal as bool;

      if (current == null || current.name != section) {
        current = _BsSection(name: section, lines: []);
        sections.add(current);
      }

      current.lines.add(_BsEntryData(label: label, amount: amount, isTotal: isTotal));
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Filter card ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _FilterCard(
            asOfDate: _asOfDate,
            fmtDate: _fmt,
            selectedBranch: _selectedBranch,
            branches: _branches,
            isBalanced: isBalanced,
            onDateTap: _pickDate,
            onBranchChanged: (v) =>
                setState(() => _selectedBranch = v ?? 'All Branches'),
            onApply: () {},
            onPrint: () {},
          ),
        ),

        // ── KPI row ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Total Assets',
                    amount: vm.totalAssets,
                    startColor: const Color(0xFF047857),
                    endColor: const Color(0xFF10B981),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Total Liabilities',
                    amount: vm.totalLiabilities,
                    startColor: const Color(0xFFB45309),
                    endColor: const Color(0xFFF59E0B),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Section cards ──────────────────────────────────────────────
        SliverList.separated(
          itemCount: sections.isEmpty ? 0 : sections.length - 1,
          itemBuilder: (ctx, i) {
            final section = sections[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BsSectionCard(section: section),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
        ),

        if (sections.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── Last section card (Equity), joined to total below ──
                    _BsSectionCard(section: sections.last, joinBottom: true),

                    // ── Liabilities + Equity total ─────────────────────────
                    _LiabEquityTotalCard(
                      total: vm.totalLiabilities + vm.totalEquity,
                      isBalanced: isBalanced,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data holders
// ─────────────────────────────────────────────────────────────────────────────

class _BsEntryData {
  final String label;
  final double amount;
  final bool isTotal;

  _BsEntryData({required this.label, required this.amount, required this.isTotal});
}

class _BsSection {
  final String name;
  final List<_BsEntryData> lines;

  _BsSection({required this.name, required this.lines});
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterCard  (single "as of" date instead of a range)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  final DateTime asOfDate;
  final String Function(DateTime) fmtDate;
  final String selectedBranch;
  final List<String> branches;
  final bool isBalanced;
  final VoidCallback onDateTap;
  final void Function(String?) onBranchChanged;
  final VoidCallback onApply;
  final VoidCallback onPrint;

  const _FilterCard({
    required this.asOfDate,
    required this.fmtDate,
    required this.selectedBranch,
    required this.branches,
    required this.isBalanced,
    required this.onDateTap,
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "As of" date
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'As of',
                  value: fmtDate(asOfDate),
                  onTap: onDateTap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Branch + Actions + Balanced badge
          Row(
            children: [
              Expanded(child: _BranchPicker(
                value: selectedBranch,
                items: branches,
                onChanged: onBranchChanged,
              )),
              const SizedBox(width: 8),
              _ActionChip(
                label: 'Apply',
                icon: Icons.tune_rounded,
                color: AppColors.secondaryLight,
                onTap: onApply,
              ),
              const SizedBox(width: 6),
              _ActionChip(
                label: 'Print',
                icon: Icons.print_outlined,
                color: Colors.grey.shade600,
                onTap: onPrint,
              ),
              const SizedBox(width: 8),
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
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.secondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight.withOpacity(0.05),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.secondaryLight.withOpacity(0.35)),
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(0.18)),
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
        border: Border.all(color: color.withOpacity(0.25)),
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
// _KpiCard  (mirrors TrialBalanceTab's gradient KPI card)
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
            color: startColor.withOpacity(0.32),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
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
                  color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LiabEquityTotalCard  – footer card for Liabilities + Equity
// ─────────────────────────────────────────────────────────────────────────────

class _LiabEquityTotalCard extends StatelessWidget {
  final double total;
  final bool isBalanced;

  const _LiabEquityTotalCard({required this.total, required this.isBalanced});

  @override
  Widget build(BuildContext context) {
    final color =
    isBalanced ? AppColors.primaryLight :  AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),

          Text(
            'SAR ${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryLight,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BsSectionCard  – one card per section (Assets, Liabilities, Equity)
// ─────────────────────────────────────────────────────────────────────────────

class _BsSectionCard extends StatelessWidget {
  final _BsSection section;
  final bool joinBottom;

  const _BsSectionCard({required this.section, this.joinBottom = false});

  @override
  Widget build(BuildContext context) {
    final accent = _secAccent(section.name);
    final surface = _secSurface(section.name);
    final icon = _secIcon(section.name);

    final lines = <Widget>[];
    for (var i = 0; i < section.lines.length; i++) {
      final e = section.lines[i];

      if (e.isTotal) {
        lines.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 6),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ));
        lines.add(_BsTotalRow(label: e.label, amount: e.amount, color: accent));
        if (!joinBottom) lines.add(const SizedBox(height: 4));
      } else {
        lines.add(_BsLineRow(label: e.label, amount: e.amount));
      }
    }

    final radius = BorderRadius.vertical(
      top: const Radius.circular(16),
      bottom: joinBottom ? Radius.zero : const Radius.circular(16),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100),
          left: BorderSide(color: Colors.grey.shade100),
          right: BorderSide(color: Colors.grey.shade100),
          bottom: joinBottom
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade100),
        ),
        boxShadow: joinBottom
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(14, 14, 14, joinBottom ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 9),
              Text(
                section.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines,
          if (joinBottom) const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _BsLineRow extends StatelessWidget {
  final String label;
  final double amount;

  const _BsLineRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount != 0 ? 'SAR ${amount.toStringAsFixed(2)}' : '—',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: amount != 0
                  ? const Color(0xFF23262D)
                  : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

class _BsTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BsTotalRow(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
          Text(
            'SAR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}