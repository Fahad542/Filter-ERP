import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/toast_service.dart';
import '../../Workshop owner/PurchaseInvoices/purchase_invoice_form_sheet.dart';
import '../Reports/reports_search_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_sheet_actions.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'inventory_management_view.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  STOCK TAB
// ═══════════════════════════════════════════════════════════════════════════════

class StockTab extends StatefulWidget {
  final InventoryV2ViewModel vm;
  const StockTab({super.key, required this.vm});

  @override
  State<StockTab> createState() => StockTabState();
}

class StockTabState extends State<StockTab> {
  InventoryV2ViewModel get vm => widget.vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = vm.filteredProducts;
    final selectedCount = vm.selectedIds.length;

    return Column(
      children: [
        // ── Search (left) + Dept + Low Stock (right) ──────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: ReportsSearchBar(
                  hint: l10n.ownerInventorySearchHint,
                  onChanged: (v) {
                    vm.setSearch(v);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 88,
                height: 44,
                child: _DeptDropdown(
                  selectedId: vm.deptFilter,
                  allProducts: vm.allProducts,
                  onChanged: (v) {
                    vm.setDeptFilter(v);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 6),
              _LowStockBtn(
                active: vm.lowStockOnly,
                onTap: () {
                  vm.toggleLowStock(!vm.lowStockOnly);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),

        // ── Selection / count bar ─────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          child: Row(
            children: [
              // Checkbox-style select all toggle
              if (selectedCount == 0)
                GestureDetector(
                  onTap: () {
                    vm.selectAll(products);
                    setState(() {});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.ownerCommonSelectAll,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    vm.clearSelection();
                    setState(() {});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.check, size: 12, color: AppColors.secondaryLight),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Deselect ($selectedCount)',
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                l10n.ownerInventoryProductsCount(products.length),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              if (selectedCount > 0) ...[
                const SizedBox(width: 8),
                _SmallBtn(
                  label: 'Bulk UOM',
                  color: AppColors.primaryLight,
                  onTap: () => _showBulkUomDialog(context),
                ),
              ],
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),

        // ── Product table ──────────────────────────────────────────────
        Expanded(
          child: vm.isLoading
              ? const _StockLoadingShimmer()
              : products.isEmpty
              ? EmptyState(
              message: vm.searchQuery.isNotEmpty
                  ? 'No results for "${vm.searchQuery}"'
                  : vm.lowStockOnly
                  ? 'No low-stock items'
                  : l10n.ownerInventoryNoProducts)
              : RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: () => vm.refresh(),
            child: StockDataTable(
              products: products,
              selectedIds: vm.selectedIds,
              onToggle: (id) => vm.toggleSelection(id),
              onRequest: (p) => _showPurchaseInvoiceRequest(context, p),
              onManualAdjust: (p) => _showManualAdjustDialog(context, p),
              onCriticalLevel: (p) => _showCriticalLevelDialog(context, p),
              onLinkUom: (p) => _showLinkUomDialog(context, p),
              onRowTap: (p) => _showStockTimeline(context, p),
            ),
          ),
        ),
      ],
    );
  }

  // ── Dialogs launched from stock tab ────────────────────────────────

  void _showPurchaseInvoiceRequest(BuildContext context, InvProduct product) {
    showNewPurchaseInvoiceSheet(context, initialProduct: product);
  }

  void _showStockTimeline(BuildContext context, InvProduct product) {
    showDialog(
      context: context,
      builder: (_) => StockTimelineDialog(product: product, vm: vm),
    );
  }

  void _showBulkUomDialog(BuildContext context) {
    final selectedProducts = vm.filteredProducts
        .where((p) => vm.selectedIds.contains(p.rowKey))
        .toList();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: BulkUomDialog(products: selectedProducts),
      ),
    );
  }

  void _showManualAdjustDialog(BuildContext context, InvProduct product) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _ManualAdjustDialog(product: product, vm: vm),
    );
  }

  void _showCriticalLevelDialog(BuildContext context, InvProduct product) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _CriticalStockDialog(product: product, vm: vm),
    );
  }

  void _showLinkUomDialog(BuildContext context, InvProduct product) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _EditUomConversionDialog(product: product),
      ),
    );
  }
}

// ─── Dept Dropdown ────────────────────────────────────────────────────────────

class _DeptDropdown extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final List<InvProduct> allProducts;
  const _DeptDropdown({
    required this.selectedId,
    required this.onChanged,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deptMap = <String, String>{};
    for (final p in allProducts) {
      if (p.departmentId.isNotEmpty) {
        deptMap[p.departmentId] = p.department;
      }
    }
    final depts = deptMap.entries.toList();
    final value = selectedId ?? 'all';
    var display = l10n.ownerCommonAllDepts;
    if (selectedId != null) {
      display = deptMap[selectedId] ?? selectedId!;
    }

    return OwnerStyledDropdown<String>(
      value: value,
      displayLabel: display,
      hint: l10n.ownerCommonAllDepts,
      height: 36,
      backgroundColor: Colors.white,
      borderColor: Colors.grey.shade200,
      options: [
        OwnerDropdownOption(value: 'all', label: l10n.ownerCommonAllDepartments),
        ...depts.map(
          (d) => OwnerDropdownOption(value: d.key, label: d.value),
        ),
      ],
      onChanged: (v) => onChanged(v == 'all' ? null : v),
    );
  }
}

// ─── Low Stock Toggle Button ──────────────────────────────────────────────────

class _LowStockBtn extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _LowStockBtn({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight.withValues(alpha: 0.18) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.primaryLight : Colors.grey.shade300),
        ),
        child: Text(
          l10n.ownerInventoryLowStockFilter,
          style: TextStyle(
            color: active ? AppColors.secondaryLight : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Small Button ─────────────────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Stock Card List ──────────────────────────────────────────────────────────

class StockDataTable extends StatelessWidget {
  final List<InvProduct> products;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final ValueChanged<InvProduct> onRequest;
  final ValueChanged<InvProduct> onManualAdjust;
  final ValueChanged<InvProduct> onCriticalLevel;
  final ValueChanged<InvProduct> onLinkUom;
  final ValueChanged<InvProduct> onRowTap;

  const StockDataTable({
    super.key,
    required this.products,
    required this.selectedIds,
    required this.onToggle,
    required this.onRequest,
    required this.onManualAdjust,
    required this.onCriticalLevel,
    required this.onLinkUom,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return _StockCard(
          product: p,
          isSelected: selectedIds.contains(p.rowKey),
          onTap: () => onRowTap(p),
          onToggle: () => onToggle(p.rowKey),
          onRequest: () => onRequest(p),
          onManualAdjust: () => onManualAdjust(p),
          onCriticalLevel: () => onCriticalLevel(p),
          onLinkUom: () => onLinkUom(p),
        );
      },
    );
  }
}

class _StockCard extends StatefulWidget {
  final InvProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onRequest;
  final VoidCallback onManualAdjust;
  final VoidCallback onCriticalLevel;
  final VoidCallback onLinkUom;

  const _StockCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.onToggle,
    required this.onRequest,
    required this.onManualAdjust,
    required this.onCriticalLevel,
    required this.onLinkUom,
  });

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard> {
  bool _requestLoading = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isSelected = widget.isSelected;
    final isLow = p.isLowStock;
    final isOut = p.isOutOfStock;
    final stockColor = isOut
        ? AppColors.errorLight
        : isLow
            ? Colors.orange.shade700
            : const Color(0xFF43A047);
    final l10n = AppLocalizations.of(context)!;
    final stockLabel = isOut
        ? l10n.posProductOutOfStock
        : isLow
            ? l10n.ownerInventoryKpiLowStock
            : l10n.posProductInStock;
    final unitLabel = ownerLocalizedUnit(l10n, p.unit);
    final currentStr = ownerLocalizeDigits(context, '${p.currentStock}');
    final openingStr = ownerLocalizeDigits(context, '${p.openingStock}');
    final currentOpeningLine = l10n.ownerInventoryCurrentOpening(
      currentStr,
      unitLabel,
      openingStr,
    );
    final criticalLine = p.criticalStock == 0
        ? l10n.ownerInventoryCriticalDash
        : l10n.ownerInventoryCriticalValue(
            '${ownerLocalizeDigits(context, '${p.criticalStock}')} · $stockLabel',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: OwnerListStyle.cardRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : OwnerListStyle.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: OwnerListStyle.cardRadius,
          child: InkWell(
            borderRadius: OwnerListStyle.cardRadius,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OwnerListIconBox(
                        icon: Icons.inventory_2_rounded,
                        showActiveDot: p.isActive && !isOut && !isLow,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: LocalizedApiText(
                                    p.name,
                                    style: OwnerListStyle.titleStyle
                                        .copyWith(fontSize: 14.5),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: widget.onToggle,
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryLight
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: AppColors.secondaryLight,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            if (p.sku.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.sku,
                                style: OwnerListStyle.subtitleStyle
                                    .copyWith(fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if ((p.branchName ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                p.branchName!.trim(),
                                style: OwnerListStyle.subtitleStyle.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              ownerFormatMoney(context, p.salePrice),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _StockMetaLine(
                              icon: Icons.category_outlined,
                              text: p.department.isNotEmpty
                                  ? (p.category.isNotEmpty
                                      ? '${p.department} · ${p.category}'
                                      : p.department)
                                  : p.category,
                              translate: true,
                            ),
                            _StockMetaLine(
                              icon: Icons.inventory_outlined,
                              text: currentOpeningLine,
                              color: stockColor,
                            ),
                            _StockMetaLine(
                              icon: Icons.warning_amber_rounded,
                              text: criticalLine,
                              color: isOut || isLow ? stockColor : null,
                            ),
                            GestureDetector(
                              onTap: widget.onLinkUom,
                              child: _StockMetaLine(
                                icon: Icons.sync_alt_rounded,
                                text: p.conversionFactor > 1
                                    ? '${p.warehouseUnit} → ${p.unit} (×${p.conversionFactor})'
                                    : p.unit,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StockActionChip(
                                  label: l10n.ownerInventoryRequest,
                                  primary: true,
                                  loading: _requestLoading,
                                  onTap: () async {
                                    if (_requestLoading) return;
                                    setState(() => _requestLoading = true);
                                    widget.onRequest();
                                    await Future.delayed(
                                        const Duration(milliseconds: 600));
                                    if (mounted) {
                                      setState(() => _requestLoading = false);
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                _StockActionChip(
                                  label: l10n.ownerInventoryAdjust,
                                  onTap: widget.onManualAdjust,
                                ),
                                const SizedBox(width: 6),
                                _StockActionChip(
                                  label: l10n.ownerInventoryCritical,
                                  onTap: widget.onCriticalLevel,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class _StockMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool translate;

  const _StockMetaLine({
    required this.icon,
    required this.text,
    this.color,
    this.translate = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final c = color ?? OwnerListStyle.mutedText;
    final style = OwnerListStyle.metaStyle.copyWith(
      fontSize: 12.5,
      color: c,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Expanded(
            child: translate
                ? LocalizedApiText(
                    text,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    text,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StockActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool loading;

  const _StockActionChip({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? AppColors.primaryLight : OwnerListStyle.actionBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondaryLight,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STOCK LOADING SHIMMER
// ═══════════════════════════════════════════════════════════════════════════════

class _StockLoadingShimmer extends StatefulWidget {
  const _StockLoadingShimmer();

  @override
  State<_StockLoadingShimmer> createState() => _StockLoadingShimmerState();
}

class _StockLoadingShimmerState extends State<_StockLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimmerBox({double width = double.infinity, double height = 14, double radius = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 18, height: 18, radius: 4),
              const SizedBox(width: 10),
              Expanded(child: _shimmerBox(height: 14)),
              const SizedBox(width: 8),
              _shimmerBox(width: 60, height: 22, radius: 12),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),
          _shimmerBox(height: 11, width: 180),
          const SizedBox(height: 10),
          Row(
            children: [
              _shimmerBox(width: 70, height: 36, radius: 10),
              const SizedBox(width: 8),
              _shimmerBox(width: 80, height: 36, radius: 10),
              const SizedBox(width: 8),
              _shimmerBox(width: 65, height: 36, radius: 10),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _shimmerBox(width: 100, height: 28, radius: 8),
              const Spacer(),
              _shimmerBox(width: 70, height: 36, radius: 8),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),
          Row(
            children: [
              _shimmerBox(width: 70, height: 28, radius: 8),
              const SizedBox(width: 6),
              _shimmerBox(width: 60, height: 28, radius: 8),
              const SizedBox(width: 6),
              _shimmerBox(width: 65, height: 28, radius: 8),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (_) => _shimmerCard()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CRITICAL STOCK LEVEL DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _CriticalStockDialog extends StatefulWidget {
  final InvProduct product;
  final InventoryV2ViewModel vm;
  const _CriticalStockDialog({required this.product, required this.vm});

  @override
  State<_CriticalStockDialog> createState() => _CriticalStockDialogState();
}

class _CriticalStockDialogState extends State<_CriticalStockDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.product.criticalStock}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _increment() {
    final v = int.tryParse(_ctrl.text.trim()) ?? 0;
    _ctrl.text = '${v + 1}';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  void _decrement() {
    final v = int.tryParse(_ctrl.text.trim()) ?? 0;
    if (v > 0) {
      _ctrl.text = '${v - 1}';
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.product;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.ownerInventoryCriticalStockLevel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  _DialogCloseBtn(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Product card ─────────────────────────────────────────
              _ProductInfoCard(
                label: 'PRODUCT',
                name: p.name,
                currentStock: p.currentStock,
                openingStock: p.openingStock,
                unit: p.unit,
              ),
              const SizedBox(height: 20),

              // ── Explanation text ─────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'When '),
                    TextSpan(
                      text: 'current stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const TextSpan(
                        text: ' is at or below this number (and the value is greater'
                            ' than 0), the product is flagged as '),
                    TextSpan(
                      text: 'low stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const TextSpan(text: '. Use '),
                    TextSpan(
                      text: '0',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const TextSpan(
                        text: ' to turn off the threshold for this branch.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Label ────────────────────────────────────────────────
              Text(
                'CRITICAL STOCK POINT (THIS BRANCH)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // ── Stepper input ────────────────────────────────────────
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryLight,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryLight, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryLight, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryLight, width: 1.8),
                  ),
                  suffixIcon: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepperArrow(
                          icon: Icons.keyboard_arrow_up_rounded,
                          onTap: _increment),
                      _StepperArrow(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onTap: _decrement),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Action buttons ───────────────────────────────────────
              OwnerSheetActions(
                onCancel: () => Navigator.pop(context),
                onPrimary: () async {
                  final v = int.tryParse(_ctrl.text.trim());
                  if (v == null) return;
                  // Optimistic local update
                  widget.vm.setCriticalStock(
                    p.id,
                    v,
                    branchId: p.branchId,
                  );
                  Navigator.pop(context);
                  // Real API call in background
                  final ok = await widget.vm.saveCriticalStock(
                    p.id,
                    v,
                    branchId: p.branchId,
                  );
                  if (context.mounted) {
                    if (ok) {
                      ToastService.showSuccess(
                          context, 'Critical level updated to $v');
                    } else {
                      ToastService.showError(context,
                          'Failed to save critical level. Please try again.');
                    }
                  }
                },
                primaryLabel: 'Save',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MANUAL INVENTORY ADJUSTMENT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _ManualAdjustDialog extends StatefulWidget {
  final InvProduct product;
  final InventoryV2ViewModel vm;
  const _ManualAdjustDialog({required this.product, required this.vm});

  @override
  State<_ManualAdjustDialog> createState() => _ManualAdjustDialogState();
}

class _ManualAdjustDialogState extends State<_ManualAdjustDialog> {
  late final TextEditingController _qtyCtrl;
  String? _selectedReason;

  static const _reasons = [
    'Opening qty',
    'Infinite qty',
    'Damaged Stock',
    'Inventory Count Correction',
    'Expired Item',
    'Returns/Exchanges',
    'Other (Manual Entry)',
  ];

  @override
  void initState() {
    super.initState();
    _qtyCtrl =
        TextEditingController(text: '${widget.product.currentStock}');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.product;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.ownerInventoryManualAdjustTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  _DialogCloseBtn(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Product card ─────────────────────────────────────────
              _ProductInfoCard(
                label: 'PRODUCT DETAILS',
                name: p.name,
                currentStock: p.currentStock,
                openingStock: p.openingStock,
                unit: p.unit,
              ),
              const SizedBox(height: 20),

              // ── Description ──────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Sets '),
                    TextSpan(
                      text: 'current stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const TextSpan(
                        text:
                        ' (effective on-hand per branch; not adoption opening).'
                            ' Enter a new total — higher to increase, lower to decrease.'
                            ' Must be ≥ 0. The server checks previousQty matches'
                            ' current stock — refresh if it changed elsewhere.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Reason dropdown ──────────────────────────────────────
              Text(
                'REASON FOR ADJUSTMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _ReasonDropdown(
                value: _selectedReason,
                isOpen: false,
                reasons: _reasons,
                onToggle: () {},
                onSelect: (r) => setState(() {
                  _selectedReason = r.isEmpty ? null : r;
                }),
              ),
              const SizedBox(height: 16),

              // ── New quantity ─────────────────────────────────────────
              Text(
                'NEW QUANTITY (CURRENT STOCK)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryLight,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryLight, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Buttons ──────────────────────────────────────────────
              OwnerSheetActions(
                onCancel: () => Navigator.pop(context),
                onPrimary: () async {
                  if (_selectedReason == null) return;
                  final v = int.tryParse(_qtyCtrl.text.trim());
                  if (v == null || v < 0) return;
                  final previousQty = p.currentStock;
                  // Optimistic local update
                  widget.vm.manualAdjust(
                    p.id,
                    v,
                    branchId: p.branchId,
                  );
                  Navigator.pop(context);
                  // Real API call
                  final ok = await widget.vm.submitManualAdjustment(
                    productId: p.id,
                    previousQty: previousQty,
                    newQty: v,
                    reason: _selectedReason!,
                    branchId: p.branchId,
                  );
                  if (context.mounted) {
                    if (ok) {
                      ToastService.showSuccess(context,
                          'Stock adjusted to $v (${_selectedReason!})');
                    } else {
                      // Revert local change on failure
                      widget.vm.manualAdjust(
                        p.id,
                        previousQty,
                        branchId: p.branchId,
                      );
                      ToastService.showError(context,
                          'Adjustment failed. Stock has been reverted.');
                    }
                  }
                },
                primaryLabel: l10n.ownerInventoryApplyAdjustment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT UOM & CONVERSION DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _EditUomConversionDialog extends StatefulWidget {
  final InvProduct product;
  const _EditUomConversionDialog({required this.product});

  @override
  State<_EditUomConversionDialog> createState() =>
      _EditUomConversionDialogState();
}

class _EditUomConversionDialogState extends State<_EditUomConversionDialog> {
  // Warehouse UOM options
  static const _warehouseUnits = [
    'pcs', 'Box', 'Carton', 'Dozen', 'Pack', 'Drum', 'Bag', 'liter',
  ];
  // Workshop UOM options
  static const _workshopUnits = [
    'pcs', 'Liter', 'liter', 'kg', 'ml', 'Set', 'piece',
  ];

  late String _warehouseUom;
  late String _workshopUom;
  late final TextEditingController _factorCtrl;

  bool _warehouseOpen = false;
  bool _workshopOpen = false;

  @override
  void initState() {
    super.initState();
    _warehouseUom = widget.product.warehouseUnit.isNotEmpty
        ? widget.product.warehouseUnit
        : 'pcs';
    _workshopUom = widget.product.unit.isNotEmpty ? widget.product.unit : 'pcs';
    _factorCtrl = TextEditingController(
        text: '${widget.product.conversionFactor > 0 ? widget.product.conversionFactor.toInt() : 1}');
  }

  @override
  void dispose() {
    _factorCtrl.dispose();
    super.dispose();
  }

  String get _conversionRule {
    final factor = int.tryParse(_factorCtrl.text.trim()) ?? 1;
    if (_warehouseUom == _workshopUom || factor <= 1) return _warehouseUom;
    return '1 $_warehouseUom = $factor $_workshopUom';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      // Close any open dropdown when tapping outside
      onTap: () {
        if (_warehouseOpen || _workshopOpen) {
          setState(() {
            _warehouseOpen = false;
            _workshopOpen = false;
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit UOM & conversion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                    _DialogCloseBtn(onTap: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Product info card ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedApiText(
                        p.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LocalizedApiText(
                        '${p.sku.isNotEmpty ? '${p.sku} · ' : ''}${p.department} · ${p.currentStock} pcs on hand',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Warning banner ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              height: 1.45,
                            ),
                            children: [
                              const TextSpan(
                                  text:
                                  'Stock quantity is not changed — only how units are labeled and converted'
                                      ' (e.g. Box vs Liter). Use '),
                              const TextSpan(
                                text: 'Manual Adjust',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              const TextSpan(text: ' to change quantities.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── UOM row ────────────────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Warehouse UOM
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WAREHOUSE UOM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _warehouseOpen = !_warehouseOpen;
                                  _workshopOpen = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _warehouseOpen
                                          ? AppColors.primaryLight
                                          : Colors.grey.shade300,
                                      width: _warehouseOpen ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _warehouseUom,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondaryLight,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          color: Colors.grey.shade500,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Purchase / bulk unit',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11)),
                            ],
                          ),
                        ),

                        // Equals sign + factor
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Text(
                                '1 =',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 52,
                                child: TextField(
                                  controller: _factorCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondaryLight,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 10),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: AppColors.primaryLight, width: 1.8),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),

                        // Workshop UOM
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORKSHOP UOM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _workshopOpen = !_workshopOpen;
                                  _warehouseOpen = false;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _workshopOpen
                                          ? AppColors.primaryLight
                                          : Colors.grey.shade300,
                                      width: _workshopOpen ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _workshopUom,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondaryLight,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          color: Colors.grey.shade500,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Inventory & sales unit',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Warehouse dropdown overlay ──────────────────────
                    if (_warehouseOpen)
                      Positioned(
                        top: 66,
                        left: 0,
                        child: _UomDropdownOverlay(
                          units: _warehouseUnits,
                          selected: _warehouseUom,
                          onSelect: (u) => setState(() {
                            _warehouseUom = u;
                            _warehouseOpen = false;
                          }),
                        ),
                      ),

                    // ── Workshop dropdown overlay ───────────────────────
                    if (_workshopOpen)
                      Positioned(
                        top: 66,
                        right: 0,
                        child: _UomDropdownOverlay(
                          units: _workshopUnits,
                          selected: _workshopUom,
                          onSelect: (u) => setState(() {
                            _workshopUom = u;
                            _workshopOpen = false;
                          }),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Conversion rule ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONVERSION RULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _conversionRule,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Divider ────────────────────────────────────────────
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),

                // ── Action buttons ─────────────────────────────────────
                OwnerSheetActions(
                  onCancel: () => Navigator.pop(context),
                  onPrimary: () async {
                    final factor =
                        int.tryParse(_factorCtrl.text.trim()) ?? 1;
                    final vm = context.read<InventoryV2ViewModel>();
                    // Optimistic local update
                    vm.bulkSetUom(
                      productIds: [p.id],
                      warehouseUnit: _warehouseUom,
                      workshopUnit: _workshopUom,
                      factor: factor,
                    );
                    Navigator.pop(context);
                    // Real API call
                    final ok = await vm.saveBranchProductUom(
                      context: context,
                      productId: p.id,
                      warehouseUnit: _warehouseUom,
                      workshopUnit: _workshopUom,
                      conversionFactor: factor,
                    );
                    if (context.mounted) {
                      if (ok) {
                        ToastService.showSuccess(context,
                            'UOM rule saved: 1 $_warehouseUom = $factor $_workshopUom');
                      } else {
                        ToastService.showError(context,
                            'Failed to save UOM rule. Please try again.');
                      }
                    }
                  },
                  primaryLabel: 'Save rule',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SHARED DIALOG SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Rounded X close button used by all three dialogs
class _DialogCloseBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DialogCloseBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600),
      ),
    );
  }
}

/// Grey product info card shown at the top of Critical + Manual Adjust dialogs
class _ProductInfoCard extends StatelessWidget {
  final String label;
  final String name;
  final int currentStock;
  final int openingStock;
  final String unit;
  const _ProductInfoCard({
    required this.label,
    required this.name,
    required this.currentStock,
    required this.openingStock,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitLabel =
        unit.isNotEmpty ? ownerLocalizedUnit(l10n, unit) : '';
    final stockLine = unit.isNotEmpty
        ? l10n.ownerInventoryCurrentOpening(
            ownerLocalizeDigits(context, '$currentStock'),
            unitLabel,
            ownerLocalizeDigits(context, '$openingStock'),
          )
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          LocalizedApiText(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          if (stockLine != null)
            Text(
              stockLine,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            )
          else
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                children: [
                  const TextSpan(text: 'Current stock: '),
                  TextSpan(
                    text: ownerLocalizeDigits(context, '$currentStock'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' · Opening (adoption): '),
                  TextSpan(
                    text: ownerLocalizeDigits(context, '$openingStock'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Up / Down arrow for the stepper input in Critical Stock dialog
class _StepperArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Icon(icon, size: 18, color: Colors.grey.shade500),
      ),
    );
  }
}

/// Reason selector — uses showMenu so the list renders outside the Dialog's
/// clip boundary and never gets cut off.
class _ReasonDropdown extends StatelessWidget {
  final String? value;
  final bool isOpen;
  final List<String> reasons;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _ReasonDropdown({
    required this.value,
    required this.isOpen,
    required this.reasons,
    required this.onToggle,
    required this.onSelect,
  });

  Future<void> _openMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    // Build items: placeholder + all reasons
    final allItems = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: '',
        child: Row(
          children: [
            if (value == null || value!.isEmpty)
              const Icon(Icons.check, size: 16, color: AppColors.secondaryLight)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            const Text('Select a reason...',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryLight)),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      ...reasons.map((r) => PopupMenuItem<String>(
        value: r,
        child: Row(
          children: [
            if (value == r)
              const Icon(Icons.check,
                  size: 16, color: AppColors.secondaryLight)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Text(r,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryLight,
                  fontWeight:
                  value == r ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      )),
    ];

    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      items: allItems,
    );

    if (selected != null) onSelect(selected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (value != null && value!.isNotEmpty)
                ? AppColors.primaryLight
                : Colors.grey.shade200,
            width: (value != null && value!.isNotEmpty) ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                (value != null && value!.isNotEmpty)
                    ? value!
                    : 'Select a reason...',
                style: TextStyle(
                  fontSize: 14,
                  color: (value != null && value!.isNotEmpty)
                      ? AppColors.secondaryLight
                      : Colors.grey.shade500,
                  fontWeight: (value != null && value!.isNotEmpty)
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}


/// Overlay dropdown for UOM selection in Edit UOM dialog
class _UomDropdownOverlay extends StatelessWidget {
  final List<String> units;
  final String selected;
  final ValueChanged<String> onSelect;
  const _UomDropdownOverlay(
      {required this.units,
        required this.selected,
        required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade50,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180, maxHeight: 260),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          children: units
              .map((u) => InkWell(
            onTap: () => onSelect(u),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (u == selected) ...[
                    const Icon(Icons.check,
                        size: 15,
                        color: AppColors.secondaryLight),
                    const SizedBox(width: 8),
                  ] else
                    const SizedBox(width: 23),
                  Text(
                    u,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryLight,
                      fontWeight: u == selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }
}
