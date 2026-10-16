import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';

import '../../../data/network/api_response.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../Reports/reports_search_bar.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'branch_catalog_shared.dart';
import 'branch_catalog_view_model.dart';
import 'catalog_shimmer.dart';

class CatalogDepartmentsTab extends StatefulWidget {
  final BranchCatalogViewModel vm;
  const CatalogDepartmentsTab({super.key, required this.vm});

  static void showCreateSheet(BuildContext context, BranchCatalogViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateDepartmentSheet(vm: vm),
    );
  }

  @override
  State<CatalogDepartmentsTab> createState() => _CatalogDepartmentsTabState();
}

class _CatalogDepartmentsTabState extends State<CatalogDepartmentsTab> {
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
  void didUpdateWidget(CatalogDepartmentsTab oldWidget) {
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
      final total = _visibleDepartments().length;
      if (_loadedCount < total) {
        setState(() {
          _loadedCount = (_loadedCount + _pageSize).clamp(0, total);
        });
      }
    }
  }

  List<CatalogDepartmentModel> _visibleDepartments() {
    final all = vm.filteredDepartments;
    if (_searchQuery.isEmpty) return all;
    return all
        .where((d) => d.name.toLowerCase().contains(_searchQuery))
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
            title: const Text('Remove Department'),
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
    final state = vm.departmentsState;

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
              state.message ?? 'Failed to load departments',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Pull down to retry',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
          ),
        ]),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: ReportsSearchBar(
            hint: AppLocalizations.of(context)!.ownerCatalogSearchDepartments,
            onChanged: (v) => setState(() {
              _searchQuery = v.trim().toLowerCase();
              _loadedCount = _pageSize;
            }),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: OwnerUi.scaffoldBackground,
            child: _buildList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final departments = _visibleDepartments();

    if (departments.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: constraints.maxHeight * 0.25),
                CatalogEmptyState(
                  message: _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'No departments found',
                ),
              ],
            );
          },
        ),
      );
    }

    final pageSlice = departments.take(_loadedCount).toList();
    final hasMore = _loadedCount < departments.length;

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
          final dept = pageSlice[i];
          return _DepartmentCard(
            key: ValueKey(dept.id),
            department: dept,
            isSpecificBranch: !vm.isAllBranches,
            isToggling: vm.isTogglingDepartment(dept.id),
            onToggleActive: (isActive) async {
              final result =
                  await vm.toggleDepartmentActive(ctx, dept.id, isActive);
              if (result != null && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(isActive
                      ? 'Department activated'
                      : 'Department deactivated'),
                ));
                final u = result.updated;
                if (u != null &&
                    (u.categories > 0 || u.products > 0 || u.services > 0)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(
                      'Also updated: ${u.categories} categories, '
                          '${u.products} products, ${u.services} services',
                    ),
                    duration: const Duration(seconds: 4),
                  ));
                }
              }
            },
            onRemove: () async {
              final confirmed = await _confirmRemove(ctx, dept.name);
              if (confirmed) {
                await vm.removeDepartmentFromBranch(ctx, dept.id);
              }
            },
          );
        },
      ),
    );
  }
}

// ─── Department Card ──────────────────────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final CatalogDepartmentModel department;
  final bool isSpecificBranch;
  final bool isToggling;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onRemove;

  const _DepartmentCard({
    super.key,
    required this.department,
    required this.isSpecificBranch,
    required this.isToggling,
    required this.onToggleActive,
    required this.onRemove,
  });

  // PERF: const decorations — zero allocation per build
  static const _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    // PERF: Removed blurRadius:12 boxShadow — shadow blur forces GPU
    // compositing layer per card which kills performance on low-end phones.
    // Replaced with a thin border which is rasterized in one pass.
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
  static const _branchStyle = TextStyle(
    color: Color(0xFF9E9E9E),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box + active dot
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
                        child: Icon(Icons.account_tree_rounded,
                            color: AppColors.primaryLight, size: 22),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: CatalogActiveDot(isActive: department.isActive),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Name + branch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedApiText(
                      department.name,
                      style: _nameStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (department.branchNames.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFFBDBDBD)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: LocalizedApiText(
                              department.branchNames.join(', '),
                              style: _branchStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Controls column — toggle switch with per-card loading indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // While the toggle API call is in-flight, replace the Switch
                  // with a small spinner so the user knows something is happening.
                  // The SizedBox matches the Switch's shrinkWrap height (36px)
                  // so the card doesn't shift layout during the transition.
                  SizedBox(
                    height: 22,
                    width: 40,
                    child: isToggling
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          )
                        : CatalogPrimaryToggle(
                            value: department.isActive,
                            onChanged: onToggleActive,
                          ),
                  ),
                  if (isSpecificBranch) ...[
                    const SizedBox(height: 4),
                    buildCatalogRemoveButton('Remove', onRemove),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Create Department Sheet ───────────────────────────────────────────────────

class CreateDepartmentSheet extends StatefulWidget {
  final BranchCatalogViewModel vm;
  const CreateDepartmentSheet({super.key, required this.vm});

  @override
  State<CreateDepartmentSheet> createState() => _CreateDepartmentSheetState();
}

class _CreateDepartmentSheetState extends State<CreateDepartmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isActive = true;

  // Branch selection — pre-seeded with the currently active branch if any
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    // Pre-select branch if one is already chosen in the main view
    if (!widget.vm.isAllBranches) {
      _selectedBranchId = widget.vm.selectedBranchId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<CatalogBranch> get _branches => widget.vm.branchPickerOptions;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

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
              const SizedBox(height: 12),
              const _SheetHandle(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!
                            .ownerCatalogRequestDepartment,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                    _CloseButton(onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Department Name (login-style field) ──────────────────
                      CustomTextField(
                        label: 'Name *',
                        hint: 'Department name',
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Branch (Discount-style dropdown) ─────────────────────
                      const Text(
                        'BRANCH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9E9E9E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      OwnerStyledDropdown<String>(
                        value: _selectedBranchId,
                        hint: 'Select branch (optional)',
                        height: 48,
                        options: _branches
                            .map((b) => OwnerDropdownOption(
                                value: b.id, label: b.name))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedBranchId = v),
                        triggerStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Active toggle ────────────────────────────────────────
                      Row(
                        children: [
                          const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9E9E9E),
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
                      const SizedBox(height: 24),

                      // ── Submit button ────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.vm.isCreatingDepartment
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            disabledBackgroundColor:
                                const Color(0x80C8E6C9),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                            ),
                            elevation: 0,
                          ),
                          child: widget.vm.isCreatingDepartment
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Department',
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
    final result = await widget.vm.createDepartment(
      context,
      name: _nameCtrl.text.trim(),
      isActive: _isActive,
      branchId: _selectedBranchId,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Department "${result.name}" created')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.vm.error ?? 'Failed to create department'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

// ─── Shared sheet sub-widgets ─────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFE0E0E0),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        child: SizedBox(width: 40, height: 4),
      );
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  static const _decoration = BoxDecoration(
    color: OwnerUi.scaffoldBackground,
    shape: BoxShape.circle,
  );

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: const DecoratedBox(
          decoration: _decoration,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF757575)),
          ),
        ),
      );
}
