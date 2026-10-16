// ─── master_catalog_add_to_branches_sheet.dart ───────────────────────────────
// Bottom sheet for "Add Selected to branches…"
// — departments: branch scope + per-dept category picker
// — categories/services: branch scope + "also adding" yellow banner
// — products: branch scope + "also adding" yellow banner + critical stock table

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../widgets/owner_sheet_actions.dart';
import 'master_catalog_shared.dart';
import 'master_catalog_view_model.dart';

enum AddSheetType { departments, categories, products, services }

class AddToBranchesSheet extends StatefulWidget {
  final AddSheetType type;
  final List<String> selectedIds;

  const AddToBranchesSheet({
    super.key,
    required this.type,
    required this.selectedIds,
  });

  @override
  State<AddToBranchesSheet> createState() => _AddToBranchesSheetState();
}

class _AddToBranchesSheetState extends State<AddToBranchesSheet> {
  BranchScope _scope = BranchScope.specific;
  final Set<String> _selectedBranchIds = {};
  final Map<String, DeptCategorySelection> _deptCatMap = {};

  // Critical stock per product id
  final Map<String, int> _criticalStockMap = {};
  final TextEditingController _applyAllController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<MasterCatalogViewModel>();
    if (vm.branches.isNotEmpty) {
      _selectedBranchIds.add(vm.branches.first.id);
    }
    if (widget.type == AddSheetType.departments) {
      for (final id in widget.selectedIds) {
        _deptCatMap[id] = DeptCategorySelection();
      }
    }
    if (widget.type == AddSheetType.products) {
      for (final id in widget.selectedIds) {
        _criticalStockMap[id] = 0;
      }
    }
  }

  @override
  void dispose() {
    _applyAllController.dispose();
    super.dispose();
  }

  String get _title {
    final n = widget.selectedIds.length;
    switch (widget.type) {
      case AddSheetType.departments:
        return 'Add $n department${n != 1 ? 's' : ''} to your workshop';
      case AddSheetType.categories:
        return 'Add $n categor${n != 1 ? 'ies' : 'y'} to your workshop';
      case AddSheetType.products:
        return 'Add $n product${n != 1 ? 's' : ''} to your workshop';
      case AddSheetType.services:
        return 'Add $n service${n != 1 ? 's' : ''} to your workshop';
    }
  }

  Future<void> _confirm(MasterCatalogViewModel vm) async {
    setState(() => _isLoading = true);
    final branchIds = _selectedBranchIds.toList();

    switch (widget.type) {
      case AddSheetType.departments:
        await vm.addDeptsToWorkshop(
          scope: _scope,
          branchIds: branchIds,
          deptCategoryMap: _deptCatMap,
        );
        break;
      case AddSheetType.categories:
        await vm.addCategoriesToWorkshop(
          scope: _scope,
          branchIds: branchIds,
        );
        break;
      case AddSheetType.products:
        await vm.addProductsToWorkshop(
          scope: _scope,
          branchIds: branchIds,
          criticalStockMap: _criticalStockMap,
          openingQtyMap: {},
        );
        break;
      case AddSheetType.services:
        await vm.addServicesToWorkshop(
          scope: _scope,
          branchIds: branchIds,
        );
        break;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MasterCatalogViewModel>();
    final isDept = widget.type == AddSheetType.departments;
    final isProduct = widget.type == AddSheetType.products;
    final isService = widget.type == AddSheetType.services;

    // Resolve "also adding" deps/cats from the ViewModel's pre-fetched preview.
    // previewProductDeps / previewServiceDeps are called before the sheet opens.
    final alsoAddingDepts = isProduct
        ? vm.productDepsMissingDepts
        : isService
        ? vm.serviceDepsMissingDepts
        : <String>[];
    final alsoAddingCats = isProduct
        ? vm.productDepsMissingCats
        : isService
        ? vm.serviceDepsMissingCats
        : <String>[];
    final showAlsoBanner =
        alsoAddingDepts.isNotEmpty || alsoAddingCats.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(
                      color: AppColors.secondaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── "Also adding" yellow banner ───────────────────────
                  if (showAlsoBanner)
                    _AlsoBanner(
                      depts: alsoAddingDepts,
                      cats: alsoAddingCats,
                    ),
                  if (showAlsoBanner) const SizedBox(height: 12),

                  // ── Hint for departments ──────────────────────────────
                  if (isDept) ...[
                    Text(
                      'Parent departments will be auto-adopted to the same branches if needed.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Branch scope ──────────────────────────────────────
                  _SectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add to which branches?',
                          style: TextStyle(
                            color: AppColors.secondaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _RadioRow(
                          label: 'All branches in this workshop',
                          value: BranchScope.all,
                          groupValue: _scope,
                          onChanged: (v) => setState(() => _scope = v!),
                        ),
                        _RadioRow(
                          label: 'Specific branches',
                          value: BranchScope.specific,
                          groupValue: _scope,
                          onChanged: (v) => setState(() => _scope = v!),
                        ),
                        if (_scope == BranchScope.specific)
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 20, top: 4),
                            child: Column(
                              children: vm.branches
                                  .map((b) => _CheckboxRow(
                                label: b.name,
                                value: _selectedBranchIds
                                    .contains(b.id),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selectedBranchIds.add(b.id);
                                  } else {
                                    _selectedBranchIds
                                        .remove(b.id);
                                  }
                                }),
                              ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Dept → category picker (departments flow) ─────────
                  if (isDept) ...[
                    const SizedBox(height: 12),
                    _PickCategoriesSection(
                      selectedDeptIds: widget.selectedIds,
                      departments: vm.departments,
                      categories: vm.categories,
                      deptCatMap: _deptCatMap,
                      onChanged: () => setState(() {}),
                    ),
                  ],

                  // ── Critical stock table (products only) ──────────────
                  if (isProduct) ...[
                    const SizedBox(height: 12),
                    _CriticalStockSection(
                      productIds: widget.selectedIds,
                      products: vm.products,
                      stockMap: _criticalStockMap,
                      applyAllController: _applyAllController,
                      onChanged: () => setState(() {}),
                    ),
                  ],

                  // ── Items being added footer text ─────────────────────
                  const SizedBox(height: 10),
                  _ItemsFooter(type: widget.type, vm: vm, ids: widget.selectedIds),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Bottom buttons ─────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: OwnerSheetActions(
              onCancel: () => Navigator.pop(context),
              onPrimary: _isLoading ? null : () => _confirm(vm),
              isLoading: _isLoading,
              primaryLabel: 'Confirm',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Also Banner ─────────────────────────────────────────────────────────────

class _AlsoBanner extends StatelessWidget {
  final List<String> depts;
  final List<String> cats;

  const _AlsoBanner({required this.depts, required this.cats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We will also add the following so the items fit in your workshop:',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (depts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Departments (${depts.length})',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            ...depts.map((d) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(d,
                  style: const TextStyle(
                      color: Color(0xFF78350F), fontSize: 12)),
            )),
          ],
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Categories (${cats.length})',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            ...cats.map((c) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(c,
                  style: const TextStyle(
                      color: Color(0xFF78350F), fontSize: 12)),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Critical Stock Section ───────────────────────────────────────────────────

class _CriticalStockSection extends StatelessWidget {
  final List<String> productIds;
  final List<MasterProduct> products;
  final Map<String, int> stockMap;
  final TextEditingController applyAllController;
  final VoidCallback onChanged;

  const _CriticalStockSection({
    required this.productIds,
    required this.products,
    required this.stockMap,
    required this.applyAllController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critical stock (per product, per branch)',
            style: TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Optional alert threshold when each branch adopts. Leave blank for 0.',
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Apply all row
          Row(
            children: [
              Text(
                'Apply to all rows',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: applyAllController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.secondaryLight),
                  decoration: InputDecoration(
                    hintText: 'Critical',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.primaryLight, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  final v = int.tryParse(applyAllController.text) ?? 0;
                  for (final id in productIds) {
                    stockMap[id] = v;
                  }
                  onChanged();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Product',
                    style: TextStyle(
                      color: AppColors.secondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 110,
                  child: Text(
                    'Critical Stock',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product rows
          ...productIds.map((id) {
            final p = products.firstWhere((p) => p.id == id,
                orElse: () => MasterProduct(
                    id: id,
                    name: 'Product $id',
                    sku: '',
                    categoryName: '',
                    unit: '',
                    salePrice: 0,
                    purchasePrice: 0,
                    openingQty: 0,
                    criticalStockPoint: 0,
                    isActive: true));
            return _StockRow(
              product: p,
              value: stockMap[id] ?? 0,
              onChanged: (v) {
                stockMap[id] = v;
                onChanged();
              },
            );
          }),
        ],
      ),
    );
  }
}

class _StockRow extends StatefulWidget {
  final MasterProduct product;
  final int value;
  final ValueChanged<int> onChanged;

  const _StockRow({
    required this.product,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_StockRow> createState() => _StockRowState();
}

class _StockRowState extends State<_StockRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value == 0 ? '' : widget.value.toString());
  }

  @override
  void didUpdateWidget(_StockRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text =
      widget.value == 0 ? '' : widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.product.name,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.secondaryLight),
              onChanged: (v) =>
                  widget.onChanged(int.tryParse(v) ?? 0),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primaryLight, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Items Footer ─────────────────────────────────────────────────────────────

class _ItemsFooter extends StatelessWidget {
  final AddSheetType type;
  final MasterCatalogViewModel vm;
  final List<String> ids;

  const _ItemsFooter(
      {required this.type, required this.vm, required this.ids});

  @override
  Widget build(BuildContext context) {
    String text = '';
    switch (type) {
      case AddSheetType.products:
        final names = ids.map((id) {
          final p = vm.products.firstWhere((p) => p.id == id,
              orElse: () => const MasterProduct(
                  id: '',
                  name: '',
                  sku: '',
                  categoryName: '',
                  unit: '',
                  salePrice: 0,
                  purchasePrice: 0,
                  openingQty: 0,
                  criticalStockPoint: 0,
                  isActive: true));
          return p.name;
        }).where((n) => n.isNotEmpty).join(', ');
        text = 'Products being added: $names.';
        break;
      case AddSheetType.services:
        final names = ids.map((id) {
          final s = vm.services.firstWhere((s) => s.id == id,
              orElse: () => const MasterService(
                  id: '',
                  name: '',
                  departmentName: '',
                  categoryName: '',
                  isActive: true));
          return s.name;
        }).where((n) => n.isNotEmpty).join(', ');
        text = 'Services being added: $names.';
        break;
      default:
        return const SizedBox.shrink();
    }
    return Text(
      text,
      style:
      TextStyle(color: Colors.grey.shade500, fontSize: 11),
    );
  }
}

// ─── Pick Categories Per Department ──────────────────────────────────────────

class _PickCategoriesSection extends StatelessWidget {
  final List<String> selectedDeptIds;
  final List<MasterDepartment> departments;
  final List<MasterCategory> categories;
  final Map<String, DeptCategorySelection> deptCatMap;
  final VoidCallback onChanged;

  const _PickCategoriesSection({
    required this.selectedDeptIds,
    required this.departments,
    required this.categories,
    required this.deptCatMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick categories for each department',
          style: TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'For each department you selected, choose which categories should be added.',
          style:
          TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        const SizedBox(height: 10),
        ...selectedDeptIds.map((deptId) {
          final dept = departments.firstWhere((d) => d.id == deptId,
              orElse: () =>
              const MasterDepartment(id: '', name: 'Unknown'));
          final deptCats =
          categories.where((c) => c.departmentName == dept.name).toList();
          final sel = deptCatMap[deptId] ?? DeptCategorySelection();
          return _DeptCategoryPicker(
            dept: dept,
            categories: deptCats,
            selection: sel,
            onChanged: onChanged,
          );
        }),
      ],
    );
  }
}

class _DeptCategoryPicker extends StatelessWidget {
  final MasterDepartment dept;
  final List<MasterCategory> categories;
  final DeptCategorySelection selection;
  final VoidCallback onChanged;

  const _DeptCategoryPicker({
    required this.dept,
    required this.categories,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dept.name,
              style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _RadioRow(
                    label: 'All categories',
                    value: CategoryMode.all,
                    groupValue: selection.mode,
                    onChanged: (v) {
                      selection.mode = v!;
                      onChanged();
                    },
                  )),
              Expanded(
                  child: _RadioRow(
                    label: 'Pick categories',
                    value: CategoryMode.pick,
                    groupValue: selection.mode,
                    onChanged: (v) {
                      selection.mode = v!;
                      onChanged();
                    },
                  )),
              Expanded(
                  child: _RadioRow(
                    label: 'No categories\n(department only)',
                    value: CategoryMode.none,
                    groupValue: selection.mode,
                    onChanged: (v) {
                      selection.mode = v!;
                      onChanged();
                    },
                  )),
            ],
          ),
          if (selection.mode == CategoryMode.pick && categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: categories.map((cat) {
                final checked =
                selection.pickedCategoryIds.contains(cat.id);
                return InkWell(
                  onTap: () {
                    if (checked) {
                      selection.pickedCategoryIds.remove(cat.id);
                    } else {
                      selection.pickedCategoryIds.add(cat.id);
                    }
                    onChanged();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Checkbox(
                          value: checked,
                          onChanged: (_) {
                            if (checked) {
                              selection.pickedCategoryIds
                                  .remove(cat.id);
                            } else {
                              selection.pickedCategoryIds.add(cat.id);
                            }
                            onChanged();
                          },
                          activeColor: const Color(0xFF6B3FA0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3)),
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Text(cat.name,
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Small Shared Widgets ─────────────────────────────────────────────────────

class _SectionBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;

  const _SectionBox(
      {required this.child, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioRow(
      {required this.label,
        required this.value,
        required this.groupValue,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.85,
            child: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF6B3FA0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: value == groupValue
                    ? AppColors.secondaryLight
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: value == groupValue
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxRow(
      {required this.label,
        required this.value,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.85,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF6B3FA0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: value ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}