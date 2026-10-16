import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/department_model.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_global_date_filters.dart';
import '../owner_shell.dart';
import 'discounts_view_model.dart';

// =============================================================================
// DiscountsView
// =============================================================================

class DiscountsView extends StatefulWidget {
  const DiscountsView({super.key});

  @override
  State<DiscountsView> createState() => _DiscountsViewState();
}

class _DiscountsViewState extends State<DiscountsView> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountsViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: l10n.ownerDiscountsTitle,
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
          _FilterPanel(vm: vm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              color: AppColors.primaryLight,
              child: vm.isLoading
                  ? const OwnerListPageShimmer(itemCount: 5)
                  : vm.error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [_ErrorState(vm: vm)],
                        )
                      : vm.invoices.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [_EmptyState(vm: vm)],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 40),
                              itemCount: vm.invoices.length,
                              itemBuilder: (_, i) => _DiscountCard(
                                key: ValueKey(vm.invoices[i].id),
                                item: vm.invoices[i],
                                currency: vm.currency,
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
// _KpiSection  — horizontal scrollable KPI row
// =============================================================================

class _KpiSection extends StatelessWidget {
  final DiscountsViewModel vm;
  const _KpiSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = vm.summary;
    final currency = vm.currency.trim().toUpperCase() == 'SAR'
        ? l10n.ownerCurrencySar
        : vm.currency;
    String fmt(double v) =>
        formatKpiAmount(v, currency: currency, context: context);

    return ReusableKpiGrid(
      layout: KpiGridLayout.singleRow,
      metrics: [
        ReusableKpiMetric(
          title: l10n.ownerDiscountsTotal,
          value: fmt(s.totalDiscount),
          icon: Icons.percent_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerDiscountsInvoices,
          value: ownerLocalizeDigits(context, '${s.invoiceCount}'),
          icon: Icons.receipt_long_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerDiscountsLineItem,
          value: fmt(s.lineDiscount),
          icon: Icons.list_alt_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerDiscountsInvoiceDiscount,
          value: fmt(s.invoiceDiscount),
          icon: Icons.request_quote_rounded,
          accentColor: AppColors.primaryLight,
        ),
        ReusableKpiMetric(
          title: l10n.ownerDiscountsPromoCode,
          value: fmt(s.promoDiscount),
          icon: Icons.local_offer_rounded,
          accentColor: AppColors.primaryLight,
        ),
      ],
      showFeatured: false,
      iconOnTop: true,
      mainAxisExtent: 108,
      singleRowCardWidth: 112,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    );
  }
}

// =============================================================================
// _FilterPanel  — Department filter (dates live in AppBar overlap)
// =============================================================================

class _FilterPanel extends StatelessWidget {
  final DiscountsViewModel vm;

  const _FilterPanel({required this.vm});

  @override
  Widget build(BuildContext context) {
    final hasDept = vm.department != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _DepartmentPill(
              selectedId: vm.departmentId,
              departments: vm.departmentOptions,
              onSelect: (deptId) {
                vm.setDepartment(deptId);
                vm.applyFilters();
              },
            ),
          ),
          if (hasDept) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                vm.setDepartment(null);
                vm.applyFilters();
              },
              icon: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.shade600),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Clear department',
            ),
          ],
        ],
      ),
    );
  }
}

class _DepartmentPill extends StatelessWidget {
  final String? selectedId;
  final List<Department> departments;
  final void Function(String?) onSelect;

  const _DepartmentPill({
    required this.selectedId,
    required this.departments,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = selectedId ?? 'all';
    var display = l10n.ownerCommonAllDepartments;
    if (selectedId != null) {
      for (final d in departments) {
        if (d.id == selectedId) {
          display = d.name;
          break;
        }
      }
    }

    return OwnerStyledDropdown<String>(
      value: value,
      displayLabel: display,
      hint: l10n.ownerCommonAllDepartments,
      options: [
        OwnerDropdownOption(
            value: 'all', label: l10n.ownerCommonAllDepartments),
        ...departments.map(
          (d) => OwnerDropdownOption(value: d.id, label: d.name),
        ),
      ],
      onChanged: (v) => onSelect(v == 'all' ? null : v),
    );
  }
}

// =============================================================================
// _DiscountCard
// =============================================================================

class _DiscountCard extends StatelessWidget {
  final WorkshopDiscountInvoice item;
  final String                  currency;

  const _DiscountCard({super.key, required this.item, required this.currency});

  static String _fmtDate(DateTime d) {
    final local = d.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day}, ${local.year}, '
        '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final customer = item.customerName.isNotEmpty
        ? item.customerName
        : item.customerMobile;
    final discountLabel =
        ownerFormatMoney(context, -item.totalDiscount, currency: currency);
    final totalLabel = ownerFormatMoney(context, item.invoiceTotal,
        currency: currency);

    return GestureDetector(
      onTap: () => _showDetail(context),
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
                    child: const Icon(
                      Icons.discount_rounded,
                      color: AppColors.primaryLight,
                      size: 18,
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
                              item.invoiceNo,
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
                              color: const Color(0x38FCC247),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              discountLabel,
                              style: const TextStyle(
                                color: AppColors.secondaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (customer.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer,
                          style: OwnerListStyle.subtitleStyle
                              .copyWith(fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Total  $totalLabel',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _DiscMetaGrid(
                        children: [
                          _DiscMetaLine(
                            icon: Icons.format_list_bulleted_rounded,
                            text:
                                'Line ${ownerFormatMoney(context, item.lineDiscount, currency: currency)}',
                          ),
                          _DiscMetaLine(
                            icon: Icons.receipt_long_outlined,
                            text:
                                'Invoice ${ownerFormatMoney(context, item.invoiceDiscount, currency: currency)}',
                          ),
                          _DiscMetaLine(
                            icon: Icons.local_offer_outlined,
                            text:
                                'Promo ${ownerFormatMoney(context, item.promoDiscount, currency: currency)}',
                          ),
                          if (item.vehiclePlate.isNotEmpty)
                            _DiscMetaLine(
                              icon: Icons.directions_car_outlined,
                              text: item.vehiclePlate,
                            ),
                          _DiscMetaLine(
                            icon: Icons.store_outlined,
                            text: item.branchName,
                          ),
                          if (item.departmentName.isNotEmpty)
                            _DiscMetaLine(
                              icon: Icons.category_outlined,
                              text: item.departmentName,
                            ),
                          _DiscMetaLine(
                            icon: Icons.access_time_rounded,
                            text: _fmtDate(item.createdAt),
                          ),
                          _DiscMetaLine(
                            icon: Icons.person_outline_rounded,
                            text: item.cashierName,
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
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:  true,
      backgroundColor:     Colors.transparent,
      builder: (_) => _DiscountDetailSheet(item: item, currency: currency),
    );
  }
}

class _DiscMetaGrid extends StatelessWidget {
  const _DiscMetaGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) {
      if (w is _DiscMetaLine) return w.text.trim().isNotEmpty;
      return true;
    }).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i += 2) {
      final left = visible[i];
      final right = i + 1 < visible.length ? visible[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < visible.length ? 2 : 0),
          child: Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 8),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _DiscMetaLine extends StatelessWidget {
  const _DiscMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 13, color: OwnerListStyle.mutedText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: OwnerListStyle.metaStyle.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _DiscountDetailSheet — bottom sheet, full breakdown
// =============================================================================

class _DiscountDetailSheet extends StatelessWidget {
  final WorkshopDiscountInvoice item;
  final String                  currency;

  const _DiscountDetailSheet({required this.item, required this.currency});

  static String _fmtDt(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day}, ${local.year}, '
        '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final discountLabel =
        ownerFormatMoney(context, -item.totalDiscount, currency: currency);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize:     0.50,
      maxChildSize:     0.95,
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
                          'Discount — ${item.invoiceNo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.customerName.isNotEmpty
                              ? item.customerName
                              : item.customerMobile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        discountLabel,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706)),
                      ),
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
                  // ── Invoice info ─────────────────────────────────────
                  _SheetCard(children: [
                    _SheetRow('Invoice',   item.invoiceNo),
                    _SheetRow('Customer',
                        item.customerName.isNotEmpty
                            ? item.customerName
                            : item.customerMobile),
                    if (item.customerMobile.isNotEmpty &&
                        item.customerName.isNotEmpty)
                      _SheetRow('Mobile', item.customerMobile),
                    _SheetRow('Vehicle',
                        item.vehiclePlate.isNotEmpty
                            ? item.vehiclePlate
                            : '—'),
                    _SheetRow('Cashier',
                        item.cashierName.isNotEmpty
                            ? item.cashierName
                            : '—'),
                    _SheetRow('Branch', item.branchName),
                    if (item.departmentName.isNotEmpty)
                      _SheetRow(AppLocalizations.of(context)!.ownerDiscountsSheetDepartment, item.departmentName),
                    _SheetRow('Date / time', _fmtDt(item.createdAt),
                        isLast: true),
                  ]),

                  const SizedBox(height: 12),

                  // ── Discount breakdown ───────────────────────────────
                  _SheetCard(children: [
                    _SheetRow(
                        'Line / item discount',
                        ownerFormatMoney(context, item.lineDiscount,
                            currency: currency)),
                    _SheetRow(
                        'Invoice discount',
                        ownerFormatMoney(context, item.invoiceDiscount,
                            currency: currency)),
                    _SheetRow(
                        'Promo code discount',
                        ownerFormatMoney(context, item.promoDiscount,
                            currency: currency)),

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),

                    const SizedBox(height: 8),

                    // Totals
                    _TotalRow(
                      label: AppLocalizations.of(context)!.ownerDiscountsSheetTotal,
                      value: discountLabel,
                      valueColor: const Color(0xFFD97706),
                    ),
                    _TotalRow(
                      label:      'Invoice total',
                      value: ownerFormatMoney(context, item.invoiceTotal,
                          currency: currency),
                      valueColor: AppColors.secondaryLight,
                      isLast:     true,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Sheet helpers
// =============================================================================

class _SheetCard extends StatelessWidget {
  final List<Widget> children;
  const _SheetCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: const Color(0xFFF0F0F5)),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2)),
      ],
    ),
    child: Column(children: children),
  );
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isLast;
  const _SheetRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
            ),
          ],
        ),
      ),
      if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  final bool   isLast;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 14 : 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF374151))),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: valueColor)),
        ),
      ],
    ),
  );
}

// =============================================================================
// Empty / Error states
// =============================================================================

class _EmptyState extends StatelessWidget {
  final DiscountsViewModel vm;
  const _EmptyState({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:      MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.discount_outlined,
                  size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(l10n.ownerDiscountsEmptyTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            Text(
              l10n.ownerDiscountsEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.5),
            ),
            if (vm.department != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: vm.clearFilters,
                icon:  const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.ownerDiscountsClearFilters,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryLight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final DiscountsViewModel vm;
  const _ErrorState({required this.vm});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:      MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded,
                size: 36, color: Colors.red.shade300),
          ),
          const SizedBox(height: 16),
          Text(vm.error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: vm.refresh,
            icon:  const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryLight),
          ),
        ],
      ),
    ),
  );
}