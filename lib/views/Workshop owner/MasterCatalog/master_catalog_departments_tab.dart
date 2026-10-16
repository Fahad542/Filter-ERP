// ─── master_catalog_departments_tab.dart ─────────────────────────────────────
// Departments tab for the Master Catalog screen.
// Grid of selectable department cards with add-to-branches flow.

import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_list_style.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'master_catalog_shared.dart';
import 'master_catalog_view_model.dart';
import 'master_catalog_add_to_branches_sheet.dart';
import '../widgets/owner_shimmer.dart';

class MasterCatalogDepartmentsTab extends StatefulWidget {
  const MasterCatalogDepartmentsTab({super.key});

  @override
  State<MasterCatalogDepartmentsTab> createState() =>
      _MasterCatalogDepartmentsTabState();
}

class _MasterCatalogDepartmentsTabState
    extends State<MasterCatalogDepartmentsTab> {
  // Track which dept ids have a pending toggle in progress
  final Set<String> _loadingDeptIds = {};

  Future<void> _openAddSheet(MasterCatalogViewModel vm) async {
    if (vm.selectedDeptIds.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: AddToBranchesSheet(
          type: AddSheetType.departments,
          selectedIds: vm.selectedDeptIds.toList(),
        ),
      ),
    );
  }

  /// Toggles active/inactive with a per-card loading state so the user
  /// sees a spinner until the async action completes.
  Future<void> _toggleActive(
      MasterCatalogViewModel vm, MasterDepartment dept) async {
    if (_loadingDeptIds.contains(dept.id)) return; // already in-flight
    setState(() => _loadingDeptIds.add(dept.id));
    try {
      await vm.toggleDeptActive(dept.id);
    } finally {
      if (mounted) setState(() => _loadingDeptIds.remove(dept.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MasterCatalogViewModel>(
      builder: (context, vm, _) {
        final departments = vm.filteredDepartments;
        final selectedCount = vm.selectedDeptIds.length;

        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          body: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: vm.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Added / Not-added toggle ─────────────────────────────
                SliverToBoxAdapter(
                  child: MCAddedToggle(
                    showAdded: vm.deptShowAdded,
                    notAddedCount: vm.departments
                        .where((d) => !d.isAddedToCurrentBranch)
                        .length,
                    addedCount: vm.departments
                        .where((d) => d.isAddedToCurrentBranch)
                        .length,
                    onToggle: vm.setDeptShowAdded,
                  ),
                ),
                // ── Result Banner ────────────────────────────────────────
                if (vm.lastResult != null)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        MCResultBanner(result: vm.lastResult!),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                // ── Selection Bar ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: MCSelectionBar(
                    count: selectedCount,
                    onSelectAll: () {
                      for (final d in departments) {
                        if (!vm.selectedDeptIds.contains(d.id)) {
                          vm.toggleDept(d.id);
                        }
                      }
                    },
                    onClear: vm.clearDeptSelections,
                    onAddToBranches: () => _openAddSheet(vm),
                  ),
                ),

                // ── List ──────────────────────────────────────────────────
                if (vm.isLoading && departments.isEmpty)
                  const SliverFillRemaining(
                    child: OwnerListPageShimmer(showSearch: false, itemCount: 8),
                  )
                else if (departments.isEmpty)
                  SliverFillRemaining(
                    child: buildMCEmptyState('No departments found'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _DepartmentCard(
                          dept: departments[i],
                          isSelected:
                              vm.selectedDeptIds.contains(departments[i].id),
                          isToggleLoading:
                              _loadingDeptIds.contains(departments[i].id),
                          onTap: () => vm.toggleDept(departments[i].id),
                          onAddTap: () {
                            vm.toggleDept(departments[i].id);
                            _openAddSheet(vm);
                          },
                          onToggleActive: () =>
                              _toggleActive(vm, departments[i]),
                        ),
                        childCount: departments.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Department Card (Manage Inventory list style) ────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final MasterDepartment dept;
  final bool isSelected;
  final bool isToggleLoading;
  final VoidCallback onTap;
  final VoidCallback onAddTap;
  final VoidCallback onToggleActive;

  const _DepartmentCard({
    required this.dept,
    required this.isSelected,
    required this.isToggleLoading,
    required this.onTap,
    required this.onAddTap,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = dept.isAddedToCurrentBranch;

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
                    icon: Icons.account_tree_rounded,
                    showActiveDot: dept.isActive,
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
                              child: LocalizedApiText(
                                dept.name,
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _ActiveToggle(
                              isActive: dept.isActive,
                              isLoading: isToggleLoading,
                              onTap: onToggleActive,
                            ),
                            const SizedBox(width: 8),
                            MCListSelectCheck(
                              isSelected: isSelected,
                              onTap: onTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        MCListMetaLine(
                          icon: Icons.layers_outlined,
                          text: dept.parentLabel == 'Master Department'
                              ? AppLocalizations.of(context)!
                                  .ownerCatalogMasterDepartment
                              : dept.parentLabel,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isAdded && !isSelected)
                              buildAddedBadge()
                            else
                              MCListActionChip(
                                label: AppLocalizations.of(context)!
                                    .ownerCatalogAdd,
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

// ─── Active Toggle Widget ─────────────────────────────────────────────────────

class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActiveToggle({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 44,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 22,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isActive
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
              isActive ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryLight
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}