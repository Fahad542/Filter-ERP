// ─── master_catalog_products_tab.dart ────────────────────────────────────────
// Products tab — unchanged UI, real API data via ViewModel.
// Virtual scroll: renders _pageSize items, loads more on scroll end.

import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_list_style.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'master_catalog_shared.dart';
import 'master_catalog_view_model.dart';
import 'master_catalog_add_to_branches_sheet.dart';
import '../widgets/owner_shimmer.dart';

class MasterCatalogProductsTab extends StatefulWidget {
  const MasterCatalogProductsTab({super.key});

  @override
  State<MasterCatalogProductsTab> createState() =>
      _MasterCatalogProductsTabState();
}

class _MasterCatalogProductsTabState extends State<MasterCatalogProductsTab> {
  static const int _pageSize = 20;
  int _loadedCount = _pageSize;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;
  String _searchQuery = '';
  bool _showAdded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final vm = context.read<MasterCatalogViewModel>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      final all = _applyFilters(vm.filteredProducts);
      if (_loadedCount < all.length) {
        setState(() {
          _isLoadingMore = true;
          _loadedCount = (_loadedCount + _pageSize).clamp(0, all.length);
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  List<MasterProduct> _applyFilters(List<MasterProduct> list) {
    list = list
        .where((p) => _showAdded
            ? p.isAddedToCurrentBranch
            : !p.isAddedToCurrentBranch)
        .toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.sku.toLowerCase().contains(_searchQuery) ||
              p.brandName.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  Future<void> _openAddSheet(MasterCatalogViewModel vm) async {
    if (vm.selectedProductIds.isEmpty) return;
    // Fetch missing dependencies so the sheet can show the yellow banner
    await vm.previewProductDeps();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: AddToBranchesSheet(
          type: AddSheetType.products,
          selectedIds: vm.selectedProductIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MasterCatalogViewModel>(
      builder: (context, vm, _) {
        // ── Still loading phase 2 ─────────────────────────────────────────
        if (vm.isLoadingProducts) {
          return const OwnerListPageShimmer(showSearch: false, itemCount: 8);
        }

        final allProducts = vm.filteredProducts;
        final filteredList = _applyFilters(allProducts);
        final displayList = filteredList.take(_loadedCount).toList();
        final selectedCount = vm.selectedProductIds.length;

        final notAddedCount = allProducts.where((p) => !p.isAddedToCurrentBranch).length;
        final addedCount = allProducts.where((p) => p.isAddedToCurrentBranch).length;

        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          body: Column(
            children: [
              // ── Toggle ────────────────────────────────────────────────
              MCAddedToggle(
                showAdded: _showAdded,
                notAddedCount: notAddedCount,
                addedCount: addedCount,
                onToggle: (v) => setState(() {
                  _showAdded = v;
                  _loadedCount = _pageSize;
                  vm.clearProductSelections();
                }),
              ),

              // ── Search + Dept filter ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {
                          _searchQuery = v.trim().toLowerCase();
                          _loadedCount = _pageSize;
                        }),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.secondaryLight),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.ownerCatalogSearchProducts,
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade400, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: Colors.grey.shade400, size: 16),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primaryLight, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 88,
                      height: 44,
                      child: MCDeptDropdown(
                        departments: vm.departments,
                        selectedId: vm.productDeptFilter,
                        onChanged: (v) {
                          vm.setProductDeptFilter(v);
                          setState(() => _loadedCount = _pageSize);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // ── Result Banner ─────────────────────────────────────────
              if (vm.lastResult != null)
                MCResultBanner(result: vm.lastResult!),

              // ── Selection Bar ─────────────────────────────────────────
              if (!_showAdded)
                MCSelectionBar(
                  count: selectedCount,
                  onSelectAll: () {
                    for (final p in filteredList) {
                      if (!vm.selectedProductIds.contains(p.id)) {
                        vm.toggleProduct(p.id);
                      }
                    }
                  },
                  onClear: vm.clearProductSelections,
                  onAddToBranches: () => _openAddSheet(vm),
                ),

              // ── List ──────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryLight,
                  onRefresh: () async {
                    setState(() => _loadedCount = _pageSize);
                    await vm.refresh();
                  },
                  child: displayList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.22),
                            buildMCEmptyState(_searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery"'
                                : _showAdded
                                    ? 'No products added yet'
                                    : 'No products found'),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount:
                              displayList.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == displayList.length) {
                              return const OwnerPaginationShimmer();
                            }
                            final product = displayList[i];
                            final isSelected =
                                vm.selectedProductIds.contains(product.id);
                            return _ProductCard(
                              product: product,
                              isSelected: isSelected,
                              showAdded: _showAdded,
                              onTap: _showAdded
                                  ? null
                                  : () => vm.toggleProduct(product.id),
                              onAddTap: () {
                                vm.toggleProduct(product.id);
                                _openAddSheet(vm);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Product Card (Manage Inventory list style) ───────────────────────────────

class _ProductCard extends StatelessWidget {
  final MasterProduct product;
  final bool isSelected;
  final bool showAdded;
  final VoidCallback? onTap;
  final VoidCallback onAddTap;

  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.showAdded,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = product.isAddedToCurrentBranch;
    final deptCat = [
      if (product.departmentName.isNotEmpty) product.departmentName,
      if (product.categoryName.isNotEmpty) product.categoryName,
    ].join(' · ');

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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OwnerListIconBox(
                    icon: Icons.inventory_2_rounded,
                    showActiveDot: product.isActive && isAdded,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!showAdded) ...[
                              const SizedBox(width: 6),
                              MCListSelectCheck(
                                isSelected: isSelected,
                                onTap: onTap,
                              ),
                            ],
                          ],
                        ),
                        if (product.sku.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.sku,
                            style: OwnerListStyle.subtitleStyle
                                .copyWith(fontSize: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          product.salePrice > 0
                              ? ownerFormatMoney(context, product.salePrice)
                              : AppLocalizations.of(context)!.ownerCommonFree,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        const SizedBox(height: 5),
                        MCListMetaLine(
                          icon: Icons.category_outlined,
                          text: deptCat,
                        ),
                        if (product.brandName.isNotEmpty)
                          MCListMetaLine(
                            icon: Icons.sell_outlined,
                            text: product.brandName,
                          ),
                        if (product.unit.isNotEmpty)
                          MCListMetaLine(
                            icon: Icons.straighten_rounded,
                            text: ownerLocalizedUnit(
                              AppLocalizations.of(context)!,
                              product.unit,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isAdded && !isSelected)
                              buildAddedBadge()
                            else
                              MCListActionChip(
                                label: AppLocalizations.of(context)!.ownerCatalogAdd,
                                primary: true,
                                onTap: onAddTap,
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
            ),
          ),
        ),
      ),
    );
  }
}
