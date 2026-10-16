import 'package:flutter/material.dart';
import '../../../services/currency_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import 'package:provider/provider.dart';

import '../../../models/department_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../Home Screen/pos_view_model.dart';
import '../Product Grid/pos_product_grid_view.dart';
import '../Technician Assignment/pos_technician_assignment_view.dart';

class PosYourJobsView extends StatefulWidget {
  const PosYourJobsView({
    super.key,
    required this.selectedDepartments,
  });

  final List<Department> selectedDepartments;

  @override
  State<PosYourJobsView> createState() => _PosYourJobsViewState();
}

class _PosYourJobsViewState extends State<PosYourJobsView> {
  late List<Department> _departments;

  @override
  void initState() {
    super.initState();
    _departments = List<Department>.from(widget.selectedDepartments);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: PosScreenAppBar(
        title: AppLocalizations.of(context)!.posYourJobsTitle,
        showBackButton: true,
        showHamburger: false,
      ),
      body: Consumer<PosViewModel>(
        builder: (context, vm, _) {
          if (_departments.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.posYourJobsNoDepartments));
          }

          if (isTablet) {
            return Row(
              children: [
                Expanded(
                  child: _DepartmentJobsList(
                    selectedDepartments: _departments,
                    onRemoveDepartment: (deptId) {
                      setState(() {
                        _departments.removeWhere((d) => d.id == deptId);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 460,
                  child: _DepartmentWiseInvoicePanel(
                    selectedDepartments: _departments,
                    vm: vm,
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 250,
                child: _DepartmentWiseInvoicePanel(
                  selectedDepartments: _departments,
                  vm: vm,
                ),
              ),
              Expanded(
                child: _DepartmentJobsList(
                  selectedDepartments: _departments,
                  onRemoveDepartment: (deptId) {
                    setState(() {
                      _departments.removeWhere((d) => d.id == deptId);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DepartmentWiseInvoicePanel extends StatelessWidget {
  const _DepartmentWiseInvoicePanel({
    required this.selectedDepartments,
    required this.vm,
  });

  final List<Department> selectedDepartments;
  final PosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cart = vm.cartItems;
    final rows = selectedDepartments.map((dept) {
      final deptItems = cart
          .where((i) => (i.product.departmentId ?? '') == dept.id)
          .toList();
      final gross = deptItems.fold<double>(0, (s, i) => s + i.lineSubtotalGross);
      final discount = deptItems.fold<double>(0, (s, i) => s + i.actualDiscountAmount);
      final taxable = (gross - discount).clamp(0, double.infinity).toDouble();
      final vat = taxable * 0.15;
      final total = taxable + vat;
      return (name: dept.name, count: deptItems.length, total: total);
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.posYourJobsDeptInvoiceTitle,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedApiText(
                              row.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLocalizations.of(context)!.posYourJobsItems(row.count),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyHelper.format(context, row.total),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.posYourJobsGrandTotal,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                CurrencyHelper.format(context, vm.getTotalAmountValue(false)),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.posYourJobsSaveDraft,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.secondaryLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.posYourJobsPlaceOrder,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepartmentJobsList extends StatelessWidget {
  const _DepartmentJobsList({
    required this.selectedDepartments,
    required this.onRemoveDepartment,
  });

  final List<Department> selectedDepartments;
  final void Function(String departmentId) onRemoveDepartment;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      itemCount: selectedDepartments.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: isTablet ? 130 : 148,
      ),
      itemBuilder: (context, index) {
        final dept = selectedDepartments[index];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedApiText(
                    dept.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PosTechnicianAssignmentView(
                                  jobId: '',
                                  departmentName: dept.name,
                                  departmentId: dept.id,
                                  isWalkIn: true,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryLight,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context)!.posYourJobsAssignTechnicians,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PosProductGridView(
                                  departmentName: dept.name,
                                  departmentId: dept.id,
                                  selectedDepartmentIds: [dept.id],
                                  selectedDepartmentNames: [dept.name],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.secondaryLight,
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context)!.posYourJobsAddInventory,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: GestureDetector(
                onTap: () => onRemoveDepartment(dept.id),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

