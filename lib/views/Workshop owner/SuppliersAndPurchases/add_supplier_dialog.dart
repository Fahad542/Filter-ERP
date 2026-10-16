import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../widgets/owner_sheet_actions.dart';
import 'suppliers_view_model.dart';

Future<void> showAddSupplierDialog(BuildContext context) {
  final vm = context.read<SuppliersViewModel>();
  vm.clearForm();
  // Kick off the registered-suppliers fetch immediately so the list is
  // either ready or already loading by the time the sheet finishes
  // animating in — avoids a blank flash on slow networks.
  vm.loadRegisteredSuppliers();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: vm,
      child: const AddSupplierDialog(),
    ),
  );
}

class AddSupplierDialog extends StatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  bool _showWorkshopOnlyForm = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // The full list is already in memory, so filtering is a cheap local
    // pass with no extra network call — no debounce needed.
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RegisteredSupplier> _filteredSuppliers(SuppliersViewModel vm) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final source = vm.registeredSuppliers;
    if (q.isEmpty) return source;
    return source.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.mobile.toLowerCase().contains(q) ||
          (s.crNumber ?? '').toLowerCase().contains(q) ||
          (s.vatId ?? '').toLowerCase().contains(q) ||
          (s.contactPerson ?? '').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  void _toggleSupplier(RegisteredSupplier supplier) {
    if (supplier.isLinkedToWorkshop) return; // already linked — nothing to do
    setState(() {
      if (_selectedIds.contains(supplier.id)) {
        _selectedIds.remove(supplier.id);
      } else {
        _selectedIds.add(supplier.id);
      }
    });
  }

  Future<void> _addSelectedSuppliers() async {
    if (_selectedIds.isEmpty) return;
    final vm = context.read<SuppliersViewModel>();
    final ids = Set<String>.from(_selectedIds);
    final ok = await vm.linkSelectedSuppliers(context, ids);
    if (ok && mounted) {
      setState(() => _selectedIds.clear());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;
    final maxWidth = isWide ? 760.0 : width;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: DraggableScrollableSheet(
            initialChildSize: isWide ? 0.86 : 0.92,
            minChildSize: 0.55,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) {
              return Material(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: _showWorkshopOnlyForm
                    ? _WorkshopOnlySupplierForm(
                  scrollController: scrollController,
                  isWide: isWide,
                  onBack: () => setState(() => _showWorkshopOnlyForm = false),
                )
                    : Consumer<SuppliersViewModel>(
                  builder: (_, vm, __) => _RegisteredSuppliersPicker(
                    scrollController: scrollController,
                    searchCtrl: _searchCtrl,
                    selectedIds: _selectedIds,
                    suppliers: _filteredSuppliers(vm),
                    isLoading: vm.isRegisteredLoading && vm.registeredSuppliers.isEmpty,
                    isLinking: vm.isActionLoading,
                    errorMessage: vm.registeredError,
                    hasSearched: _searchCtrl.text.trim().isNotEmpty,
                    onToggle: _toggleSupplier,
                    onWorkshopOnly: () {
                      vm.clearForm();
                      setState(() => _showWorkshopOnlyForm = true);
                    },
                    onCancel: () => Navigator.pop(context),
                    onAddSelected: _addSelectedSuppliers,
                    onRetry: () => vm.refreshRegisteredSuppliers(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisteredSuppliersPicker extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController searchCtrl;
  final Set<String> selectedIds;
  final List<RegisteredSupplier> suppliers;
  final bool isLoading;
  final bool isLinking;
  final String? errorMessage;
  final bool hasSearched;
  final ValueChanged<RegisteredSupplier> onToggle;
  final VoidCallback onWorkshopOnly;
  final VoidCallback onCancel;
  final VoidCallback onAddSelected;
  final VoidCallback onRetry;

  const _RegisteredSuppliersPicker({
    required this.scrollController,
    required this.searchCtrl,
    required this.selectedIds,
    required this.suppliers,
    required this.isLoading,
    required this.isLinking,
    required this.errorMessage,
    required this.hasSearched,
    required this.onToggle,
    required this.onWorkshopOnly,
    required this.onCancel,
    required this.onAddSelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _DialogHeader(
          title: l10n.ownerAddSupplierTitle,
          onClose: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            children: [
              isWide
                  ? Row(
                children: [
                  Expanded(child: _SearchField(controller: searchCtrl)),
                  const SizedBox(width: 12),
                  _WorkshopOnlyButton(onTap: onWorkshopOnly),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchField(controller: searchCtrl),
                  const SizedBox(height: 10),
                  _WorkshopOnlyButton(onTap: onWorkshopOnly),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const _LoadingSuppliers()
              else if (errorMessage != null)
                _ErrorSuppliers(message: errorMessage!, onRetry: onRetry)
              else if (suppliers.isEmpty)
                  _EmptyRegisteredSuppliers(isFiltered: hasSearched)
                else if (isWide)
                    _RegisteredSupplierTable(
                      suppliers: suppliers,
                      selectedIds: selectedIds,
                      onToggle: onToggle,
                    )
                  else
                    _RegisteredSupplierCards(
                      suppliers: suppliers,
                      selectedIds: selectedIds,
                      onToggle: onToggle,
                    ),
              const SizedBox(height: 16),
              Text(
                l10n.ownerAddSupplierPickerHint,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _PickerFooter(
          selectedCount: selectedIds.length,
          isLinking: isLinking,
          onCancel: onCancel,
          onAddSelected: onAddSelected,
        ),
      ],
    );
  }
}

class _LoadingSuppliers extends StatelessWidget {
  const _LoadingSuppliers();

  @override
  Widget build(BuildContext context) {
    // Skeleton rows instead of a spinner — feels faster on slow networks
    // and avoids a layout jump once real rows arrive.
    return Column(
      children: List.generate(
        4,
            (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 78,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorSuppliers extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorSuppliers({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.ownerCommonRetry),
          ),
        ],
      ),
    );
  }
}

class _RegisteredSupplierTable extends StatelessWidget {
  final List<RegisteredSupplier> suppliers;
  final Set<String> selectedIds;
  final ValueChanged<RegisteredSupplier> onToggle;

  const _RegisteredSupplierTable({
    required this.suppliers,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: OwnerUi.scaffoldBackground,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
                Expanded(flex: 20, child: _TableHead(l10n.ownerAddSupplierColSupplier)),
                Expanded(flex: 18, child: _TableHead(l10n.ownerAddSupplierColContact)),
                Expanded(flex: 16, child: _TableHead(l10n.ownerSuppliersCr)),
                Expanded(flex: 20, child: _TableHead(l10n.ownerSuppliersVat)),
                SizedBox(width: 90, child: Align(alignment: Alignment.centerRight, child: _TableHead(l10n.ownerAddSupplierColAction))),
              ],
            ),
          ),
          ...suppliers.asMap().entries.map((entry) {
            final supplier = entry.value;
            final selected = selectedIds.contains(supplier.id);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(flex: 20, child: _SupplierName(name: supplier.name)),
                      Expanded(flex: 18, child: _CellText(supplier.mobile.isEmpty ? '–' : ownerLocalizeDigits(context, supplier.mobile))),
                      Expanded(flex: 16, child: _CellText(supplier.crNumber != null ? ownerLocalizeDigits(context, supplier.crNumber!) : '–')),
                      Expanded(flex: 20, child: _CellText(supplier.vatId != null ? ownerLocalizeDigits(context, supplier.vatId!) : '–')),
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _SelectButton(
                            selected: selected,
                            linked: supplier.isLinkedToWorkshop,
                            onTap: () => onToggle(supplier),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.key != suppliers.length - 1) Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RegisteredSupplierCards extends StatelessWidget {
  final List<RegisteredSupplier> suppliers;
  final Set<String> selectedIds;
  final ValueChanged<RegisteredSupplier> onToggle;

  const _RegisteredSupplierCards({
    required this.suppliers,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Built as a plain Column inside the parent ListView (capped at 500
    // entries server-side), so it's still scrolled lazily by the outer
    // scroll view's sliver machinery without needing its own builder.
    return Column(
      children: suppliers.map((supplier) {
        final selected = selectedIds.contains(supplier.id);
        final linked = supplier.isLinkedToWorkshop;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: linked ? const Color(0xFFFAFBFD) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primaryLight : Colors.grey.shade200,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: supplier.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SupplierName(name: supplier.name),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        if (supplier.mobile.isNotEmpty)
                          _InfoChip(
                            icon: Icons.phone_outlined,
                            text: ownerLocalizeDigits(context, supplier.mobile),
                          ),
                        _InfoChip(
                          icon: Icons.badge_outlined,
                          text: l10n.ownerAddSupplierCrValue(
                            l10n.ownerSuppliersCr,
                            ownerLocalizeDigits(
                                context, supplier.crNumber ?? '–'),
                          ),
                        ),
                        _InfoChip(
                          icon: Icons.receipt_long_outlined,
                          text: l10n.ownerAddSupplierCrValue(
                            l10n.ownerSuppliersVat,
                            ownerLocalizeDigits(
                                context, supplier.vatId ?? '–'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SelectButton(selected: selected, linked: linked, onTap: () => onToggle(supplier)),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _WorkshopOnlySupplierForm extends StatelessWidget {
  final ScrollController scrollController;
  final bool isWide;
  final VoidCallback onBack;

  const _WorkshopOnlySupplierForm({
    required this.scrollController,
    required this.isWide,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DialogHeader(
          title: AppLocalizations.of(context)!.ownerAddSupplierWorkshopOnlyTitle,
          onClose: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            children: [
              _Form(isWide: isWide),
            ],
          ),
        ),
        _WorkshopOnlyFooter(onBack: onBack),
      ],
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _DialogHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h2.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F3F7),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 24, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final bool isWide;
  const _Form({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuppliersViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final mobile = _Field(
      label: l10n.ownerAddSupplierMobile,
      controller: vm.mobileController,
      keyboardType: TextInputType.phone,
    );
    final vatField = _Field(
      label: l10n.ownerAddSupplierVatNumber,
      controller: vm.vatNumberController,
      keyboardType: TextInputType.number,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(label: l10n.ownerAddSupplierName, hint: l10n.ownerAddSupplierCompanyHint, controller: vm.nameController),
        if (isWide)
          Row(children: [Expanded(child: mobile), const SizedBox(width: 14), Expanded(child: vatField)])
        else ...[
          mobile,
          vatField,
        ],
        _Field(label: l10n.ownerAddSupplierAddress, controller: vm.addressController),
        _Field(label: l10n.ownerAddSupplierNotes, controller: vm.notesController, maxLines: 3),
        const SizedBox(height: 8),
        Text(
          l10n.ownerAddSupplierWorkshopOnlyHint,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: maxLines > 1 ? 3 : 1,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight,
            ),
            decoration: _fieldDecoration(hint),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.secondaryLight,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }
}

InputDecoration _fieldDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
    filled: true,
    fillColor: const Color(0xFFFAFBFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.ownerAddSupplierSearchHint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
              icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
              onPressed: controller.clear,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}

class _WorkshopOnlyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WorkshopOnlyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: CustomButton(
        text: AppLocalizations.of(context)!.ownerAddSupplierWorkshopOnly,
        onPressed: onTap,
        backgroundColor: AppColors.secondaryLight,
        textColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        fontWeight: FontWeight.w800,
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PickerFooter extends StatelessWidget {
  final int selectedCount;
  final bool isLinking;
  final VoidCallback onCancel;
  final VoidCallback onAddSelected;

  const _PickerFooter({
    required this.selectedCount,
    required this.isLinking,
    required this.onCancel,
    required this.onAddSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: SafeArea(
        top: false,
        child: OwnerSheetActions(
          onCancel: onCancel,
          onPrimary: (selectedCount == 0 || isLinking) ? null : onAddSelected,
          isLoading: isLinking,
          cancelLabel: l10n.ownerCommonCancel,
          primaryLabel: l10n.ownerAddSupplierAddSelected(
            ownerLocalizeDigits(context, '$selectedCount'),
          ),
        ),
      ),
    );
  }
}

class _WorkshopOnlyFooter extends StatelessWidget {
  final VoidCallback onBack;
  const _WorkshopOnlyFooter({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuppliersViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: vm.isActionLoading ? null : onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryLight,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.secondaryLight.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.ownerAddSupplierBack,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: vm.isActionLoading
                      ? null
                      : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryLight,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.secondaryLight.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.ownerCommonCancel,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: vm.isActionLoading
                      ? null
                      : () => vm.submitWorkshopOnlySupplier(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.secondaryLight,
                    disabledBackgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: vm.isActionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondaryLight,
                          ),
                        )
                      : Text(
                          l10n.ownerAddSupplierAddToWorkshop,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
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

class _SelectButton extends StatelessWidget {
  final bool selected;
  final bool linked;
  final VoidCallback onTap;

  const _SelectButton({required this.selected, required this.linked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (linked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8EF),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          l10n.ownerAffiliatedLinked,
          style: const TextStyle(
            color: Color(0xFF27AE60),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          selected ? l10n.ownerAddSupplierSelected : l10n.ownerAddSupplierSelect,
          style: TextStyle(
            color: selected ? AppColors.secondaryLight : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  final String text;
  const _TableHead(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SupplierName extends StatelessWidget {
  final String name;
  const _SupplierName({required this.name});

  @override
  Widget build(BuildContext context) {
    return LocalizedApiText(
      name,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 14,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  const _CellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.secondaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w900,
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
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyRegisteredSuppliers extends StatelessWidget {
  final bool isFiltered;
  const _EmptyRegisteredSuppliers({this.isFiltered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            isFiltered
                ? AppLocalizations.of(context)!.ownerAddSupplierNoMatch
                : AppLocalizations.of(context)!.ownerAffiliatedNoRegistered,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}