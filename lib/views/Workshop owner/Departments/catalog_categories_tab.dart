// ─── catalog_categories_tab.dart ─────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../../data/network/api_response.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../Reports/reports_search_bar.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'branch_catalog_shared.dart';
import 'branch_catalog_view_model.dart';
import 'catalog_shimmer.dart';

class CatalogCategoriesTab extends StatefulWidget {
  final BranchCatalogViewModel vm;

  const CatalogCategoriesTab({super.key, required this.vm});

  /// Called by the parent Scaffold's FAB ("Request Category").
  static void showCreateSheet(BuildContext context, BranchCatalogViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCategorySheet(vm: vm),
    );
  }

  @override
  State<CatalogCategoriesTab> createState() => _CatalogCategoriesTabState();
}

class _CatalogCategoriesTabState extends State<CatalogCategoriesTab> {
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
  void didUpdateWidget(CatalogCategoriesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.selectedBranchId != vm.selectedBranchId) {
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
      final total = _visibleCategories().length;
      if (_loadedCount < total) {
        setState(() {
          _loadedCount = (_loadedCount + _pageSize).clamp(0, total);
        });
      }
    }
  }

  List<CatalogCategoryModel> _visibleCategories() {
    final all = vm.filteredCategories;
    if (_searchQuery.isEmpty) return all;
    return all
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery) ||
            c.departmentName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _onRefresh() async {
    setState(() => _loadedCount = _pageSize);
    await vm.refresh();
  }

  Future<bool> _confirmRemove(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove Category'),
            content: Text('Remove "$name" from this branch?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = vm.categoriesState;

    if (state.status == Status.loading) {
      return const CatalogListLoadingShimmer();
    }

    if (state.status == Status.error) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Text(
              state.message ?? 'Failed to load categories',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Pull down to retry',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ]),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: ReportsSearchBar(
            hint: l10n.ownerCatalogSearchCategories,
            onChanged: (v) => setState(() {
              _searchQuery = v.trim().toLowerCase();
              _loadedCount = _pageSize;
            }),
          ),
        ),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final categories = _visibleCategories();

    if (categories.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          buildCatalogEmptyState(_searchQuery.isNotEmpty
              ? 'No results for "$_searchQuery"'
              : 'No categories found'),
        ]),
      );
    }

    final pageSlice = categories.take(_loadedCount).toList();
    final hasMore = _loadedCount < categories.length;

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: pageSlice.length + (hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == pageSlice.length) {
            return const CatalogPaginationShimmer();
          }
          final cat = pageSlice[i];
          return _CategoryCard(
            key: ValueKey(cat.id),
            category: cat,
            isSpecificBranch: !vm.isAllBranches,
            onRemove: () async {
              final confirmed = await _confirmRemove(ctx, cat.name);
              if (confirmed) {
                await vm.removeCategoryFromBranch(ctx, cat.id);
              }
            },
          );
        },
      ),
    );
  }
}

// ─── Create Category Sheet ─────────────────────────────────────────────────────
// Styled to match _RequestServiceSheet from services tab.

class CreateCategorySheet extends StatefulWidget {
  final BranchCatalogViewModel vm;
  const CreateCategorySheet({super.key, required this.vm});

  @override
  State<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String? _selectedDeptId;
  String _type = 'product';
  bool _isActive = true;

  static const _types = ['product', 'service'];

  List<CatalogDepartmentModel> get _depts =>
      widget.vm.departmentsState.data ?? [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────────────────────
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

              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Request Category',
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

              // ── Form (height follows content) ───────────────────────────────
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // NAME
                      _SvcLabel('NAME *'),
                      _SvcField(
                        controller: _nameCtrl,
                        hint: '',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // DEPARTMENT + TYPE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SvcLabel('DEPARTMENT *'),
                                _SvcDropdown<String>(
                                  value: _selectedDeptId,
                                  hint: 'Select',
                                  options: _depts
                                      .map((d) => OwnerDropdownOption(
                                          value: d.id, label: d.name))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedDeptId = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SvcLabel('TYPE'),
                                _SvcDropdown<String>(
                                  value: _type,
                                  hint: 'Select',
                                  options: _types
                                      .map((t) => OwnerDropdownOption(
                                          value: t, label: t))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _type = v ?? 'product'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ACTIVE toggle
                      Row(
                        children: [
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeColor: AppColors.primaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              widget.vm.isCreatingCategory ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            disabledBackgroundColor:
                                const Color(0x8088C34A), // primaryLight 50%
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: widget.vm.isCreatingCategory
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Create Category',
                                  style: TextStyle(
                                    color: AppColors.secondaryLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    final result = await widget.vm.createCategory(
      context,
      name: _nameCtrl.text.trim(),
      type: _type,
      departmentId: _selectedDeptId!,
      isActive: _isActive,
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "${result.name}" created')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.vm.error ?? 'Failed to create category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CatalogCategoryModel category;
  final bool isSpecificBranch;
  final VoidCallback onRemove;

  // PERF: const decorations — zero allocation per build
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
  static const _typeBadgeDecoration = BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );
  static const _typeBadgeStyle = TextStyle(
    color: AppColors.onPrimaryLight,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  static const _subtextStyle = TextStyle(
    color: Color(0xFF9E9E9E),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  const _CategoryCard({
    super.key,
    required this.category,
    required this.isSpecificBranch,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isProduct = category.type == 'product';

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
                    DecoratedBox(
                      decoration: _iconDecoration,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          isProduct
                              ? Icons.inventory_2_rounded
                              : Icons.miscellaneous_services_rounded,
                          color: AppColors.primaryLight,
                          size: 22,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: CatalogActiveDot(isActive: category.isActive),
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
                          child: Text(
                            category.name,
                            style: _nameStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: _typeBadgeDecoration,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            child: Text(category.type, style: _typeBadgeStyle),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined,
                            size: 13, color: Color(0xFFBDBDBD)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            category.departmentName,
                            style: _subtextStyle,
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
                            category.branchNames.isNotEmpty
                                ? category.branchNames.join(', ')
                                : '—',
                            style: _subtextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSpecificBranch)
                buildCatalogRemoveButton('Remove', onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared sheet sub-widgets ─────────────────────────────────────────────────

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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SvcField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _SvcField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
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
