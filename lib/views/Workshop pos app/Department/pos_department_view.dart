import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/department_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import '../Home Screen/pos_view_model.dart';
import '../Navbar/pos_shell.dart';
import 'department_view_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';

String _normalizeDeptKeyForExclude(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

class PosDepartmentView extends StatefulWidget {
  final List<String>? preSelectedProducts;
  final String? initialDepartmentId;

  /// When set, the primary action adds jobs to this existing walk-in draft (POST …/jobs) and pops.
  final String? addJobsToOrderId;

  /// Departments already represented on that order (by id or normalized name) — not selectable.
  final List<String> excludedDepartmentIds;
  final List<String> excludedNormalizedNameKeys;

  const PosDepartmentView({
    super.key,
    this.preSelectedProducts,
    this.initialDepartmentId,
    this.addJobsToOrderId,
    this.excludedDepartmentIds = const [],
    this.excludedNormalizedNameKeys = const [],
  });

  @override
  State<PosDepartmentView> createState() => _PosDepartmentViewState();
}

class _PosDepartmentViewState extends State<PosDepartmentView> {
  bool _autoSelectionDone = false;
  bool _placingOrder = false;

  bool _departmentExcluded(Department d) {
    if (widget.excludedDepartmentIds.contains(d.id)) return true;
    final k = _normalizeDeptKeyForExclude(d.name);
    return widget.excludedNormalizedNameKeys.contains(k);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentViewModel>().fetchDepartments();
    });
  }

  IconData _getIconForDepartment(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('oil')) return Icons.oil_barrel_outlined;
    if (lowerName.contains('wash')) return Icons.local_car_wash_outlined;
    if (lowerName.contains('repair')) return Icons.build_outlined;
    if (lowerName.contains('tyre')) return Icons.tire_repair_outlined;
    if (lowerName.contains('ac')) return Icons.ac_unit_outlined;
    if (lowerName.contains('inspect')) return Icons.search_outlined;
    if (lowerName.contains('detail')) return Icons.auto_awesome_outlined;
    if (lowerName.contains('battery')) return Icons.battery_charging_full_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final isAddToExisting =
        (widget.addJobsToOrderId ?? '').trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: PosScreenAppBar(
        title: isAddToExisting ? l10n.posDeptAddTitle : l10n.posDeptSelectTitle,
      ),
      body: Consumer<DepartmentViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _DepartmentsShimmerGrid(isTablet: isTablet);
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.posDeptRetry),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchDepartments(),
                    child: Text(l10n.posDeptRetry),
                  ),
                ],
              ),
            );
          }

          final departments = viewModel.departments;
          final preferredDepartmentId = isAddToExisting
              ? widget.initialDepartmentId
              : (widget.initialDepartmentId ??
              context.read<PosViewModel>().editDepartmentId);

          if (departments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  l10n.posCatalogSyncEmptyHint,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_autoSelectionDone &&
              preferredDepartmentId != null &&
              viewModel.selectedIndex == null) {
            final idx = departments.indexWhere((d) => d.id == preferredDepartmentId);
            if (idx != -1) {
              _autoSelectionDone = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<DepartmentViewModel>().setSelectedIndex(idx);
                }
              });
            }
          }

          return Column(
            children: [
              SizedBox(height: isTablet ? 8 : 6),

              // Department grid (shrink-wrap + scroll — avoids large empty gap under few cards)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
                  child: GridView.builder(
                    itemCount: departments.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 6 : 4,
                      childAspectRatio: isTablet ? 1.22 : 1.18,
                      crossAxisSpacing: isTablet ? 6 : 5,
                      mainAxisSpacing: isTablet ? 6 : 5,
                    ),
                    itemBuilder: (context, index) {
                      final dept = departments[index];
                      final isSelected = viewModel.selectedIndices.contains(index);
                      final excluded = _departmentExcluded(dept);

                      return GestureDetector(
                        onTap: excluded
                            ? () {
                          ToastService.showError(
                            context,
                            l10n.posDeptAlreadyOnOrder,
                          );
                        }
                            : () {
                          viewModel.toggleSelectedIndex(index);
                        },
                        child: AnimatedOpacity(
                          opacity: excluded ? 0.42 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              gradient: isSelected && !excluded
                                  ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryLight.withOpacity(0.15),
                                  AppColors.primaryLight.withOpacity(0.05),
                                ],
                              )
                                  : null,
                              borderRadius:
                              BorderRadius.circular(isTablet ? 14 : 12),
                              border: Border.all(
                                color: excluded
                                    ? Colors.grey.shade300
                                    : isSelected
                                    ? AppColors.primaryLight.withOpacity(0.6)
                                    : Colors.grey.shade200.withOpacity(0.8),
                                width: isSelected && !excluded ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected && !excluded
                                      ? AppColors.primaryLight.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: isSelected && !excluded ? 10 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : 8,
                                vertical: isTablet ? 4 : 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isTablet ? 7 : 6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForDepartment(dept.name),
                                      size: isTablet ? 22 : 18,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 6 : 5),
                                  LocalizedApiText(
                                    dept.name,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight:
                                      isSelected ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: isTablet ? 12 : 10,
                                      height: 1.15,
                                      color: isSelected
                                          ? AppColors.secondaryLight
                                          : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom Action
              if (viewModel.selectedIndices.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 24 : 16,
                    8,
                    isTablet ? 24 : 16,
                    isTablet ? 20 : 16,
                  ),
                  child: Column(
                    children: [
                      // Selected department info
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 14 : 12,
                          vertical: isTablet ? 8 : 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isTablet ? 5 : 4),
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForDepartment(
                                  viewModel.selectedDepartments.first.name,
                                ),
                                size: isTablet ? 14 : 12,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            SizedBox(width: isTablet ? 10 : 6),
                            LocalizedApiText(
                              viewModel.selectedIndices.length == 1
                                  ? viewModel.selectedDepartments.first.name
                                  : l10n.posDeptSelectedCount(viewModel.selectedIndices.length),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isTablet ? 13 : 12,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      SizedBox(height: isTablet ? 10 : 8),

                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 46 : 42,
                        child: _buildOrderPlacedButton(
                          context,
                          viewModel.selectedDepartments,
                          isTablet,
                          _placingOrder,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderPlacedButton(
      BuildContext context,
      List<Department> selectedDepartments,
      bool isTablet,
      bool isPlacing,
      ) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<PosViewModel>(
        builder: (context, posViewModel, child) {
          final selectedDeptIds = selectedDepartments.map((d) => d.id).toList();
          final busy = isPlacing || posViewModel.isLoading;
          final addToExistingOrderId = widget.addJobsToOrderId?.trim() ?? '';
          final isAddToExistingFlow = addToExistingOrderId.isNotEmpty;
          return ElevatedButton(
            onPressed: busy
                ? null
                : () async {
              if (isAddToExistingFlow) {
                final validIds = selectedDepartments
                    .where((d) => !_departmentExcluded(d))
                    .map((d) => d.id.trim())
                    .where((id) => id.isNotEmpty)
                    .toList();
                if (validIds.isEmpty) {
                  ToastService.showError(
                    context,
                    l10n.posDeptSelectAtLeastOne,
                  );
                  return;
                }
                setState(() => _placingOrder = true);
                try {
                  final ok = await posViewModel.addDepartmentsToWalkInOrder(
                    context,
                    addToExistingOrderId,
                    validIds,
                  );
                  if (!context.mounted || !ok) return;
                  Navigator.of(context).pop();
                } finally {
                  if (mounted) {
                    setState(() => _placingOrder = false);
                  }
                }
                return;
              }

              if (posViewModel.vehicleNumber
                  .trim()
                  .isEmpty) {
                ToastService.showError(
                  context,
                  l10n.posDeptVehicleRequired,
                );
                return;
              }

              setState(() => _placingOrder = true);
              try {
                if (posViewModel.editingOrder == null) {
                  final placed = await posViewModel.placeWalkInShellOrder(
                    selectedDeptIds,
                    context,
                  );
                  if (!context.mounted || !placed) return;
                }
                final createdOrderId = posViewModel.lastCreatedWalkInOrderId;

                final previousDeptId = posViewModel.editDepartmentId;
                final isDeptChanged =
                    posViewModel.editingOrder != null &&
                        previousDeptId != null &&
                        previousDeptId.isNotEmpty &&
                        !selectedDeptIds.contains(previousDeptId);

                if (isDeptChanged) {
                  final shouldContinue = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) {
                      final w = MediaQuery
                          .of(dialogCtx)
                          .size
                          .width;
                      final isDialogTablet = w > 600;
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        insetPadding: EdgeInsets.symmetric(
                          horizontal: isDialogTablet ? w * 0.28 : 24,
                          vertical: 24,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isDialogTablet ? 28 : 22,
                            isDialogTablet ? 24 : 20,
                            isDialogTablet ? 28 : 22,
                            isDialogTablet ? 22 : 18,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.posDeptChangeDeptTitle,
                                style: AppTextStyles.h3.copyWith(
                                  fontSize: isDialogTablet ? 26 : 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.posDeptChangeDeptBody,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey.shade800,
                                  fontSize: isDialogTablet ? 17 : 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.posDeptChangeDeptRefresh,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: isDialogTablet ? 16 : 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          () => Navigator.pop(dialogCtx, false),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isDialogTablet ? 16 : 13,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.posDeptChangeDeptCancel,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w700,
                                          fontSize: isDialogTablet ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(dialogCtx, true),
                                      style: ElevatedButton.styleFrom(
                                        overlayColor: Colors.transparent,
                                        backgroundColor: AppColors.primaryLight,
                                        foregroundColor: AppColors.secondaryLight,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isDialogTablet ? 16 : 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.posDeptChangeDeptContinue,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: isDialogTablet ? 16 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (shouldContinue != true) return;

                  // Reset current invoice/cart state so user can rebuild
                  // order against the newly selected department.
                  posViewModel.clearCart(isMainTab: false);
                }

                if (!context.mounted) return;
                await posViewModel.refreshOrdersAfterPlacement(
                  preferredOrderId: createdOrderId,
                );
                if (!context.mounted) return;
                navigateToPosShellOrdersTab(context);
              } finally {
                if (mounted) {
                  setState(() => _placingOrder = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.secondaryLight,
              overlayColor: Colors.transparent,
              disabledBackgroundColor: AppColors.primaryLight,
              disabledForegroundColor: AppColors.secondaryLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              ),
            ),
            child: busy
                ? const _DepartmentButtonShimmer()
                : Text(
              isAddToExistingFlow ? l10n.posDeptAddToOrder : l10n.posDeptOrderPlaced,
              style: AppTextStyles.button.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          );
        } );
  }
}

class _DepartmentsShimmerGrid extends StatelessWidget {
  const _DepartmentsShimmerGrid({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(isTablet ? 12 : 8, isTablet ? 8 : 6, isTablet ? 12 : 8, 20),
      child: GridView.builder(
        itemCount: isTablet ? 18 : 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 6 : 4,
          childAspectRatio: isTablet ? 1.22 : 1.18,
          crossAxisSpacing: isTablet ? 6 : 5,
          mainAxisSpacing: isTablet ? 6 : 5,
        ),
        itemBuilder: (_, __) => const _DepartmentCardShimmer(),
      ),
    );
  }
}

class _DepartmentCardShimmer extends StatelessWidget {
  const _DepartmentCardShimmer();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: const PosShimmer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PosShimmerBox(width: 40, height: 40, radius: 20),
              SizedBox(height: 8),
              PosShimmerBox(width: 64, height: 9, radius: 5),
              SizedBox(height: 5),
              PosShimmerBox(width: 48, height: 9, radius: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentButtonShimmer extends StatelessWidget {
  const _DepartmentButtonShimmer();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryLight),
      ),
    );
  }
}
