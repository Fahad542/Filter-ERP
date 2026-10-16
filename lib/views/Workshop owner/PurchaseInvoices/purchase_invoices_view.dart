import 'package:flutter/material.dart';
import 'purchase_invoices_view_model.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/reusable_kpi_grid.dart';
import 'purchase_invoice_form_sheet.dart';
import 'purchase_invoice_tax_view_sheet.dart';

// =============================================================================
// PurchaseInvoicesView
// =============================================================================

class PurchaseInvoicesView extends StatefulWidget {
  final bool openNewInvoiceOnStart;

  const PurchaseInvoicesView({
    super.key,
    this.openNewInvoiceOnStart = false,
  });

  @override
  State<PurchaseInvoicesView> createState() => _PurchaseInvoicesViewState();
}

class _PurchaseInvoicesViewState extends State<PurchaseInvoicesView> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final vm = context.read<PurchaseInvoicesViewModel>();
      await vm.init();

      if (widget.openNewInvoiceOnStart && mounted) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          _showNewInvoiceSheet(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PurchaseInvoicesViewModel>();
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: l10n.ownerPurchaseInvoicesTitle,
        showDrawer: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewInvoiceSheet(context),
        backgroundColor: AppColors.primaryLight,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: Text(
          l10n.ownerPurchaseInvoicesNew,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        elevation: 4,
      ),
      body: vm.isLoading
          ? const OwnerListPageShimmer(
              showKpi: true,
              showTabs: true,
              showSearch: true,
            )
          : vm.error != null
              ? _buildError(vm)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryRow(vm, l10n),
                    Transform.translate(
                      offset: const Offset(0, -26),
                      child: PosSegmentedListTabs(
                        tabs: [
                          PosSegmentedTab(
                              id: 'invoices',
                              label: l10n.ownerPurchaseInvoicesTitle),
                          PosSegmentedTab(
                              id: 'priceReport',
                              label: l10n.ownerPurchaseInvoicesPriceReport),
                        ],
                        selectedId:
                            vm.activeTab == PurchaseInvoicesTab.invoices
                                ? 'invoices'
                                : 'priceReport',
                        onSelected: (id) => vm.setActiveTab(
                          id == 'invoices'
                              ? PurchaseInvoicesTab.invoices
                              : PurchaseInvoicesTab.priceReport,
                        ),
                        layout: PosSegmentedTabLayout.expanded,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        outerRadius: OwnerUi.segmentedTabOuterRadius,
                        innerRadius: OwnerUi.segmentedTabInnerRadius,
                        tabGap: 2,
                        containerInnerPadding: 5,
                        tabVerticalPadding: isTablet ? 11.0 : 10.0,
                        tabHorizontalPadding: isTablet ? 8.0 : 4.0,
                        fontSize: isTablet ? 12.5 : 11.5,
                      ),
                    ),
                    if (vm.activeTab == PurchaseInvoicesTab.invoices) ...[
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: _buildStatusTabs(vm, isTablet),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -12),
                        child: _buildSearchRow(vm),
                      ),
                      Expanded(child: _buildInvoiceCards(vm)),
                    ] else ...[
                      Expanded(child: _buildPriceReport(vm)),
                    ],
                  ],
                ),
    );
  }

  // ── Summary cards ─────────────────────────────────────────────────────────

  Widget _buildSummaryRow(PurchaseInvoicesViewModel vm, AppLocalizations l10n) {
    return ReusableKpiGrid(
      crossAxisCount: 2,
      showFeatured: false,
      dense: true,
      iconOnLeft: false,
      mainAxisExtent: 92,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerPurchaseInvoicesKpiPayable,
          value: formatKpiAmount(
            vm.totalAccountsPayable,
            context: context,
          ),
          icon: Icons.account_balance_wallet_rounded,
          accentColor: AppColors.primaryLight,
          subtitle: l10n.ownerPurchaseInvoicesKpiPayableSub,
        ),
        ReusableKpiMetric(
          title: l10n.ownerPurchaseInvoicesKpiTotal,
          value: ownerLocalizeDigits(context, '${vm.totalInvoicesCount}'),
          icon: Icons.receipt_long_rounded,
          accentColor: AppColors.primaryLight,
          subtitle: l10n.ownerPurchaseInvoicesKpiTotalSub,
        ),
      ],
    );
  }

  // ── Status tabs (replaces bottom-sheet status filter) ─────────────────────

  static const _statusTabIds = <String>[
    'all',
    'pending',
    'approved',
    'delivered',
    'completed',
    'draft',
    'rejected',
  ];

  List<String> _statusTabLabels(AppLocalizations l10n) => [
        l10n.ownerPurchaseInvoicesStatusAll,
        l10n.ownerPurchaseInvoicesStatusPending,
        l10n.ownerPurchaseInvoicesStatusApproved,
        l10n.ownerPurchaseInvoicesStatusDelivered,
        l10n.ownerPurchaseInvoicesStatusCompleted,
        l10n.ownerPurchaseInvoicesStatusDraft,
        l10n.ownerPurchaseInvoicesStatusRejected,
      ];

  PurchaseInvoiceStatus? _statusFromTabId(String id) {
    switch (id) {
      case 'pending':
        return PurchaseInvoiceStatus.pending;
      case 'approved':
        return PurchaseInvoiceStatus.approved;
      case 'delivered':
        return PurchaseInvoiceStatus.delivered;
      case 'completed':
        return PurchaseInvoiceStatus.completed;
      case 'draft':
        return PurchaseInvoiceStatus.draft;
      case 'rejected':
        return PurchaseInvoiceStatus.rejected;
      default:
        return null;
    }
  }

  String _tabIdFromStatus(PurchaseInvoiceStatus? status) {
    if (status == null) return 'all';
    return status.name;
  }

  Widget _buildStatusTabs(PurchaseInvoicesViewModel vm, bool isTablet) {
    final labels = _statusTabLabels(AppLocalizations.of(context)!);
    return PosSegmentedListTabs(
      tabs: [
        for (var i = 0; i < _statusTabIds.length; i++)
          PosSegmentedTab(
            id: _statusTabIds[i],
            label: labels[i],
          ),
      ],
      selectedId: _tabIdFromStatus(vm.statusFilter),
      onSelected: (id) => vm.setStatusFilter(_statusFromTabId(id)),
      layout: PosSegmentedTabLayout.scrollable,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      outerRadius: OwnerUi.segmentedTabOuterRadius,
      innerRadius: OwnerUi.segmentedTabInnerRadius,
      tabGap: 2,
      containerInnerPadding: 4,
      tabVerticalPadding: OwnerUi.segmentedTabVerticalPad(isTablet),
      tabHorizontalPadding: isTablet ? 10.0 : 8.0,
      fontSize: isTablet ? 12.0 : 11.0,
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchRow(PurchaseInvoicesViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
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
                controller: _searchCtrl,
                onChanged: (q) {
                  vm.setSearchQuery(q);
                  setState(() {});
                },
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryLight,
                  height: 1.2,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!
                      .ownerPurchaseInvoicesSearchHint,
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
            if (_searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  vm.setSearchQuery('');
                  setState(() {});
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
      ),
    );
  }

  // ── Invoice list (card view) ─────────────────────────────────────────────

  Widget _buildInvoiceCards(PurchaseInvoicesViewModel vm) {
    final invoices = vm.invoices;

    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.ownerPurchaseInvoicesEmpty,
              style: TextStyle(
                  color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.secondaryLight,
      onRefresh: vm.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: invoices.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, index) =>
            _buildInvoiceCard(vm, invoices[index]),
      ),
    );
  }

  Widget _buildInvoiceCard(
      PurchaseInvoicesViewModel vm, PurchaseInvoiceEntity inv) {
    final l10n = AppLocalizations.of(context)!;
    final hasBalance = !inv.isPaid && inv.balance > 0;
    final paymentLabel = inv.isPaid
        ? l10n.ownerPurchaseInvoicesPaid
        : inv.paymentStatus == 'partially_paid'
            ? l10n.ownerPurchaseInvoicesPartial
            : l10n.ownerPurchaseInvoicesUnpaid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: OwnerListStyle.cardRadius,
          child: InkWell(
            borderRadius: OwnerListStyle.cardRadius,
            onTap: () => _showInvoiceDetail(context, inv, vm.currency),
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
                          Icons.receipt_long_rounded,
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
                                inv.invoiceNo.isNotEmpty
                                    ? inv.invoiceNo
                                    : l10n.ownerPurchaseInvoicesInvoice,
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(inv.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inv.vendorName.isNotEmpty
                              ? inv.vendorName
                              : l10n.ownerPurchaseInvoicesUnknownVendor,
                          style: OwnerListStyle.subtitleStyle
                              .copyWith(fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ownerFormatMoney(context, inv.grandTotal,
                                    currency: vm.currency),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondaryLight,
                                ),
                              ),
                            ),
                            Text(
                              hasBalance
                                  ? ownerFormatMoney(context, inv.balance,
                                      currency: vm.currency)
                                  : paymentLabel,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: hasBalance
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _InvoiceMetaChip(
                              icon: Icons.calendar_today_rounded,
                              text: _fmtDate(inv.issueDate),
                            ),
                            if (inv.dueDate.year > 1970)
                              _InvoiceMetaChip(
                                icon: Icons.event_rounded,
                                text: l10n.ownerPurchaseInvoicesDue(
                                    _fmtDate(inv.dueDate)),
                              ),
                            if (inv.branchName.isNotEmpty)
                              _InvoiceMetaChip(
                                icon: Icons.store_outlined,
                                text: inv.branchName,
                                maxWidth: 140,
                              ),
                            if (inv.ref.isNotEmpty)
                              _InvoiceMetaChip(
                                icon: Icons.tag_rounded,
                                text: inv.ref,
                              ),
                            _InvoiceMetaChip(
                              icon: inv.isPaid
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.payments_outlined,
                              text: paymentLabel,
                            ),
                            _InvoiceMetaChip(
                              icon: inv.stockUpdated
                                  ? Icons.inventory_2_outlined
                                  : Icons.hourglass_empty_rounded,
                              text: inv.stockUpdated
                                  ? l10n.ownerPurchaseInvoicesStockUpdated
                                  : l10n.ownerPurchaseInvoicesStockPending,
                            ),
                          ],
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
      ),
    );
  }

  // ── Purchase Price Report tab (card view) ─────────────────────────────────

  Widget _buildPriceReport(PurchaseInvoicesViewModel vm) {
    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _buildReportDropdown(
                  hint: AppLocalizations.of(context)!
                      .ownerPurchaseInvoicesAllVendors,
                  icon: Icons.store_rounded,
                  value: vm.reportVendorFilter,
                  items: vm.reportVendorOptions,
                  onChanged: vm.setReportVendorFilter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportDropdown(
                  hint: AppLocalizations.of(context)!
                      .ownerPurchaseInvoicesAllProducts,
                  icon: Icons.inventory_2_rounded,
                  value: vm.reportProductFilter,
                  items: vm.reportProductOptions,
                  onChanged: vm.setReportProductFilter,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: vm.filteredReportRows.isEmpty
              ? Center(
            child: Text(
              'No price history found',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            itemCount: vm.filteredReportRows.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            itemBuilder: (context, index) =>
                _buildPriceReportCard(vm, vm.filteredReportRows[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceReportCard(
      PurchaseInvoicesViewModel vm, PurchasePriceReportRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + invoice number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LocalizedApiText(
                  row.productName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  row.invoiceNo,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLight),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Vendor + date
          Row(
            children: [
              Icon(Icons.store_rounded, size: 11, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: LocalizedApiText(
                  row.vendorName,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.calendar_today_rounded,
                  size: 11, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                ownerLocalizeDigits(context, _fmtShortDate(row.date)),
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),
          // Stats grid — row 1
          Row(
            children: [
              Expanded(
                child: _PriceStat(
                  label: AppLocalizations.of(context)!.ownerPurchaseQtyUnit,
                  value: '${ownerLocalizeDigits(context, row.qty.toStringAsFixed(0))} ${ownerLocalizedUnit(AppLocalizations.of(context)!, row.unit)}',
                ),
              ),
              Expanded(
                child: _PriceStat(
                  label: AppLocalizations.of(context)!.ownerPurchaseUnitPrice,
                  value: ownerFormatMoney(context, row.unitPrice, currency: vm.currency),
                ),
              ),
              Expanded(
                child: _PriceStat(
                  label: AppLocalizations.of(context)!.ownerPurchaseLineTotal,
                  value: ownerFormatMoney(context, row.lineTotal, currency: vm.currency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stats grid — row 2
          Row(
            children: [
              Expanded(
                child: _PriceStat(
                  label: AppLocalizations.of(context)!.ownerPurchaseTaxVat,
                  value: ownerFormatMoney(context, row.taxAmt, currency: vm.currency),
                ),
              ),
              Expanded(
                flex: 2,
                child: _PriceStat(
                  label: AppLocalizations.of(context)!.ownerPurchaseGrandTotal,
                  value: ownerFormatMoney(context, row.grandTotal, currency: vm.currency),
                  valueColor: AppColors.secondaryLight,
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtShortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year % 100}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';

  Widget _buildReportDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade500, size: 18),
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                onChanged: (v) => onChanged(v),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(hint,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  ...items.map((item) =>
                      DropdownMenuItem(value: item, child: Text(item))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(PurchaseInvoicesViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              vm.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: vm.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────

  void _showNewInvoiceSheet(BuildContext context) {
    final vm = context.read<PurchaseInvoicesViewModel>();
    showNewPurchaseInvoiceSheet(context, existingVm: vm);
  }

  void _showInvoiceDetail(
      BuildContext context, PurchaseInvoiceEntity inv, String currency) {
    showPurchaseInvoiceTaxView(
      context,
      invoice: inv,
      currency: currency,
    );
  }
}

// =============================================================================
// _PriceStat
// =============================================================================

class _PriceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  const _PriceStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: emphasize ? 13 : 12,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _StatusBadge
// =============================================================================

class _StatusBadge extends StatelessWidget {
  final PurchaseInvoiceStatus status;
  const _StatusBadge(this.status);

  Color get _fg {
    switch (status) {
      case PurchaseInvoiceStatus.approved:
      case PurchaseInvoiceStatus.completed:
        return const Color(0xFF2E7D32);
      case PurchaseInvoiceStatus.rejected:
        return Colors.red;
      case PurchaseInvoiceStatus.pending:
        return AppColors.secondaryLight;
      case PurchaseInvoiceStatus.delivered:
        return AppColors.secondaryLight;
      case PurchaseInvoiceStatus.draft:
        return OwnerListStyle.mutedText;
    }
  }

  Color get _bg {
    switch (status) {
      case PurchaseInvoiceStatus.approved:
      case PurchaseInvoiceStatus.completed:
        return const Color(0x1A43A047);
      case PurchaseInvoiceStatus.pending:
        return const Color(0x38FCC247);
      case PurchaseInvoiceStatus.rejected:
        return const Color(0x14F44336);
      case PurchaseInvoiceStatus.delivered:
        return OwnerListStyle.actionBg;
      case PurchaseInvoiceStatus.draft:
        return const Color(0x149E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status.labelFor(AppLocalizations.of(context)!),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}

class _InvoiceMetaChip extends StatelessWidget {
  const _InvoiceMetaChip({
    required this.icon,
    required this.text,
    this.maxWidth,
  });

  final IconData icon;
  final String text;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final label = Text(
      text,
      style: OwnerListStyle.metaStyle.copyWith(fontSize: 11.5),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: OwnerListStyle.mutedText),
        const SizedBox(width: 3),
        if (maxWidth != null) Flexible(child: label) else label,
      ],
    );
    if (maxWidth == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: child,
    );
  }
}
