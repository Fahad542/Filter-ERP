import 'package:flutter/material.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../data/repositories/owner_repository.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_shimmer.dart';
import 'affiliated_suppliers_view_model.dart';
import 'filter_affiliated_suppliers_models.dart';

class AddAffiliatedSuppliersScreen extends StatefulWidget {
  final void Function(List<RegisteredAffiliatedSupplier> selected) onAdd;

  const AddAffiliatedSuppliersScreen({super.key, required this.onAdd});

  @override
  State<AddAffiliatedSuppliersScreen> createState() =>
      _AddAffiliatedSuppliersScreenState();
}

class _AddAffiliatedSuppliersScreenState
    extends State<AddAffiliatedSuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _hideLinked = false;

  late AffiliatedSuppliersViewModel _vm;
  final _catalogRepository = CatalogRepository();

  // Branches (for the "Default branch" picker) — fetched once, independent
  // of the supplier list/loading state.
  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId;
  bool _branchesLoading = false;
  String? _branchesError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm = context.read<AffiliatedSuppliersViewModel>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AffiliatedSuppliersViewModel>().loadAvailableSuppliers();
      _loadBranches();
    });
  }

  Future<void> _loadBranches() async {
    setState(() {
      _branchesLoading = true;
      _branchesError = null;
    });
    try {
      final token = await _vm.sessionService.getToken(role: 'owner');
      if (token == null) throw Exception('No token found');
      final branches = await _catalogRepository.fetchBranchesList(token);
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _selectedBranchId = branches.isNotEmpty
            ? branches.first['id']?.toString()
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _branchesError = AppLocalizations.of(context)!.ownerAffiliatedCouldNotLoadBranches);
    } finally {
      if (mounted) setState(() => _branchesLoading = false);
    }
  }

  List<RegisteredAffiliatedSupplier> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final all = _vm.availableSuppliers;
    return all.where((s) {
      if (_hideLinked && s.isLinked) return false;
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.mobile.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.vatId.toLowerCase().contains(q) ||
          s.cr.toLowerCase().contains(q);
    }).toList();
  }

  List<RegisteredAffiliatedSupplier> get _selected => _vm.availableSuppliers
      .where((s) => _selectedIds.contains(s.id))
      .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    // Row controllers (opening balance / date) live on the view model so
    // they survive a rebuild of this screen; clean them up here instead.
    _vm.disposeAvailableSuppliers();
    super.dispose();
  }

  void _toggleSupplier(RegisteredAffiliatedSupplier supplier, bool? value) {
    if (supplier.isLinked) return;
    setState(() {
      if (value == true) {
        _selectedIds.add(supplier.id);
      } else {
        _selectedIds.remove(supplier.id);
      }
    });
  }

  void _toggleAll(bool? value) {
    setState(() {
      final selectable = _filtered.where((s) => !s.isLinked);
      if (value == true) {
        _selectedIds.addAll(selectable.map((s) => s.id));
      } else {
        _selectedIds.removeAll(selectable.map((s) => s.id));
      }
    });
  }

  Future<void> _submit() async {
    final branchId = _selectedBranchId;
    if (branchId == null || branchId.isEmpty) {
      ToastService.showError(context, 'Please select a branch.');
      return;
    }
    final selected = _selected;
    if (selected.isEmpty) return;

    final error = await context.read<AffiliatedSuppliersViewModel>().addAffiliatedSuppliers(
          branchId: branchId,
          selected: selected,
        );

    if (!mounted) return;
    if (error != null) {
      ToastService.showError(context, error);
      return;
    }

    widget.onAdd(selected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AffiliatedSuppliersViewModel>();
    final filtered = _filtered;
    final selectable = filtered.where((s) => !s.isLinked).toList();
    final allSelected = selectable.isNotEmpty &&
        selectable.every((s) => _selectedIds.contains(s.id));

    final branchItems = _branches
        .map((b) => DropdownMenuItem<String>(
              value: b['id']?.toString(),
              child: Text(
                (b['name'] ?? b['branchName'] ?? 'Branch').toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ))
        .toList();

    Widget listBody;
    if (vm.isLoadingAvailable) {
      listBody = const OwnerListPageShimmer(itemCount: 4);
    } else if (vm.availableError != null) {
      listBody = _AddSupplierErrorState(
        message: vm.availableError!,
        onRetry: () =>
            context.read<AffiliatedSuppliersViewModel>().loadAvailableSuppliers(),
      );
    } else {
      listBody = _RegisteredSupplierCardList(
        items: filtered,
        selectedIds: _selectedIds,
        onToggle: _toggleSupplier,
      );
    }

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: AppLocalizations.of(context)!.ownerAffiliatedAddTitle),
        showDrawer: false,
        showBackButton: true,
        showNotification: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _AddSupplierTopCard(
                    branchItems: branchItems,
                    selectedBranchId: _selectedBranchId,
                    branchesLoading: _branchesLoading,
                    branchesError: _branchesError,
                    onBranchChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedBranchId = v);
                    },
                    searchCtrl: _searchCtrl,
                    onSearchChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _hideLinked,
                        onChanged: (v) =>
                            setState(() => _hideLinked = v ?? false),
                        activeColor: AppColors.primaryLight,
                        checkColor: AppColors.secondaryLight,
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.ownerAffiliatedHideLinked,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ── Card list instead of table ───────────────────────
                  listBody,
                ],
              ),
            ),
            _AddSupplierFooter(
              allSelected: allSelected,
              onToggleAll: _toggleAll,
              selectedCount: _selectedIds.length,
              isSubmitting: vm.isAddingSuppliers,
              onCancel: () => Navigator.pop(context),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state (mirrors the main list's error card) ──────────────────────

class _AddSupplierErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _AddSupplierErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 44, color: Colors.red.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(AppLocalizations.of(context)!.ownerCommonRetry)),
        ],
      ),
    );
  }
}

// ── Card List ───────────────────────────────────────────────────────────────

class _RegisteredSupplierCardList extends StatelessWidget {
  final List<RegisteredAffiliatedSupplier> items;
  final Set<String> selectedIds;
  final void Function(RegisteredAffiliatedSupplier supplier, bool? value)
  onToggle;

  const _RegisteredSupplierCardList({
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined,
                size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.ownerAffiliatedNoRegistered,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              Divider(height: 0, thickness: 0.6, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final supplier = items[index];
            final isSelected = selectedIds.contains(supplier.id);
            return _RegisteredSupplierCard(
              supplier: supplier,
              isSelected: isSelected,
              onToggle: (v) => onToggle(supplier, v),
            );
          },
        ),
      ),
    );
  }
}

class _RegisteredSupplierCard extends StatelessWidget {
  final RegisteredAffiliatedSupplier supplier;
  final bool isSelected;
  final ValueChanged<bool?> onToggle;

  const _RegisteredSupplierCard({
    required this.supplier,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool linked = supplier.isLinked;

    return Material(
      color: linked ? const Color(0xFFFAFBFD) : Colors.white,
      child: InkWell(
        onTap: linked ? null : () => onToggle(!isSelected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Checkbox ─────────────────────────────────────────────
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: linked ? false : isSelected,
                  onChanged: linked ? null : onToggle,
                  activeColor: AppColors.primaryLight,
                  checkColor: AppColors.secondaryLight,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              // ── Avatar ────────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withOpacity(linked ? 0.05 : 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  supplier.name.isEmpty
                      ? '?'
                      : supplier.name[0].toUpperCase(),
                  style: TextStyle(
                    color: linked
                        ? AppColors.secondaryLight.withOpacity(0.4)
                        : AppColors.secondaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Info ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            style: TextStyle(
                              color: linked
                                  ? Colors.grey.shade400
                                  : AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (linked)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.ownerAffiliatedLinked,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      supplier.email,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.phone_outlined,
                          text: supplier.mobile,
                        ),
                        _InfoChip(
                          icon: Icons.receipt_outlined,
                          text: '${AppLocalizations.of(context)!.ownerSuppliersVat}: ${supplier.vatId}',
                        ),
                        if ((supplier.contactPerson ?? '').isNotEmpty)
                          _InfoChip(
                            icon: Icons.person_outline_rounded,
                            text: supplier.contactPerson!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Opening balance field ─────────────────────────────────
              if (!linked)
                SizedBox(
                  width: 88,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.ownerAffiliatedOpeningBal,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _CompactTextField(
                        controller: supplier.openingCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppLocalizations.of(context)!.ownerAffiliatedAsOfDate,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _CompactTextField(
                        controller: supplier.dateCtrl,
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top card ────────────────────────────────────────────────────────────────

class _AddSupplierTopCard extends StatelessWidget {
  final List<DropdownMenuItem<String>> branchItems;
  final String? selectedBranchId;
  final bool branchesLoading;
  final String? branchesError;
  final ValueChanged<String?> onBranchChanged;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;

  const _AddSupplierTopCard({
    required this.branchItems,
    required this.selectedBranchId,
    required this.branchesLoading,
    required this.branchesError,
    required this.onBranchChanged,
    required this.searchCtrl,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 620;
          final branch = _FieldBlock(
            label: AppLocalizations.of(context)!.ownerAffiliatedDefaultBranch,
            child: _BranchDropdown(
              items: branchItems,
              value: selectedBranchId,
              loading: branchesLoading,
              errorText: branchesError,
              onChanged: onBranchChanged,
            ),
          );
          final search = _FieldBlock(
            label: AppLocalizations.of(context)!.ownerAffiliatedSearchRegistered,
            child: _SearchField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
            ),
          );

          if (!isWide) {
            return Column(
              children: [branch, const SizedBox(height: 12), search],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 270, child: branch),
              const SizedBox(width: 14),
              Expanded(child: search),
            ],
          );
        },
      ),
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────────────

class _AddSupplierFooter extends StatelessWidget {
  final bool allSelected;
  final ValueChanged<bool?> onToggleAll;
  final int selectedCount;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _AddSupplierFooter({
    required this.allSelected,
    required this.onToggleAll,
    required this.selectedCount,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: allSelected,
              onChanged: isSubmitting ? null : onToggleAll,
              activeColor: AppColors.primaryLight,
              checkColor: AppColors.secondaryLight,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.ownerCommonSelectAll,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 94,
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                AppLocalizations.of(context)!.ownerCommonCancel,
                style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 164,
            child: CustomButton(
              text: isSubmitting
                  ? AppLocalizations.of(context)!.ownerAffiliatedAdding
                  : AppLocalizations.of(context)!.ownerAffiliatedAddCount(
                      ownerLocalizeDigits(context, '$selectedCount'),
                    ),
              onPressed: (selectedCount == 0 || isSubmitting) ? () {} : onSubmit,
              backgroundColor: AppColors.secondaryLight,
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────────────

class _FieldBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _BranchDropdown extends StatelessWidget {
  final List<DropdownMenuItem<String>> items;
  final String? value;
  final bool loading;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  const _BranchDropdown({
    required this.items,
    required this.value,
    required this.loading,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.centerLeft,
      child: loading
          ? Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context)!.ownerAffiliatedLoadingBranches,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
              ],
            )
          : items.isEmpty
              ? Text(
                  errorText ?? 'No branches found',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade500),
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
    );
    return box;
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.ownerAffiliatedSearchHint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
        prefixIcon: Icon(Icons.search_rounded,
            color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;

  const _CompactTextField({
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textAlign: suffixIcon == null ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          suffixIcon: suffixIcon == null
              ? null
              : Icon(suffixIcon, size: 13, color: Colors.grey.shade500),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}