import 'package:flutter/material.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/owner_perm_l10n.dart';
import 'package:provider/provider.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import 'employee_management_view_model.dart';
import '../Reports/reports_search_bar.dart';
import '../Departments/branch_catalog_shared.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/reusable_data_table.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_segmented_tabs.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shimmer.dart';
import '../owner_shell.dart';
import '../widgets/add_button_fab.dart';
import '../widgets/owner_sheet_actions.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'roles_sheet.dart';

// ─── Dummy data for roles, commission types ──────────────────────────────────

const _kRoles = [
  'cashier',
  'staff',
  'technician',
  'supervisor',
  'manager',
  'team leader',
  'locker supervisor',
  'locker collector',
];

const _kCommissionTypes = [
  '% of Revenue',
  '% of Service',
  '% of Profit',
  'Fixed per Order',
];

// ─────────────────────────────────────────────────────────────────────────────
// EmployeeManagementView
// ─────────────────────────────────────────────────────────────────────────────

/// Employee Management screen — Employees + Roles tabs.
class EmployeeManagementView extends StatefulWidget {
  const EmployeeManagementView({super.key});

  @override
  State<EmployeeManagementView> createState() => _EmployeeManagementViewState();
}

class _EmployeeManagementViewState extends State<EmployeeManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<EmployeeManagementViewModel>(
      builder: (context, vm, _) {
        final showBack = OwnerShell.openedWithBack(context);
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: OwnerDashboardTitle(subtitle: l10n.ownerEmployeesTitle),
            showBackButton: showBack,
            showDrawer: !showBack,
            showNotification: true,
            onBackPressed:
                showBack ? () => OwnerShell.goHome(context) : null,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
            onMenuPressed: () => OwnerShell.openDrawer(context),
          ),
          floatingActionButton: _buildFab(vm),
          body: vm.isLoading
              ? const _EmployeesPageShimmer()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Selector<EmployeeManagementViewModel,
                              (int, int, int)>(
                            selector: (_, vm) => (
                              vm.totalStaff,
                              vm.onWorkshopDutyCount,
                              vm.onCallCount,
                            ),
                            builder: (context, data, _) {
                              final (total, onDuty, onCall) = data;
                              return ReusableKpiGrid(
                                layout: KpiGridLayout.singleRow,
                                metrics: [
                                  ReusableKpiMetric(
                                    title: l10n.ownerEmployeesKpiTotalStaff,
                                    value: ownerLocalizeDigits(context, '$total'),
                                    icon: Icons.people_alt_rounded,
                                    accentColor: AppColors.primaryLight,
                                  ),
                                  ReusableKpiMetric(
                                    title: l10n.ownerEmployeesKpiOnDuty,
                                    value: ownerLocalizeDigits(context, '$onDuty'),
                                    icon: Icons.engineering_rounded,
                                    accentColor: AppColors.primaryLight,
                                  ),
                                  ReusableKpiMetric(
                                    title: l10n.ownerEmployeesKpiOnCall,
                                    value: ownerLocalizeDigits(context, '$onCall'),
                                    icon: Icons.phone_in_talk_rounded,
                                    accentColor: AppColors.primaryLight,
                                  ),
                                ],
                                showFeatured: false,
                                iconOnTop: true,
                                mainAxisExtent: 108,
                                singleRowCardWidth: 112,
                                padding: EdgeInsets.zero,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          OwnerSegmentedTabs(
                            controller: _tabController,
                            tabs: [
                              l10n.ownerEmployeesTabEmployees,
                              l10n.ownerEmployeesTabRoles,
                            ],
                            layout: PosSegmentedTabLayout.expanded,
                            padding: EdgeInsets.zero,
                            counts: [
                              vm.totalStaff,
                              vm.roles.length,
                            ],
                          ),
                          if (_currentTab == 0) ...[
                            const SizedBox(height: 10),
                            ReportsSearchBar(
                              hint: l10n.ownerEmployeesSearchHint,
                              onChanged: vm.updateSearchQuery,
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          RefreshIndicator(
                            onRefresh: () => vm.fetchEmployees(),
                            color: AppColors.primaryLight,
                            child: _buildEmployeeList(context, vm),
                          ),
                          const RolesTabContent(),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFab(EmployeeManagementViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    if (_currentTab == 1) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab-role'),
        onPressed: () => RolesTabContent.openCreateRole(context, vm),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.secondaryLight,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.ownerEmployeesCreateRole,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }
    return AppFabSheetButton<EmployeeManagementViewModel>(
      key: const ValueKey('fab-employee'),
      label: l10n.ownerEmployeesAddEmployee,
      icon: Icons.add_rounded,
      viewModel: vm,
      onClear: vm.clearForm,
      sheetBuilder: (context, vm) => const _AddEmployeeSheet(),
    );
  }
}

/// Scrollable employee list only — KPIs / search stay fixed above.
Widget _buildEmployeeList(
    BuildContext context, EmployeeManagementViewModel vm) {
  final employees = _EmployeeSection.getEmployees(vm);

  if (employees.isEmpty) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _EmptyState(
          isFiltered: vm.searchQuery.isNotEmpty,
          onClearSearch: () => vm.updateSearchQuery(''),
        ),
      ],
    );
  }

  final isWide = MediaQuery.of(context).size.width > 700;

  if (isWide) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _WideTable(vm: vm, employees: employees),
      ],
    );
  }

  return ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
    itemCount: employees.length,
    itemBuilder: (ctx, i) =>
        _MobileEmployeeCard(employee: employees[i], vm: vm),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Employee table section
// ─────────────────────────────────────────────────────────────────────────────

class _EmployeeSection {
  static List<OwnerEmployee> getEmployees(EmployeeManagementViewModel vm) {
    return vm.employees;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide table using ReusableDataTable
// ─────────────────────────────────────────────────────────────────────────────

class _WideTable extends StatelessWidget {
  final EmployeeManagementViewModel vm;
  final List<OwnerEmployee> employees;
  const _WideTable({required this.vm, required this.employees});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ReusableDataTable<OwnerEmployee>(
      items: employees,
      outerPadding: EdgeInsets.zero,
      minWidth: 720,
      columns: [
        ReusableTableColumn(key: 'name', title: l10n.ownerEmpColName.toUpperCase(), width: 120),
        ReusableTableColumn(key: 'role', title: l10n.ownerEmpColRole.toUpperCase(), width: 100),
        ReusableTableColumn(key: 'assignedRole', title: l10n.ownerEmpColAssignedRole.toUpperCase(), width: 100),
        ReusableTableColumn(key: 'dept', title: l10n.ownerEmpColDepartment.toUpperCase(), width: 130),
        ReusableTableColumn(key: 'branch', title: l10n.ownerEmpColBranch.toUpperCase(), width: 100),
        ReusableTableColumn(key: 'phone', title: l10n.ownerEmpColPhone.toUpperCase(), width: 105),
        ReusableTableColumn(
            key: 'commission',
            title: l10n.ownerEmpColCommission.toUpperCase(),
            width: 90,
            alignment: Alignment.center),
        ReusableTableColumn(
            key: 'duty',
            title: l10n.ownerEmpColWorkshopDuty.toUpperCase(),
            width: 100,
            alignment: Alignment.center),
        ReusableTableColumn(
            key: 'status',
            title: l10n.ownerEmpColStatus.toUpperCase(),
            width: 80,
            alignment: Alignment.center),
        ReusableTableColumn(
            key: 'actions',
            title: l10n.ownerEmpColActions.toUpperCase(),
            width: 140,
            alignment: Alignment.center),
      ],
      rowBuilder: (ctx, emp, idx) {
        final workshopDuty = _dutyInfo(emp, l10n);
        return [
          // Name
          Text(
            emp.displayName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Role
          Text(
            ownerLocalizeRoleName(l10n, emp.displayRole.replaceAll('_', ' ')),
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          // Assigned Role (custom role from permissions system)
          Text(
            '—',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400),
          ),
          // Department
          Text(
            emp.displayDepartmentLabels.isNotEmpty
                ? emp.displayDepartmentLabels.first
                : '—',
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Branch
          Text(
            emp.displayBranchName ?? '—',
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Phone
          Text(
            emp.mobile.isEmpty ? '—' : emp.mobile,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          // Commission %
          Text(
            '${emp.commissionPercent.toStringAsFixed(emp.commissionPercent == emp.commissionPercent.roundToDouble() ? 0 : 2)}%',
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          // Workshop Duty badge
          TablePill(
            label: workshopDuty.label,
            bgColor: workshopDuty.bg,
            textColor: workshopDuty.color,
            fontSize: 9.5,
          ),
          // Status badge
          TablePill(
            label: emp.isActive
                ? l10n.ownerCommonActiveLabel
                : l10n.ownerCommonInactive,
            bgColor: emp.isActive
                ? const Color(0xFFE8F8EF)
                : Colors.grey.shade100,
            textColor: emp.isActive
                ? const Color(0xFF27AE60)
                : Colors.grey.shade500,
            fontSize: 9.5,
          ),
          // Actions
          _TableActionRow(
            vm: vm,
            emp: emp,
          ),
        ];
      },
    );
  }
}

class _TableActionRow extends StatelessWidget {
  final EmployeeManagementViewModel vm;
  final OwnerEmployee emp;
  const _TableActionRow({required this.vm, required this.emp});

  @override
  Widget build(BuildContext context) {
    if (vm.actionEmployeeId == emp.id) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primaryLight),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIconBtn(
          icon: Icons.edit_outlined,
          color: OwnerListStyle.actionIcon,
          bg: OwnerListStyle.actionBg,
          onTap: () => _onEdit(context),
        ),
        const SizedBox(width: 4),
        _ActionIconBtn(
          icon: Icons.delete_outline_rounded,
          color: Colors.white,
          bg: Colors.red,
          onTap: () => _onDelete(context),
        ),
        const SizedBox(width: 4),
        _ActionIconBtn(
          icon: Icons.key_rounded,
          color: OwnerListStyle.actionIcon,
          bg: OwnerListStyle.actionBg,
          onTap: () => _onResetPassword(context),
        ),
        const SizedBox(width: 4),
        _ActionIconBtn(
          icon: Icons.shield_outlined,
          color: OwnerListStyle.actionIcon,
          bg: OwnerListStyle.actionBg,
          onTap: () => _onPermissions(context),
        ),
      ],
    );
  }

  void _onEdit(BuildContext context) {
    vm.setEditEmployee(emp);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const _AddEmployeeSheet(),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(employeeName: emp.displayName),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteEmployee(context, emp.id, emp.role);
    }
  }

  void _onResetPassword(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _ResetPasswordSheet(employee: emp),
      ),
    );
  }

  void _onPermissions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionsSheet(employee: emp),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile card list
// ─────────────────────────────────────────────────────────────────────────────

class _MobileEmployeeCard extends StatelessWidget {
  final OwnerEmployee employee;
  final EmployeeManagementViewModel vm;
  const _MobileEmployeeCard(
      {required this.employee, required this.vm});

  static const _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFEEEEEE))),
  );

  @override
  Widget build(BuildContext context) {
    final isDutyActive = _isDutyActive(employee);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + active dot (only when on-duty / active)
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _initials(employee.name),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: CatalogActiveDot(isActive: isDutyActive),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerLocalizeRoleName(
                        AppLocalizations.of(context)!,
                        employee.displayRole.replaceAll('_', ' '),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (employee.displayBranchName != null)
                          _InfoChip(
                            icon: Icons.store_outlined,
                            text: employee.displayBranchName!,
                          ),
                        if (employee.mobile.isNotEmpty)
                          _InfoChip(
                            icon: Icons.phone_outlined,
                            text: employee.mobile,
                          ),
                        _InfoChip(
                          icon: Icons.percent_rounded,
                          text:
                              '${employee.commissionPercent.toStringAsFixed(employee.commissionPercent == employee.commissionPercent.roundToDouble() ? 0 : 2)}%',
                        ),
                      ],
                    ),
                    if (employee.displayDepartmentLabels.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        text: employee.displayDepartmentLabels.first,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 4),

              if (vm.actionEmployeeId == employee.id)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryLight,
                    ),
                  ),
                )
              else
                _MobileActionMenu(employee: employee, vm: vm),
            ],
          ),
        ),
      ),
    );
  }

  /// Same meaning as the old Active badge (workshop-duty technicians).
  bool _isDutyActive(OwnerEmployee e) {
    if (e.role.toLowerCase() != 'technician') return false;
    return e.technicianType == 'workshop' || e.technicianType == 'both';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';

    String firstChar(String s) {
      if (s.isEmpty) return '';
      return String.fromCharCode(s.runes.first).toUpperCase();
    }

    if (parts.length == 1) {
      final c = firstChar(parts[0]);
      return c.isEmpty ? '?' : c;
    }
    final a = firstChar(parts[0]);
    final b = firstChar(parts[1]);
    if (a.isEmpty && b.isEmpty) return '?';
    return '$a$b';
  }
}

/// Three-dot menu that opens a bottom sheet with employee actions.
class _MobileActionMenu extends StatelessWidget {
  final OwnerEmployee employee;
  final EmployeeManagementViewModel vm;
  const _MobileActionMenu({required this.employee, required this.vm});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showActionsSheet(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 22,
        color: Colors.grey.shade600,
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmployeeActionsSheet(
        employee: employee,
        vm: vm,
      ),
    );
  }
}

class _EmployeeActionsSheet extends StatelessWidget {
  final OwnerEmployee employee;
  final EmployeeManagementViewModel vm;

  const _EmployeeActionsSheet({
    required this.employee,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  employee.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            _EmployeeActionTile(
              icon: Icons.edit_outlined,
              iconColor: OwnerListStyle.actionIcon,
              iconBg: OwnerListStyle.actionBg,
              label: l10n.empMgmtMenuEdit,
              onTap: () {
                Navigator.pop(context);
                _onEdit(context);
              },
            ),
            _EmployeeActionTile(
              icon: Icons.key_rounded,
              iconColor: OwnerListStyle.actionIcon,
              iconBg: OwnerListStyle.actionBg,
              label: l10n.ownerEmpMenuResetPassword,
              onTap: () {
                Navigator.pop(context);
                _onResetPassword(context);
              },
            ),
            _EmployeeActionTile(
              icon: Icons.shield_outlined,
              iconColor: OwnerListStyle.actionIcon,
              iconBg: OwnerListStyle.actionBg,
              label: l10n.ownerEmpMenuPermissions,
              onTap: () {
                Navigator.pop(context);
                _onPermissions(context);
              },
            ),
            _EmployeeActionTile(
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.white,
              iconBg: Colors.red,
              label: l10n.empMgmtMenuDelete,
              labelColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _onDelete(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onEdit(BuildContext context) {
    vm.setEditEmployee(employee);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const _AddEmployeeSheet(),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(employeeName: employee.displayName),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteEmployee(context, employee.id, employee.role);
    }
  }

  void _onResetPassword(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _ResetPasswordSheet(employee: employee),
      ),
    );
  }

  void _onPermissions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionsSheet(employee: employee),
    );
  }
}

class _EmployeeActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _EmployeeActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: labelColor ?? AppColors.secondaryLight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper to compute workshop duty info
// ─────────────────────────────────────────────────────────────────────────────

({String label, Color color, Color bg}) _dutyInfo(
  OwnerEmployee e,
  AppLocalizations l10n,
) {
  if (e.role.toLowerCase() == 'technician') {
    final isWorkshop =
        e.technicianType == 'workshop' || e.technicianType == 'both';
    return isWorkshop
        ? (
    label: l10n.ownerCommonActiveLabel,
    color: const Color(0xFF27AE60),
    bg: const Color(0xFFE8F8EF),
    )
        : (
    label: l10n.ownerEmpDutyOff,
    color: Colors.grey.shade600,
    bg: Colors.grey.shade100,
    );
  }
  return (
  label: l10n.ownerEmpDutyOff,
  color: Colors.grey.shade600,
  bg: Colors.grey.shade100,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Employee bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddEmployeeSheet extends StatefulWidget {
  const _AddEmployeeSheet();

  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  String _selectedRole = 'cashier';
  String? _selectedBranchId;
  String _selectedCommissionType = '% of Revenue';
  String _selectedStatus = 'Active';
  final Set<String> _selectedDepartmentIds = {};
  bool _isWorkshop = true;
  bool _isOnCall = true;
  bool _isTechnician = false;
  bool _passwordVisible = false;
  final TextEditingController _iqamaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Compute synchronously — avoids an extra rebuild frame when sheet opens
    final vm = context.read<EmployeeManagementViewModel>();
    if (vm.branches.length == 1) {
      _selectedBranchId = vm.branches.first.id;
    }
  }

  @override
  void dispose() {
    _iqamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EmployeeManagementViewModel>();
    final isEditing = vm.isEditing;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: OwnerUi.sheetInitialSize,
      minChildSize: OwnerUi.sheetMinSize,
      maxChildSize: OwnerUi.sheetMaxSize,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle + header ──────────────────────────────────
            _SheetHeader(
              title: isEditing
                  ? AppLocalizations.of(context)!.ownerEmpFormEditTitle
                  : AppLocalizations.of(context)!.ownerEmpFormAddTitle,
              onClose: () => Navigator.pop(ctx),
            ),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPad),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    final currency = l10n.ownerCurrencySar;
                    String roleLabel(String r) =>
                        ownerLocalizeRoleName(l10n, r);

                    String commissionLabel(String t) {
                      switch (t) {
                        case '% of Revenue':
                          return l10n.ownerEmpCommOfRevenue;
                        case '% of Service':
                          return l10n.ownerEmpCommOfService;
                        case '% of Profit':
                          return l10n.ownerEmpCommOfProfit;
                        case 'Fixed per Order':
                          return l10n.ownerEmpCommFixedPerOrder;
                        default:
                          return t;
                      }
                    }

                    return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── BASIC INFORMATION ─────────────────────────────
                    _SectionLabel(text: l10n.ownerEmpFormBasicInfo),
                    const SizedBox(height: 12),

                    // Full Name + Mobile
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: l10n.ownerEmpFormFullName,
                            required: true,
                            controller: vm.nameController,
                            hint: l10n.ownerEmpFormFullName,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            label: l10n.ownerEmpFormMobile,
                            required: true,
                            controller: vm.mobileController,
                            hint: l10n.ownerEmpFormMobileHint,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Email + Iqama / CNIC
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: l10n.ownerEmpFormEmail,
                            controller: vm.emailController,
                            hint: l10n.ownerEmpFormEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            label: l10n.ownerEmpFormIqama,
                            controller: _iqamaController,
                            hint: l10n.ownerEmpFormIqama,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Branch + Role
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(
                                l10n.ownerEmpFormBranch,
                                required: true,
                              ),
                              const SizedBox(height: 6),
                              OwnerStyledDropdown<String>(
                                value: _selectedBranchId,
                                hint: l10n.ownerEmpFormSelectBranch,
                                height: 48,
                                localizeLabels: false,
                                options: vm.branches.isEmpty
                                    ? [
                                        OwnerDropdownOption(
                                          value: '__none',
                                          label: l10n.ownerEmpFormNoBranches,
                                        ),
                                      ]
                                    : vm.branches
                                        .map((b) => OwnerDropdownOption(
                                              value: b.id,
                                              label: (b.translatedName ?? b.name)
                                                  .toUpperCase(),
                                            ))
                                        .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedBranchId = v),
                                triggerStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.ownerEmpFormRole),
                              const SizedBox(height: 6),
                              OwnerStyledDropdown<String>(
                                value: _selectedRole,
                                hint: l10n.ownerEmpFormSelectRole,
                                height: 48,
                                localizeLabels: false,
                                displayLabel: roleLabel(_selectedRole),
                                options: _kRoles
                                    .map((r) => OwnerDropdownOption(
                                          value: r,
                                          label: roleLabel(r),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedRole = v;
                                      // Auto-set technician flag when role is technician
                                      _isTechnician = v == 'technician';
                                    });
                                  }
                                },
                                triggerStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.ownerEmpFormRoleHint,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.grey.shade500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── DEPARTMENTS (show when technician role or flag) ─
                    if (_selectedRole == 'technician' || _isTechnician) ...[
                      _FieldLabel(
                        l10n.ownerEmpFormDepartments,
                        suffix: l10n.ownerEmpFormDepartmentsSuffix,
                      ),
                      const SizedBox(height: 10),
                      _DepartmentPicker(
                        departments: vm.departments,
                        selectedIds: _selectedDepartmentIds,
                        onToggle: (id, selected) => setState(() {
                          if (selected) {
                            _selectedDepartmentIds.add(id);
                          } else {
                            _selectedDepartmentIds.remove(id);
                          }
                        }),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── TECHNICIAN SETTINGS ────────────────────────────
                    _SectionLabel(text: l10n.ownerEmpFormTechSettings),
                    const SizedBox(height: 12),
                    _CheckRow(
                      label: l10n.ownerEmpFormIsTechnician,
                      value: _isTechnician,
                      onChanged: (v) =>
                          setState(() => _isTechnician = v ?? false),
                    ),
                    if (_isTechnician) ...[
                      const SizedBox(height: 12),
                      _FieldLabel(l10n.ownerEmpFormTechType),
                      const SizedBox(height: 4),
                      Text(
                        l10n.ownerEmpFormTechTypeHint,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade500,
                            height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _CheckRow(
                            label: l10n.ownerEmpFormWorkshop,
                            value: _isWorkshop,
                            onChanged: (v) =>
                                setState(() => _isWorkshop = v ?? false),
                          ),
                          const SizedBox(width: 24),
                          _CheckRow(
                            label: l10n.ownerEmpFormOnCall,
                            value: _isOnCall,
                            onChanged: (v) =>
                                setState(() => _isOnCall = v ?? false),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── FINANCIAL ──────────────────────────────────────
                    _SectionLabel(text: l10n.ownerEmpFormFinancial),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: l10n.ownerEmpFormBasicSalary(currency),
                            controller: vm.baseSalaryController,
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            label: l10n.ownerEmpFormCommissionPct,
                            controller: vm.commissionPercentController,
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.ownerEmpFormCommissionType),
                              const SizedBox(height: 6),
                              OwnerStyledDropdown<String>(
                                value: _selectedCommissionType,
                                hint: l10n.ownerEmpFormSelectType,
                                height: 48,
                                localizeLabels: false,
                                displayLabel:
                                    commissionLabel(_selectedCommissionType),
                                options: _kCommissionTypes
                                    .map((t) => OwnerDropdownOption(
                                          value: t,
                                          label: commissionLabel(t),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(
                                            () => _selectedCommissionType = v);
                                  }
                                },
                                triggerStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(l10n.ownerEmpFormStatus),
                              const SizedBox(height: 6),
                              OwnerStyledDropdown<String>(
                                value: _selectedStatus,
                                hint: l10n.ownerEmpFormSelectStatus,
                                height: 48,
                                localizeLabels: false,
                                displayLabel: _selectedStatus == 'Active'
                                    ? l10n.ownerCommonActiveLabel
                                    : l10n.ownerCommonInactive,
                                options: [
                                  OwnerDropdownOption(
                                      value: 'Active',
                                      label: l10n.ownerCommonActiveLabel),
                                  OwnerDropdownOption(
                                      value: 'Inactive',
                                      label: l10n.ownerCommonInactive),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedStatus = v);
                                    vm.toggleStatus(v == 'Active');
                                  }
                                },
                                triggerStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── INITIAL PASSWORD ───────────────────────────────
                    _SectionLabel(text: l10n.ownerEmpFormInitialPassword),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ownerEmpFormPasswordHint,
                      style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    _PasswordField(
                      controller: vm.passwordController,
                      hint: l10n.ownerEmpFormPasswordPlaceholder,
                      visible: _passwordVisible,
                      onToggle: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    const SizedBox(height: 32),

                    // ── ACTION BUTTONS ─────────────────────────────────
                    OwnerSheetActions(
                      onCancel: () => Navigator.pop(ctx),
                      onPrimary: vm.isActionLoading ? null : _submit,
                      isLoading: vm.isActionLoading,
                      primaryLabel: l10n.ownerEmpFormSave,
                    ),
                  ],
                );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final vm = context.read<EmployeeManagementViewModel>();
    if (_selectedRole == 'technician' || _isTechnician) {
      await vm.submitTechnicianForm(
        context,
        branchId: _selectedBranchId,
        departmentId: _selectedDepartmentIds.isNotEmpty
            ? _selectedDepartmentIds.first
            : null,
        isWorkshop: _isWorkshop,
        isOnCall: _isOnCall,
      );
    } else {
      await vm.submitCashierForm(context, branchId: _selectedBranchId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Department picker grid
// ─────────────────────────────────────────────────────────────────────────────

class _DepartmentPicker extends StatelessWidget {
  final List departments; // List<Department>
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  const _DepartmentPicker({
    required this.departments,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: departments.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.of(context)!.ownerEmpFormNoDepartments,
          style:
          TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      )
          : GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.2,
        ),
        itemCount: departments.length,
        itemBuilder: (ctx, i) {
          final dept = departments[i];
          final selected = selectedIds.contains(dept.id as String);
          return GestureDetector(
            onTap: () =>
                onToggle(dept.id as String, !selected),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: selected,
                    activeColor: AppColors.primaryLight,
                    checkColor: AppColors.secondaryLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => onToggle(
                        dept.id as String, v == true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LocalizedApiText(
                    dept.name as String,
                    uppercase: true,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.secondaryLight
                          : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reset Password sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ResetPasswordSheet extends StatefulWidget {
  final OwnerEmployee employee;
  const _ResetPasswordSheet({required this.employee});

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _newPasswordCtrl = TextEditingController();
  bool _visible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: l10n.ownerEmpResetTitle,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwnerListStyle.actionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 16, color: OwnerListStyle.actionIcon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.employee.displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(l10n.ownerEmpResetNewPassword),
          const SizedBox(height: 6),
          _PasswordField(
            controller: _newPasswordCtrl,
            hint: l10n.ownerEmpResetHint,
            visible: _visible,
            onToggle: () => setState(() => _visible = !_visible),
          ),
          const SizedBox(height: 24),
          OwnerSheetActions(
            onCancel: () => Navigator.pop(context),
            onPrimary: _isLoading ? null : _submit,
            isLoading: _isLoading,
            primaryLabel: l10n.ownerEmpResetTitle,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_newPasswordCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Stub
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTE: _RolesPermissionsSheet, _CreateRoleSheet, _PermNode, _PermSection,
// _buildPermSections, _kRoleNames, _kPortals, and _BranchChip have been moved
// to roles_sheet.dart.  Use RolesPermissionsSheet (public) from that file.
// ─────────────────────────────────────────────────────────────────────────────


class _PermissionsSheet extends StatelessWidget {
  final OwnerEmployee employee;
  const _PermissionsSheet({required this.employee});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: l10n.ownerEmpAssignRoleTitle,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwnerListStyle.actionBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: OwnerListStyle.actionIcon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    employee.displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4C1D95)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.ownerEmpAssignRoleEmpty,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(l10n.ownerCommonClose,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryLight)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final String employeeName;
  const _DeleteConfirmDialog({required this.employeeName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.empMgmtDeleteTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.empMgmtDeleteBody(employeeName),
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
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      l10n.empMgmtDeleteCancel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.secondaryLight,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.empMgmtDeleteConfirm,
                      style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w800,
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading shimmer (full page — matches real layout)
// ─────────────────────────────────────────────────────────────────────────────

class _EmployeesPageShimmer extends StatelessWidget {
  const _EmployeesPageShimmer();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OwnerUi.scaffoldBackground,
      child: PosShimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const OwnerKpiGridShimmer(
              count: 3,
              crossAxisCount: 3,
              childAspectRatio: 1.35,
            ),
            const SizedBox(height: 8),
            const OwnerSearchBarShimmer(),
            const SizedBox(height: 10),
            const PosShimmerBox(
              width: double.infinity,
              height: 44,
              radius: 14,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              6,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: OwnerCardRowShimmer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClearSearch;
  const _EmptyState(
      {required this.isFiltered, required this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Icon(
            isFiltered
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered
                ? AppLocalizations.of(context)!.ownerEmployeesEmptyFiltered
                : AppLocalizations.of(context)!.ownerEmployeesEmptyDefault,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClearSearch,
              child: Text(AppLocalizations.of(context)!.ownerEmployeesClearSearch),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final String? suffix;
  final bool required;
  const _FieldLabel(this.label, {this.suffix, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.grey.shade600,
        ),
        children: [
          if (required)
            const TextSpan(
                text: ' *', style: TextStyle(color: Colors.red)),
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.required = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primaryLight, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool visible;
  final VoidCallback onToggle;
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.grey.shade400, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool?>? onChanged;
  const _CheckRow({
    required this.label,
    required this.value,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primaryLight,
            checkColor: AppColors.secondaryLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared badge / chip widgets
// ─────────────────────────────────────────────────────────────────────────────

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
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  const _ActionIconBtn(
      {required this.icon,
        required this.color,
        required this.bg,
        this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}