import 'package:flutter/material.dart';

import '../../../data/network/api_response.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../Reports/reports_search_bar.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../widgets/owner_sheet_actions.dart';
import 'branch_catalog_shared.dart';
import 'branch_catalog_view_model.dart';
import 'catalog_shimmer.dart';

// ─── Products Tab ─────────────────────────────────────────────────────────────

class CatalogProductsTab extends StatefulWidget {
  final BranchCatalogViewModel vm;
  const CatalogProductsTab({super.key, required this.vm});

  static void showCreateSheet(
      BuildContext context, BranchCatalogViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateProductSheet(vm: vm),
    );
  }

  @override
  State<CatalogProductsTab> createState() => _CatalogProductsTabState();
}

class _CatalogProductsTabState extends State<CatalogProductsTab> {
  static const int _pageSize = 20;
  int _loadedCount = _pageSize;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  BranchCatalogViewModel get vm => widget.vm;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CatalogProductsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when branch or dept filter changes
    if (oldWidget.vm.selectedBranchId != vm.selectedBranchId ||
        oldWidget.vm.productDeptFilter != vm.productDeptFilter) {
      _loadedCount = _pageSize;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final total = _visibleProducts().length;
      if (_loadedCount < total) {
        setState(() {
          _loadedCount = (_loadedCount + _pageSize).clamp(0, total);
        });
      }
    }
  }

  List<CatalogProductModel> _visibleProducts() {
    final all = vm.filteredProducts;
    if (_searchQuery.isEmpty) return all;
    return all
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery) ||
            (p.sku.toLowerCase().contains(_searchQuery)))
        .toList();
  }

  Future<void> _onRefresh() async {
    setState(() => _loadedCount = _pageSize);
    await vm.refresh();
  }

  Future<void> _removeFromBranch(
      BuildContext context, CatalogProductModel product) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Remove Product',
      message:
          'Remove this product from this branch only?',
      confirmLabel: 'Remove',
    );
    if (confirmed && context.mounted) {
      final ok = await vm.removeProductFromBranch(context, product.id);
      if (!context.mounted) return;
      if (ok) {
        ToastService.showSuccess(context, 'Product removed from branch');
      } else {
        ToastService.showError(
            context, vm.error ?? 'Failed to remove product');
      }
    }
  }

  /// All-branches scope — same as admin web "Remove from workshop".
  Future<void> _removeFromWorkshop(
      BuildContext context, CatalogProductModel product) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Remove from Workshop',
      message:
          'Remove this product from all branches in this workshop?',
      confirmLabel: 'Remove from workshop',
    );
    if (!confirmed || !context.mounted) return;

    final (wasRemoved, blockReason) =
        await vm.removeWorkshopProduct(context, product.id);

    if (!context.mounted) return;
    if (wasRemoved) {
      ToastService.showSuccess(context, 'Product removed from workshop');
    } else {
      ToastService.showError(
        context,
        'Cannot remove: ${blockReason ?? vm.error ?? "Unknown reason"}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = vm.productsState;
    final depts = vm.departmentsState.data ?? [];

    if (state.status == Status.loading) {
      return const CatalogListLoadingShimmer(showDeptDropdown: true);
    }

    if (state.status == Status.error) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Text(
                state.message ?? 'Failed to load products',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Pull down to retry',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final isSpecificBranch = !vm.isAllBranches;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: ReportsSearchBar(
                  hint: l10n.ownerCatalogSearchProducts,
                  onChanged: (v) => setState(() {
                    _searchQuery = v.trim().toLowerCase();
                    _loadedCount = _pageSize;
                  }),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: CatalogDeptFilterDropdown(
                    departments: depts,
                    selectedId: vm.productDeptFilter,
                    onChanged: (v) {
                      vm.setProductDeptFilter(v);
                      setState(() => _loadedCount = _pageSize);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList(context, isSpecificBranch)),
      ],
    );
  }

  Widget _buildList(BuildContext context, bool isSpecificBranch) {
    final products = _visibleProducts();

    if (products.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            buildCatalogEmptyState(_searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No products found'),
          ],
        ),
      );
    }

    final pageSlice = products.take(_loadedCount).toList();
    final hasMore = _loadedCount < products.length;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: pageSlice.length + (hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          // Loading indicator at bottom when more items remain
          if (i == pageSlice.length) {
            return const CatalogPaginationShimmer();
          }
          final product = pageSlice[i];
          return _ProductCard(
            key: ValueKey(product.id),
            product: product,
            isSpecificBranch: isSpecificBranch,
            onRemove: () => isSpecificBranch
                ? _removeFromBranch(ctx, product)
                : _removeFromWorkshop(ctx, product),
          );
        },
      ),
    );
  }

  Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            disabledBackgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.secondaryLight,
                            disabledForegroundColor: AppColors.secondaryLight,
                            minimumSize: const Size.fromHeight(56),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }
}

// ─── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final CatalogProductModel product;
  final bool isSpecificBranch;
  final VoidCallback onRemove;

  const _ProductCard({
    super.key,
    required this.product,
    required this.isSpecificBranch,
    required this.onRemove,
  });

  static const _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFEEEEEE))),
  );
  static const _iconDecoration = BoxDecoration(
    color: AppColors.secondaryLight,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const _nameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.secondaryLight,
  );
  static const _metaStyle = TextStyle(
    color: Color(0xFF9E9E9E),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = product;
    final qtyStr = ownerLocalizeDigits(
      context,
      p.currentQty.toStringAsFixed(p.allowDecimalQty ? 2 : 0),
    );
    final priceQtyLine =
        '${ownerFormatMoney(context, p.salePrice)} · ${l10n.ownerCommonQty}: $qtyStr ${ownerLocalizedUnit(l10n, p.unit)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const DecoratedBox(
                      decoration: _iconDecoration,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.inventory_2_rounded,
                            color: AppColors.primaryLight, size: 22),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: CatalogActiveDot(isActive: p.isActive),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LocalizedApiText(
                            p.name,
                            style: _nameStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.isLowStock) ...[
                          const SizedBox(width: 6),
                          const _LowBadge(),
                        ],
                      ],
                    ),
                    if (p.sku.isNotEmpty || p.brandName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (p.sku.isNotEmpty) p.sku,
                          if (p.brandName.isNotEmpty) p.brandName,
                        ].join(' · '),
                        style: _metaStyle,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined,
                            size: 13, color: Color(0xFFBDBDBD)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: LocalizedApiText(
                                  p.departmentName,
                                  style: _metaStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(' › ', style: _metaStyle),
                              Flexible(
                                child: LocalizedApiText(
                                  p.categoryName,
                                  style: _metaStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceQtyLine,
                      style: _metaStyle,
                    ),
                    if (p.branchDisplayName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFFBDBDBD)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              p.branchDisplayName,
                              style: _metaStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              buildCatalogRemoveButton(
                isSpecificBranch ? 'Remove' : 'Remove from workshop',
                onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowBadge extends StatelessWidget {
  const _LowBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: const BoxDecoration(
          color: Color(0x1FFB8C00),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: const Text('LOW',
            style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );
}

// ─── Request Product Sheet ─────────────────────────────────────────────────────

class CreateProductSheet extends StatefulWidget {
  final BranchCatalogViewModel vm;
  const CreateProductSheet({super.key, required this.vm});

  @override
  State<CreateProductSheet> createState() => _CreateProductSheetState();
}

class _CreateProductSheetState extends State<CreateProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _arabicNameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController(text: '0.00');
  final _notesCtrl = TextEditingController();

  String? _selectedUnit;
  String? _selectedMasterDeptId;
  String? _selectedMasterCategoryId;
  List<MasterCategoryItem> _masterCategories = const [];
  bool _loadingCategories = false;
  bool _isSubmitting = false;

  // Cached dropdown item lists — rebuilt lazily when source data changes
  List<OwnerDropdownOption<String>>? _unitItems;
  List<OwnerDropdownOption<String>>? _deptItems;
  List<OwnerDropdownOption<String>>? _categoryItems;

  // Track last-seen list lengths to detect when API data arrives post-open
  int _lastUnitCount = -1;
  int _lastDeptCount = -1;

  @override
  void initState() {
    super.initState();
    _rebuildUnitItems();
    _rebuildDeptItems();
  }

  // ── Unit items ────────────────────────────────────────────────────────────
  // FIX: Pehle initState mein ek baar banate the. Agar sheet tab open ho jab
  // units abhi load ho rahi hoon to dropdown khali rehta tha.
  // Ab didUpdateWidget mein check karte hain — naye units aate hi rebuild.
  void _rebuildUnitItems() {
    final units = widget.vm.productUnits;
    _unitItems = units
        .map((u) => OwnerDropdownOption(value: u, label: u))
        .toList();
    // Default unit set karo agar abhi kuch select nahi hua
    if (_selectedUnit == null && units.isNotEmpty) {
      _selectedUnit = widget.vm.defaultProductUnit;
    }
    _lastUnitCount = units.length;
  }

  // ── Dept items ────────────────────────────────────────────────────────────
  void _rebuildDeptItems() {
    final depts = widget.vm.masterDepartmentsState.data?.departments ?? [];
    _deptItems = depts
        .map((d) => OwnerDropdownOption(value: d.id, label: d.name))
        .toList();
    _lastDeptCount = depts.length;
  }

  @override
  void didUpdateWidget(CreateProductSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // FIX: Jab vm notify kare aur units ya depts count badal jaaye to
    // cached items rebuild karo — no full setState, sirf targeted update.
    final currentUnitCount = widget.vm.productUnits.length;
    final currentDeptCount =
        widget.vm.masterDepartmentsState.data?.departments.length ?? 0;

    if (currentUnitCount != _lastUnitCount ||
        currentDeptCount != _lastDeptCount) {
      setState(() {
        if (currentUnitCount != _lastUnitCount) _rebuildUnitItems();
        if (currentDeptCount != _lastDeptCount) _rebuildDeptItems();
      });
    }
  }

  void _buildCategoryItems() {
    _categoryItems = _masterCategories
        .map((c) => OwnerDropdownOption(value: c.id, label: c.name))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _arabicNameCtrl.dispose();
    _brandCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _salePriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _onDeptChanged(String? deptId) async {
    setState(() {
      _selectedMasterDeptId = deptId;
      _selectedMasterCategoryId = null;
      _masterCategories = const [];
      _categoryItems = const [];
      _loadingCategories = deptId != null;
    });
    if (deptId == null) return;
    final cats =
        await widget.vm.fetchMasterCategories(deptId, type: 'product');
    if (!mounted) return;
    _masterCategories = cats;
    _buildCategoryItems();
    setState(() => _loadingCategories = false);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedMasterDeptId == null) {
      _showSnack('Please select a department');
      return;
    }
    if (_selectedMasterCategoryId == null) {
      _showSnack('Please select a category');
      return;
    }
    if (_selectedUnit == null) {
      _showSnack('Please select a unit');
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.vm.submitProductRequest(
      context,
      name: _nameCtrl.text.trim(),
      brandName: _brandCtrl.text.trim(),
      unit: _selectedUnit!,
      salePriceInclusiveVat: double.tryParse(_salePriceCtrl.text) ?? 0,
      masterDepartmentId: _selectedMasterDeptId!,
      masterCategoryId: _selectedMasterCategoryId!,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result != null && result.success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Product request "${_nameCtrl.text.trim()}" submitted')));
    } else {
      _showSnack(widget.vm.error ?? 'Failed to submit product request');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin:
          EdgeInsets.only(top: MediaQuery.sizeOf(context).height * 0.08),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Request Product',
                    style: AppTextStyles.h2.copyWith(
                        fontSize: 18, color: AppColors.secondaryLight),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Form ──────────────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding:
                    EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 24),
                children: [
                  // Info note
                  const _InfoNote(),
                  const SizedBox(height: 16),

                  // NAME *
                  const _FieldLabel('NAME *'),
                  _SvcField(
                    controller: _nameCtrl,
                    hint: '',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // ARABIC NAME
                  const _FieldLabel('ARABIC NAME'),
                  _SvcField(
                    controller: _arabicNameCtrl,
                    hint: 'الاسم بالعربية',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 14),

                  // BRAND NAME
                  const _FieldLabel('BRAND NAME'),
                  _SvcField(controller: _brandCtrl, hint: ''),
                  const SizedBox(height: 14),

                  // SKU + UNIT *
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('SKU'),
                            _SvcField(
                                controller: _skuCtrl, hint: 'Optional'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('UNIT *'),
                            // FIX: Units API se aati hain — agar abhi load ho
                            // rahi hain to loading indicator dikhao
                            widget.vm.productUnitsState.status ==
                                    Status.loading
                                ? const _CategoryLoadingBox()
                                : _SvcDropdown<String>(
                                    value: _selectedUnit,
                                    hint: 'Select unit',
                                    options: _unitItems ?? const [],
                                    onChanged: (v) =>
                                        setState(() => _selectedUnit = v),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // DESCRIPTION
                  const _FieldLabel('DESCRIPTION'),
                  _SvcField(
                    controller: _descCtrl,
                    hint: 'Product description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),

                  // SALES PRICE (half width)
                  const _FieldLabel('SALES PRICE INCLUSIVE VAT (EXPECTED) *'),
                  _HalfWidthField(
                    child: _SvcField(
                      controller: _salePriceCtrl,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // NOTES
                  const _FieldLabel('NOTES'),
                  _SvcField(
                    controller: _notesCtrl,
                    hint: 'Internal notes for approvers',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),

                  // DEPARTMENT (MASTER) *
                  const _FieldLabel('DEPARTMENT (MASTER) *'),
                  // FIX: Depts API se aate hain — loading state handle kiya
                  widget.vm.masterDepartmentsState.status == Status.loading
                      ? const _CategoryLoadingBox()
                      : _SvcDropdown<String>(
                          value: _selectedMasterDeptId,
                          hint: 'Select department',
                          options: _deptItems ?? const [],
                          onChanged: _onDeptChanged,
                        ),
                  const SizedBox(height: 14),

                  // CATEGORY (MASTER) *
                  const _FieldLabel('CATEGORY (MASTER) *'),
                  if (_loadingCategories)
                    const _CategoryLoadingBox()
                  else
                    _SvcDropdown<String>(
                      value: _selectedMasterCategoryId,
                      hint: _selectedMasterDeptId == null
                          ? 'Select a department first'
                          : 'Select category',
                      options: _categoryItems ?? const [],
                      onChanged: _selectedMasterDeptId == null
                          ? null
                          : (v) =>
                              setState(() => _selectedMasterCategoryId = v),
                    ),
                  const SizedBox(height: 28),

                  // Buttons
                  OwnerSheetActions(
                    onCancel: () => Navigator.pop(context),
                    onPrimary: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small const widgets ──────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  const _InfoNote();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBDEFB)),
        ),
        child: const Text(
          'Request adds a row to the master catalog queue (super-admin). '
          'Departments and categories are loaded from the global master catalog.',
          style: TextStyle(
              color: Color(0xFF1565C0), fontSize: 12, height: 1.4),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9E9E9E),
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _CategoryLoadingBox extends StatelessWidget {
  const _CategoryLoadingBox();
  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _HalfWidthField extends StatelessWidget {
  final Widget child;
  const _HalfWidthField({required this.child});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: MediaQuery.sizeOf(context).width / 2 - 26, child: child);
}

// ─── Reusable sheet sub-widgets ───────────────────────────────────────────────

class _SvcLabel extends StatelessWidget {
  final String text;
  const _SvcLabel(this.text);
  @override
  Widget build(BuildContext context) => _FieldLabel(text);
}

class _SvcField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextDirection? textDirection;
  final TextAlign textAlign;

  const _SvcField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.textDirection,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textDirection: textDirection,
      textAlign: textAlign,
      style: const TextStyle(
          fontSize: 15,
          color: AppColors.secondaryLight,
          fontWeight: FontWeight.w500),
      decoration: CustomTextField.decoration(hint: hint.isEmpty ? null : hint),
    );
  }
}

class _SvcDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<OwnerDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;

  const _SvcDropdown({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OwnerStyledDropdown<T>(
      value: value,
      hint: hint,
      options: options,
      onChanged: onChanged,
      enabled: onChanged != null,
      height: 48,
      menuMaxHeight: 260,
      triggerStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onChanged == null
            ? Colors.grey.shade400
            : AppColors.secondaryLight,
      ),
    );
  }
}
