import 'package:flutter/material.dart';

import '../../../../data/repositories/owner_repository.dart';
import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../Workshop owner/widgets/owner_app_bar.dart';
import '../../../Workshop owner/widgets/owner_shimmer.dart';
import 'non_affilidated_supplier_models.dart';

class NonAffiliatedSupplierLedgerView extends StatefulWidget {
  final NonAffiliatedSupplier supplier;
  final String token;
  final NonAffiliatedSuppliersRepository repo;

  const NonAffiliatedSupplierLedgerView({
    super.key,
    required this.supplier,
    required this.token,
    required this.repo,
  });

  @override
  State<NonAffiliatedSupplierLedgerView> createState() =>
      _NonAffiliatedSupplierLedgerViewState();
}

class _NonAffiliatedSupplierLedgerViewState
    extends State<NonAffiliatedSupplierLedgerView> {
  late DateTime _fromDate;
  late DateTime _toDate;
  late Future<NonAffiliatedLedgerResponse> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _future = _load();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<NonAffiliatedLedgerResponse> _load() {
    return widget.repo.getLedger(
      widget.token,
      supplierId: widget.supplier.id,
      from: _iso(_fromDate),
      to: _iso(_toDate),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
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
      _future = _load();
    });
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
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
        onRefresh: _refresh,
        child: FutureBuilder<NonAffiliatedLedgerResponse>(
          future: _future,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final data = snapshot.data;

            return CustomScrollView(
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
                        _LedgerFilterCard(
                          fromLabel: _fmt(_fromDate),
                          toLabel: _fmt(_toDate),
                          onFromTap: () => _pickDate(context, true),
                          onToTap: () => _pickDate(context, false),
                        ),
                        const SizedBox(height: 14),
                        _LedgerInfoCard(
                          openingBalance:
                              data?.openingBalance ?? widget.supplier.openingBalance,
                          finalBalance: data?.totals.closingBalance ??
                              widget.supplier.finalBalance,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: OwnerListPageShimmer(itemCount: 4),
                  )
                else if (hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text('${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11.5, color: Colors.grey.shade500)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryLight,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: _LedgerCardList(
                      entries: data!.toDisplayEntries(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supplier header
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerSupplierHeader extends StatelessWidget {
  final NonAffiliatedSupplier supplier;
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
// Date filter card — picking a date auto-reloads the ledger from the API
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerFilterCard extends StatelessWidget {
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final String fromLabel;
  final String toLabel;

  const _LedgerFilterCard({
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
            child: _DateTile(label: 'From date', value: fromLabel, onTap: onFromTap),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateTile(label: 'To date', value: toLabel, onTap: onToTap),
          ),
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
  const _LedgerInfoCard({required this.openingBalance, required this.finalBalance});

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
          Container(width: 1, height: 38, color: Colors.white.withOpacity(0.12)),
          Expanded(
            child: _InfoItem(
              label: 'Closing balance',
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
// Ledger card list
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerCardList extends StatelessWidget {
  final List<NonAffiliatedLedgerEntry> entries;
  const _LedgerCardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: entries.length + 1, // +1 for header
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        if (i == 0) return const _LedgerCardHeader();
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
          Expanded(flex: 2, child: _HeaderCell('DATE')),
          Expanded(flex: 5, child: _HeaderCell('DESCRIPTION')),
          Expanded(flex: 2, child: _HeaderCell('DEBIT', right: true)),
          Expanded(flex: 2, child: _HeaderCell('CREDIT', right: true)),
          Expanded(flex: 2, child: _HeaderCell('BALANCE', right: true)),
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
  final NonAffiliatedLedgerEntry entry;
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
          Expanded(
            flex: 2,
            child: Text(
              entry.date.isEmpty ? '—' : entry.date,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                color: isTotal ? AppColors.secondaryLight : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              entry.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: (isTotal || isOpening) ? FontWeight.w900 : FontWeight.w600,
                color: (isTotal || isOpening)
                    ? AppColors.secondaryLight
                    : Colors.grey.shade700,
              ),
            ),
          ),
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
                color: isTotal ? AppColors.secondaryLight : Colors.grey.shade700,
              ),
            ),
          ),
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
                color: isTotal ? AppColors.secondaryLight : Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'SAR ${entry.balance.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                color: isTotal ? AppColors.secondaryLight : Colors.grey.shade700,
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  const _InfoItem({required this.label, required this.value, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
  const _PillBadge({required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
