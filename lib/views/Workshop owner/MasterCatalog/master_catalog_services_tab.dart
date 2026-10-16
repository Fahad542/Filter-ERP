// ─── master_catalog_services_tab.dart ────────────────────────────────────────
// Services tab — unchanged UI, real API data via ViewModel.

import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_list_style.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'master_catalog_shared.dart';
import 'master_catalog_view_model.dart';
import 'master_catalog_add_to_branches_sheet.dart';
import '../widgets/owner_shimmer.dart';

class MasterCatalogServicesTab extends StatefulWidget {
  const MasterCatalogServicesTab({super.key});

  @override
  State<MasterCatalogServicesTab> createState() =>
      _MasterCatalogServicesTabState();
}

class _MasterCatalogServicesTabState extends State<MasterCatalogServicesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAdded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MasterService> _applyFilters(List<MasterService> list) {
    list = list
        .where((s) => _showAdded
            ? s.isAddedToCurrentBranch
            : !s.isAddedToCurrentBranch)
        .toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery) ||
              s.departmentName.toLowerCase().contains(_searchQuery) ||
              s.categoryName.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  Future<void> _openAddSheet(MasterCatalogViewModel vm) async {
    if (vm.selectedServiceIds.isEmpty) return;
    // Fetch missing dependencies so the sheet can show the yellow banner
    await vm.previewServiceDeps();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: AddToBranchesSheet(
          type: AddSheetType.services,
          selectedIds: vm.selectedServiceIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MasterCatalogViewModel>(
      builder: (context, vm, _) {
        // ── Still loading phase 2 ─────────────────────────────────────────
        if (vm.isLoadingServices) {
          return const OwnerListPageShimmer(showSearch: false, itemCount: 8);
        }

        final allServices = vm.filteredServices;
        final filteredList = _applyFilters(allServices);
        final selectedCount = vm.selectedServiceIds.length;

        final notAddedCount =
            allServices.where((s) => !s.isAddedToCurrentBranch).length;
        final addedCount =
            allServices.where((s) => s.isAddedToCurrentBranch).length;

        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          body: Column(
            children: [
              MCAddedToggle(
                showAdded: _showAdded,
                notAddedCount: notAddedCount,
                addedCount: addedCount,
                onToggle: (v) => setState(() {
                  _showAdded = v;
                  vm.clearServiceSelections();
                }),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim().toLowerCase()),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.secondaryLight),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.ownerCatalogSearchServices,
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
                        selectedId: vm.serviceDeptFilter,
                        onChanged: vm.setServiceDeptFilter,
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.lastResult != null)
                MCResultBanner(result: vm.lastResult!),

              if (!_showAdded)
                MCSelectionBar(
                  count: selectedCount,
                  onSelectAll: () {
                    for (final s in filteredList) {
                      if (!vm.selectedServiceIds.contains(s.id)) {
                        vm.toggleService(s.id);
                      }
                    }
                  },
                  onClear: vm.clearServiceSelections,
                  onAddToBranches: () => _openAddSheet(vm),
                ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryLight,
                  onRefresh: vm.refresh,
                  child: filteredList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.22),
                            buildMCEmptyState(_searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery"'
                                : _showAdded
                                    ? 'No services added yet'
                                    : 'No services found'),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filteredList.length,
                          itemBuilder: (_, i) {
                            final service = filteredList[i];
                            final isSelected =
                                vm.selectedServiceIds.contains(service.id);
                            return _ServiceCard(
                              service: service,
                              isSelected: isSelected,
                              showAdded: _showAdded,
                              onTap: _showAdded
                                  ? null
                                  : () => vm.toggleService(service.id),
                              onAddTap: () {
                                vm.toggleService(service.id);
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

// ─── Service Card (Manage Inventory list style) ───────────────────────────────

class _ServiceCard extends StatelessWidget {
  final MasterService service;
  final bool isSelected;
  final bool showAdded;
  final VoidCallback? onTap;
  final VoidCallback onAddTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.showAdded,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = service.isAddedToCurrentBranch;
    final price = service.salePrice;
    final deptCat = [
      if (service.departmentName.isNotEmpty) service.departmentName,
      if (service.categoryName.isNotEmpty) service.categoryName,
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
                    icon: Icons.handyman_rounded,
                    showActiveDot: service.isActive && isAdded,
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
                                service.name,
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
                        const SizedBox(height: 6),
                        Text(
                          price != null && price > 0
                              ? ownerFormatMoney(context, price)
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
