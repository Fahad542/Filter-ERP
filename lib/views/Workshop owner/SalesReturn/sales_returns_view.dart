import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_global_date_filters.dart';
import '../owner_shell.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';
import 'sales_returns_view_model.dart';

// =============================================================================
// SalesReturnsView
// =============================================================================

class SalesReturnsView extends StatefulWidget {
  const SalesReturnsView({super.key});

  @override
  State<SalesReturnsView> createState() => _SalesReturnsViewState();
}

class _SalesReturnsViewState extends State<SalesReturnsView> {
  static const _statusKeys = ['all', 'approved', 'pending', 'rejected'];
  String _statusLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'approved':
        return l10n.ownerSalesReturnsStatusApproved;
      case 'pending':
        return l10n.ownerSalesReturnsStatusPending;
      case 'rejected':
        return l10n.ownerSalesReturnsStatusRejected;
      default:
        return l10n.ownerSalesReturnsStatusAll;
    }
  }

  final _invoiceController = TextEditingController();

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SalesReturnsViewModel>();
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: l10n.ownerSalesReturnsTitle,
        showDrawer: true,
        showBackButton: false,
        showNotification: false,
        onMenuPressed: () => OwnerShell.openDrawer(context),
        bottomOverlap: const OwnerGlobalDateOverlapFilters(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiSection(vm: vm),
          Transform.translate(
            offset: const Offset(0, -14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _InvoiceSearch(
                controller: _invoiceController,
                onChanged: vm.setInvoiceSearch,
              ),
            ),
          ),
          PosSegmentedListTabs(
            tabs: [
              for (final key in _statusKeys)
                PosSegmentedTab(
                  id: key,
                  label: _statusLabel(l10n, key),
                ),
            ],
            selectedId: vm.statusFilter,
            onSelected: vm.setStatusFilter,
            layout: PosSegmentedTabLayout.expanded,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            outerRadius: OwnerUi.segmentedTabOuterRadius,
            innerRadius: OwnerUi.segmentedTabInnerRadius,
            tabGap: 2,
            containerInnerPadding: 4,
            tabVerticalPadding: OwnerUi.segmentedTabVerticalPad(isTablet),
            tabHorizontalPadding: isTablet ? 8.0 : 4.0,
            fontSize: isTablet ? 12.5 : 11.5,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              color: AppColors.primaryLight,
              child: vm.isLoading
                  ? const OwnerListPageShimmer(itemCount: 5)
                  : vm.returns.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          children: [
                            _EmptyState(vm: vm),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: vm.returns.length,
                          itemBuilder: (_, i) => _ReturnCard(
                            key: ValueKey(vm.returns[i].id),
                            item: vm.returns[i],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _KpiSection
// =============================================================================

class _KpiSection extends StatelessWidget {
  final SalesReturnsViewModel vm;
  const _KpiSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ReusableKpiGrid.owner(
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerSalesReturnsKpiShownReturns,
          value: '${vm.shownCount}',
          icon: Icons.assignment_return_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.ownerSalesReturnsKpiShownAmount,
          value: '${vm.currency} ${vm.shownAmount.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet_rounded,
        ),
      ],
      crossAxisCount: 2,
      iconOnLeft: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}

// =============================================================================
// _ReturnCard — tap opens detail bottom sheet
// =============================================================================

class _ReturnCard extends StatelessWidget {
  final SalesReturnItem item;
  const _ReturnCard({super.key, required this.item});

  static String _fmtDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  $h:$m';
  }

  static String _typeLabel(AppLocalizations l10n, SalesReturnType t) {
    switch (t) {
      case SalesReturnType.cash:
        return l10n.ownerSalesReturnsTypeCash;
      case SalesReturnType.creditNote:
        return l10n.ownerSalesReturnsTypeCreditNote;
      case SalesReturnType.exchange:
        return l10n.ownerSalesReturnsTypeExchange;
    }
  }

  static IconData _typeIcon(SalesReturnType t) {
    switch (t) {
      case SalesReturnType.cash:
        return Icons.payments_rounded;
      case SalesReturnType.creditNote:
        return Icons.receipt_rounded;
      case SalesReturnType.exchange:
        return Icons.swap_horiz_rounded;
    }
  }

  static Color _statusFg(String s) {
    switch (s) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.secondaryLight;
    }
  }

  static Color _statusBg(String s) {
    switch (s) {
      case 'approved':
        return const Color(0x1A43A047);
      case 'pending':
        return const Color(0x38FCC247);
      case 'rejected':
        return const Color(0x14F44336);
      default:
        return OwnerListStyle.actionBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusFg = _statusFg(item.status);
    final statusBg = _statusBg(item.status);
    final displayStatus = item.displayStatus;
    final statusLabel = displayStatus.isEmpty
        ? '—'
        : displayStatus[0].toUpperCase() + displayStatus.substring(1);

    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DecoratedBox(
          decoration: OwnerListStyle.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: DecoratedBox(
                    decoration: OwnerListStyle.iconBoxDecoration,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        _typeIcon(item.type),
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.creditNoteNumber,
                              style: OwnerListStyle.titleStyle
                                  .copyWith(fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusFg,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.invoiceNumber,
                        style: OwnerListStyle.subtitleStyle
                            .copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.displayCustomerName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.currency} ${item.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _ReturnMetaLine(
                        icon: Icons.confirmation_number_outlined,
                        text: item.returnNo,
                      ),
                      _ReturnMetaLine(
                        icon: Icons.store_outlined,
                        text: item.displayBranchName,
                      ),
                      _ReturnMetaLine(
                        icon: Icons.swap_horiz_rounded,
                        text: _typeLabel(l10n, item.type),
                      ),
                      _ReturnMetaLine(
                        icon: Icons.access_time_rounded,
                        text: _fmtDate(item.dateTime),
                      ),
                      _ReturnMetaLine(
                        icon: Icons.person_outline_rounded,
                        text: item.displayCashierName,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SalesReturnDetailSheet(item: item),
    );
  }
}

class _ReturnMetaLine extends StatelessWidget {
  const _ReturnMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: OwnerListStyle.mutedText),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _SalesReturnDetailSheet — bottom sheet (image 2 style)
// =============================================================================

class _SalesReturnDetailSheet extends StatelessWidget {
  final SalesReturnItem item;
  const _SalesReturnDetailSheet({required this.item});

  static String _fmtDt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}, '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: OwnerUi.sheetMaxSize,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales return ${item.creditNoteNumber}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invoice ${item.invoiceNumber} · ${item.displayCustomerName}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBg(item.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.displayStatus[0].toUpperCase() +
                          item.displayStatus.substring(1),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(item.status)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Info card ─────────────────────────────────────────
                  _SheetCard(
                    children: [
                      _SheetRow('Credit note', item.creditNoteNumber),
                      _SheetRow('Invoice',     item.invoiceNumber),
                      _SheetRow('Customer',
                          '${item.displayCustomerName}${item.customerMobile.isNotEmpty ? ' · ${item.customerMobile}' : ''}'),
                      _SheetRow('Vehicle',     item.vehiclePlate.isNotEmpty ? item.vehiclePlate : '—'),
                      _SheetRow('Cashier',     item.displayCashierName.isNotEmpty ? item.displayCashierName : '—'),
                      _SheetRow('Branch',      item.displayBranchName),
                      _SheetRow('Return type',
                          item.returnScope == 'full' ? 'Full return' : 'Partial return'),
                      _SheetRow('Date', _fmtDt(item.dateTime), isLast: true),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Items / totals table ──────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0F0F5)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: const [
                              Expanded(flex: 3,
                                  child: _TblHeader('Product / service')),
                              Expanded(
                                  child: _TblHeader('Return qty',
                                      align: TextAlign.center)),
                              Expanded(
                                  child: _TblHeader('Line total',
                                      align: TextAlign.right)),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.displayNotes?.split('\n').first ?? '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF374151),
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const Expanded(
                                child: Text('1',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827))),
                              ),
                              Expanded(
                                child: Text(
                                  '${item.currency} ${item.subtotal.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                          child: Column(
                            children: [
                              _TotalRow('Subtotal',
                                  '${item.currency} ${item.subtotal.toStringAsFixed(2)}'),
                              _TotalRow('VAT',
                                  '${item.currency} ${item.vatAmount.toStringAsFixed(2)}'),
                              _TotalRow(
                                'Total',
                                '${item.currency} ${item.amount.toStringAsFixed(2)}',
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Action buttons ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: open invoice URL
                          },
                          icon: const Icon(Icons.open_in_new_rounded,
                              size: 15),
                          label: const Text('View digital invoice'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: const Color(0xFF374151),
                            textStyle: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showCreditNoteDialog(context, item);
                          },
                          icon: const Icon(Icons.print_outlined, size: 15),
                          label: const Text('View credit note / Print'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFFB8860B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            textStyle: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'approved': return const Color(0xFF059669);
      case 'pending':  return const Color(0xFFD97706);
      case 'rejected': return const Color(0xFFDC2626);
      default:         return Colors.grey;
    }
  }

  static Color _statusBg(String s) {
    switch (s) {
      case 'approved': return const Color(0xFFD1FAE5);
      case 'pending':  return const Color(0xFFFEF3C7);
      case 'rejected': return const Color(0xFFFEE2E2);
      default:         return const Color(0xFFF3F4F6);
    }
  }
}

// =============================================================================
// _showCreditNoteDialog + _CreditNoteDialog — image 1 style
// =============================================================================

void _showCreditNoteDialog(BuildContext context, SalesReturnItem item) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: _CreditNoteDialog(item: item),
    ),
  );
}

class _CreditNoteDialog extends StatelessWidget {
  final SalesReturnItem item;
  const _CreditNoteDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final dt = item.dateTime;
    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(dt.day)}/${two(dt.month)}/${dt.year}, ${two(dt.hour)}:${two(dt.minute)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('CREDIT NOTE',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.5)),
                          SizedBox(height: 4),
                          Text('FILTER',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFB8860B),
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ZATCA Phase 2\nQR Code\n(set branch/\nworkshop\nVAT no.)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Info grid (3 columns) ────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CnCol(children: [
                            _CnField('Phone No.', '—'),
                            _CnField('Vehicle No.',
                                item.vehiclePlate.isNotEmpty
                                    ? item.vehiclePlate
                                    : '—'),
                            _CnField('Customer', item.displayCustomerName),
                          ]),
                        ),
                        VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Colors.grey.shade300),
                        Expanded(
                          child: _CnCol(children: [
                            _CnField('Return Date', dateStr),
                            _CnField('Invoice Number', item.invoiceNumber),
                            _CnField('Return By',
                                item.displayCashierName.isNotEmpty
                                    ? item.displayCashierName
                                    : '—'),
                            _CnField('Credit Note No.',
                                item.creditNoteNumber),
                          ]),
                        ),
                        VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Colors.grey.shade300),
                        Expanded(
                          child: _CnCol(children: [
                            _CnField('Branch Name', item.displayBranchName),
                            _CnField('VAT Number', '—'),
                            _CnField('Return type',
                                item.returnScope == 'full'
                                    ? 'Full return'
                                    : 'Partial return'),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Items table ──────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: const [
                            Expanded(
                                flex: 3,
                                child: Text('Nature of goods or services',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                            Expanded(
                                child: Text('Unit price',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                            Expanded(
                                child: Text('Return Qty',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                            Expanded(
                                child: Text('Item Subtotal (Incl. VAT)',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(
                                  item.displayNotes?.split('\n').first ?? '—',
                                  style: const TextStyle(fontSize: 12),
                                )),
                            Expanded(
                                child: Text(
                                    '${item.subtotal.toStringAsFixed(2)} ${item.currency}',
                                    textAlign: TextAlign.center,
                                    style:
                                    const TextStyle(fontSize: 12))),
                            const Expanded(
                                child: Text('1',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12))),
                            Expanded(
                                child: Text(
                                    '${item.subtotal.toStringAsFixed(2)} ${item.currency}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'CREDIT NOTE — THIS IS A VALID TENDER FOR THE AMOUNT '
                        '${item.amount.toStringAsFixed(2)} SR',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827)),
                  ),
                ),

                const SizedBox(height: 20),

                // Signatures
                Row(
                  children: const [
                    Expanded(child: _SigLine('Supervisor Signature')),
                    SizedBox(width: 12),
                    Expanded(child: _SigLine('Accountant Signature')),
                    SizedBox(width: 12),
                    Expanded(child: _SigLine('Customer Signature')),
                  ],
                ),

                const SizedBox(height: 14),

                Center(
                  child: Text(
                    'VALID ONLY IN ${item.displayBranchName.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Dialog actions ───────────────────────────────────────────────
        Divider(height: 1, color: Colors.grey.shade200),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: const Color(0xFF374151),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: integrate flutter/printing package
                  },
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFB8860B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Sheet / dialog helper widgets
// =============================================================================

class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0F0F5)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2)),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(children: children),
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(this.label, this.value, {this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

class _TblHeader extends StatelessWidget {
  const _TblHeader(this.text, {this.align = TextAlign.left});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: align,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280)));
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: bold ? 13 : 12,
                  fontWeight:
                  bold ? FontWeight.w800 : FontWeight.w500,
                  color: bold
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280))),
        ),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF111827))),
      ],
    ),
  );
}

class _CnCol extends StatelessWidget {
  final List<Widget> children;
  const _CnCol({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children),
  );
}

class _CnField extends StatelessWidget {
  const _CnField(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 11, color: Color(0xFF374151), height: 1.4),
        children: [
          TextSpan(
              text: '$label: ',
              style:
              const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

class _SigLine extends StatelessWidget {
  const _SigLine(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Divider(color: Colors.grey.shade400, thickness: 0.8),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500)),
    ],
  );
}

// =============================================================================
// _InvoiceSearch
// =============================================================================

class _InvoiceSearch extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String?) onChanged;

  const _InvoiceSearch({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLight,
                height: 1.2,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.ownerSalesReturnsSearchHint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged(null);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Colors.grey.shade500),
              ),
            ),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.secondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _EmptyState
// =============================================================================

class _EmptyState extends StatelessWidget {
  final SalesReturnsViewModel vm;
  const _EmptyState({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSearch =
        vm.invoiceSearch != null && vm.invoiceSearch!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined,
                size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(l10n.ownerSalesReturnsEmptyTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF374151))),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? l10n.ownerSalesReturnsEmptySearchBody
                : l10n.ownerSalesReturnsEmptyDefaultBody,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
          if (hasSearch || vm.statusFilter != 'all') ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: vm.clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text(l10n.ownerSalesReturnsClearFilters,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryLight),
            ),
          ],
        ],
      ),
    );
  }
}