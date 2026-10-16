import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../widgets/owner_sheet_actions.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'owner_promo_view_model.dart';

/// Bottom sheet used to create or edit a Promo Code.
/// Designed mobile-first: stacks fields vertically, uses the app's
/// existing color theme (AppColors.primaryLight / secondaryLight),
/// and avoids any horizontal overflow on small screens.
class PromoCreateSheet extends StatelessWidget {
  const PromoCreateSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: context.read<OwnerPromoViewModel>(),
        child: const PromoCreateSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OwnerPromoViewModel>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          _SheetHeader(vm: vm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              children: [
                _SectionLabel(
                  title: 'Promo details',
                  subtitle: 'Code, discount and optional description.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _LabeledField(
                        label: 'PROMO CODE *',
                        child: _PromoTextField(
                          controller: vm.codeController,
                          hint: 'e.g. SAVE20',
                          icon: Icons.confirmation_number_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _LabeledField(
                        label: 'STATUS',
                        child: _StatusDropdown(vm: vm),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'DISCOUNT TYPE *',
                  child: _DiscountTypeToggle(vm: vm),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'DISCOUNT VALUE *',
                  child: _PromoTextField(
                    controller: vm.discountValueController,
                    hint: vm.discountType == 'percent' ? 'e.g. 10 (%)' : 'e.g. 50 (SAR)',
                    icon: Icons.percent_rounded,
                    isNumber: true,
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'DESCRIPTION',
                  child: _PromoTextField(
                    controller: vm.descriptionController,
                    hint: 'Optional internal note',
                    icon: Icons.notes_rounded,
                    maxLines: 2,
                  ),
                ),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 18),

                _SectionLabel(
                  title: 'Validity & limits',
                  subtitle: 'When the promo is valid and how often it can be used.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'VALID FROM *',
                        child: _DatePickerField(controller: vm.validFromController, hint: 'dd/mm/yyyy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: 'VALID TO *',
                        child: _DatePickerField(controller: vm.validToController, hint: 'dd/mm/yyyy'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'USAGE LIMIT',
                        child: _PromoTextField(
                          controller: vm.usageLimitController,
                          hint: 'Unlimited',
                          icon: Icons.repeat_rounded,
                          isNumber: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabeledField(
                        label: 'MIN ORDER (SAR)',
                        child: _PromoTextField(
                          controller: vm.minOrderAmountController,
                          hint: 'Optional',
                          icon: Icons.shopping_basket_rounded,
                          isNumber: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 18),

                _SectionLabel(
                  title: 'Where this promo applies',
                  subtitle: 'Set branches, then choose for products and services: all, specific, or none.',
                ),
                const SizedBox(height: 12),

                _LabeledField(
                  label: 'BRANCHES *',
                  child: _ScopeToggle(
                    options: const ['All branches', 'Selected branches'],
                    values: const ['all', 'selected'],
                    selected: vm.branchesMode,
                    onChanged: vm.setBranchesMode,
                  ),
                ),
                if (vm.branchesMode == 'selected') ...[
                  const SizedBox(height: 10),
                  _SelectableList(
                    emptyLabel: 'No branches available',
                    items: const [
                      _PickItem(id: 'main', label: 'Main Branch'),
                    ],
                    selectedIds: vm.selectedBranchIds,
                    onToggle: vm.toggleBranch,
                  ),
                ] else
                  _HintText('Promo applies to all active branches.'),

                const SizedBox(height: 18),

                _LabeledField(
                  label: 'PRODUCTS',
                  child: _ScopeToggle(
                    options: const ['All', 'Specific only', 'Does not apply'],
                    values: const ['all', 'specific', 'none'],
                    selected: vm.productsMode,
                    onChanged: vm.setProductsMode,
                  ),
                ),
                if (vm.productsMode == 'specific') ...[
                  const SizedBox(height: 10),
                  _SearchableSelectableList(
                    hint: 'Search products...',
                    emptyLabel: 'No products found',
                    items: const [
                      _PickItem(id: 'p1', label: 'AC DELCO 0W20'),
                      _PickItem(id: 'p2', label: 'AC DELCO 5W30'),
                      _PickItem(id: 'p3', label: 'AC DELCO oil filter 504'),
                      _PickItem(id: 'p4', label: 'AC FILTER TOYOTA 12010'),
                      _PickItem(id: 'p5', label: 'AC Filter 4H000'),
                      _PickItem(id: 'p6', label: 'AC Filter 97133-1C000'),
                      _PickItem(id: 'p7', label: 'AC FILTER ACCENT 2E210'),
                    ],
                    selectedIds: vm.selectedProductIds,
                    onToggle: vm.toggleProduct,
                  ),
                ],

                const SizedBox(height: 18),

                _LabeledField(
                  label: 'SERVICES',
                  child: _ScopeToggle(
                    options: const ['All', 'Specific only', 'Does not apply'],
                    values: const ['all', 'specific', 'none'],
                    selected: vm.servicesMode,
                    onChanged: vm.setServicesMode,
                  ),
                ),
                if (vm.servicesMode == 'specific') ...[
                  const SizedBox(height: 10),
                  _SearchableSelectableList(
                    hint: 'Search services...',
                    emptyLabel: 'No services found',
                    items: const [
                      _PickItem(id: 's1', label: 'CAR INSPECTION'),
                      _PickItem(id: 's2', label: 'CHANGE FILTER SERVICE B2B'),
                      _PickItem(id: 's3', label: 'CHANGE OIL AND FILTER THE CUSTOMER'),
                      _PickItem(id: 's4', label: 'CHANGE OIL BRAKES SERVICE'),
                      _PickItem(id: 's5', label: 'CHANGE OIL SERVICE FROM CUSTOMER'),
                      _PickItem(id: 's6', label: 'CHANGE OIL SERVICES'),
                    ],
                    selectedIds: vm.selectedServiceIds,
                    onToggle: vm.toggleService,
                  ),
                ],
              ],
            ),
          ),
          _SheetFooter(vm: vm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 40,
        height: 5,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final OwnerPromoViewModel vm;
  const _SheetHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              vm.isEditing ? 'Edit Promo Code' : 'Create Promo Code',
              style: AppTextStyles.h2.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h2.copyWith(fontSize: 15, color: AppColors.secondaryLight)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5), softWrap: true),
      ],
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PromoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isNumber;
  final int maxLines;

  const _PromoTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isNumber = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.secondaryLight, size: 19),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _DatePickerField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 730)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primaryLight,
                  onPrimary: AppColors.secondaryLight,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.secondaryLight, size: 18),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final OwnerPromoViewModel vm;
  const _StatusDropdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    return OwnerStyledDropdown<String>(
      value: vm.status,
      hint: 'Status',
      height: 48,
      backgroundColor: Colors.grey.withOpacity(0.06),
      options: const [
        OwnerDropdownOption(value: 'active', label: 'Active'),
        OwnerDropdownOption(value: 'inactive', label: 'Inactive'),
      ],
      onChanged: (v) {
        if (v != null) vm.setStatus(v);
      },
      triggerStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

class _DiscountTypeToggle extends StatelessWidget {
  final OwnerPromoViewModel vm;
  const _DiscountTypeToggle({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Fixed (SAR)',
            selected: vm.discountType == 'fixed',
            onTap: () => vm.setDiscountType('fixed'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleChip(
            label: 'Percentage (%)',
            selected: vm.discountType == 'percent',
            onTap: () => vm.setDiscountType('percent'),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: selected ? AppColors.secondaryLight : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Generic 2-3 way scope selector (All / Specific / None, or All / Selected)
/// rendered as wrap-friendly chips so it never overflows on narrow screens.
class _ScopeToggle extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ScopeToggle({
    required this.options,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final isSelected = values[i] == selected;
        return GestureDetector(
          onTap: () => onChanged(values[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.grey.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryLight : Colors.grey.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 15,
                  color: isSelected ? AppColors.secondaryLight : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.secondaryLight : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _PickItem {
  final String id;
  final String label;
  const _PickItem({required this.id, required this.label});
}

/// Simple checkbox list for small fixed sets (e.g. branches).
class _SelectableList extends StatelessWidget {
  final List<_PickItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final String emptyLabel;

  const _SelectableList({
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(emptyLabel, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: items.map((item) {
          final checked = selectedIds.contains(item.id);
          return CheckboxListTile(
            value: checked,
            onChanged: (_) => onToggle(item.id),
            title: Text(
              item.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryLight,
            checkColor: AppColors.secondaryLight,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          );
        }).toList(),
      ),
    );
  }
}

/// Checkbox list with a search field and a scrollable, height-limited
/// container so long product/service lists never overflow the sheet.
class _SearchableSelectableList extends StatefulWidget {
  final List<_PickItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final String hint;
  final String emptyLabel;

  const _SearchableSelectableList({
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    required this.hint,
    required this.emptyLabel,
  });

  @override
  State<_SearchableSelectableList> createState() => _SearchableSelectableListState();
}

class _SearchableSelectableListState extends State<_SearchableSelectableList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((i) => i.label.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 18),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.selectedIds.length} selected',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondaryLight),
              ),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxHeight: 230),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: filtered.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(widget.emptyLabel, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              final checked = widget.selectedIds.contains(item.id);
              return CheckboxListTile(
                value: checked,
                onChanged: (_) => widget.onToggle(item.id),
                title: Text(
                  item.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primaryLight,
                checkColor: AppColors.secondaryLight,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SheetFooter extends StatelessWidget {
  final OwnerPromoViewModel vm;
  const _SheetFooter({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: OwnerSheetActions(
        onCancel: () => Navigator.pop(context),
        onPrimary:
            vm.isActionLoading ? null : () => vm.submitPromoCode(context),
        isLoading: vm.isActionLoading,
        primaryLabel: vm.isEditing ? 'Update Promo' : 'Create Promo',
      ),
    );
  }
}