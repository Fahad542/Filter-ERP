// ─── catalog_services_tab.dart ────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../../data/network/api_response.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/toast_service.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../Reports/reports_search_bar.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../widgets/owner_sheet_actions.dart';
import 'branch_catalog_shared.dart';
import 'branch_catalog_view_model.dart';
import 'catalog_shimmer.dart';

// ─── Services Tab ─────────────────────────────────────────────────────────────

class CatalogServicesTab extends StatefulWidget {
  final BranchCatalogViewModel vm;
  const CatalogServicesTab({super.key, required this.vm});

  @override
  State<CatalogServicesTab> createState() => _CatalogServicesTabState();
}

class _CatalogServicesTabState extends State<CatalogServicesTab> {
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
  void didUpdateWidget(CatalogServicesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.selectedBranchId != vm.selectedBranchId ||
        oldWidget.vm.serviceDeptFilter != vm.serviceDeptFilter) {
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
      final total = _visibleServices().length;
      if (_loadedCount < total) {
        setState(() {
          _loadedCount = (_loadedCount + _pageSize).clamp(0, total);
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _loadedCount = _pageSize);
    await vm.refresh();
  }

  List<CatalogServiceModel> _visibleServices() {
    final all = vm.filteredServices;
    if (_searchQuery.isEmpty) return all;
    return all
        .where((s) =>
    s.name.toLowerCase().contains(_searchQuery) ||
        s.sku.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = vm.servicesState;
    final depts = vm.departmentsState.data ?? [];

    if (state.status == Status.loading) {
      return Scaffold(
        backgroundColor: OwnerUi.scaffoldBackground,
        body: const CatalogListLoadingShimmer(showDeptDropdown: true),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _RequestServiceSheet.show(context, vm),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.secondaryLight,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(l10n.ownerCatalogRequestService,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: ReportsSearchBar(
                    hint: l10n.ownerCatalogSearchServices,
                    onChanged: (v) => setState(() {
                      _searchQuery = v.trim().toLowerCase();
                      _loadedCount = _pageSize;
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 88,
                  height: 44,
                  child: CatalogDeptFilterDropdown(
                    departments: depts,
                    selectedId: vm.serviceDeptFilter,
                    onChanged: (v) {
                      vm.setServiceDeptFilter(v);
                      setState(() => _loadedCount = _pageSize);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                _DeleteIconButton(
                  count: vm.selectedServiceIds.length,
                  onPressed: () => _removeSelected(context),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _RequestServiceSheet.show(context, vm),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.secondaryLight,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(l10n.ownerCatalogRequestService,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, dynamic state) {
    if (state.status == Status.error) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
              child: Text(state.message ?? 'Failed to load services',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center)),
          const SizedBox(height: 8),
          const Center(
              child: Text('Pull down to retry',
                  style: TextStyle(color: Colors.grey, fontSize: 12))),
        ]),
      );
    }

    final services = _visibleServices();

    if (services.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          buildCatalogEmptyState(_searchQuery.isNotEmpty
              ? 'No results for "$_searchQuery"'
              : 'No services found'),
        ]),
      );
    }

    final pageSlice = services.take(_loadedCount).toList();
    final hasMore = _loadedCount < services.length;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: pageSlice.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == pageSlice.length) {
            return const CatalogPaginationShimmer();
          }
          final s = pageSlice[i];
          return _ServiceCard(
            key: ValueKey(s.id),
            service: s,
            isSelected: vm.selectedServiceIds.contains(s.id),
            onToggle: (v) => vm.toggleServiceSelection(s.id, v),
          );
        },
      ),
    );
  }

  Future<void> _removeSelected(BuildContext context) async {
    final count = vm.selectedServiceIds.length;
    if (count == 0) return;
    final isSpecificBranch = !vm.isAllBranches;
    final noun = count == 1 ? 'service' : 'services';
    final confirmed = await _confirmAction(
      context,
      title: isSpecificBranch ? 'Remove Selected' : 'Remove from Workshop',
      message: isSpecificBranch
          ? 'Remove $count $noun from this branch only?'
          : 'Remove $count $noun from all branches in this workshop?',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;

    final (removed, error) =
        await vm.removeSelectedWorkshopServices(context);
    if (!context.mounted) return;
    if (error != null && removed == 0) {
      ToastService.showError(context, error);
    } else if (error != null) {
      ToastService.showError(
          context, 'Removed $removed. Some failed: $error');
    } else {
      ToastService.showSuccess(
        context,
        isSpecificBranch
            ? 'Removed $removed $noun from branch'
            : 'Removed $removed $noun from workshop',
      );
    }
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
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
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

// ─── Delete Icon Button ───────────────────────────────────────────────────────

class _DeleteIconButton extends StatelessWidget {
  final int count;
  final VoidCallback? onPressed;
  const _DeleteIconButton({required this.count, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: isEmpty ? null : onPressed,
          style: IconButton.styleFrom(
            backgroundColor: isEmpty
                ? Colors.grey.shade100
                : Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(10),
          ),
          tooltip: 'Remove selected',
          icon: Icon(Icons.delete_outline_rounded,
              color: isEmpty ? Colors.grey.shade400 : Colors.red, size: 22),
        ),
        if (!isEmpty)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final CatalogServiceModel service;
  final bool isSelected;
  final ValueChanged<bool> onToggle;

  const _ServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onToggle,
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

  double? get _price => service.sellingPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final price = _price;
    final priceLabel = price != null && price > 0
        ? ownerFormatMoney(context, price)
        : l10n.ownerCommonFree;

    return GestureDetector(
      onTap: () => onToggle(!isSelected),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: _cardDecoration.copyWith(
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight
                  : const Color(0xFFEEEEEE),
              width: isSelected ? 1.5 : 1,
            ),
          ),
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
                          child: Icon(
                            Icons.miscellaneous_services_rounded,
                            color: AppColors.primaryLight,
                            size: 22,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: CatalogActiveDot(isActive: service.isActive),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedApiText(
                        service.name,
                        style: _nameStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.account_tree_outlined,
                              size: 13, color: Color(0xFFBDBDBD)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: LocalizedApiText(
                              service.departmentName,
                              style: _metaStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFFBDBDBD)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              service.branchDisplayName,
                              style: _metaStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceLabel,
                        style: _metaStyle,
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (v) => onToggle(v ?? false),
                    activeColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Request Service Sheet ────────────────────────────────────────────────────

class _RequestServiceSheet extends StatefulWidget {
  final BranchCatalogViewModel vm;

  const _RequestServiceSheet({required this.vm});

  static Future<void> show(BuildContext context, BranchCatalogViewModel vm) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestServiceSheet(vm: vm),
    );
  }

  @override
  State<_RequestServiceSheet> createState() => _RequestServiceSheetState();
}

class _RequestServiceSheetState extends State<_RequestServiceSheet> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _currentStockCtrl = TextEditingController(text: '0');
  final _criticalLevelCtrl = TextEditingController();
  final _reorderLevelCtrl = TextEditingController();

  // Dropdowns
  String? _selectedBranchId;
  String? _selectedDeptId;
  String? _selectedCategoryId;
  String _type = 'Service';

  // FIX: _unit ab hardcoded nahi — initState mein API defaultUnit se set hoga.
  // Agar units load nahi huin to null rahega aur form mein hint dikhega.
  String? _unit;

  bool _isSubmitting = false;

  // FIX: _units hardcoded list hata di. Ab ye getter API se leta hai.
  // Agar productUnitsState abhi loading hai to empty list milegi —
  // dropdown loading indicator dikhata hai us waqt.
  List<String> get _units => widget.vm.productUnits;

  // _types static hai — ye API se nahi aata
  static const List<String> _types = ['Service', 'Product'];

  @override
  void initState() {
    super.initState();
    // Pre-select branch agar specific branch selected hai main view mein
    if (!widget.vm.isAllBranches) {
      _selectedBranchId = widget.vm.selectedBranchId;
    }
    // FIX: Default unit API se lo. Agar units load ho chuki hain to
    // turant set karo, warna didUpdateWidget mein set hoga.
    final defaultUnit = widget.vm.defaultProductUnit;
    if (_units.isNotEmpty) {
      _unit = _units.contains(defaultUnit) ? defaultUnit : _units.first;
    }
  }

  @override
  void didUpdateWidget(_RequestServiceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // FIX: Jab vm notify kare aur units pehli baar aayein to default set karo.
    // Sirf tab set karo jab _unit abhi null ho — user ka selection preserve karo.
    if (_unit == null && _units.isNotEmpty) {
      final defaultUnit = widget.vm.defaultProductUnit;
      setState(() {
        _unit = _units.contains(defaultUnit) ? defaultUnit : _units.first;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _salePriceCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _currentStockCtrl.dispose();
    _criticalLevelCtrl.dispose();
    _reorderLevelCtrl.dispose();
    super.dispose();
  }

  List<CatalogBranch> get _branches => widget.vm.branchPickerOptions;

  List<CatalogDepartmentModel> get _departments =>
      widget.vm.departmentsState.data ?? [];

  List<CatalogCategoryModel> get _categories {
    final all = widget.vm.categoriesState.data ?? [];
    if (_selectedDeptId == null) return all;
    return all.where((c) => c.departmentId == _selectedDeptId).toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBranchId == null) {
      _showSnack('Please select a branch');
      return;
    }
    if (_selectedDeptId == null) {
      _showSnack('Please select a department');
      return;
    }
    if (_unit == null) {
      _showSnack('Please select a unit');
      return;
    }

    final vm = widget.vm;
    // workshopId aur branchId vm se lo — woh session mein stored hain
    final workshopId = vm.branchPickerOptions
        .firstWhere((b) => b.id == _selectedBranchId,
        orElse: () => vm.branchPickerOptions.first)
        .workshopId;

    setState(() => _isSubmitting = true);

    final request = CreateServiceRequest(
      workshopId: workshopId,
      branchId: _selectedBranchId!,
      name: _nameCtrl.text.trim(),
      departmentId: _selectedDeptId!,
      categoryId: _selectedCategoryId,
      unit: _unit!,
      purchasePrice:
      double.tryParse(_purchasePriceCtrl.text.trim()) ?? 0,
      salePrice:
      double.tryParse(_salePriceCtrl.text.trim()) ?? 0,
      openingQty:
      int.tryParse(_currentStockCtrl.text.trim()) ?? 0,
      criticalStockPoint:
      int.tryParse(_criticalLevelCtrl.text.trim()) ?? 0,
      isActive: true,
    );

    final success = await vm.createService(context, request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service created successfully'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    } else {
      _showSnack(vm.error ?? 'Failed to create service');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    // FIX: units loading state — agar abhi aa rahi hain to loading box dikhao
    final unitsLoading =
        widget.vm.productUnitsState.status == Status.loading;

    return Container(
      margin:
      EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ownerCatalogRequestService,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 18,
                      color: AppColors.secondaryLight,
                    ),
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

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
                children: [
                  // NAME
                  _SvcLabel('NAME *'),
                  _SvcField(
                    controller: _nameCtrl,
                    hint: '',
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // BRANCH + DEPARTMENT  (dept pehle — category is dept-dependent)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('BRANCH'),
                            _SvcDropdown<String>(
                              value: _selectedBranchId,
                              hint: 'Select Branch',
                              options: _branches
                                  .where((b) => b.id != 'all')
                                  .map((b) => OwnerDropdownOption(
                                      value: b.id, label: b.name))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedBranchId = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('DEPARTMENT *'),
                            _SvcDropdown<String>(
                              value: _selectedDeptId,
                              hint: 'Select Department',
                              options: _departments
                                  .map((d) => OwnerDropdownOption(
                                      value: d.id, label: d.name))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedDeptId = v;
                                // Dept change hone par category reset
                                _selectedCategoryId = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // SKU / BARCODE + CATEGORY  (dept ke baad — categories dept se filter hongi)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('SKU / BARCODE'),
                            _SvcField(controller: _skuCtrl, hint: 'Optional'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('CATEGORY'),
                            _SvcDropdown<String>(
                              value: _selectedCategoryId,
                              hint: _selectedDeptId == null
                                  ? 'Select dept first'
                                  : 'Select Category',
                              options: _categories
                                  .map((c) => OwnerDropdownOption(
                                      value: c.id, label: c.name))
                                  .toList(),
                              onChanged: _selectedDeptId == null
                                  ? null
                                  : (v) =>
                                      setState(() => _selectedCategoryId = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // TYPE + UNIT
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('TYPE'),
                            _SvcDropdown<String>(
                              value: _type,
                              options: _types
                                  .map((t) =>
                                      OwnerDropdownOption(value: t, label: t))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _type = v ?? _type),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('UNIT'),
                            // FIX: Pehle _units hardcoded ['pcs','liter',...] tha.
                            // Ab productUnitsState se aata hai.
                            // Loading state mein loading box dikhao.
                            unitsLoading
                                ? _UnitsLoadingBox()
                                : _SvcDropdown<String>(
                              value: _unit,
                              hint: 'Select unit',
                              options: _units
                                  .map((u) =>
                                      OwnerDropdownOption(value: u, label: u))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _unit = v ?? _unit),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // PURCHASE PRICE + SALE PRICE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('PURCHASE PRICE (SAR)'),
                            _SvcField(
                              controller: _purchasePriceCtrl,
                              hint: '',
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('SALE PRICE (SAR, INCL. VAT)'),
                            _SvcField(
                              controller: _salePriceCtrl,
                              hint: '',
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CURRENT STOCK + CRITICAL LEVEL
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SvcLabel('CURRENT STOCK QTY'),
                            _SvcField(
                              controller: _currentStockCtrl,
                              hint: '0',
                              keyboardType: TextInputType.number,
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
                                const Flexible(
                                  child: _SvcLabel('CRITICAL LEVEL'),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(ALERT THRESHOLD)',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            _SvcField(
                              controller: _criticalLevelCtrl,
                              hint: '',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // REORDER LEVEL
                  _SvcLabel('REORDER LEVEL'),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 26,
                    child: _SvcField(
                      controller: _reorderLevelCtrl,
                      hint: '',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
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

// ─── Units Loading Box ────────────────────────────────────────────────────────
// FIX: Naya widget — units API se load ho rahi hoon to yeh dikhata hai.

class _UnitsLoadingBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

// ─── Service-specific Sheet Helpers ──────────────────────────────────────────

class _SvcLabel extends StatelessWidget {
  final String text;
  const _SvcLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SvcField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _SvcField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
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
  final String? hint;
  final List<OwnerDropdownOption<T>> options;
  // nullable — null passed karne par dropdown disabled ho jata hai
  final ValueChanged<T?>? onChanged;

  const _SvcDropdown({
    required this.value,
    required this.options,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return OwnerStyledDropdown<T>(
      value: value,
      hint: hint ?? 'Select',
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