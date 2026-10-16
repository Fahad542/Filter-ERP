// ─── master_catalog_categories_tab.dart ──────────────────────────────────────
// Categories tab — list UI matching Manage Inventory.

import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_list_style.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import 'master_catalog_shared.dart';
import 'master_catalog_view_model.dart';
import 'master_catalog_add_to_branches_sheet.dart';

class MasterCatalogCategoriesTab extends StatefulWidget {
  const MasterCatalogCategoriesTab({super.key});

  @override
  State<MasterCatalogCategoriesTab> createState() =>
      _MasterCatalogCategoriesTabState();
}

class _MasterCatalogCategoriesTabState
    extends State<MasterCatalogCategoriesTab> {

  Future<void> _openAddSheet(MasterCatalogViewModel vm) async {
    if (vm.selectedCategoryIds.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: AddToBranchesSheet(
          type: AddSheetType.categories,
          selectedIds: vm.selectedCategoryIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MasterCatalogViewModel>(
      builder: (context, vm, _) {
        final categories = vm.filteredCategories;
        final selectedCount = vm.selectedCategoryIds.length;

        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          body: Column(
            children: [
              MCAddedToggle(
                showAdded: vm.categoryShowAdded,
                notAddedCount: vm.categories
                    .where((c) => !c.isAddedToCurrentBranch)
                    .length,
                addedCount: vm.categories
                    .where((c) => c.isAddedToCurrentBranch)
                    .length,
                onToggle: vm.setCategoryShowAdded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: MCDeptDropdown(
                          departments: vm.departments,
                          selectedId: vm.categoryDeptFilter,
                          onChanged: vm.setCategoryDeptFilter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      height: 44,
                      child: _TypeDropdown(
                        selected: vm.categoryTypeFilter,
                        onChanged: vm.setCategoryTypeFilter,
                      ),
                    ),
                  ],
                ),
              ),

              if (vm.lastResult != null)
                MCResultBanner(result: vm.lastResult!),

              MCSelectionBar(
                count: selectedCount,
                onSelectAll: () {
                  for (final c in categories) {
                    if (!vm.selectedCategoryIds.contains(c.id)) {
                      vm.toggleCategory(c.id);
                    }
                  }
                },
                onClear: vm.clearCategorySelections,
                onAddToBranches: () => _openAddSheet(vm),
              ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryLight,
                  onRefresh: vm.refresh,
                  child: categories.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25),
                            buildMCEmptyState('No categories found'),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: categories.length,
                          itemBuilder: (_, i) => _CategoryCard(
                            cat: categories[i],
                            isSelected: vm.selectedCategoryIds
                                .contains(categories[i].id),
                            onTap: () =>
                                vm.toggleCategory(categories[i].id),
                            onAddTap: () {
                              vm.toggleCategory(categories[i].id);
                              _openAddSheet(vm);
                            },
                          ),
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

// ─── Type Dropdown ────────────────────────────────────────────────────────────

class _TypeDropdown extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _TypeDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.only(left: 8, right: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected ?? 'all',
          isExpanded: true,
          isDense: true,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade500, size: 16),
          onChanged: (v) => onChanged(v == 'all' ? null : v),
          selectedItemBuilder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.ownerCatalogAllTypes,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.ownerCatalogTypeProduct,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.ownerCatalogTypeService,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ];
          },
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(AppLocalizations.of(context)!.ownerCatalogAllTypes),
            ),
            DropdownMenuItem(
              value: 'product',
              child: Text(AppLocalizations.of(context)!.ownerCatalogTypeProduct),
            ),
            DropdownMenuItem(
              value: 'service',
              child: Text(AppLocalizations.of(context)!.ownerCatalogTypeService),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final MasterCategory cat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  const _CategoryCard({
    required this.cat,
    required this.isSelected,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = cat.isAddedToCurrentBranch;

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
                    icon: Icons.folder_rounded,
                    showActiveDot: isAdded,
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
                                cat.name,
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            MCListSelectCheck(
                              isSelected: isSelected,
                              onTap: onTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        MCListMetaLine(
                          icon: Icons.account_tree_outlined,
                          text: cat.departmentName.isNotEmpty
                              ? cat.departmentName
                              : '—',
                        ),
                        MCListMetaLine(
                          icon: Icons.label_outline_rounded,
                          text: cat.type.isNotEmpty
                              ? cat.type[0].toUpperCase() + cat.type.substring(1)
                              : '',
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
