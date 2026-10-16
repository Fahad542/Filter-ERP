import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_shimmer.dart';
import 'affiliated_suppliers_view_model.dart';
import 'filter_affiliated_suppliers_models.dart';

class AffiliatedSupplierLedgerView extends StatefulWidget {
  final AffiliatedSupplier supplier;

  const AffiliatedSupplierLedgerView({
    super.key,
    required this.supplier,
  });

  @override
  State<AffiliatedSupplierLedgerView> createState() =>
      _AffiliatedSupplierLedgerViewState();
}

class _AffiliatedSupplierLedgerViewState
    extends State<AffiliatedSupplierLedgerView> {
  DateTime? _fromDate = DateTime(2026, 6, 1);
  DateTime? _toDate = DateTime(2026, 6, 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchLedger();
    });
  }

  Future<void> _fetchLedger() async {
    if (_fromDate == null || _toDate == null) return;
    await context.read<AffiliatedSuppliersViewModel>().loadLedger(
      supplierId: widget.supplier.supplierId,
      from: _fromDate!,
      to: _toDate!,
    );
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.secondaryLight,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
    if (_fromDate != null && _toDate != null) {
      _fetchLedger();
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AffiliatedSuppliersViewModel>();

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: const OwnerDashboardTitle(subtitle: 'Supplier Ledger'),
        showDrawer: false,
        showBackButton: true,
        showNotification: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _fetchLedger,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LedgerSupplierHeader(supplier: widget.supplier),
                    const SizedBox(height: 14),
                    // ── Date filter ────────────────────────────────────────
                    _LedgerFilterCard(
                      fromDate: _fromDate,
                      toDate: _toDate,
                      onFromTap: () => _pickDate(context, true),
                      onToTap: () => _pickDate(context, false),
                      fromLabel: _fmt(_fromDate),
                      toLabel: _fmt(_toDate),
                    ),
                    const SizedBox(height: 14),
                    _LedgerInfoCard(
                      openingBalance: vm.isLedgerLoading
                          ? widget.supplier.openingBalance
                          : vm.ledgerOpeningBalance,
                      finalBalance: vm.isLedgerLoading
                          ? widget.supplier.finalBalance
                          : vm.ledgerClosingBalance,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (vm.isLedgerLoading)
              const SliverToBoxAdapter(
                child: OwnerListPageShimmer(itemCount: 4),
              )
            else if (vm.ledgerError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: _LedgerErrorState(
                      message: vm.ledgerError!, onRetry: _fetchLedger),
                ),
              )
            else
            // ── Ledger entries as cards ─────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: _LedgerCardList(entries: vm.ledgerEntries),
              ),
          ],
        ),
      ),
    );
  }
}

class _LedgerErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LedgerErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 44, color: Colors.red.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supplier header
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerSupplierHeader extends StatelessWidget {
  final AffiliatedSupplier supplier;
  const _LedgerSupplierHeader({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              supplier.name.isEmpty ? '?' : supplier.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  supplier.branch,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _PillBadge(
            label: supplier.isActive ? 'Active' : 'Inactive',
            bg: supplier.isActive
                ? const Color(0xFFE8F8EF)
                : Colors.grey.shade100,
            color: supplier.isActive
                ? const Color(0xFF27AE60)
                : Colors.grey.shade600,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date filter card — no Apply button, picking both dates auto-applies
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerFilterCard extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final String fromLabel;
  final String toLabel;

  const _LedgerFilterCard({
    required this.fromDate,
    required this.toDate,
    required this.onFromTap,
    required this.onToTap,
    required this.fromLabel,
    required this.toLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateTile(
              label: 'From date',
              value: fromLabel,
              onTap: onFromTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateTile(
              label: 'To date',
              value: toLabel,
              onTap: onToTap,
            ),
          ),
          const SizedBox(width: 10),
          _SmallWhiteButton(label: 'PDF', icon: Icons.picture_as_pdf_outlined),
          const SizedBox(width: 8),
          _SmallWhiteButton(label: 'CSV', icon: Icons.table_chart_outlined),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerInfoCard extends StatelessWidget {
  final double openingBalance;
  final double finalBalance;
  const _LedgerInfoCard(
      {required this.openingBalance, required this.finalBalance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              label: 'Opening balance',
              value: 'SAR ${openingBalance.toStringAsFixed(2)}',
            ),
          ),
          Container(
              width: 1, height: 38, color: Colors.white.withOpacity(0.12)),
          Expanded(
            child: _InfoItem(
              label: 'Final balance',
              value: 'SAR ${finalBalance.toStringAsFixed(2)}',
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ledger card list — replaces horizontal-scroll table
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerCardList extends StatelessWidget {
  final List<LedgerEntry> entries;
  const _LedgerCardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Column header
    return SliverList.separated(
      itemCount: entries.length + 1, // +1 for header
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        if (i == 0) return _LedgerCardHeader();
        final entry = entries[i - 1];
        return _LedgerEntryCard(entry: entry, index: i - 1);
      },
    );
  }
}

class _LedgerCardHeader extends StatelessWidget {
  const _LedgerCardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: _HeaderCell('DATE'),
          ),
          Expanded(
            flex: 5,
            child: _HeaderCell('DESCRIPTION'),
          ),
          Expanded(
            flex: 2,
            child: _HeaderCell('DEBIT', right: true),
          ),
          Expanded(
            flex: 2,
            child: _HeaderCell('CREDIT', right: true),
          ),
          Expanded(
            flex: 2,
            child: _HeaderCell('BALANCE', right: true),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool right;
  const _HeaderCell(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _LedgerEntryCard extends StatelessWidget {
  final LedgerEntry entry;
  final int index;
  const _LedgerEntryCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final isTotal = entry.isTotal;
    final isOpening = entry.isOpening;
    final bg = isTotal
        ? AppColors.primaryLight.withOpacity(0.18)
        : index.isEven
        ? Colors.white
        : const Color(0xFFFAFAFA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTotal
              ? AppColors.primaryLight.withOpacity(0.4)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Text(
              entry.date.isEmpty ? '—' : entry.date,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                color: isTotal
                    ? AppColors.secondaryLight
                    : Colors.grey.shade600,
              ),
            ),
          ),
          // Description
          Expanded(
            flex: 5,
            child: Text(
              entry.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: (isTotal || isOpening)
                    ? FontWeight.w900
                    : FontWeight.w600,
                color: (isTotal || isOpening)
                    ? AppColors.secondaryLight
                    : Colors.grey.shade700,
              ),
            ),
          ),
          // Debit
          Expanded(
            flex: 2,
            child: Text(
              entry.debit != null
                  ? 'SAR ${entry.debit!.toStringAsFixed(2)}'
                  : (isTotal ? 'SAR ${entry.debit?.toStringAsFixed(2) ?? "0.00"}' : '—'),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                color: isTotal
                    ? AppColors.secondaryLight
                    : Colors.grey.shade700,
              ),
            ),
          ),
          // Credit
          Expanded(
            flex: 2,
            child: Text(
              entry.credit != null
                  ? 'SAR ${entry.credit!.toStringAsFixed(2)}'
                  : (isTotal ? 'SAR ${(entry.credit ?? 0).toStringAsFixed(2)}' : '—'),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                color: isTotal
                    ? AppColors.secondaryLight
                    : Colors.grey.shade700,
              ),
            ),
          ),
          // Balance
          Expanded(
            flex: 2,
            child: Text(
              'SAR ${(entry.balance ?? 0).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                color: isTotal
                    ? AppColors.secondaryLight
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SmallWhiteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SmallWhiteButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.secondaryLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  const _InfoItem(
      {required this.label, required this.value, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.60),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  const _PillBadge(
      {required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style:
        TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}