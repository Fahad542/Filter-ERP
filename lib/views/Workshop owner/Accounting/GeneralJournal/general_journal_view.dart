import 'package:flutter/material.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/custom_search_bar.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../../owner_shell.dart';
// GeneralJournalView — Journal entry log
// ─────────────────────────────────────────────────────────────────────────────

class GeneralJournalView extends StatefulWidget {
  const GeneralJournalView({super.key});

  @override
  State<GeneralJournalView> createState() => _GeneralJournalViewState();
}

class _GeneralJournalViewState extends State<GeneralJournalView> {
  String _searchQuery = '';
  String? _selectedType; // null = All Types

  // All unique entry types from dummy data
  List<String> get _entryTypes {
    final types = GeneralJournalDummyData.entries
        .map((e) => e.type)
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  List<JournalEntry> get _filteredEntries {
    return GeneralJournalDummyData.entries.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.entryNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType =
          _selectedType == null || e.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final totalEntries = GeneralJournalDummyData.entries.length;
    final postedCount =
        GeneralJournalDummyData.entries.where((e) => e.status == JournalStatus.posted).length;
    final balancedCount =
        GeneralJournalDummyData.entries.where((e) => e.isBalanced).length;
    final totalDebit = GeneralJournalDummyData.entries
        .fold(0.0, (sum, e) => sum + e.totalDebit);

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: const OwnerDashboardTitle(subtitle: 'General Journal'),
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
                  title: 'Total Debit',
                  value: 'SAR ${totalDebit.toStringAsFixed(2)}',
                  subtitle: '$totalEntries total entries',
                  icon: Icons.receipt_long_rounded,
                ),
                ReusableKpiMetric(
                  title: 'Total Entries',
                  value: '$totalEntries',
                  subtitle: 'Journal entries',
                  icon: Icons.format_list_bulleted_rounded,
                ),
                ReusableKpiMetric(
                  title: 'Posted / Balanced',
                  value: '$postedCount / $balancedCount',
                  subtitle: 'of $totalEntries',
                  icon: Icons.check_circle_outline_rounded,
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
                    hintText: 'Search entry # or description...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 10),
                _TypeFilterButton(
                  selectedType: _selectedType,
                  types: _entryTypes,
                  onChanged: (t) => setState(() => _selectedType = t),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  if (entries.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyJournalState()),

                  SliverList.separated(
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _JournalEntryCard(entry: entries[i]),
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
// _TypeFilterButton
// ─────────────────────────────────────────────────────────────────────────────

class _TypeFilterButton extends StatelessWidget {
  final String? selectedType;
  final List<String> types;
  final ValueChanged<String?> onChanged;

  const _TypeFilterButton({
    required this.selectedType,
    required this.types,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedType != null;

    return GestureDetector(
      onTap: () => _showTypeSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFiltered ? AppColors.secondaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFiltered
                ? AppColors.secondaryLight
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: isFiltered ? AppColors.primaryLight : Colors.grey.shade500,
            ),
            const SizedBox(width: 5),
            Text(
              isFiltered ? _formatType(selectedType!) : 'All Types',
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
              color: isFiltered ? AppColors.primaryLight : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) =>
      type.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');

  void _showTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TypeFilterSheet(
        selectedType: selectedType,
        types: types,
        onChanged: onChanged,
        formatType: _formatType,
      ),
    );
  }
}

class _TypeFilterSheet extends StatelessWidget {
  final String? selectedType;
  final List<String> types;
  final ValueChanged<String?> onChanged;
  final String Function(String) formatType;

  const _TypeFilterSheet({
    required this.selectedType,
    required this.types,
    required this.onChanged,
    required this.formatType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Filter by Type',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _typeChip(context, null, 'All Types'),
              ...types.map((t) => _typeChip(context, t, formatType(t))),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _typeChip(BuildContext context, String? type, String label) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        onChanged(type);
        Navigator.pop(context);
      },
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
// _JournalEntryCard
// ─────────────────────────────────────────────────────────────────────────────

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;

  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPosted = entry.status == JournalStatus.posted;
    final statusColor =
        isPosted ? const Color(0xFFD97706) : const Color(0xFF6B7280);
    final statusBg =
        isPosted ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6);

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
                  _iconForType(entry.type),
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
                      entry.entryNumber,
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
                          label: _formatType(entry.type),
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
              // Status badge
              _Badge(
                label: entry.status.label.toUpperCase(),
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

          // ── Detail row: Lines + Balanced ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Lines',
                  value: '${entry.lines}',
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Balanced',
                  value: entry.isBalanced ? '✓ Yes' : '✗ No',
                  valueColor: entry.isBalanced
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── DR / CR pills ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _AmountPill(
                  label: 'Total DR',
                  amount: entry.totalDebit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountPill(
                  label: 'Total CR',
                  amount: entry.totalCredit,
                  highlight: true,
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'sales':
        return Icons.point_of_sale_rounded;
      case 'counter_closing':
        return Icons.store_rounded;
      case 'commission_accrual':
        return Icons.handshake_outlined;
      case 'PurchaseInvoice':
        return Icons.receipt_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatType(String type) =>
      type.replaceAll('_', ' ').split(' ').map((w) {
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
  final String label;
  final double amount;
  final bool highlight;

  const _AmountPill({
    required this.label,
    required this.amount,
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

class _EmptyJournalState extends StatelessWidget {
  const _EmptyJournalState();

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
              'No journal entries found',
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
// Models & Dummy Data (general_journal_models.dart)
// ─────────────────────────────────────────────────────────────────────────────
// Place these in a separate file: general_journal_models.dart

enum JournalStatus {
  posted,
  draft;

  String get label => switch (this) {
        JournalStatus.posted => 'Posted',
        JournalStatus.draft => 'Draft',
      };
}

class JournalEntry {
  final String entryNumber;
  final String date;
  final String type;
  final String description;
  final int lines;
  final double totalDebit;
  final double totalCredit;
  final bool isBalanced;
  final JournalStatus status;

  const JournalEntry({
    required this.entryNumber,
    required this.date,
    required this.type,
    required this.description,
    required this.lines,
    required this.totalDebit,
    required this.totalCredit,
    required this.isBalanced,
    required this.status,
  });
}

abstract class GeneralJournalDummyData {
  static const List<JournalEntry> entries = [
    JournalEntry(
      entryNumber: 'JE0008',
      date: '11/06/2026',
      type: 'counter_closing',
      description: 'POS closing #148 · session 189 · Sultan',
      lines: 2,
      totalDebit: 18.00,
      totalCredit: 18.00,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0007',
      date: '10/06/2026',
      type: 'sales',
      description: 'Sales — INV-01703',
      lines: 5,
      totalDebit: 30.92,
      totalCredit: 30.92,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0006',
      date: '10/06/2026',
      type: 'commission_accrual',
      description: 'Commission accrual — Job#2128',
      lines: 2,
      totalDebit: 0.66,
      totalCredit: 0.66,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0005',
      date: '03/06/2026',
      type: 'PurchaseInvoice',
      description: 'Supplier invoice approved WPI-SI-47 — Al...',
      lines: 2,
      totalDebit: 235.75,
      totalCredit: 235.75,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0004',
      date: '03/06/2026',
      type: 'PurchaseInvoice',
      description: 'Supplier invoice approved WPI-SI-46 — Al...',
      lines: 2,
      totalDebit: 202.56,
      totalCredit: 202.56,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0003',
      date: '03/06/2026',
      type: 'PurchaseInvoice',
      description: 'Local supplier PI WLPI-12 — Fahad Non Af...',
      lines: 2,
      totalDebit: 624.75,
      totalCredit: 624.75,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0002',
      date: '01/06/2026',
      type: 'sales',
      description: 'Sales — INV-01698',
      lines: 4,
      totalDebit: 881.71,
      totalCredit: 881.71,
      isBalanced: true,
      status: JournalStatus.posted,
    ),
    JournalEntry(
      entryNumber: 'JE0001',
      date: '01/06/2026',
      type: 'counter_closing',
      description: 'POS closing #147 · session 188 · Main',
      lines: 2,
      totalDebit: 0.00,
      totalCredit: 0.00,
      isBalanced: true,
      status: JournalStatus.draft,
    ),
  ];
}